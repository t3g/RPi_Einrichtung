#!/bin/bash
#Visit www.timeapi.org to find the correct url for your timezone. Then replace the url in the first line

time=$(wget http://www.timeapi.org/utc/in+two+hours?format=%25d%20%25b%20%25Y%20%25I:%25M:%25S -q -O -)
echo "Time set to:"
sudo date -s "\`echo $time`"
