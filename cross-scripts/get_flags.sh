#!/usr/bin/bash
pos=()
format="command"
includes=true
libraries=true
lang="c++"
while [ "$#" -gt 0 ]; do
    case "$1" in
	"--format"|"-f")
	    shift
	    format="$1"
	    ;;
	"--includes"|"-I")
	    libraries=false
	    ;;
	"--libraries"|"-L")
	    includes=false
	    ;;
	"--lang"|"-l")
	    shift;	    
	    lang="$1"
	    ;;
	*)
	    pos+=("$1")
	    ;;
    esac
    shift
done
if [ "$includes" = true ]; then
    if [ "$format" = "command" ]; then
	prefix="-I"
    else
	prefix=""
    fi
    while read -r -u 5 line; do
        echo -n "$prefix${pos[0]}$line ";
    done 5< <(echo | gcc "-x$lang" -E -v - 2>&1 | sed -n '/#include <...> search starts here/,/End of search list/p' | tail -n+2 | head -n-1)
fi
if [ "$libraries" = true ]; then
   if [ "$format" = "command" ]; then
       prefix="-L"
   else
       prefix=""
   fi
   IFS=":" read -a libs < <(echo | gcc "-x$lang" -E -v - 2>&1 | sed -n '/^LIBRARY_PATH=/{s///;p}')
   for f in "${libs[@]}"; do
       echo -n "$prefix${pos[0]}$f "
   done
fi
echo
