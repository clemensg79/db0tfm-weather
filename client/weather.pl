#!/usr/local/bin/perl
use strict;
use warnings;
use LWP::Simple;
use JSON::Parse 'parse_json';
use Data::Dumper;
use RRD::Simple;
use POSIX 'strftime';
use Daemon::Generic;
use Storable;
#use 5.014;
use Math::Round;
use GD;
use GD::Arrow;
use GD::Simple;
use Math::Round;
use Math::Trig;
use IO::Socket::INET;

$ENV{TZ}="Europe/Berlin";

my $aprswxcall = "DB0TFM-6";
my $maxentries = 10;
my $wwwpath = "/usr/local/www/nginx/wind/";
my $campath = "/usr/local/www/nginx/cam/latest/";

#my $jsonurl = "http://api.aprs.fi/api/get\?name=".$aprswxcall."\&what=wx\&apikey=74798.6oguLdHy9T2EBk\&format=json";
my $perlstorefile = lc($aprswxcall).".perlstore";
my $htmlfile = $wwwpath.lc($aprswxcall).".inc";
my $rrdfile = lc($aprswxcall).".rrd";
my $rrd = RRD::Simple->new( file => $rrdfile );


$rrd->create('3years',
	wind_speed => "GAUGE",
	wind_direction => "GAUGE",
	wind_gust => "GAUGE",
) unless -f $rrdfile;



newdaemon(
	progname => 'weather.pl',
	pidfile => 'weather.pid',
);

sub gd_run {
	#generate arrows
	genarrows();
	#my $json;
	my $epochlast = 0;
	my @lastentries;
	my $lastcount = 0;
	my $lastentriesref = retrieve($perlstorefile) if -f "$perlstorefile";
	if (defined $lastentriesref) {
		@lastentries = @{$lastentriesref};
		$lastcount = @lastentries;
		my $lastentrie  = $lastentries[$lastcount-1];
		$epochlast = $lastentrie->{time};
	}


	while (1) {
		my $socket_data = socket_client();
		$socket_data =~ m/^(\d+):(\d+\.\d+):(\d+\.\d+):(\d+)$/g;
		my $epoch = $1;
		my $wind_speed = $2;
		my $wind_gust = $3;
		my $wind_dir = $4;

		my $entrie;
		$entrie->{time} = $epoch;
		$entrie->{wind_speed} = $wind_speed;
		$entrie->{wind_gust} = $wind_gust;
		$entrie->{wind_direction} = $wind_dir;

	      	my $date = strftime '%Y/%m/%d %H:%M:%S', localtime $epoch;	
		if ($epoch != $epochlast) {
			$epochlast = $epoch;
			push @lastentries, $entrie;
			store(\@lastentries, $perlstorefile) || die "can't store to file $perlstorefile\n";
			$lastcount++;
			if ($lastcount >= $maxentries+1 ) {
				shift @lastentries;
				$lastcount--;
			}
		}
		$rrd->update(
			wind_speed => $wind_speed*3.6,
			wind_direction => $wind_dir,
			wind_gust => $wind_gust*3.6
		);
		printhtml(\@lastentries);

		# generate image for cam overlay
		genwindimg($wind_speed*3.6, $wind_gust*3.6, $wind_dir);
		
		sleep 60;
	}
}

