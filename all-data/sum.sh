awk -F: '{a+=$3; b+=$4}END{print "udis="a" " " pids="b" ";
if(a>b){
	print a
}else{
print b
}
}' /etc/passwd
