for i in `ls /usr/bin`
do
	j=`echo $i | head -c 2 | tail -c 1`
	if [ "$j" == "a" ]
	then
		echo $i >> /tmp/test
	fi
done
