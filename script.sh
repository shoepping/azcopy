#!/bin/bash
#set -x
while true
do
  echo "***********Start copy last files***********"
  echo ""
  day_before_yesterday=`date -d '-2 day' +%Y%m%d`
  yesterday=`date -d '-1 day' +%Y%m%d`
  today=`date +%Y%m%d`
  azcopy cp $1 "/home/logs" --include-regex ${yesterday} --recursive --overwrite=false
  azcopy cp $1 "/home/logs" --include-regex ${today} --recursive --overwrite=false
  for filename in /home/logs/*; do
    if [[ $(file --mime-encoding -b $filename) = binary ]]; then
       mv $filename $filename.xz
       unxz $filename.xz
       short_name=$( echo "$filename" | cut -d\/ -f4 )
       cp $filename /home/volume/$short_name.json
    fi
  done
  echo "***********Delete files older than 2 days***********"
  echo ""
  find /home/logs -name "*$day_before_yesterday*" -exec rm -f {} \;
  find /home/volume -mtime +2 -exec rm {} \;
  sleep 5
done
