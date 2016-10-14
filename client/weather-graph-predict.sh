#!/bin/sh
export TZ="Europe/Berlin"
cd /home/gesell/
/usr/local/bin/rrdtool graph /usr/local/www/nginx/wind/vorhersage6.png  \
DEF:wind=db0tfm-6.rrd:wind_speed:AVERAGE \
DEF:wind_gust=db0tfm-6.rrd:wind_gust:AVERAGE \
DEF:wind_dir=db0tfm-6.rrd:wind_direction:AVERAGE \
VDEF:wind_avg=wind,AVERAGE \
VDEF:wind_slope=wind,LSLSLOPE \
VDEF:wind_cons=wind,LSLINT \
CDEF:wind_lsl2=wind,POP,wind_slope,COUNT,*,wind_cons,+ \
VDEF:wind_gust_avg=wind_gust,AVERAGE \
VDEF:wind_gust_slope=wind_gust,LSLSLOPE \
VDEF:wind_gust_cons=wind_gust,LSLINT \
CDEF:wind_gust_lsl2=wind_gust,POP,wind_gust_slope,COUNT,*,wind_gust_cons,+ \
CDEF:wind_predict=21600,-4,900,wind,PREDICT  \
CDEF:wind_gust_predict=21600,-4,900,wind_gust,PREDICT \
AREA:wind_gust#FF0000:"Wind Boe\n" \
AREA:wind#006400:"Wind\n" \
LINE:wind_avg#00FF00:"Wind - Durchschnitt\n":dashes=5 \
LINE:wind_lsl2#00FF00:"Wind - Linare Vorhersage\n":dashes=8 \
LINE:wind_gust_avg#FF0000:"Wind Boe - Durchschnitt\n":dashes=5 \
LINE:wind_gust_lsl2#FF0000:"Wind Boe - Linare Vorhersage\n":dashes=8 \
LINE2:wind_gust_predict#DF01A5:"Wind Boe - Vorhersage\n" \
LINE2:wind_predict#58FA58:"Wind - Vorhersage\n" \
HRULE:20#FFFF00:"20 km/h Linie\n" \
-r \
-v km/h \
-h 250 -w 600 \
-c CANVAS#000000 -c FONT#FFFFFF -c BACK#000000 \
--title="Flugwetter Teufelsmuehle Loffenau" \
--upper-limit 35 \
--start now-12h \
--end now+6h 


/usr/local/bin/rrdtool graph /usr/local/www/nginx/wind/vorhersage6-dir.png \
DEF:wind_dir=db0tfm-6.rrd:wind_direction:AVERAGE \
CDEF:wind_dir_predict=21600,-4,900,wind_dir,PREDICT  \
HRULE:355#00FF00 HRULE:240#00FF00 \
LINE2:wind_dir#FF0000 \
LINE2:wind_dir_predict#FF00FF \
HRULE:270#0000FF:"Startplatz W":dashes \
HRULE:304#FFFF00:"Startplatz NW"  \
-h 250 -w 600 -u 360 -l 0 \
-v Windrichtung \
-c CANVAS#000000 -c FONT#FFFFFF -c BACK#000000 \
--title="Flugwetter Teufelsmuehle Loffenau" \
--upper-limit 360 \
--lower-limit 1 -r \
--start now-12h \
--end now+6h 


/usr/local/bin/rrdtool graph /usr/local/www/nginx/wind/vorhersage12-dir.png \
DEF:wind_dir=db0tfm-6.rrd:wind_direction:AVERAGE \
CDEF:wind_dir_predict=21600,-4,900,wind_dir,PREDICT  \
HRULE:355#00FF00 HRULE:240#00FF00 \
LINE2:wind_dir#FF0000 \
LINE2:wind_dir_predict#FF00FF \
HRULE:270#0000FF:"Startplatz W":dashes \
HRULE:304#FFFF00:"Startplatz NW"  \
-h 250 -w 600 -u 360 -l 0 \
-v Windrichtung \
-c CANVAS#000000 -c FONT#FFFFFF -c BACK#000000 \
--title="Flugwetter Teufelsmuehle Loffenau" \
--upper-limit 360 \
--lower-limit 1 -r \
--start now-24h \
--end now+12h 


/usr/local/bin/rrdtool graph /usr/local/www/nginx/wind/vorhersage24-dir.png \
DEF:wind_dir=db0tfm-6.rrd:wind_direction:AVERAGE \
CDEF:wind_dir_predict=21600,-4,900,wind_dir,PREDICT  \
HRULE:355#00FF00 HRULE:240#00FF00 \
LINE2:wind_dir#FF0000 \
LINE2:wind_dir_predict#FF00FF \
HRULE:270#0000FF:"Startplatz W":dashes \
HRULE:304#FFFF00:"Startplatz NW"  \
-h 250 -w 600 -u 360 -l 0 \
-v Windrichtung \
-c CANVAS#000000 -c FONT#FFFFFF -c BACK#000000 \
--title="Flugwetter Teufelsmuehle Loffenau" \
--upper-limit 360 \
--lower-limit 1 -r \
--start now-48h \
--end now+24h 




