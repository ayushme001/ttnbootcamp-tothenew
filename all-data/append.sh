cat $3 | awk  -v v1=$1 -v v2=$2 '{ print v1" " $0" " v2; }'
