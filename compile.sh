#!/bin/bash
OLD_IFS="$IFS"
IFS=$'\n'


TEMPLATE=new-template.yml
FOLDER=files

cat $FOLDER/template.yml > $TEMPLATE
echo "objects:" >> $TEMPLATE

for f in $(ls $FOLDER | grep '.yml$' | grep -v "template.yml");
do
  echo "- "$(head -n 1 $FOLDER/$f) >> $TEMPLATE
  for line in $(sed 1d $FOLDER/$f);
  do
    echo "  "$line >> $TEMPLATE
  done
done


IFS=$OLD_IFS
