show_help() {
cat << EOF
Usage: ${0##*/} [--silent] [--release=Base,2.4.23] [--no-env-setup]
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
   --acount           The CERN account name to download the last RootCore
                      release. When not informed, it will use the current 
                      account of the system.
                      If it fails to download with the provided account, it 
                      will use a git copy of the RootCore.
    --grid            Flag that environment should be set for the grid
    --ncpus           Flag the number of cpus to use
    --no-cvmfs        Ignore cvmfs if it is available and install it without
                      AnalysisBase.
    --no-color        Set RCM_NO_COLOR flag to tell jobs to display uncolored 
                      log messages
EOF
}

# Default values
silent=0
release='Base,2.4.23'
#release='Base,2.3.22'
NO_ENV_SETUP=0
NO_CVMFS=0
account=$(whoami)
export RCM_GRID_ENV=0
export RCM_NO_COLOR=0
export RCM_NCPUS=""

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
    --no-cvmfs)
      if [ ${2#--} != $2 ]; then
        NO_CVMFS=1
      else
        NO_CVMFS=$2
        shift 2
        continue
      fi
      ;;
    --no-cvmfs=?*)
      NO_CVMFS=${1#*=} # Delete everything up to "=" and assign the remainder.
      ;;
    --no-cvmfs=)       # Handle the case of an empty --no-cvmfs=
      echo 'ERROR: "--no-cvmfs" requires a non-empty option argument.\n' >&2
      return 1
      ;;
    --no-color)
      if [ ${2#--} != $2 ]; then
        RCM_NO_COLOR=1
      else
        RCM_NO_COLOR=$2
        shift 2
        continue
      fi
      ;;
    --no-color=?*)
      RCM_NO_COLOR=${1#*=} # Delete everything up to "=" and assign the remainder.
      ;;
    --no-color=)       # Handle the case of an empty --no-cvmfs=
      echo 'ERROR: "--no-color" requires a non-empty option argument.\n' >&2
      return 1
      ;;
    --grid)
      if [ ${2#--} != $2 ]; then
        RCM_GRID_ENV=1
      else
        RCM_GRID_ENV=$2
        shift 2
        continue
      fi
      ;;
    --grid=?*)
      RCM_GRID_ENV=${1#*=} # Delete everything up to "=" and assign the remainder.
      ;;
    --grid=)   # Handle the case of an empty --grid=
      echo 'ERROR: "--grid" requires a non-empty option argument.\n' >&2
      return 1
      ;;
    --ncpus)
      if [ ${2#--} != $2 ]; then
        echo 'ERROR: "--ncpus" requires a non-empty option argument.\n' >&2
        return 1
      else
        RCM_NCPUS=$2
        shift 2
        continue
      fi
      ;;
    --ncpus=?*)
      RCM_NCPUS=${1#*=} # Delete everything up to "=" and assign the remainder.
      ;;
    --ncpus=)   # Handle the case of an empty --ncpus=
      echo 'ERROR: "--ncpus" requires a non-empty option argument.\n' >&2
      return 1
      ;;
    --account)
      if [ ${2#--} != $2 ]; then
        echo 'ERROR: "--account" requires a non-empty option argument.\n' >&2
        return 1
      else
        account=$2
        shift 2
        continue
      fi
      ;;
    --account=?*)
      acccount=${1#*=}
      ;;
    --account=)   # Handle the case of an empty --account=
      echo 'ERROR: "--account" requires a non-empty option argument.\n' >&2
      return 1
      ;;
    --)              # End of all options.
      shift
      break
      ;;
    -?*)
      printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
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

# Get sourced script absolute path
if test "$RCM_GRID_ENV" -eq "1"; then
  script_place=$PWD
else
  if test -n "$($SHELL -c 'echo $ZSH_VERSION')"; then
    script_place="$(dirname $(readlink -f "$0"))"
  elif test -n "$($SHELL -c 'echo $BASH_VERSION')"; then
    script_place=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
  elif test "$(basename "$SHELL")" = "zsh"; then
    script_place="$(dirname $(readlink -f "$0"))"
  elif test "$(basename "$SHELL")" = "bash"; then
    script_place=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
  else
    printf "ERROR: Unsupported shell." >&2 && return 1;
  fi
fi
test $(basename "$script_place") = "RootCoreMacros" && script_place="$(dirname $script_place)"

# FIXME: This messes up with dirs history by removing $script_place dir if it
# was in the history.
dopop=false
test "$PWD" != "$script_place" && pushd $script_place > /dev/null && dopop=true

