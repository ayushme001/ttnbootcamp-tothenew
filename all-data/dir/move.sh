for i in `ls`
do
	if [[ "$i" != "dest1" && "$i" != "dest2" && "$i" != "move.sh" ]]
	then
		if [ -f $i ]
		then
		       	mv $i dest1/$i
		fi
		if [ -d  $i ]
		then
			mv $i dest2/$i
		fi
	fi
done

