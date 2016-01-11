show_help() {
cat << EOF
Usage: ${0##*/} [--clean|--distclean] [--grid]

Compile RootCore environment and install it. This should be sourced, otherwise
it won't change your shell environment and you may have issues using RootCore.

    -h             display this help and exit
    --clean        Clean previous RootCore binaries and recompile.
    --distclean    As clean, but also clean previous installed dependencies before
                   recompiling.
    --grid         Flag that compilation is for the grid environment. 
EOF
}

# Default values
grid=0
clean=0
distclean=0

while :; do
  case $1 in
    -h|-\?|--help)   # Call a "show_help" function to display a synopsis, then exit.
      show_help
      exit
      ;;
    --clean)
      if [ ${2#--} != $2 ]; then
        clean=1
      else
        clean=$2
        shift 2
        continue
      fi
      ;;
    --clean=?*)
      clean=${1#*=} # Delete everything up to "=" and assign the remainder.
      ;;
    --clean=)   # Handle the case of an empty --clean=
      echo 'ERROR: "--clean" requires a non-empty option argument.\n' >&2
      exit 1
      ;;
    --distclean)
      if [ ${2#--} != $2 ]; then
        distclean=1
        clean=1
      else
        distclean=$2
        if test "$distclean" -eq "1"; then
          clean=1
        fi
        shift 2
        continue
      fi
      ;;
    --distclean=?*)
      distclean=${1#*=} # Delete everything up to "=" and assign the remainder.
      if test "$distclean" -eq "1"; then
        clean=1
      fi
      ;;
    --distclean=)   # Handle the case of an empty --distclean=
      echo 'ERROR: "--distclean" requires a non-empty option argument.\n' >&2
      exit 1
      ;;
    --grid)
      if [ ${2#--} != $2 ]; then
        grid=1
      else
        grid=$2
        shift 2
        continue
      fi
      ;;
    --grid=?*)
      grid=${1#*=} # Delete everything up to "=" and assign the remainder.
      ;;
    --grid=)   # Handle the case of an empty --grid=
      echo 'ERROR: "--grid" requires a non-empty option argument.\n' >&2
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

# Update environment
source ./setrootcore.sh --silent

# Compile
test $clean -eq "1" && "$ROOTCOREBIN/bin/$ROOTCORECONFIG/rc" clean
test $distclean -eq "1" -a -n "$ROOTCOREBIN" && rm -r $ROOTCOREBIN/../Downloads/ $ROOTCOREBIN/../InstallArea

if ! "$ROOTCOREBIN/bin/$ROOTCORECONFIG/rc" compile
then
  echo "Error occured while trying to compile RootCore packages." && return 1;
fi

# Update environment
source ./setrootcore.sh --silent

true
