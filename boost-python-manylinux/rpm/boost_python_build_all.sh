#!/usr/bin/bash
set -e
declare -A base_versions
declare -A extended_versions
declare -A python_strings
# CPython
MIN_CPYTHON3_VERSION=8
MAX_CPYTHON3_VERSION=14
MIN_CPYTHON3T_VERSION=13
MAX_CPYTHON3T_VERSION=14
for ((v="$MIN_CPYTHON3_VERSION";v<="$MAX_CPYTHON3_VERSION";v++)); do
    version_string="cp3$v-cp3$v"
    base_versions["$version_string"]="3.$v"
    extended_versions["$version_string"]="3.$v"
    python_strings["$version_string"]="python"
done
for ((v="$MIN_CPYTHON3T_VERSION";v<="$MAX_CPYTHON3T_VERSION";v++)); do
    version_string="cp3$v-cp3${v}t"
    base_versions["$version_string"]="3.$v"
    extended_versions["$version_string"]="3.${v}t"
    python_strings["$version_string"]="python"
done
# PyPy
base_versions["pp311-pypy311_pp73"]="3.11"
extended_versions["pp311-pypy311_pp73"]="3.11"
python_strings["pp311-pypy311_pp73"]="pypy"
show_versions=false
while [ "$#" -gt 0 ]; do
    case "$1" in
	"--show-versions")
	    show_versions=true
	    ;;
	*)
	    if ! [[ -v boost_dir ]]; then
		boost_dir="$1"
	    else
		>&2 echo "Cannot provide more than one directory."
		exit 1
	    fi
	    ;;
    esac
    shift
done
if [ "$show_versions" = true ]; then
    for version in "${!base_versions[@]}"; do
	echo "version $version: ${base_versions[$version]}, ${extended_versions[$version]}, ${python_strings[$version]}"
    done
    exit 0
fi
if ! [[ -v boost_dir ]]; then
    >&2 echo "Must provide a boost source directory."
    exit 1
fi
set -x
cd "$boost_dir"
./bootstrap.sh
./b2 tools/bcp
mv project-config.jam project-config.jam.generic
for version in "${!base_versions[@]}"; do
    echo "version $version: ${base_versions[$version]}, ${extended_versions[$version]}"
    sed '/^project.*;$/r /dev/stdin' project-config.jam.generic > project-config.jam <<EOF

# Python configuration
import python ;
if ! [ python.configured ]
{
    using python : "${base_versions[$version]}" : "/opt/python/$version/bin/python" :  "/opt/python/$version/include/${python_strings[$version]}${extended_versions[$version]}" : "/opt/python/$version/lib/${python_strings[$version]}${extended_versions[$version]}" ;
}
EOF
    ./b2 stage --clean
    ./b2 stage --with-python --python-buildid="$version" link=shared variant=debug
done
