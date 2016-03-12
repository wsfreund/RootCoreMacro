show_help() {
cat << EOF
Usage: ${0##*/} [--silent] [--release=Base,2.3.22] [--no-env-setup]
                [--grid]

Set current shell to use this folder RootCore environment. This should be
sourced, otherwise it won't change your shell environment and you may
have issues using RootCore.

When no CVMFS is available, it will download the latest release using svn.
Thus, you need to have svn installed to be able to set the environment with
no CVMFS access.

    -h                display this help and return
    -s|--silent       Don't print any message.
    -r|--release      The RootCore release it should use. This only takes
                      effect if used with CVMFS access. 
   --no-env-setup     Do not source new environment files.
    --grid            Flag that environment should be set for the grid (set
                      single-thread)
EOF
}

# Default values
silent=0
grid=0
release='Base,2.3.22'
NO_ENV_SETUP=0

while :; do
  case $1 in
    -h|-\?|--help)   # Call a "show_help" function to display a synopsis, then exit.
      show_help
      return
      ;;
    -s|--silent)
      if [ ${2#--} != $2 ]; then
        silent=1
      else
        silent=$2
        shift 2
        continue
      fi
      ;;
    -s=?*|--silent=?*)
      silent=${1#*=} # Delete everything up to "=" and assign the remainder.
      ;;
    -s=|--silent=)   # Handle the case of an empty --silent=
      echo 'ERROR: "--silent" requires a non-empty option argument.\n' >&2
      return 1
      ;;
    -r|--release)
      release=$2
      shift 2
      continue
      ;;
    -r=?*|--release=?*)
      release=${1#*=} # Delete everything up to "=" and assign the remainder.
      ;;
    -r=|--release=)   # Handle the case of an empty --release=
      echo 'ERROR: "--release" requires a non-empty option argument.\n' >&2
      return 1
      ;;
    --no-env-setup)
      if [ ${2#--} != $2 ]; then
        NO_ENV_SETUP=1
      else
        NO_ENV_SETUP=$2
        shift 2
        continue
      fi
      ;;
    --no-env-setup=?*)
      NO_ENV_SETUP=${1#*=} # Delete everything up to "=" and assign the remainder.
      ;;
    --no-env-setup=)   # Handle the case of an empty --no-env-setup=
      echo 'ERROR: "--no-env-setup" requires a non-empty option argument.\n' >&2
      return 1
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
      return 1
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

# source atlasLocalSetup
if test "x$ATLAS_LOCAL_ROOT_BASE" = "x"
then
  export ATLAS_LOCAL_ROOT_BASE=/cvmfs/atlas.cern.ch/repo/ATLASLocalRootBase
fi

if test -e "$ATLAS_LOCAL_ROOT_BASE"
then
  source "${ATLAS_LOCAL_ROOT_BASE}/user/atlasLocalSetup.sh" > /dev/null
  # cvmfs exists
  # Set to a stable release
  script_place="$(readlink -f $(dirname "$0"))"
  baseDir=$(basename "$ROOTCOREBIN")
  # We only set the environment if it wasn't set to the desired release:
  if test "x${ROOTCOREBIN}" = "x" -o "$ROOTCOREBIN" != "$script_place/$baseDir" -o "${release/,/ }" != "$(source $ATLAS_LOCAL_RCSETUP_PATH/rcSetup.sh -M)"
  then
    # Unset previous rootcore
    test "x${ROOTCOREBIN}" != "x" && source "$ATLAS_LOCAL_RCSETUP_PATH/rcSetup.sh" -u -q
    # Set it and find packages:
    source "$ATLAS_LOCAL_RCSETUP_PATH/rcSetup.sh" -q -f $release > /dev/null
    #"$ROOTCOREBIN/bin/$ROOTCORECONFIG/rc" find_packages > /dev/null
  else
    test "$silent" -eq 0 && echo "Environment already set, did not set it again!"
  fi
else 
  unset ATLAS_LOCAL_ROOT_BASE
  if test \! -e RootCore
  then
    svn co "svn+ssh://svn.cern.ch/reps/atlasoff/PhysicsAnalysis/D3PDTools/RootCore/tags/`svn ls svn+ssh://svn.cern.ch/reps/atlasoff/PhysicsAnalysis/D3PDTools/RootCore/tags | tail -n 1`" RootCore
    cd RootCore
    svn upgrade
    cd - > /dev/null
  else 
    test \! -e RootCore && echo "Couldn't find retrieve RootCore to compile in standalone." && return 1
  fi
  if test -e RootCore
  then 
    if test "x${ROOTCOREBIN}" = "x"
    then
      cd RootCore
      . scripts/setup.sh
      cd ..
    else
      test "$silent" -eq 0 && echo "Environment already set, did not set it again!"
    fi
    if ! "$ROOTCOREBIN/internal/rc" find_packages > /dev/null
    then
      echo "Couldn't find_packages!"
    fi
  else
    test "x${ROOTCOREBIN}" = "x" && echo "Cannot find RootCore dir. Something went wrong during the setup" && return 1
  fi
fi

# Check if everything was ok and load default environment.
test "x$ROOTCOREBIN" = "x" && echo "FAILED: For some reason ROOTCOREBIN is not set. Skipping..." && return 1

source "$ROOTCOREBIN/../RootCoreMacros/base_env.sh"

# Add environment variables
if test $NO_ENV_SETUP -eq "0"; then
  for file in `find -L "$ROOTCOREBIN/.." -maxdepth 3 -mindepth 3 -path "*/cmt/*" -name "$BASE_NEW_ENV_FILE" `
  do
    test -x "$file" && source "$file" && { test "$silent" -eq 0 && echo "Adding $file to environment"; }
  done
fi

# Override number of cores if in grid environment:
export RCM_GRID_ENV=0
if test $grid -eq 1; then 
  export RCM_GRID_ENV=1; # Tell packages that we are on grid
  export ROOTCORE_NCPUS=1; # RootCore, just to prevent mistakes
  # We set all variables that armadillo may use as an library accelerator:
  # TODO Maybe we want to tell armadillo to link to single-thread library
  export OMP_NUM_THREADS=1; # AMD ACML (openMP) # works with gpu
  export OPENBLAS_NUM_THREADS=1; # openblas
  export GOTO_NUM_THREADS=1; # GotoBLAS2
  export MKL_NUM_THREADS=1; # Intel MKL
else
  export OMP_NUM_THREADS=$ROOTCORE_NCPUS;
  export OPENBLAS_NUM_THREADS=$ROOTCORE_NCPUS; # openblas
  export GOTO_NUM_THREADS=$ROOTCORE_NCPUS; # GotoBLAS2
  export MKL_NUM_THREADS=$ROOTCORE_NCPUS; # Intel MKL
fi

true
