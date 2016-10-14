#!/bin/sh
export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/games:/usr/local/sbin:/usr/local/bin:/root/bin
LATEST=/usr/local/www/nginx/cam/latest/
cd $LATEST
/home/gesell/timelapse-deflicker.pl -p 2 -v
cd Deflickered 
ffmpeg -framerate 30 -y -f image2 -r 1/0.1 -i '%*.jpg' -c:v libx264 -tune stillimage -preset veryslow -movflags +faststart -crf 18 -vf scale=800:-1 timelapse1.mp4
mv -f timelapse1.mp4 ../timelapse1.mp4
ffmpeg -framerate 30 -y -f image2 -r 1/0.1 -i '%*.jpg' -c:v libvpx -crf 5 -b:v 2M -vf scale=800:-1 timelapse1.webm
mv -f timelapse1.webm ../timelapse1.webm
ffmpeg -framerate 30 -y -f image2 -r 1/0.1 -i '%*.jpg' -c:v libtheora -qscale:v 10 -vf scale=800:-1 timelapse1.ogv
mv -f timelapse1.ogv ../timelapse1.ogv
cd ..
rm -rf Deflickered
