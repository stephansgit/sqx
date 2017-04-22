#! /bin/bash

dt=$(date +%Y%m%d%H%M%S)
for fullfile in /home/fibo/boerse/sqx/data/*.RData
do
    name=$(basename "$fullfile")
    echo $name
    mv /home/fibo/boerse/sqx/data/$name /home/fibo/boerse/sqx/data/archive/${name}_${dt}
done
