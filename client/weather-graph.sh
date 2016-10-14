#!/bin/sh
export TZ="Europe/Berlin"
cd /home/gesell/
/usr/local/bin/rrdtool graph /usr/local/www/nginx/wind/db0tfm-6.png  DEF:wind=db0tfm-6.rrd:wind_speed:AVERAGE DEF:wind_gust=db0tfm-6.rrd:wind_gust:AVERAGE DEF:wind_dir=db0tfm-6.rrd:wind_direction:AVERAGE AREA:wind_gust#FF0000:"Wind Boe" AREA:wind#006400:"Wind" HRULE:20#FFFF00:"20 km/h" -v km/h -h 250 -w 600 -c CANVAS#000000 -c FONT#FFFFFF -c BACK#000000 --title="Flugwetter Teufelsmuehle Loffenau" --start end-12h --upper-limit 35 -r > /dev/null 2>&1
/usr/local/bin/rrdtool graph /usr/local/www/nginx/wind/db0tfm-6-dir.png DEF:wind_dir=db0tfm-6.rrd:wind_direction:AVERAGE HRULE:355#00FF00 HRULE:240#00FF00 LINE2:wind_dir#FF0000 HRULE:270#0000FF:"Startplatz W":dashes HRULE:304#FFFF00:"Startplatz NW"  -h 250 -w 600 -u 360 -l 0 -v Windrichtung -c CANVAS#000000 -c FONT#FFFFFF -c BACK#000000 --title="Flugwetter Teufelsmuehle Loffenau" --start end-12h --upper-limit 360 --lower-limit 1 -r > /dev/null 2>&1
