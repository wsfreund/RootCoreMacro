# Set rootcore environment
source ./setrootcore.sh --silent

# FIXME Low priority: set compilation to reset PWD, use dirs

# This is needed to install boost
if test -e RingerCore/cmt;
then
  cd RingerCore/cmt/
  if ! ./precompile.RootCore
  then
    echo "Couldn't prepare boost installation..." && return 1;
  fi
fi

cd - > /dev/null

# Update environment
source ./setrootcore.sh --silent

# Compile
$ROOTCOREBIN/bin/$ROOTCORECONFIG/rc clean
if ! $ROOTCOREBIN/bin/$ROOTCORECONFIG/rc compile
then
  echo "Error occured while trying to compile RootCore packages." && return 1;
fi

# Update environment
source ./setrootcore.sh --silent

true
