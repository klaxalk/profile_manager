PROFILER_SOURCE_DIR=`dirname "$BASH_SOURCE"`
export PROFILER_SOURCE_DIR=`( cd "$PROFILER_SOURCE_DIR" && pwd )`

expandPath() {

  local path
  local -a pathElements resultPathElements
  IFS=':' read -r -a pathElements <<<"$1"
  : "${pathElements[@]}" # `
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

  IFS=' ' read -r -a ADDITIONS_ARRAY <<< "$PROFILER_ADDITIONS" # `
  IFS=' ' read -r -a DELETIONS_ARRAY <<< "$PROFILER_DELETIONS" # `
  IFS=' ' read -r -a BOTH_ARRAY <<< "$PROFILER_BOTH" # `

  # parse the csv file and extract file paths
  i="0"
  while IFS=, read -r path1 path2 style; do

    gitloc[$i]=`eval echo "$path1"`
    locloc[$i]=`eval echo "$path2"`
    # parse the commenting style and remove leading and trailing whitespaces
    commenting_style[$i]="$(echo -e "${style}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

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
      if [ ! -e "$localpath" ]; then

        mkdir -p `dirname "$localpath"`

        echo "Dotprofiler: the local path $localpath did not exist during deploying, trying to create it."

      fi

      cp "$gitpath" "$localpath" 

      epigen -m addition -A -f "$localpath"  -c "${commenting_style[$i]}"
      epigen -m deletion -A -f "$localpath"  -c "${commenting_style[$i]}"

      # for each addition mode
      for ((j=0; j < ${#ADDITIONS_ARRAY[*]}; j++));
      do

        # set the mode on the local file
        epigen -m addition -s -f "$localpath" -g "${ADDITIONS_ARRAY[$j]}" -c "${commenting_style[$i]}"

      done

      # for each reduction mode
      for ((j=0; j < ${#DELETIONS_ARRAY[*]}; j++));
      do

        # set the mode on the local file
        epigen -m deletion -s -f "$localpath" -g "${DELETIONS_ARRAY[$j]}" -c "${commenting_style[$i]}"

      done

      # for both
      for ((j=0; j < ${#BOTH_ARRAY[*]}; j++));
      do

        # set the mode on the local file
        epigen -m addition -s -f "$localpath" -g "${BOTH_ARRAY[$j]}" -c "${commenting_style[$i]}"
        epigen -m deletion -s -f "$localpath" -g "${BOTH_ARRAY[$j]}" -c "${commenting_style[$i]}"

      done

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

        epigen -m addition -A -f "$gitpath"  -c "${commenting_style[$i]}"
        epigen -m deletion -A -f "$gitpath" -c "${commenting_style[$i]}"

      else

        echo "Dotprofiler: backup of $localpath is not possible, the file does not exist."

      fi

    done

  else
    echo "$HELP"
    return 1
  fi
}

dotfilesProfiler "$@"
