#!/bin/bash
read a
b=${#a}
if [ $a -ge 0 ]
then
	echo ${#a}
elif [ $a -le 0 ]
then
	echo $((--b))
fi

