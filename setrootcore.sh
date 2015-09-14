#!/bin/bash
# If executed rather then sourced this won't update the environment.

option=$1
if test $# -eq 1
then
  shift
fi

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
  if test "x${ROOTCOREBIN}" = "x" -o ! "$ROOTCOREBIN" = "$script_place/$baseDir"
  then
    # Unset previous rootcore if it was set:
    test "x${ROOTCOREBIN}" != "x" && source $ATLAS_LOCAL_RCSETUP_PATH/rcSetup.sh -u -q
    # Set it and find packages:
    source $ATLAS_LOCAL_RCSETUP_PATH/rcSetup.sh -q Base,2.3.22
    $ROOTCOREBIN/bin/$ROOTCORECONFIG/rc find_packages > /dev/null
  else
    test "x$option" != "x--silent" && echo "Environment already set, did not set it again!"
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
      test "x$option" != "x--silent" && echo "Environment already set, did not set it again!"
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
NEW_ENV_FILE=new_env_file.sh
for file in `find "$ROOTCOREBIN/.." -maxdepth 3 -mindepth 3 -path "*/cmt/*" -name "$NEW_ENV_FILE" `
do
  test -x "$file" && source "$file" && test "x$option" != "x--silent" && echo "Adding $file to environment"
done


true
