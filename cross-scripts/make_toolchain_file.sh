#!/usr/bin/env bash
pos=()
arch=
proc=
prefix=
while [ "$#" -gt 0 ]; do
    case "$1" in
	"--arch"|"-a")
	    shift;
	    arch="$1";
	    ;;
	"--processor"|"-P")
	    shift;
	    proc="$1";
	    ;;
	"--prefix"|"-p")
	    shift;
	    prefix="$1";
	    ;;
	*)
	    pos+=("$1");
	    ;;
    esac
    shift
done
system_name="$(uname -s)"
system_version="$(uname -r)"
if [ -z "$arch" ]; then
    arch="$(uname -m)"
fi
if [ -z "$proc" ]; then
    proc="$arch"
fi
gcc_version="$(gcc -dumpversion)"
gcc_root="$(realpath "$(dirname "$(which gcc)")/../..")"
c_standard_include_dirs="$(bash get_flags.sh -f cmake -I -l c "$prefix")"
cxx_standard_include_dirs="$(bash get_flags.sh -f cmake -I -l c++ "$prefix")"
c_standard_libraries="$(bash get_flags.sh -f command -L -l c "$prefix")"
cxx_standard_libraries="$(bash get_flags.sh -f command -L -l c++ "$prefix")"
cat << EOF
set(CMAKE_SYSTEM_NAME $system_name)
set(CMAKE_SYSTEM_VERSION $system_version)
set(CMAKE_SYSTEM_PROCESSOR $proc)

set(CMAKE_C_COMPILER $arch-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER $arch-linux-gnu-g++)

set(CMAKE_FIND_ROOT_PATH /usr/lib/gcc/$arch-linux-gnu/$gcc_version/ $prefix $prefix$gcc_root)
set(CMAKE_SYSROOT $prefix)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)

# search headers and libraries in the target environment
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

set(CMAKE_C_STANDARD_INCLUDE_DIRECTORIES $c_standard_include_dirs)
set(CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES $cxx_standard_include_dirs)
set(CMAKE_C_STANDARD_LIBRARIES "$c_standard_libraries")
set(CMAKE_CXX_STANDARD_LIBRARIES "$cxx_standard_libraries")
EOF
if [[ $arch =~ i.86 ]]; then
    cat << EOF
UNSET(CMAKE_C_FLAGS CACHE)
SET(CMAKE_C_FLAGS "-m32" CACHE STRING "" FORCE)
UNSET(CMAKE_CXX_FLAGS CACHE)
SET(CMAKE_CXX_FLAGS "-m32" CACHE STRING "" FORCE)
EOF
fi
