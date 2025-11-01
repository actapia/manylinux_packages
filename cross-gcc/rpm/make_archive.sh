#!/usr/bin/bash
clean=false
pos=()
while [ "$#" -gt 0 ]; do
    case "$1" in
	"--clean")
	    clean=true
	    ;;
	*)
	    pos+=("$1")
	    ;;
    esac
    shift
done
if [ "$clean" = true ]; then
    rm -rf gcc-dir.tmp
fi
set -e
set -x
date="$(grep "${pos[0]}" -e '%global DATE' | cut -d' ' -f3)"
gitrev="$(grep "${pos[0]}" -e '%global gitrev' | cut -d' ' -f3)"
gcc_version="$(grep "${pos[0]}" -e '%global gcc_version' | cut -d' ' -f3)"
name="gcc-${gcc_version}-${date}"
echo "Making $name"
git clone --depth 1 git://gcc.gnu.org/git/gcc.git gcc-dir.tmp
git --git-dir=gcc-dir.tmp/.git fetch --depth 1 origin "$gitrev"

git --git-dir=gcc-dir.tmp/.git archive --prefix="$name/" "$gitrev" | xz -9e -T0 > "${name}.tar.xz"
