MAKEFILE="$PWD/Makefile.RootCore"
BASE_NEW_ENV_FILE="new_env_file.sh"
NEW_ENV_FILE="$PWD/$BASE_NEW_ENV_FILE"

arch=$(root-config --arch)
CXX=$(root-config --cxx)

if test "$arch" = "macosx64"
then
  include_marker="-I"
  include_system_marker="-isystem"
else
  include_marker="-I"
  include_system_marker="-isystem"
fi

test "x$ROOTCOREBIN" = "x" && { echo "\$ROOTCOREBIN isn't set."  && return 1; }

DEP_AREA="$ROOTCOREBIN/../Downloads"; DEP_AREA_BSLASH="\${ROOTCOREBIN}/../Downloads"
INSTALL_AREA="$ROOTCOREBIN/../InstallArea"; INSTALL_AREA_BSLASH="\${ROOTCOREBIN}/../InstallArea"

# Make sure the folders exist
test \! -d "$DEP_AREA" && mkdir -p "$DEP_AREA"
test \! -d "$INSTALL_AREA" && mkdir -p "$INSTALL_AREA"

source "$ROOTCOREBIN/../RootCoreMacros/common_shell_fcns.sh"
