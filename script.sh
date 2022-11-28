#!/bin/bash
#set -x

URL=$1

AZ_COPY_SOURCE_DIR=${AZ_COPY_SOURCE_DIR:-"/home/logs"}
AZ_COPY_TARGET_DIR=${AZ_COPY_TARGET_DIR:-"/home/volume"}
AZ_COPY_SLEEP_TIME=${AZ_COPY_SLEEP_TIME:-5}
AZ_COPY_DELETE_SOURCE_FILES_OLDER_THAN_MINS=${AZ_COPY_DELETE_SOURCE_FILES_OLDER_THAN_MINS:-1440}
AZ_COPY_DELETE_TARGET_FILES_OLDER_THAN_MINS=${AZ_COPY_DELETE_TARGET_FILES_OLDER_THAN_MINS:-2880}

echo "Starting AZCOPY"
echo "AZ COPY URL: ${URL}"
echo "AZ_COPY_SOURCE_DIR: ${AZ_COPY_SOURCE_DIR}"
echo "AZ_COPY_TARGET_DIR: ${AZ_COPY_TARGET_DIR}"
echo "AZ_COPY_SLEEP_TIME: ${AZ_COPY_SLEEP_TIME}"
echo "AZ_COPY_DELETE_SOURCE_FILES_OLDER_THAN_MINS: ${AZ_COPY_DELETE_SOURCE_FILES_OLDER_THAN_MINS}"
echo "AZ_COPY_DELETE_TARGET_FILES_OLDER_THAN_MINS: ${AZ_COPY_DELETE_TARGET_FILES_OLDER_THAN_MINS}"

while true
do
  echo "***********Start copy last files***********"
  now=$(date "+%Y-%m-%d %H:%M %S")
  echo "$now"
  echo ""

  today=$(date +%Y%m%d)

  # Copy the logs into the using the given URL as parameter 1
  echo "Copying files to $AZ_COPY_SOURCE_DIR with regex pattern $today"
  #azcopy sync "$URL" "$AZ_COPY_SOURCE_DIR" --include-regex "${today}" --recursive
  azcopy list $URL | grep "${today}"
  azcopy cp "$URL" "$AZ_COPY_SOURCE_DIR" --include-regex "${today}" --recursive --overwrite=true

  count=0
  find "$AZ_COPY_SOURCE_DIR" ! -name ".azDownload*" -type f -print0 | while IFS= read -r -d '' filename
  do
    count=$((count+1))
    file_encoding=$(file --mime-encoding -b "$filename")
    short_name=$(basename "$filename")
    echo "$count. $short_name has $file_encoding file encoding. Full path $filename"
    if [[ $(file --mime-encoding -b "$filename") = binary ]]; then
       if [ ! -f "$AZ_COPY_TARGET_DIR/$short_name.json" ] ; then
         echo "Binary encoded file. Moving ${filename} to ${filename}.xz and copying"
         mv "$filename" "$filename".xz
         unxz "$filename".xz
         cp "$filename" "$AZ_COPY_TARGET_DIR"/"$short_name".json
       fi
    else
       if [ ! -f "$AZ_COPY_TARGET_DIR"/"$short_name".json ] ; then
         echo "Copying ${filename} to ${AZ_COPY_TARGET_DIR}/${short_name}.json and copying"
         cp "$filename" "$AZ_COPY_TARGET_DIR"/"$short_name".json
       fi
         echo "File exists. Updating ${AZ_COPY_TARGET_DIR}/${short_name}.json"
         cp "$filename" "$AZ_COPY_TARGET_DIR"/"$short_name".json
    fi
  done

  echo "***********Delete files older than 2 days***********"
  echo ""
  echo "Finding source files in ${AZ_COPY_SOURCE_DIR} older than ${AZ_COPY_DELETE_SOURCE_FILES_OLDER_THAN_MINS} minutes"
  find "$AZ_COPY_SOURCE_DIR" -type f -mmin +"$AZ_COPY_DELETE_SOURCE_FILES_OLDER_THAN_MINS" -exec rm -f {} \;
  echo "Finding target files in ${AZ_COPY_TARGET_DIR} older than ${AZ_COPY_DELETE_TARGET_FILES_OLDER_THAN_MINS} minutes"
  find "$AZ_COPY_TARGET_DIR" -type f -mmin +"$AZ_COPY_DELETE_TARGET_FILES_OLDER_THAN_MINS" -exec rm -f {} \;

  echo "List jobs:"
  azcopy jobs list
  wait
  echo "Deleting old azcopy jobe.."
  azcopy jobs clean

  echo "Done. Sleeping for $AZ_COPY_SLEEP_TIME seconds"
  sleep "$AZ_COPY_SLEEP_TIME"
done