if test -e "$ATLAS_LOCAL_ROOT_BASE" -a \! \( "$NO_CVMFS" != "0" \)
then
  # cvmfs exists
  source "${ATLAS_LOCAL_ROOT_BASE}/user/atlasLocalSetup.sh" > /dev/null
  baseDir=$(basename "$ROOTCOREBIN")
  # We only set the environment if it wasn't set to the desired release:
  if test "x${ROOTCOREBIN}" = "x" -o "$ROOTCOREBIN" != "$script_place/$baseDir" -o "${release/,/ }" != "$(source $ATLAS_LOCAL_RCSETUP_PATH/rcSetup.sh -M -q)"
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
    if svn co -q \
      --config-option config:tunnels:ssh="ssh -o PasswordAuthentication=no -o NumberOfPasswordPrompts=0" \
      "svn+ssh://${account}@svn.cern.ch/reps/atlasoff/PhysicsAnalysis/D3PDTools/RootCore/tags/$(svn ls \
        --config-option config:tunnels:ssh="ssh -o PasswordAuthentication=no -o NumberOfPasswordPrompts=0" \
        "svn+ssh://${account}@svn.cern.ch/reps/atlasoff/PhysicsAnalysis/D3PDTools/RootCore/tags" 2> /dev/null | tail -n 1)" RootCore \
        2> /dev/null
  then
      pushd RootCore > /dev/null
      svn upgrade 2> /dev/null
      popd > /dev/null
    else
      git clone -q https://github.com/wsfreund/RCMirror.git tmpDir
      mv tmpDir/RootCore.tgz .
      rm -rf tmpDir 
      tar xfz RootCore.tgz
      pushd RootCore > /dev/null
      svn upgrade 2> /dev/null
      popd > /dev/null
      rm RootCore.tgz
    fi
  else 
    test \! -e RootCore && echo "Couldn't find retrieve RootCore to compile in standalone." >&2 && \
      { $dopop && popd > /dev/null || true; } && return 1
  fi
  if test -e RootCore
  then 
    if test "x${ROOTCOREBIN}" = "x"
    then
      pushd RootCore > /dev/null
      . scripts/setup.sh
      popd > /dev/null
    else
      test "$silent" -eq 0 && echo "Environment already set, did not set it again!"
    fi
    if ! "$ROOTCOREBIN/internal/rc" find_packages > /dev/null
    then
      echo "Couldn't find_packages!"
    fi
  else
    test "x${ROOTCOREBIN}" = "x" && echo "Cannot find RootCore dir. Something went wrong during the setup" >&2 && \
      { $dopop && popd > /dev/null || true; } && return 1
  fi
fi

# Check if everything was ok and load default environment.
test "x${ROOTCOREBIN}" = "x" && echo "FAILED: For some reason ROOTCOREBIN is not set. Skipping..." >&2 && \
  { $dopop && popd > /dev/null || true; } && return 1

test -e "${ROOTCOREBIN}/../RootCoreMacros/base_env.sh" || { echo "Cannot find base_env.sh file!" >&2 && return 1; }

source "${ROOTCOREBIN}/../RootCoreMacros/base_env.sh"

# Add environment variables
if test $NO_ENV_SETUP -eq "0"; then
  for file in $(find -L "$ROOTCOREBIN/.." -maxdepth 3 -mindepth 3 -path "*/cmt/*" -name "$BASE_NEW_ENV_FILE")
  do
    test -x "$file" && source "$file" && { test "$silent" -eq 0 && echo "Adding $file to environment"; }
  done
fi

# Override number of cores
if test "x$RCM_NCPUS" = "x"; then
  export RCM_NCPUS=$ROOTCORE_NCPUS
fi

# We set all variables that may be used as an library accelerator:
export OMP_NUM_THREADS=$RCM_NCPUS;
export OPENBLAS_NUM_THREADS=$RCM_NCPUS; # openblas
export GOTO_NUM_THREADS=$RCM_NCPUS; # GotoBLAS2
export MKL_NUM_THREADS=$RCM_NCPUS; # Intel MKL
export ROOTCORE_NCPUS=$RCM_NCPUS; # RootCore, just to prevent mistakes


if test -f "/sw/apps/intel16/compilers_and_libraries_2016.4.258/linux/bin/intel64/icpc"; then
  if test "$RCM_GRID_ENV" -eq "1"; then 
    RCM_GRID_EXTRA="ssh service1 "
  fi
  if module display intel > /dev/null 2> /dev/null; then
    RCM_THEANO_CXX="${RCM_GRID_EXTRA}/sw/apps/intel16/compilers_and_libraries_2016.4.258/linux/bin/intel64/icpc"
    RCM_THEANO_CXXFLAGS=",gcc.cxxflags='-O3 -parallel'"
  else
    echo "WARN: failed to load intel compiler, set to use cxx"
    RCM_THEANO_CXX="$(which cxx)"
    RCM_THEANO_CXXFLAGS=",gcc.cxxflags='-O3 -parallel'"
  fi
  unset RCM_GRID_EXTRA
fi


if test "x$THEANO_FLAGS" = "x"; then
  if test "$RCM_THEANO_CXX"; then
    export THEANO_FLAGS="openmp=True,cxx=$RCM_THEANO_CXX$RCM_THEANO_CXXFLAGS"
  else
    export THEANO_FLAGS="openmp=True"
  fi
fi

# Return to original dir
$dopop && popd > /dev/null

true
