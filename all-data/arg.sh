if [[ "$1" =~ ^[0-9]+$ ]] && [[ "$2" =~ ^[0-9]+$ ]]
then
	echo "ARGS ARE INTERGERS"
else
	echo "BOTH ARGS ARE NOT INTEGERS"
	echo "BOTH ARGS ARE NOT INTEGERS" > error.log
fi
