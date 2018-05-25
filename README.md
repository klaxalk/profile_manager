# Dotprofiler
 
creating profiles in linux dotfiles

## Description 

## Premise

This piece of software allows to create profiles in linux _dotfiles_.
The profiles can be maintained within a single branch on git, which streamlines the proces of sharing configuration between various devices and even users, both of which might need minor customizations in othewise mostly universal set of files.
The authors personal experience suggests that maintaining minor customizations in git branches often leads to difficult rebasing, which generally slows down the process of pushing new changes from any devices to any other device, resulting in fractured setup.
Thus appeared the idea to contain each version of the configuration within the file.
The section will be activated by uncommenting it only on the device (or by a user) which it is meant for.
Dotprofiler takes care of automatic commenting/uncommenting of sections of dotfiles via an updated _git_ command with custom hooks.

## Dependencies

Dotprofiler depends (through [Epigen](https://github.com/klaxalk/epigen) on
1. **bash**,
2. **vim** (7.0 or higher).
No speial configuration is needed for either of those.

Epigen utilizes Tim Pope's [vim-commentary](https://github.com/tpope/vim-commentary) vim plugin, which has been integrated in the Epigen's .vimrc.

## Automating while using **git**

```bash
# upgrades the "git pull" to allow dotfiles profiling on linux-setup
# Other "git" features should not be changed
git() {

  case $* in pull*|checkout*|"reset --hard")

    # give me the path to root of the repo we are in
    ROOT_DIR=`git rev-parse --show-toplevel` 2> /dev/null

    if [[ "$?" == "0" ]]; then

      # if we are in the 'linux-setup' repo, use the git profiler
      if [[ "$ROOT_DIR" == "$GIT_PATH/linux-setup" ]]; then

        PROFILER="$GIT_PATH/linux-setup/submodules/dotprofiler/profiler.sh"

        bash -c "$PROFILER backup $GIT_PATH/linux-setup/appconfig/dotprofiler/file_list.txt"

        command git "$@"

        case $* in pull*)
          echo "Updating git submodules"
          command git submodule update --init --recursive
        esac

        if [[ "$?" == "0" ]]; then

          bash -c "$PROFILER deploy $GIT_PATH/linux-setup/appconfig/dotprofiler/file_list.txt"

        fi

      else
        command git "$@"
        case $* in pull*)
          echo "Updating git submodules"
          command git submodule update --init --recursive
        esac
      fi

    else
      command git "$@"
      case $* in pull*)
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
