show_help() {
cat << EOF
Usage: ${0##*/} [--clean|--veryclean|--distclean] [--no-build] [--cleanenv] [--grid]

Compile RootCore environment and install it. This should be sourced, otherwise
it won't change your shell environment and you may have issues using RootCore.

    -h             display this help and return
    --clean-env|--cleanenv
                   This will clean environment files, although it won't reset
                   the shell environment. It is better used with a new fresh
                   cell before compiling.
    --clean        Clean previous RootCore binaries and recompile.
    --very-clean|--veryclean    
                   As clean, but also clean previous environment files before
                   recompiling.
    --dist-clean|--distclean    
                   As veryclean, but also clean previous installed dependencies
                   before recompiling.
    --no-build     Use this flag if you don't want to build the RootCore packages.
                   When combined with the cleaning flags, it can be used to
                   set package to start conditions.
    --with-{var}   Set environment variable \${VAR} to true. This only makes effect
                   if some dependent package checks for this variable.
    --grid         Flag that compilation is for the grid environment. 
EOF
}

# Taken from: http://stackoverflow.com/a/28776166/1162884
([[ -n $ZSH_EVAL_CONTEXT && $ZSH_EVAL_CONTEXT =~ :file$ ]] || 
 [[ -n $KSH_VERSION && $(cd "$(dirname -- "$0")" &&
    printf '%s' "${PWD%/}/")$(basename -- "$0") != "${.sh.file}" ]] || 
 [[ -n $BASH_VERSION && $0 != "$BASH_SOURCE" ]]) && sourced=1 || sourced=0

# Default values
grid=0
clean=0
cleanenv=0
veryclean=0
distclean=0
nobuild=0

while :; do
  case $1 in
    -h|-\?|--help)   # Call a "show_help" function to display a synopsis, then exit.
      show_help
      test "$sourced" -eq 1 && return || exit
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
      test "$sourced" -eq 1 && return 1 || exit 1
      ;;
    --cleanenv|--clean-env)
      if [ ${2#--} != $2 ]; then
        cleanenv=1
      else
        cleanenv=$2
        shift 2
        continue
      fi
      ;;
    --cleanenv=?*|--clean-env=?*)
      cleanenv=${1#*=} # Delete everything up to "=" and assign the remainder.
      ;;
    --cleanenv=|--clean-env=)   # Handle the case of an empty --cleanenv=
      echo 'ERROR: "--cleanenv" requires a non-empty option argument.\n' >&2
      test "$sourced" -eq 1 && return 1 || exit 1
      ;;
    --distclean|--dist-clean)
      if [ ${2#--} != $2 ]; then
        distclean=1
      else
        distclean=$2
        shift 2
        continue
      fi
      ;;
    --distclean=?*|--dist-clean=?*)
      distclean=${1#*=} # Delete everything up to "=" and assign the remainder.
      ;;
    --distclean=|--dist-clean=)   # Handle the case of an empty --distclean=
      echo 'ERROR: "--distclean" requires a non-empty option argument.\n' >&2
      test "$sourced" -eq 1 && return 1 || exit 1
      ;;
    --veryclean|--very-clean)
      if [ ${2#--} != $2 ]; then
        veryclean=1
      else
        veryclean=$2
        shift 2
        continue
      fi
      ;;
    --veryclean=?*|--very-clean=?*)
      veryclean=${1#*=} # Delete everything up to "=" and assign the remainder.
      ;;
    --veryclean=|--very-clean=)   # Handle the case of an empty --veryclean=
      echo 'ERROR: "--veryclean" requires a non-empty option argument.\n' >&2
      test "$sourced" -eq 1 && return 1 || exit 1
      ;;
    --no-build|nobuild)
      if [ ${2#--} != $2 ]; then
        nobuild=1
      else
        nobuild=$2
        shift 2
        continue
      fi
      ;;
    --no-build=?*|nobuild=?*)
      nobuild=${1#*=} # Delete everything up to "=" and assign the remainder.
      ;;
    --no-build=|nobuild=)   # Handle the case of an empty --nobuild=
      echo 'ERROR: "--no-build" requires a non-empty option argument.\n' >&2
      test "$sourced" -eq 1 && return 1 || exit 1
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
      test "$sourced" -eq 1 && return 1 || exit 1
      ;;
    --with-?*)
      eval "export $(echo ${1#--with-} | tr "[a-z]" "[A-Z]" | tr "-" "_")=1" # Assign variable to true.
      ;;
      # TODO Grep = value
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

test $veryclean -eq 1 && clean=1;
test $distclean -eq 1 && clean=1 && veryclean=1;

# Set RootCore environment
source ./setrootcore.sh --silent --no-env-setup "--grid=$grid"

# Compile
test $clean -eq "1" && "$ROOTCOREBIN/bin/$ROOTCORECONFIG/rc" clean

if test $veryclean -eq 1 -o $cleanenv -eq 1; then
  echo "cleaning environment-files..."
  # Remove old environment files (to be sure that we won't have old files on the environment):
  for file in `find -L "$ROOTCOREBIN/.." -maxdepth 3 -mindepth 3 -path "*/cmt/*" -name "$BASE_NEW_ENV_FILE" `
  do
    test -x "$file" && rm "$file"
  done
fi

if test $distclean -eq "1"; then
  echo "cleaning everything..."
  rm -rf "$DEP_AREA" "$INSTALL_AREA"
fi

# Now add the new environment files
source ./setrootcore.sh --silent "--grid=$grid"

if test $nobuild -eq "0"; then
  if ! "$ROOTCOREBIN/bin/$ROOTCORECONFIG/rc" compile; then
    echo "Error occured while trying to compile RootCore packages." && test "$sourced" -eq 1 && return 1 || exit 1
  fi
else
  echo "--no-build flag set, skipped building..."
fi

# Finally, update user environment to the one needed by the installation
source ./setrootcore.sh --silent "--grid=$grid"

true
