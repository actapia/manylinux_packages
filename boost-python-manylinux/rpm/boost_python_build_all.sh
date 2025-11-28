#!/usr/bin/bash
function find_dep {
    shopt -s nullglob
    toolkits=("$1"*"$3")
    if [ "${#toolkits[@]}" -lt 1 ]; then
	>&2 echo "Could not find $2. Was it installed?"
	exit 1
    elif [ "${#toolkits[@]}" -gt 1 ]; then
	>&2 echo "Multiple $2 installations found. Refusing to pick."
	exit 1
    fi
    echo "${toolkits[0]}"
}
set -e
show_versions=false
pos=()
while [ "$#" -gt 0 ]; do
    case "$1" in
	"--show-versions")
	    show_versions=true
	    ;;
	*)
	    pos+=("$1")
	    ;;
    esac
    shift
done
if [ "${#pos[@]}" -ne 2 ]; then
    >&2 echo "This script requires exactly two positional arguments."
    exit 1
fi
boost_dir="${pos[0]}"
lib_dir="${pos[1]}"
cd "$boost_dir"
if [ "$show_versions" = false ]; then
    set -x
    ./bootstrap.sh
    ./b2 tools/bcp
    mv project-config.jam project-config.jam.generic
fi
build_dir="mybuild"
for pydir in /opt/python/*; do
    # if ! [[ $version =~ ^cp313-cp313 ]]; then
    # 	continue
    # fi
    version="$(basename "$pydir")"
    base_version="$("$pydir"/bin/python -c \
        'import sys; print(".".join(map(str,sys.version_info[:2])))'
    )"    
    echo "version $version: $base_version"
    if /opt/python/$version/bin/python -c 'import sys; sys.exit(not sys._is_gil_enabled())'; then
	have_gil=
    else
	have_gil="define=Py_GIL_DISABLED"
    fi
    python_include="$(find_dep "$pydir"/include/ "$version_name include dir" /)"
    python_lib="$(find_dep "$pydir"/lib/py "$version_name lib dir" /)"
    if [ "$show_versions" = true ]; then
	echo "include: $python_include"
	echo "lib: $python_lib"
	echo "------------------------------"
	continue
    fi
    sed '/^project.*;$/r /dev/stdin' project-config.jam.generic > project-config.jam <<EOF

# Python configuration
import python ;
if ! [ python.configured ]
{
    using python : "$base_version" : "/opt/python/$version/bin/python" :  "$python_include" : "$python_lib" ;
}
EOF
    ./b2 stage --clean-all --build-dir="$build_dir"
    rm -rf "$build_dir"
    ./b2 stage --with-python --build-dir="$build_dir" --python-buildid="$version" link=shared variant=debug hardcode-dll-paths=true dll-path="'\$ORIGIN/../$lib_dir'" $have_gil
done
