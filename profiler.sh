#!/bin/bash

PROFILER_SOURCE_DIR=`dirname "$BASH_SOURCE"`
export PROFILER_SOURCE_DIR=`( cd "$PROFILER_SOURCE_DIR" && pwd )`

expandPath() {

  local path
  local -a pathElements resultPathElements
  IFS=':' read -r -a pathElements <<<"$1"
  : "${pathElements[@]}"
  for path in "${pathElements[@]}"; do
    : "$path"
    case $path in
      "~+"/*)
        path=$PWD/${path#"~+/"}
        ;;
      "~-"/*)
        path=$OLDPWD/${path#"~-/"}
        ;;
      "~"/*)
        path=$HOME/${path#"~/"}
        ;;
      "~"*)
        username=${path%%/*}
        username=${username#"~"}
        IFS=: read _ _ _ _ _ homedir _ < <(getent passwd "$username")
        if [[ $path = */* ]]; then
          path=${homedir}/${path#*/}
        else
          path=$homedir
        fi
        ;;
    esac
    resultPathElements+=( "$path" )
  done
  local result
  printf -v result '%s:' "${resultPathElements[@]}"
  printf '%s\n' "${result%:}"
}

dotfilesProfiler() {

  HELP="usage: profiler file_path

file_path: ...
"

  if [ $# -lt 2 ]; then
    echo "$HELP"
    return 1
  fi

  eval FILES_PATH="$(cd "$(dirname "$2")"; pwd)/$(basename "$2")"
  if [ ! -e "$FILES_PATH" ]; then
    echo "The file in the argument does not exist!"
    echo "Debug: $FILES_PATH"
    return 1
  fi

  # parse the csv file and extract file paths
  i="0"
  while IFS=, read -r path1 path2; do
    gitloc[$i]=`eval echo "$path1"`
    locloc[$i]=`eval echo "$path2"`
    # echo "$i ${gitloc[$i]} ${locloc[$i]}"
    i=$(expr $i + 1)
  done < "$FILES_PATH"

  OPERATION="$1"
  N_FILES="$i"

  source "$PROFILER_SOURCE_DIR"/epigen/epigen.sh

  if [[ "$OPERATION" == "deploy" ]]; then

    # for each file
    for ((i=0; i < $N_FILES; i++));
    do

      # get the full path to the file
      gitpath="$(expandPath ${gitloc[$i]})"
      localpath="$(expandPath ${locloc[$i]})"

      # copy the file from the git path to the local path
      if [ -e "$localpath" ]; then

        cp "$gitpath" "$localpath" 

        epigen addition -A "$localpath" 

        # for each addition mode
        for ((j=0; j < ${#EPIGEN_ADDITIONS[*]}; j++));
        do

          # set the mode on the local file
          epigen addition -s "$localpath" "${EPIGEN_ADDITIONS[$j]}"

        done

        # for each reduction mode
        for ((j=0; j < ${#EPIGEN_REDUCTIONS[*]}; j++));
        do

          # set the mode on the local file
          epigen reduction -s "$localpath" "${EPIGEN_REDUCTIONS[$j]}"

        done

      else

        echo "Profiler: Omitting ${locloc[$i]} since the local file does not exist"

      fi

    done

  elif [[ "$OPERATION" == "backup" ]]; then

    # for each file
    for ((i=0; i < $N_FILES; i++));
    do

      # get the full path to the file
      gitpath="$(expandPath ${gitloc[$i]})"
      localpath="$(expandPath ${locloc[$i]})"

      # copy the file from the git path to the local path
      if [ -e "$localpath" ]; then

        # copy the file from the local path to the git path
        cp "$localpath" "$gitpath" 

        epigen addition -A "$gitpath" 
        epigen reduction -A "$gitpath"

      else

        echo "Profiler: Omitting ${locloc[$i]} since the local file does not exist"

      fi

    done

  else
    echo "$HELP"
    return 1
  fi
}

dotfilesProfiler "$@"
