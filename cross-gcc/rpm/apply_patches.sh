pos=()
dry_run=
do_git=false
while [ "$#" -gt 0 ]; do
    case "$1" in
	"--git")
	    do_git=true
	    ;;
	"--dry-run")
	    dry_run="--dry-run"
	    ;;
	*)
	    pos+=("$1")
	    ;;
    esac
    shift
done
echo "dry_run?: $dry_run"
echo "git?: $do_git"
echo "positional args: ${pos[*]}"
if ! [ -f "${pos[0]}" ]; then
    echo "${pos[0]} doesn't exist"
    exit 1
fi
while read -r -u 5 line; do
    echo -e "\033[92m$line\033[0m";
    if ! patch -f -p0 --fuzz=0 $dry_run < "../rpmbuild/SOURCES/$line"; then
	break;
    fi;
    if [ "$do_git" = true ]; then
	git add -u;
	git commit -m "$line";
    fi
done 5< <(grep "${pos[0]}" -e '^Patch' | grep -v 900 | awk '{print $2}')
