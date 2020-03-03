#!/bin/bash
read n
remainder=0
sum=0
while [ $n -gt 0 ]
do
    n=$(( $n / 10 ))
    sum=$(( $sum + 1))
done
echo "$sum"
