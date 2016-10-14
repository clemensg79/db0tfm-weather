#!/bin/sh
AUDIODEV=hw:1 rec -c 1 -r 22050 -b 16 -e s -q -t raw - | multimon-ng -q -a AFSK1200 -A -t raw -
