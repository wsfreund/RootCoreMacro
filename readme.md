
# Ringer framework: RootCoreMacros package

This package is a non-official plug-in for RootCore that offers a series of
shell macros and functions. It makes easier for the user to build RootCore
packages and to setup the RootCore environment automatically adding local project
dependencies and executables to path.

Table of Contents
=================

  * [Ringer framework: RootCoreMacros package](#ringer-framework-rootcoremacros-package)
  * [Usage](#usage)
    * [setrootcore.sh](#setrootcoresh)
      * [To do and known bugs:](#to-do-and-known-bugs)
    * [buildthis.sh](#buildthissh)
      * [Procedure for a clean build](#procedure-for-a-clean-build)
      * [To do and known bugs](#to-do-and-known-bugs-1)
    * [setup_modules.sh](#setup_modulessh)
      * [Retrieving framework source codes for the first time](#retrieving-framework-source-codes-for-the-first-time)
      * [Updating the framework to the last stable release](#updating-the-framework-to-the-last-stable-release)
      * [Remark for developers](#remark-for-developers)
  * [Information for developers](#information-for-developers)
    * [base_env.sh](#base_envsh)
    * [common_shell_fcns.sh](#common_shell_fcnssh)
    * [retrieve_python_info.sh](#retrieve_python_infosh)


# Usage

The available shell files are:



```python
%%bash
find . -name "*.sh"
```

    ./buildthis.sh
    ./setrootcore.sh
    ./setup_modules.sh
    ./base_env.sh
    ./common_shell_fcns.sh
    ./retrieve_python_info.sh


A brief explanation on them:

- [`buildthis.sh`](https://github.com/wsfreund/RootCoreMacros/tree/master/buildthis.sh): Used for compiling or cleaning the framework;
- [`setrootcore.sh`](https://github.com/wsfreund/RootCoreMacros/tree/master/setrootcore.sh): Main shell script to setup the RootCore local project. It also changes the variables of the shell environment to hold project dependencies and adds its executables to the shell path;
- [`setup_modules.sh`](https://github.com/wsfreund/RootCoreMacros/tree/master/setup_modules.sh): Script for making easier the interaction with `git submodules` for git newbies. It must be used right after cloning the framework;
- [`base_env.sh`](https://github.com/wsfreund/RootCoreMacros/tree/master/base_env.sh): Contains the basic environment variables to be used by dependent packages;
- [`common_shell_fcns.sh`](https://github.com/wsfreund/RootCoreMacros/tree/master/common_shell_fcns.sh): Contains the shell functions that may be used by all dependent packages;
- [`retrieve_python_info.sh`](https://github.com/wsfreund/RootCoreMacros/tree/master/retrieve_python_info.sh): A shell script to determine python installation place and other related variables.

## setrootcore.sh

This script must be sourced (otherwise the environment changes wouldn't make effect on the current shell process). It changes the shell (tested with bash and zsh) environment by setting the RootCore environment, also adding other local project dependencies to the environment. If the environment has already been previously compiled, all you need to do is to run this script to have access to all functionalities provided by the local RootCore project. 

It detects if another RootCore environment was previously set and, if so, disables it to set the new RootCore environment on the base path where the `setrootcore.sh`file is. 

The standard release is the RootCore `Base`, where you will have access to ATLAS base framework, with xAOD access and many other functionalities. The release can be changed by specifying the `--release` flag. As this is not needed for performing some of the frameworks functionalities, you can set it on a machine isolated from the CERN network. The `--release` flag does not make any effect if it is being sourced outside the CERN network.

The `--no-env-setup` flag can be used if it is needed to set only the RootCore environment, but not to source the plug-in specific environment files.

Finally, the `--grid` flag is used for specifying that the environment is being set inside the CERN grid. However, users might want to call it if single-core should be used.


```python
%%bash
source $ROOTCOREBIN/../setrootcore.sh -h
```

    Usage: bash [--silent] [--release=Base,2.3.22] [--no-env-setup]
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


### To do and known bugs:

- Add option to clean environment by unsetting every change made by the plug-in in the shell environment;
- Without CVMFS: if the user account is different from the CERN account, it will fail to download the svn package;
- Make it python managed.

## buildthis.sh

When sourced, this script will compile the environment as if using `rc compile`, but also taking care of other environment details needed by the packages compilation and setup, as defining the environment variables needed by the framework besides the ones defined by RootCore.

If the script is executed instead of sourced, it will compile without any flaws, however you will need to run `./setrootcore.sh` to set the environment.

*Important*: If you are using svn version of the RootCore (usually without CVMFS access), you will need to run the buildthis.sh twice. If you don't know what this means, just do this every time you want to build the program:

```
source buildthis.sh
source buildthis.sh
```

It seems that the current RootCore versions are having trouble to update the Makefile.RootCore file before executing it, hence it is needed to run the first time to update the file and the second to correctly build the package. If, however, after executing a second time the same error is stated, then there is a bug and it should be reported.


```python
%%bash
source $ROOTCOREBIN/../buildthis.sh -h
```

    Usage: bash [--clean|--veryclean|--distclean] [--no-build] [--cleanenv] [--grid]
    
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
        --with-{var}   Set environment variable ${VAR} to true. This only makes effect
                       if some dependent package checks for this variable.
        --grid         Flag that compilation is for the grid environment. 


### Procedure for a clean build

*This should only be needed by developers*

If the RootCore project has already been installed and a build upon a clean environment is needed, consider following this procedure:



```python
%%bash
# Clean everything
source buildthis.sh --clean-env --dist-clean --no-build
# Now open a new shell to have a clean environment and source the buildthis.sh with the desired flags.
# This step can be skipped if you have used ./buildthis.sh instead of source buildthis.sh
```

Some cases where this may be needed:

- Add or removal of package dependencies on `precompile.sh`;
- Need to change the shell environment variables order. 

### To do and known bugs

- Make it python managed;
- When using svn RootCore, it is needed to execute the script several times to have a successful build.

## setup_modules.sh

In order to determine package dependencies and valid releases, meanwhile keeping packages independences, the frameworks use `git submodules`. This script aims on simplifying the usage for the user.

The command usage is:


```python
%%bash
./setup_modules.sh -h
```

    Usage: setup_modules.sh [--dev] [--head]
    
    Initialize current master module and get child modules on their respective commits
    determined by the master module release.
    
        -h                display this help and return
        -d|--dev          If set to true, then retrieve commited packages with 
                          your ssh git push rights. Of course, this assumes that
                          your git account has the rights to do so, otherwise it
                          will fail. 
       -H|--head          It will update to the submodules head instead of the used
                          commit versions stablished to be used by the packge.


### Retrieving framework source codes for the first time

The procedure to be followed is:

```zsh
git clone <project_url>
./setup_modules.sh
```

where `<project_url>` can be any framework, as the [RingerProject](https://github.com/joaoVictorPinto/RingerProject) or [RingerTuning](https://github.com/wsfreund/RingerTuning).

### Updating the framework to the last stable release

Update the framework package and run again the `setup_modules.sh` as follows:

```zsh
git pull origin master
./setup_modules.sh
```
### Remark for developers

The `--dev` flag will change the submodules origins to work with your git ssh key, allowing you to push your changes to the package without any requests (as long your account has the permissions).

On the other hand, the `--head` flag will set the packages to their last master commits (assumed to be the packages head commit).

# Information for developers

## base_env.sh

When sourced, it defines constants to be used by the framework packages, as the name of the folders and the name of the new shell environment file. Also gives access to the content available on the `common_shell_fcns.sh`.

Currently it defines the followin variables:

- `MAKEFILE`: RootCore makefile name;
- `BASE_NEW_ENV_FILE`: basic name of the new environment file;
- `NEW_ENV_FILE`: environment file being used by the currently package being compiled;
- `arch`: architeture of the processor (as defined by root-config);
- `include_marker`: C++ include marker used by the compiler;
- `include_system_marker`: C++ include system marker used by the compiler;
- `DEP_AREA`: The area for downloading dependent packages;
- `DEP_AREA_BSLASH`: Same as before, but with `$ROOTCOREBIN` not expanded;
- `INSTALL_AREA`: Place for installing the dependencies binaries;
- `INSTALL_AREA_BSLASH`: Same as before, but with `$ROOTCOREBIN` not expanded;


## common_shell_fcns.sh

It defines functions to be used by other packages: 

- `find_lib`: Check if library (`$1`) is available in `$LD_LIBRARY_PATH`;
- `add_to_env_file`: Add value to the environment file, changed when `setrootcore.sh` is sourced, eg:

```
add_to_env_file PATH "\$ROOTCOREBIN/user_scripts/TuningTools/grid_scripts/"
```
where the option `--only-set` can be used if this shouldn't be added to a variable of list type, but rather just set the variable to the value.

- `add_to_env`: Changes current environment variable by adding the value to its list.


## retrieve_python_info.sh

Defines the following variables:

- PYTHON_EXEC_PATH: Python binary base path;
- PYTHON_VERSION_NUM: Python version, without '.' character;
- PYTHON_INCLUDE_PATH: Python include path to be passed to the C++ compilers;
- PYTHON_NUMPY_PATH (if `--numpy-info` specified): the base path to the numpy package;
- INCLUDE_NUMPY (if `--numpy-info` specified): Numpy include path to be passed to the C++ compilers.