/usr/local/bin/rrdtool graph /usr/local/www/nginx/wind/vorhersage12.png  \
DEF:wind=db0tfm-6.rrd:wind_speed:AVERAGE \
DEF:wind_gust=db0tfm-6.rrd:wind_gust:AVERAGE \
DEF:wind_dir=db0tfm-6.rrd:wind_direction:AVERAGE \
VDEF:wind_avg=wind,AVERAGE \
VDEF:wind_slope=wind,LSLSLOPE \
VDEF:wind_cons=wind,LSLINT \
CDEF:wind_lsl2=wind,POP,wind_slope,COUNT,*,wind_cons,+ \
VDEF:wind_gust_avg=wind_gust,AVERAGE \
VDEF:wind_gust_slope=wind_gust,LSLSLOPE \
VDEF:wind_gust_cons=wind_gust,LSLINT \
CDEF:wind_gust_lsl2=wind_gust,POP,wind_gust_slope,COUNT,*,wind_gust_cons,+ \
CDEF:wind_predict=21600,-4,900,wind,PREDICT  \
CDEF:wind_gust_predict=21600,-4,900,wind_gust,PREDICT \
AREA:wind_gust#FF0000:"Wind Boe\n" \
AREA:wind#006400:"Wind\n" \
LINE:wind_avg#00FF00:"Wind - Durchschnitt\n":dashes=5 \
LINE:wind_lsl2#00FF00:"Wind - Linare Vorhersage\n":dashes=8 \
LINE:wind_gust_avg#FF0000:"Wind Boe - Durchschnitt\n":dashes=5 \
LINE:wind_gust_lsl2#FF0000:"Wind Boe - Linare Vorhersage\n":dashes=8 \
LINE2:wind_gust_predict#DF01A5:"Wind Boe - Vorhersage\n" \
LINE2:wind_predict#58FA58:"Wind - Vorhersage\n" \
HRULE:20#FFFF00:"20 km/h Linie\n" \
-r \
-v km/h \
-h 250 -w 600 \
-c CANVAS#000000 -c FONT#FFFFFF -c BACK#000000 \
--title="Flugwetter Teufelsmuehle Loffenau" \
--upper-limit 35 \
--start now-24h \
--end now+12h 

/usr/local/bin/rrdtool graph /usr/local/www/nginx/wind/vorhersage24.png  \
DEF:wind=db0tfm-6.rrd:wind_speed:AVERAGE \
DEF:wind_gust=db0tfm-6.rrd:wind_gust:AVERAGE \
DEF:wind_dir=db0tfm-6.rrd:wind_direction:AVERAGE \
VDEF:wind_avg=wind,AVERAGE \
VDEF:wind_slope=wind,LSLSLOPE \
VDEF:wind_cons=wind,LSLINT \
CDEF:wind_lsl2=wind,POP,wind_slope,COUNT,*,wind_cons,+ \
VDEF:wind_gust_avg=wind_gust,AVERAGE \
VDEF:wind_gust_slope=wind_gust,LSLSLOPE \
VDEF:wind_gust_cons=wind_gust,LSLINT \
CDEF:wind_gust_lsl2=wind_gust,POP,wind_gust_slope,COUNT,*,wind_gust_cons,+ \
CDEF:wind_predict=21600,-4,900,wind,PREDICT  \
CDEF:wind_gust_predict=21600,-4,900,wind_gust,PREDICT \
AREA:wind_gust#FF0000:"Wind Boe\n" \
AREA:wind#006400:"Wind\n" \
LINE:wind_avg#00FF00:"Wind - Durchschnitt\n":dashes=5 \
LINE:wind_lsl2#00FF00:"Wind - Linare Vorhersage\n":dashes=8 \
LINE:wind_gust_avg#FF0000:"Wind Boe - Durchschnitt\n":dashes=5 \
LINE:wind_gust_lsl2#FF0000:"Wind Boe - Linare Vorhersage\n":dashes=8 \
LINE2:wind_gust_predict#DF01A5:"Wind Boe - Vorhersage\n" \
LINE2:wind_predict#58FA58:"Wind - Vorhersage\n" \
HRULE:20#FFFF00:"20 km/h Linie\n" \
-r \
-v km/h \
-h 250 -w 600 \
-c CANVAS#000000 -c FONT#FFFFFF -c BACK#000000 \
--title="Flugwetter Teufelsmuehle Loffenau" \
--upper-limit 35 \
--start now-48h \
--end now+24h 

