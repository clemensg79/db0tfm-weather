#!/usr/local/bin/perl
use strict;
use warnings;
use LWP::Simple;
use Data::Dumper;
use Daemon::Generic;
use File::Path qw(make_path remove_tree);
use POSIX 'strftime';
use Astro::Sunrise;
use DateTime;
use Time::Local;
$ENV{TZ}="Europe/Berlin";

my $sleep = 60;
my $wwwpath = '/usr/local/www/nginx/cam/';
my $imageurl = 'http://192.168.1.2/cgi-bin/CGIProxy.fcgi?cmd=snapPicture2&usr=admin&pwd=teufel';
my $wwwowner = 'www';
my $wwwgroup = 'www';

newdaemon(
	progname => 'cam.pl',
	pidfile => 'cam.pid',
);

sub gd_run {
	while(1) {
		if (is_day()) {
			make_datedir();
			get_image();
		}
		sleep 60;
	}
}



sub get_image {
	my $time = strftime '%H%M%S', localtime;	
	
	my $imagepath = image_path(); 
	my $imagefile = $imagepath.'/'.$time.'.jpg';
	my $rc = LWP::Simple::getstore($imageurl,$imagefile);

	if (is_success($rc)) {
		# overlay wind image
		overlay_image($imagefile);
	
		#atomic symlink the last picture
		my $imagefilelatest = $imagepath.'/latest.jpg';
		my $imagefilelatesttmp = $imagepath.'/latest.jpgtmp';
		symlink($imagefile,$imagefilelatesttmp);
		rename($imagefilelatesttmp,$imagefilelatest);
	} else {
		print "Error: while fetching Url $imageurl\n";
		print "Error: deleting broker image $imagefile\n";
		unlink($imagefile);

	}
	return $rc;
}

sub overlay_image {
	my $origimage = shift;
	my $imagepath = image_path();
	my $windimage = $imagepath.'/wind.png';	
	my $overlayimage = $imagepath.'/overlay.jpg';

	`convert $origimage $windimage -background black -flatten -alpha remove -alpha off -quality 100% $overlayimage`;	
	unlink($origimage);
	rename($overlayimage,$origimage);
}


sub is_day {
	# Loffenau
	# Koordinaten: 8°23'O, 48°46'N900m Höhe über NN
	
	my $is_day = 0;	
	my $sunrise = sun_rise( { lat => 48.46, lon => 8.23 } );
	my $sunset = sun_set( { lat => 48.46, lon => 8.23 } );
	
	my @sunrise = split(/:/,$sunrise); 
	my @sunset  = split(/:/,$sunset); 
		
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	my $sunrise_epoch = timelocal(0,$sunrise[1],$sunrise[0],$mday,$mon,$year); 
	my $sunset_epoch = timelocal(0,$sunset[1],$sunset[0],$mday,$mon,$year); 
	$sunrise_epoch = $sunrise_epoch-1200;
	$sunset_epoch = $sunset_epoch+1200;
	my $epoch = time;
	if ($epoch > $sunrise_epoch and $epoch < $sunset_epoch) {
		$is_day = 1;
	}
	return $is_day;
}

sub make_datedir {
	my $imagepath = image_path(); 
	make_path $imagepath, {owner=>$wwwowner, group=>$wwwgroup};

	#atomic symlink with rename
	symlink($imagepath,$wwwpath.'latesttmp');
	rename($wwwpath.'latesttmp',$wwwpath.'latest');
}

sub image_path {
	my $date = strftime '%Y%m%d', localtime;	
	return $wwwpath.$date;
} 
