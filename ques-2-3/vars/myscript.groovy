def info(message) {
	echo  "\033[4;32mINFO:\033[0m \033[1;33m${message}\033[0m\n"	
}

def warning(message) {
    echo "WARNING: \033[1;31;43m${message}\033[0m"
}

def gitCommitId(message)
{
      echo  "\033[4;32m[Git Commit ID] \033[0m \033[1;33m ${message} \033[0m\n"
}