sub printhtml {
	my $entriesref = shift;
	my @entries = @{$entriesref}; 

	open(my $FH, '>', $htmlfile) or die "Could not open file '$htmlfile' $!";

	print $FH <<EOF;
<style type="text/css">
.tg  {border-collapse:collapse;border-spacing:0;border-color:#aaa;}
.tg td{font-family:Arial, sans-serif;font-size:14px;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;border-color:#aaa;color:#333;background-color:#fff;}
.tg th{font-family:Arial, sans-serif;font-size:14px;font-weight:normal;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;border-color:#aaa;color:#fff;background-color:#f38630;}
.tg .tg-green{background-color:#009901}
.tg .tg-red{background-color:#fe0000}
.tg .tg-yellow{background-color:#f8ff00}
</style>
<table class="tg">
  <tr>
    <th class="tg-031e">Messzeitpunkt</th>
    <th class="tg-031e">Windr. (Grad)</th>
    <th class="tg-031e">Windgesch. (km/h)</th>
    <th class="tg-031e">Windboen (km/h)</th>
  </tr>
EOF
	
	foreach my $row (reverse @entries) {
		my ($ws,$wg,$wd,$t,$h,$r,$e,$d) = 0;
		$ws = $row->{wind_speed}*3.6;	
		$wg = $row->{wind_gust}*3.6;		
		$wd = $row->{wind_direction};
		$wd = 0 if ($wd eq '');	
		$t = $row->{temp};	
		$h = $row->{humidity};	
		$r = $row->{rain_nm};	
		$e = $row->{time};
		$d = strftime '%d/%m/%Y %H:%M:%S', localtime $e;	

		my $wdclass = "tg-031e";
		my $wsclass = "tg-031e";
		my $wgclass = "tg-031e";

		# windrichtung ok
		$wdclass = "tg-green" if ($wd >= 250 and $wd <= 340);
		# windrichtung nicht ok
		$wdclass = "tg-red" if ($wd >= 0 and $wd <= 240);
		$wdclass = "tg-red" if ($wd >= 351 and $wd <= 360);
		# windrichtung grenzwaertig
		$wdclass = "tg-yellow" if ($wd >= 240 and $wd <= 249);
		$wdclass = "tg-yellow" if ($wd >= 341 and $wd <= 350);

		#round
		$ws = round($ws);
		# windstaerke ok
		$wsclass = "tg-green" if ($ws >= 0 and $ws <= 18);
		# windstaerke naja
		$wsclass = "tg-yellow" if ($ws >= 19 and $ws <= 25);
		# windstaerke ohha 
		$wsclass = "tg-red" if ($ws >= 26);
	
			
		# windboe ok
		$wg = round($wg);
		$wgclass = "tg-green" if ($wg >= 0 and $wg <= 21);
		# windboe naja
		$wgclass = "tg-yellow" if ($wg >= 22 and $wg <= 28);
		# windbow ohha 
		$wgclass = "tg-red" if ($wg >= 29);

		my $windtext = wind2text($wd);
		print $FH <<EOF;
  <tr>
    <td class="tg-031e">$d</td>
    <td class="$wdclass"><img src="arrow$wd.png">$windtext ($wd)</td>
    <td class="$wsclass">$ws</td>
    <td class="$wgclass">$wg</td>
  </tr>
EOF
		}
print $FH <<EOF;
</table>
EOF
	close $FH;
}

sub wind2text {
	my $wd = shift;
	my $wdtext = 'Error';
	$wdtext = 'N  ' if ($wd >= 0   and $wd <= 10);
	$wdtext = 'NNE' if ($wd >= 11  and $wd <= 30);
	$wdtext = 'NE ' if ($wd >= 31  and $wd <= 60);
	$wdtext = 'ENE' if ($wd >= 61  and $wd <= 80);
	$wdtext = 'E  ' if ($wd >= 81  and $wd <= 100);
	$wdtext = 'ESE' if ($wd >= 101  and $wd <= 120);
	$wdtext = 'SE ' if ($wd >= 121  and $wd <= 150);
	$wdtext = 'SSE' if ($wd >= 151  and $wd <= 170);
	$wdtext = 'S  ' if ($wd >= 171  and $wd <= 190);
	$wdtext = 'SSW' if ($wd >= 191  and $wd <= 210);
	$wdtext = 'SW ' if ($wd >= 211  and $wd <= 240);
	$wdtext = 'WSW' if ($wd >= 241  and $wd <= 260);
	$wdtext = 'W  ' if ($wd >= 261  and $wd <= 280);
	$wdtext = 'WNW' if ($wd >= 281  and $wd <= 300);
	$wdtext = 'NW ' if ($wd >= 301  and $wd <= 330);
	$wdtext = 'NNW' if ($wd >= 331  and $wd <= 350);
	$wdtext = 'N  ' if ($wd >= 351  and $wd <= 360);
	return $wdtext;
}

sub genarrows{
	my $width = 4;
	for (my $i=0;$i<=360;$i++) {
		my $j = $i + 180;
		$j = $j - 360 if ($i > 180 ); 
		my $r = 12;
		my $irad = deg2rad($i+90);
		my $jrad = deg2rad($j+90);
		my $x1 = round($r*cos($irad))+16;
		my $y1 = round($r*sin($irad))+16;
		my $x2 = round($r*cos($jrad))+16;
		my $y2 = round($r*sin($jrad))+16;

	my $arrow = GD::Arrow::Full->new( 
	                -X1    => $x1, 
	                -Y1    => $y1, 
	                -X2    => $x2, 
	                -Y2    => $y2, 
	                -WIDTH => $width,
	            );
 
	my $image = GD::Image->new(32, 32);
	my $white = $image->colorAllocate(255, 255, 255);
	my $black = $image->colorAllocate(0, 0, 0);
	my $blue = $image->colorAllocate(0, 0, 255);
	my $yellow = $image->colorAllocate(255, 255, 0);
	# make the background transparent and interlaced
	$image->transparent($white);
	$image->interlaced('true');
	$image->setAntiAliased($white);
	 
	$image->filledPolygon($arrow,$black);
	$image->polygon($arrow,$black, gdAntiAliased);

	open IMAGE, "> $wwwpath/arrow$i.png" or die $!;
	binmode(IMAGE, ":raw");
	print IMAGE $image->png;
	close IMAGE;
	}
}

sub genwindimg {
	my $ws = shift; # wind speed km/h
	my $wg = shift; # wind gust speed km/h
	my $wd = shift; # wind direction

	$ws = round($ws);
	$wg = round($wg);

	# create a new image (width, height)
	my $image = GD::Image->new(1280,720);
        $image->colorAllocateAlpha(0, 0, 0, 127);

        my $white = $image->colorAllocate(255, 255, 255);
	my $black = $image->colorAllocate(0, 0, 0);
	my $green = $image->colorAllocate(0, 255, 0);
	my $red = $image->colorAllocate(255, 0, 0);
	my $orange = $image->colorAllocate(255, 140, 0);
	
	$image->filledRectangle(45,680-$wg*10, 50, 680, $red); # (top_left_x, top_left_y, bottom_right_x, bottom_right_y)
	$image->filledRectangle(40,680-$ws*10, 45, 680, $green); # (top_left_x, top_left_y, bottom_right_x, bottom_right_y)
	
	#draw ruler
	$image->line(30, 680-35*10, 30, 680, $white);
	for my $i (0..35) {
	        $image->setThickness(2);
	        $image->string(&gdGiantFont, 0, 670-$i*10, $i, $white) if (($i % 5)==0);
	        $image->line(25, 680-$i*10,35,680-$i*10,$white);
	        $image->line(20, 680-$i*10,40,680-$i*10,$white) if (($i % 5) == 0);
	}

	#draw ruler
	my $offset = 60;
	my $calib = 240;
	# fliegbarer bereich 350 grad bis 240 grad = 110 Grad 
	my $flywindow = 110;
	$image->setThickness(2);
	$image->line(40, 695, 1200, 695, $white);

	#draw ruler
	for my $i (0..$flywindow) {
	        $image->setThickness(2);
	        my $x = ($i*10)+$offset;
	        $image->line($x,690,$x,700,$white);
	        $image->line($x,685,$x,705,$white) if (($i % 5)==0);
	        my $str = $i+$calib;
	        $image->string(&gdGiantFont, $i*10-4+60, 705, $str, $white) if (($i % 5)==0);
	}
	# 240 Grad bis 250 Grad = 0-10 = Orange
	$image->line($offset, 695, $offset+10*10, 695, $orange);

	## 250 Grad bis 295 Grad = 10-55 = Gruen Startplatz West 
	# 250 Grad bis 320 Grad = 10-80 = Gruen Startplatz West + NW
	#$image->line($offset+10*10, 695, $offset+55*10, 695, $green);
	$image->line($offset+10*10, 695, $offset+80*10, 695, $green);

	# 295 Grad bis 300 Grad = 55 - 60 = Orange
	#$image->line($offset+55*10, 695, $offset+60*10, 695, $orange);

	# 300 Grad bis 320 Grad = 60 - 80 = Gruen = Startplatz NW
	#$image->line($offset+60*10, 695, $offset+80*10, 695, $green);

	# 320 Grad bis 350 Grad = 80 - 110 = Orange
	$image->line($offset+80*10, 695, $offset+110*10, 695, $orange);

	# draw wind dir
	if ($wd >= $calib and $wd <= $calib+$flywindow) {
		my $x = (($wd-$calib)*10)+$offset;
		$image->setThickness(4);
	        $image->line($x,675,$x,720,$green);
	}
	
        # make the background transparent and interlaced
	$image->transparent($black);
        $image->interlaced('true');
        $image->setAntiAliased($black);
	$image->alphaBlending(1);
	$image->saveAlpha(1);
	
	# convert into png data
        open IMAGE, "> $campath/wind.png" or die $!;
        binmode(IMAGE, ":raw");
        print IMAGE $image->png;
        close IMAGE;
}

sub socket_client{
	# create a connecting socket
	my $socket = new IO::Socket::INET (
	    PeerHost => '192.168.1.144',
	    PeerPort => '7777',
	    Proto => 'tcp',
	);
	my $response='0:0:0:0:0';
	return $response unless $socket;
	
	$socket->recv($response, 80);
 
	$socket->close();
	return $response;
}
