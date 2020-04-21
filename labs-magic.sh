#!/bin/bash

########################
# Need before demo magic
########################

function usage {
  echo -e ""
  echo -e "Usage: $0 [options] [task_id] [step_id]"
  echo -e ""
  echo -e "\tWhere options is one or more of:"
  echo -e "\t-h\tPrints Help text"
  echo -e "\t-d\tDebug mode. Disables simulated typing"
  echo -e "\t-n\tNo wait"
  echo -e "\t-w\tWaits max the given amount of seconds before proceeding with demo (e.g. '-w5')"
  echo -e "\t-l\tList all tasks and steps with their states, titles and ids"
  echo -e ""
}

DOCS_PATH=docs

DONE_COLOR="\033[0;36m"
QUES_COLOR="\033[0;33m"
CURR_COLOR="\033[0;37m"
NORM_COLOR="\033[0m"

touch .lab.states
touch .lab.settings

function task::print-all {
  local task_dirs=($(find $DOCS_PATH -maxdepth 1 -type d | sort))

  echo

  for task_dir in ${task_dirs[@]}; do
    local has_task_or_step=0

    task::print $task_dir && has_task_or_step=1

    local step_files=($(find ${task_dir%/} -maxdepth 1 -name "*.md" -type f | sort | grep -v README))
    for step_file in ${step_files[@]}; do
      task::print $step_file && has_task_or_step=1
    done

    [[ $has_task_or_step == 1 ]] && echo
  done

  echo "To run a specific task or step, find the task or step id, and run $0 <task> <step>."
  echo
}

function task::print {
  local task=${1%/*}
  task=${task##*/}

  local step=${1##*/}
  step=${step%.md}

  local file=$1
  if [[ -n $task && -z $step ]]; then
    file="$1README.md"
  fi

  if [[ -f $file ]]; then
    local head_line="$(head -n 1 $file)"

    if [[ $head_line =~ ^#" " ]]; then
      local state

      if [[ -n $task && -n $step ]] && cat .lab.states | grep -q -e "^.\? $task $step"; then
        state=$(cat .lab.states | grep -e "^.\? $task $step")
        state=${state% $task $step}
      fi

      case $state in
      "*")
        head_line="${CURR_COLOR}$(echo $head_line | sed -e "s/^#/ ➞ /g")${NORM_COLOR}"
        ;;
      "v")
        head_line="${DONE_COLOR}$(echo $head_line | sed -e "s/^#/[✓]/g")${NORM_COLOR}"
        ;;
      "?")
        head_line="${QUES_COLOR}$(echo $head_line | sed -e "s/^#/[?]/g")${NORM_COLOR}"
        ;;
      *)
        if [[ -n $task && -n $step ]]; then
          head_line="$(echo $head_line | sed -e "s/^#/[ ]/g")"
        else
          head_line="$(echo $head_line | sed -e "s/^#/   /g")"
        fi
        ;;
      esac

      if [[ -n $task && -n $step ]]; then
        echo -e "$head_line [$task $step]"
      else
        echo -e "$head_line [$task]"
      fi
    fi
  else
    return 1
  fi
}

case "$1" in
-h)
  usage
  exit
  ;;
-l)
  task::print-all
  exit
  ;;
esac

########################
# Load demo magic
########################

. ./demo-magic.sh

########################
# Configure demo magic
########################

#
# custom prompt
#
# see http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/bash-prompt-escape-sequences.html for escape sequences
#
DEMO_PROMPT="${GREEN}➜ ${CYAN}\W "

#
# custom colors
#
DEMO_CMD_COLOR="\033[0;37m"
DEMO_COMMENT_COLOR=$CYAN

########################
# Start labs magic
########################

START_TIME=$SECONDS

trap on_exit exit

function on_exit {
  elapsed_time=$(($SECONDS - $START_TIME))
  logger::info "Total elapsed time: $elapsed_time seconds"
}

function logger::info {
  # Cyan
  printf "\033[0;36mINFO\033[0m $@\n"
}

function logger::warn {
  # Yellow
  printf "\033[0;33mWARN\033[0m $@\n"
}

function logger::error {
  # Red
  printf "\033[0;31mERRO\033[0m $@\n"
  exit 1
}

