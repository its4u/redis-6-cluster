#!/bin/bash
OLD_IFS="$IFS"
IFS=$'\n'


TEMPLATE=redis-6-cluster-template.yml
FOLDER=files

yq e 'del(.objects)' redis-6-cluster-template.yml > $FOLDER/template.yml

get_name()
{
  TEMPLATE=$1
  i=$2

  type=$(yq e ".objects[$i].kind" $TEMPLATE)
  name=$(
    yq e ".objects[$i].metadata.name" $TEMPLATE |\
     sed 's/\${.*}//' |\
     sed 's/^-//'
  )
  if [ "$name" = "" ]; then
    echo $type".yml"
  else
    echo $type"_"$name".yml"
  fi
}

i=0;
name=$(get_name $TEMPLATE $i)

yq e '.objects[] |splitDoc' $TEMPLATE > tmp_file.yml

for line in $(cat tmp_file.yml); 
do 
  
  if [ "$line" = "---" ]; then
    i=$((i+1));
    name=$(get_name $TEMPLATE $i)
  else
    echo "$line" >> $FOLDER/$name
  fi; 

done;

rm tmp_file.yml
IFS="$OLD_IFS"
