show_help() {
cat << EOF
Usage: ${0##*/} [--numpy-path]

Retrieve python information.

    -h             display this help and exit
    --numpy-info   Export python related information. Default 1
EOF
}

# Default values
NUMPY_INFO=0

while :; do
  case $1 in
    -h|-\?|--help)   # Call a "show_help" function to display a synopsis, then exit.
      show_help
      exit
      ;;
    --numpy-info)
      if [ ${2#--} != $2 ]; then
        NUMPY_INFO=1
      else
        NUMPY_INFO=$2
        shift 2
        continue
      fi
      ;;
    --numpy-info=?*)
      NUMPY_INFO=${1#*=} # Delete everything up to "=" and assign the remainder.
      ;;
    --numpy-info=)   # Handle the case of an empty --numpy-info=
      echo 'ERROR: "--numpy-info" requires a non-empty option argument.\n' >&2
      exit 1
      ;;
    --)              # End of all options.
      shift
      break
      ;;
    -?*)
      echo 'WARN: Unknown option (ignored): %s\n' "$1" >&2
      ;;
    *)               # Default case: If no more options then break out of the loop.
      break
  esac
  shift
done

source "$ROOTCOREBIN/../RootCoreMacros/base_env.sh" || { echo "Couldn't load base shell environment." && exit 1; }

PYTHON_EXEC_PATH=`pyenv whence --path python 2>/dev/null || which python`
PYTHON_EXEC_PATH=`readlink -f "$PYTHON_EXEC_PATH"`
PYTHON_INCLUDE_CANDIDATES=${PYTHON_EXEC_PATH//bin\/python*/include\/}
PYTHON_INCLUDE_CANDIDATES=`find "$PYTHON_INCLUDE_CANDIDATES" -name "python?.?" -type d` # pick only last result
PYTHON_VERSION_NUM=0
for candidate in $PYTHON_INCLUDE_CANDIDATES
do
  version=`basename "$candidate"`
  candidateVNUM=${version//python/}
  candidateVNUM=${candidateVNUM//./}
  if test "$candidateVNUM" -ge "$PYTHON_VERSION_NUM"
  then
    PYTHON_LIB_VERSION=$version
    vNUM=$candidateVNUM
  fi
done
PYTHON_INCLUDE_PATH=""
for candidate in $PYTHON_INCLUDE_CANDIDATES
do
  if test "`basename $candidate`" = $PYTHON_LIB_VERSION
  then
    if test -e $candidate/import.h -o -e $candidate/pyconfig.h
    then
      PYTHON_INCLUDE_PATH="$PYTHON_INCLUDE_PATH $include_system_marker$candidate"
    fi
  fi
done

if test "$NUMPY_INFO" -eq "1"; then
  NUMPY_LCG=0
  PYTHON_NUMPY_PATH=$(python -c "import numpy; path=numpy.__file__; print path[:path.rfind('numpy')]" 2> /dev/null)
  ## Add numpy to python path and to include path if we are using afs:
  if test \( "x$PYTHON_NUMPY_PATH" = "x" \
    -o "$PYTHON_NUMPY_PATH" != "${PYTHON_NUMPY_PATH/\/afs\/cern.ch\/sw\/lcg\/external\/pyanalysis\//}" \) \
    -a -e /afs/cern.ch/sw/lcg/external/pyanalysis/ 
  then
    PYTHON_NUMPY_PATH=`find /afs/cern.ch/sw/lcg/external/pyanalysis/ -maxdepth 1 -name "*$PYTHON_LIB_VERSION" | tail -1`
    PYTHON_NUMPY_PATH="$PYTHON_NUMPY_PATH/$rootCmtConfig/lib/$PYTHON_LIB_VERSION/site-packages/"
    # We must add PYTHON_NUMPY_PATH to the environment
    INCLUDE_NUMPY="$include_system_marker$PYTHON_NUMPY_PATH/numpy/core/include"
    NUMPY_LCG=1
  else
    if test -e "$PYTHON_NUMPY_PATH/numpy/core/include"; then
      INCLUDE_NUMPY="$include_system_marker$PYTHON_NUMPY_PATH/numpy/core/include"
    else
      if test -e "/usr/include/numpy"; then
        INCLUDE_NUMPY="$include_system_marker/usr/include/numpy"
      fi
    fi
  fi
  true
fi
