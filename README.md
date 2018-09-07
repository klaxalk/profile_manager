# Profile manager
 
creating profiles in linux dotfiles

## Description 

_Profile manager_ handles automatic switching of profiles in config files based on predefined set of keywords.

## Premise

This piece of software allows to create profiles in linux _dotfiles_.
The profiles can be maintained within a single branch on git, which streamlines the proces of sharing configuration between various devices and even users, both of which might need minor customizations in othewise mostly universal set of files.
Morover, profiles are "must have" for switching colorschemes.
The authors personal experience suggests that maintaining minor customizations in git branches often leads to difficult rebasing, which generally slows down the process of pushing new changes from any devices to any other device, resulting in fractured setup.
Thus appeared the idea to contain each version of the configuration within the file.
The section will be activated by uncommenting it only on the device (or by a user) which it is meant for.
_Profile manager_ takes care of automatic commenting/uncommenting of sections of dotfiles via an updated _git_ command with custom hooks.

## Dependencies

_Profile manager_ depends on
1. **bash** (need array manipulation, etc.),
2. **vim** (via [epigen](https://github.com/klaxalk/epigen))
No speial configuration is needed for either of those.

Epigen utilizes Tim Pope's [vim-commentary](https://github.com/tpope/vim-commentary) vim plugin, which has been integrated in the epigen's .vimrc.

## How to

1. The dotfiles, containing profile-specific code, should follow [epigen](https://github.com/klaxalk/epigen)'s syntax.
2. _Profile manager_ expects a list of profiles (that should be activated) as exported variables (presumably set in .bashrc/.zshrc file).
 Those are _PROFILES_ADDITIONS_ (effects only uncommenting), _PROFILES_DELETIONS_ (effects only commenting out) and _PROFILES_BOTH_ (effects both commenting out and uncommenting). Example follows:
 ```
 export PROFILES_ADDITIONS=""
 export PROFILES_DELETIONS="SPECIFIC_SETTING1"
 export PROFILES_BOTH="JOHN LAPTOP"
 ```
3. The dotfiles, which should be handled by _Profile manager_, should be listed within a config file.
 Each line should contain the original path of the file (presumably in git repo), the local path (elsewhere, or ignored by git) and the commenting style descriptor for the particular syntax of the file (see [epigen](https://github.com/klaxalk/epigen)).
 The file might look like this:
 ```
 $GIT_PATH/linux-setup/appconfig/vim/dotvimrc, ~/.vimrc, \"\ %s
 $GIT_PATH/linux-setup/appconfig/urxvt/dotXresources, ~/.Xresources, \!\ %s
 $GIT_PATH/linux-setup/appconfig/bash/dotbashrc_git, $GIT_PATH/linux-setup/appconfig/bash/dotbashrc, \#\ %s
 $GIT_PATH/linux-setup/appconfig/zsh/dotzshrc_git, $GIT_PATH/linux-setup/appconfig/zsh/dotzshrc, \#\ %s
 ```
4. _Profile manager_ might be called either manually (see Examples) or hooked up to _git pull_ or other git commands.

# Examples

## Calling _Profile manager_ manually

An example can be seen in **example** subfolder.

The script **deploy_configs.sh** deploys the _my_config.txt_ file to /tmp while it activates the _TEST1_ profile for both additions and deletions:
```bash
# make the script run in bash/zsh while having the dotfile sourced
PNAME=$( ps -p "$$" -o comm= )
SNAME=$( echo "$SHELL" | grep -Eo '[^/]+/?$' )
if [ "$PNAME" != "$SNAME" ]; then
exec "$SHELL" "$0" "$@"
exit "$?"
else
source ~/."$SNAME"rc
fi

export PROFILES_ADDITIONS=""
export PROFILES_DELETIONS=""
export PROFILES_BOTH="TEST1"

../profile_manager.sh deploy example_file_list.txt
```

The script **backup_config.sh** backups the same config file back while it unsets all profiles to the default state:
```bash
# make the script run in bash/zsh while having the dotfile sourced
PNAME=$( ps -p "$$" -o comm= )
SNAME=$( echo "$SHELL" | grep -Eo '[^/]+/?$' )
if [ "$PNAME" != "$SNAME" ]; then
exec "$SHELL" "$0" "$@"
exit "$?"
else
source ~/."$SNAME"rc
fi

../profile_manager.sh backup example_file_list.txt
```

## Basic workflow

Since the selected files will apear in two places on your system

* the **original**, typically synced with git,
* the **personalized**, which is only local and should not be commited,

following workflow should be established:

1. Before any **git** action, which might modify or commit files in the repository, the **personalized** configs should be backud app to git and all profiles should be unset.
2. After any action in **git** repo, which might modify the files (reset, checkout, pull, ...), local file should be updated.

The workflow can be automated, see the following section.

## Automating with **git**

Hooking up _Profile manager_ to git might seem to be possible using _git hooks_, however I struggled to find a solution, which could run custom commands both before and after _pull_, _checkout_ and _reset_.
This can be solved by custom git alias, which can also contain other usefull stuff, e.g., updating submodules after pulling, etc.
Please be inspired, but do not forget to **change the path to your repository**:
```bash
# upgrades the "git pull" to allow dotfiles profiling on linux-setup
# Other "git" features should not be changed
git() {

  case $* in pull*|checkout*|"reset --hard")

    # give me the path to root of the repo we are in
    ROOT_DIR=`git rev-parse --show-toplevel` 2> /dev/null

    if [[ "$?" == "0" ]]; then

      # if we are in the 'linux-setup' repo, use the Profile manager
      if [[ "$ROOT_DIR" == "$GIT_PATH/linux-setup" ]]; then

        PROFILE_MANAGER="$GIT_PATH/linux-setup/submodules/profile_manager/profile_manager.sh"

        bash -c "$PROFILE_MANAGER backup $GIT_PATH/linux-setup/appconfig/profile_manager/file_list.txt"

        command git "$@"

        case $* in pull*|checkout*)
          echo "Updating git submodules"
          command git submodule update --init --recursive
        esac

        if [[ "$?" == "0" ]]; then

          bash -c "$PROFILE_MANAGER deploy $GIT_PATH/linux-setup/appconfig/profile_manager/file_list.txt"

        fi

      else
        command git "$@"
        case $* in pull*|checkout*)
          echo "Updating git submodules"
          command git submodule update --init --recursive
        esac
      fi

    else
      command git "$@"
      case $* in pull*|checkout*)
        echo "Updating git submodules"
        command git submodule update --init --recursive
      esac
    fi

    ;;
  *)
    command git "$@"
    ;;

  esac
}
```

then, when running e.g. _git pull_, it should look like on the following image.
The first _git pull_ shows the alias withing a folder with _Profile manager_, the other in just a general git repository.

![example_git_pull](misc/screenshot_git_pull.png)
