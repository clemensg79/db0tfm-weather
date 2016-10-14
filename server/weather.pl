#!/usr/bin/perl
use strict;
use warnings;
#use LWP::Simple;
#use JSON::Parse 'parse_json';
use Data::Dumper;
use RRD::Simple;
use POSIX 'strftime';
use Daemon::Generic;
use Storable;
use Math::Round;
use GD;
use GD::Arrow;
use Math::Round;
use Math::Trig;
use Ham::APRS::FAP;
#use IO::Socket::INET;
use IO::Socket::INET6;
use threads;
use threads::shared;

$ENV{TZ}="Europe/Berlin";

my $aprswxcall = "DB0TFM-6";
my $aprsheaderfilter = 'DB0TFM-6>APOTC1,WIDE1-1,WIDE2-1';
my $maxentries = 10;
my $wwwpath = "/tmp";

my $perlstorefile = lc($aprswxcall).".perlstore";
my $htmlfile = $wwwpath.'/'.lc($aprswxcall).".inc";

my $wind_speed :shared = 0;
my $wind_gust :shared = 0;
my $wind_dir :shared = 0;
my $wind_dir_cor = -40;
my $temp :shared = 0;
my $hum :shared = 0;
my $rain :shared = 0;
my $epochrcvd :shared = 0;


newdaemon(
	progname => 'weather.pl',
	pidfile => 'weather.pid',
);

sub gd_run {


my $thr1 = threads->create(\&update_rrd);
$thr1->detach();
#my $thr2 = threads->create(\&socket_server4);
#$thr2->detach();
my $thr3 = threads->create(\&socket_server6);
$thr3->detach();

	#generate arrows
	genarrows();

	my $json;
	my $epochlast = 0;
	my @lastentries;
	my $lastcount = 0;
	my $lastpacketbody = '';
	my $lastentriesref = retrieve($perlstorefile) if -f "$perlstorefile";
	if (defined $lastentriesref) {
		@lastentries = @{$lastentriesref};
		$lastcount = @lastentries;
		my $lastentrie  = $lastentries[$lastcount-1];
		$epochlast = $lastentrie->{time};
	}


	open (PIPE, "./aprs.sh |") || die "couldn't start pipe: $!";

	while (<PIPE>) {
		chomp;
		next if (!m/^APRS: /); 
		s/^APRS: //g;
		my %packet = parse_aprs($_);
	
		next if (!defined $packet{'srccallsign'});
		my $srccallsign = $packet{'srccallsign'}; 
		next if ($srccallsign ne $aprswxcall);

		next if (!defined $packet{'wx'} );
		my $entrie = $packet{'wx'};
	
		# check if wx packet was received more than once	
		my $packetbody = $packet{'body'};
		next if ($packetbody eq $lastpacketbody);
		$lastpacketbody = $packetbody;		

		$wind_speed = $entrie->{wind_speed} if (defined $entrie->{wind_speed});
		$wind_gust = $entrie->{wind_gust} if (defined $entrie->{wind_gust});
		$wind_dir = $entrie->{wind_direction} if (defined $entrie->{wind_direction});

		#wind dir correction
		if (($wind_dir + $wind_dir_cor) >= 0 ) {
			$wind_dir = $wind_dir + $wind_dir_cor;
		} elsif (($wind_dir + $wind_dir_cor) < 0 ) {
			$wind_dir = $wind_dir + $wind_dir_cor + 360;
		}

		$temp = $entrie->{temp} if (defined $entrie->{temp});	
		$hum = $entrie->{humidity} if (defined $entrie->{humidity});	
		$rain = $entrie->{rain_1h} if (defined $entrie->{rain_1h});

		$entrie->{time} = time();
		my $epoch = $entrie->{time};
		$epochrcvd = $entrie->{time};

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
		
		#print "Wind Speed:$wind_speed Wind Gust:$wind_gust Wind Direction: $wind_dir\n";	
		printhtml(\@lastentries);
	}
	close (PIPE);
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
		$ws = $row->{wind_speed} * 3.6;	
		$wg = $row->{wind_gust} * 3.6;		
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
		$wdclass = "tg-green" if ($wd >= 290 and $wd <= 355);
		# windrichtung nicht ok
		$wdclass = "tg-red" if ($wd >= 0 and $wd <= 250);
		$wdclass = "tg-red" if ($wd >= 356 and $wd <= 360);
		# windrichtung grenzwaertig
		$wdclass = "tg-yellow" if ($wd >= 251 and $wd <= 289);

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

sub parse_aprs { 
	my $aprspacket = shift;
	my %packet;
	my $retval = Ham::APRS::FAP::parseaprs($aprspacket, \%packet);
	if ($retval == 0) {
		%packet = ();
	}
	return %packet;
}

sub update_rrd{
	my $rrdfile = lc($aprswxcall).".rrd";
	my $rrd = RRD::Simple->new( file => $rrdfile );

	$rrd->create('3years',
		wind_speed => "GAUGE",
		wind_direction => "GAUGE",
		wind_gust => "GAUGE",
	) unless -f $rrdfile;
	
	while(1) {
		$rrd->update(
			wind_speed => $wind_speed*3.6,
			wind_direction => $wind_dir,
			wind_gust => $wind_gust*3.6
		);
		sleep 60;
	}
}

sub handle_connection {
    my $socket = shift;
    my $output = shift || $socket;
    print $output "$epochrcvd:$wind_speed:$wind_gust:$wind_dir\n";
}

sub socket_server4{

        # creating a listening socket ipv4 only
        my $listen4 = new IO::Socket::INET (
            LocalAddr => '0.0.0.0',
            LocalPort => '7777',
            Proto => 'tcp',
            Listen => 10,
            Reuse => 1,
        );

        while (my $socket4 = $listen4->accept) {
                async(\&handle_connection, $socket4)->detach;
        }
}

sub socket_server6{

        # creating a listening socket ipv6 only
        my $listen6= new IO::Socket::INET6 (
            LocalAddr => '::',
            LocalPort => '7777',
            Proto => 'tcp',
            Listen => 10,
            Reuse => 1,
        );

        while (my $socket6 = $listen6->accept) {
                async(\&handle_connection, $socket6)->detach;
        }
}
