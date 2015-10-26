#!/bin/bash
# If executed rather then sourced this won't update the environment.

show_help() {
cat << EOF
Usage: ${0##*/} [--dev=1]

Set current shell to use this folder RootCore environment. This should be
sourced, otherwise it won't change your shell environment and you may
have issues using RootCore.

When no CVMFS is available, it will download the latest release using svn.
Thus, you need to have svn installed to be able to set the environment with
no CVMFS access.

    -h             display this help and exit
    --silent       Don't print any message.
    --release      The RootCore release it should use. This only takes effect
                   if used with CVMFS access. 
EOF
}

# Default values
silent=0
release='Base,2.3.22'

while :; do
  case $1 in
    -h|-\?|--help)   # Call a "show_help" function to display a synopsis, then exit.
      show_help
      exit
      ;;
    --silent)
      if [ ${2#--} != $2 ]; then
        silent=1
      else
        silent=$2
        shift 2
        continue
      fi
      ;;
    --release)
      release=$2
      shift 2
      continue
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


if test -e $ATLAS_LOCAL_ROOT_BASE
then
  source ${ATLAS_LOCAL_ROOT_BASE}/user/atlasLocalSetup.sh > /dev/null
  # cvmfs exists
  # Set to a stable release
  script_place="$(readlink -f $(dirname "$0"))"
  baseDir=$(basename "$ROOTCOREBIN")
  # We only set the environment if it wasn't set to the desired release:
  if test "x${ROOTCOREBIN}" = "x" -o "$ROOTCOREBIN" != "$script_place/$baseDir" -o "${release/,/ }" != "$(source $ATLAS_LOCAL_RCSETUP_PATH/rcSetup.sh -M)"
  then
    # Unset previous rootcore
    test "x${ROOTCOREBIN}" != "x" && source $ATLAS_LOCAL_RCSETUP_PATH/rcSetup.sh -u -q
    # Set it and find packages:
    source $ATLAS_LOCAL_RCSETUP_PATH/rcSetup.sh -q -f $release > /dev/null
    #$ROOTCOREBIN/bin/$ROOTCORECONFIG/rc find_packages > /dev/null
  else
    test "$silent" -eq 0 && echo "Environment already set, did not set it again!"
  fi
else 
  unset ATLAS_LOCAL_ROOT_BASE
  if test \! -e RootCore
  then
    svn co svn+ssh://svn.cern.ch/reps/atlasoff/PhysicsAnalysis/D3PDTools/RootCore/tags/`svn ls svn+ssh://svn.cern.ch/reps/atlasoff/PhysicsAnalysis/D3PDTools/RootCore/tags | tail -n 1` RootCore
    cd RootCore
    svn upgrade > /dev/null
    cd -
  else 
    test \! -e RootCore && echo "Cannot find a RootCore.tgz to compile in standalone." && return 1
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
    if ! $ROOTCOREBIN/internal/rc find_packages > /dev/null
    then
      echo "Couldn't find_packages!"
    fi
  else
    test "x${ROOTCOREBIN}" = "x" && echo "Cannot find RootCore dir. Something went wrong during the setup" && return 1
  fi
fi

# Add environment variables
export NEW_ENV_FILE=new_env_file.sh
test "x$ROOTCOREBIN" = "x" && echo "For some reason ROOTCOREBIN is not set." && return 1
for file in `find -L "$ROOTCOREBIN/.." -maxdepth 3 -mindepth 3 -path "*/cmt/*" -name "$NEW_ENV_FILE" `
do
  test -x "$file" && source "$file" && { test "$silent" -eq 0 && echo "Adding $file to environment"; }
done


true