function task::run {
  local task=$1
  local step=$2
  local file="$DOCS_PATH/README.md"
  if [[ -n $task && -z $step ]]; then
    file="$DOCS_PATH/$task/README.md"
  elif [[ -n $task && -n $step ]]; then
    file="$DOCS_PATH/$task/$step.md"
  fi

  if [[ -f $file ]]; then
    task::run-with-logs $file $task $step
  fi

  local task_dir=$(dirname $file)
  if [[ -z $step && -d $task_dir ]]; then
    local step_files=($(find ${task_dir} -maxdepth 1 -name "*.md" -type f | sort | grep -v README))
    for file in ${step_files[@]}; do
      step=${file##*/}
      step=${step%.md}
      task::run-with-logs $file $task $step
    done
  fi
}

function task::run-with-logs {
  local file=$1
  local task=$2
  local step=$3
  if [[ -n $task && -n $step ]]; then
    sed -e "s/^*/?/g" .lab.states > .lab.states.tmp
    mv .lab.states{.tmp,}

    if cat .lab.states | grep -q -e "^.\? $task $step"; then
      sed -e "s/^? $task $step/* $task $step/g" \
          -e "s/^v $task $step/* $task $step/g" \
        .lab.states > .lab.states.tmp
      mv .lab.states{.tmp,}
    else
      echo "* $task $step" >> .lab.states
    fi
  fi

  local method_prefix=$task
  local display_name="$task"
  if [[ -n $task && -n $step ]]; then
    method_prefix="$task::$step"
    display_name="$task $step"
  fi
  if type ${method_prefix}::before &>/dev/null && ! ${method_prefix}::before; then
    logger::warn "Start [$display_name] failed because it does not pass the pre-condition check"
    logger::warn "Please try again later by running: $0 $display_name"
    logger::warn "Or list all tasks and their states by running: $0 -l"
    exit 0
  fi

  if task::run-file $file && [[ -n $task && -n $step ]]; then
    sed -e "s/^* $task $step/v $task $step/g" .lab.states > .lab.states.tmp
    mv .lab.states{.tmp,}
  fi
}

function task::run-file {
  local file=$1
  if [[ -f $file ]]; then
    # print title
    p "$(head -n 1 $file)"

    # read lines
    local lines=()
    while IFS= read -r line; do
      lines+=("$line");
    done < $file

    # print content
    local summary=1
    local title=0
    local code=0
    local shell=0
    local hidden=0

    for line in "${lines[@]:1}"; do
      # reach the end of summary
      if [[ $line == --- && $summary == 1 ]]; then
        echo "  $line"
        summary=0
        continue
      fi

      line=$(echo "$line" | \
        sed -e 's%!\[\(.*\)\](.*)%\1 (See online version of the lab instructions)%g' \
            -e 's%\[\(.*\)\](.*)%\1%g')

      # print summary
      if [[ $summary == 1 ]]; then
        echo "  $line"
      # print details
      else
        # reach title
        if [[ $line =~ ^## ]]; then
          title=1
        elif [[ $line == \`\`\` ]]; then
          # reach the start of code
          if [[ $code == 0 && $shell == 0 ]]; then
            code=1
          # reach the end of code or shell
          else
            code=0
            shell=0
          fi
          continue
        # reach the start of shell
        elif [[ $line == \`\`\`shell && $shell == 0 ]]; then
          shell=1
          continue
        # reach the start of hidden
        elif [[ $line =~ ^\<!-- ]]; then
          hidden=1
          continue
        # reach the end of hidden
        elif [[ $line =~ ^--\> ]]; then
          hidden=0
          continue
        fi

        # print title
        if [[ $title == 1 ]]; then
          p "$line"
          title=0
        # print shell
        elif [[ $shell == 1 ]]; then
          pe "$line"
        # print code
        elif [[ $code == 1 ]]; then
          echo "$line"
        # run code implicitly
        elif [[ $hidden == 1 ]]; then
          eval "$line"
        # print normal text
        else
          # echo -e "\033[0;33m  $line\033[0m"
          pp "$line"
        fi
      fi
    done
  else
    p "## $@"
  fi
  
  echo
}

function task::main {
  local POSITIONAL=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
    -d|-n|-c|-w*)
      shift
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
    esac
  done

  clear
  task::run "${POSITIONAL[@]}"
}

function var::set {
  local message=$1
  local field=$2
  echo -n -e "${CYAN}? ${DEMO_CMD_COLOR}${message}${COLOR_RESET}"

  local current_value=$(eval echo \$${field})
  if [[ -n $current_value ]]; then
    echo -n -e "(${current_value}): "
  else
    echo -n -e ": "
  fi

  local new_value
  read -r new_value
  if [[ -n $new_value ]]; then
    eval ${field}=\'$new_value\'
  else
    return 1
  fi
}

function var::set-required {
  var::set "$@"
  while [[ -z $(eval echo \$$2) ]]; do
    var::set "$@"
  done
}

function var::save {
  local field=$1
  local value="$(eval echo \$${field})"
  sed -e "s#^${field}=.*#${field}='${value}'#g" .lab.settings > .lab.settings.tmp
  mv .lab.settings{.tmp,}
}

function wait() {
  if [[ $WAIT_COUNTER == 0 && $NO_WAIT_BEFORE == 1 ]]; then
    return
  fi

  if [[ $WAIT_COUNTER == 1 && $NO_WAIT_AFTER == 1 ]]; then
    WAIT_COUNTER=0
    return
  fi
  
  if [[ "$PROMPT_TIMEOUT" == "0" ]]; then
    read -rs
  else
    read -rst "$PROMPT_TIMEOUT"
  fi

  if [[ $WAIT_COUNTER == 0 ]]; then
    WAIT_COUNTER=1
  else
    WAIT_COUNTER=0
  fi
}

function pn {
  NO_WAIT_BEFORE=1 && p && NO_WAIT_BEFORE=0
}

function pp {
  if [[ -n $1 ]]; then
    local origin_color=$DEMO_CMD_COLOR
    DEMO_CMD_COLOR=$BROWN
    p "$1"
    DEMO_CMD_COLOR=$origin_color
  else
    local origin_wait=$NO_WAIT
    NO_WAIT=true
    p "$1"
    NO_WAIT=$origin_wait
  fi
}