echo -e "Name\t\t\t\tSize"
ls -l ~ | awk '{printf ("%-30s|%-18s\n" ,$9,$5)}'
