#!/bin/bash
read a
b=$((a/100))
echo $b
for((i=0; i<$b; i++))
do
	echo "100"
done
