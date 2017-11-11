#
# Enables local Python package installation.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#   Sebastian Wiesner <lunaryorn@googlemail.com>
#

# Return if requirements are not found.
if (( ! $+commands[python3] )); then
  return 1
fi

VIRTUALENV_DIR_NAMES=(.env .venv)

function _test_venv_dir {
  for dir_name in $VIRTUALENV_DIR_NAMES; do
    if [[ -f "$1/$dir_name/bin/activate" ]]; then
      return 0
    fi
  done

  return 1
}

function _python-workon-cwd {
  # Check if this is a Git repo
  local GIT_REPO_ROOT=""
  local GIT_TOPLEVEL="$(git rev-parse --show-toplevel 2> /dev/null)"
  if [[ $? == 0 ]]; then
    GIT_REPO_ROOT="$GIT_TOPLEVEL"
  fi
  # Get absolute path, resolving symlinks
  local PROJECT_ROOT="${PWD:A}"
  while [[ "$PROJECT_ROOT" != "/" && ! -f "$PROJECT_ROOT/.venv" ]] \
            && ! _test_venv_dir $PROJECT_ROOT \
            && [[ ! -d "$PROJECT_ROOT/.git"  && "$PROJECT_ROOT" != "$GIT_REPO_ROOT" ]]; do
    PROJECT_ROOT="${PROJECT_ROOT:h}"
  done
  if [[ "$PROJECT_ROOT" == "/" ]]; then
    PROJECT_ROOT="."
  fi
  # Check for virtualenv name override
  local ENV_NAME=""
  if [[ -f "$PROJECT_ROOT/.venv" ]]; then
    ENV_NAME="$(cat "$PROJECT_ROOT/.venv")"
  elif _test_venv_dir $PROJECT_ROOT; then
    for dir_name in $VIRTUALENV_DIR_NAMES; do
      if [[ -f "$PROJECT_ROOT/$dir_name/bin/activate" ]]; then
        ENV_NAME="$PROJECT_ROOT/$dir_name"
      fi
    done
  elif [[ "$PROJECT_ROOT" != "." ]]; then
    ENV_NAME="${PROJECT_ROOT:t}"
  fi
  if [[ -n $CD_VIRTUAL_ENV && "$ENV_NAME" != "$CD_VIRTUAL_ENV" ]]; then
    # We've just left the repo, deactivate the environment
    # Note: this only happens if the virtualenv was activated automatically
    deactivate && unset CD_VIRTUAL_ENV
  fi
  if [[ "$ENV_NAME" != "" ]]; then
    # Activate the environment only if it is not already active
    if [[ "$VIRTUAL_ENV" != "$ENV_NAME" ]]; then
      if [[ -n "$WORKON_HOME" && -e "$WORKON_HOME/$ENV_NAME/bin/activate" ]]; then
        workon "$ENV_NAME" && export CD_VIRTUAL_ENV="$ENV_NAME"
      elif [[ -e "$ENV_NAME/bin/activate" ]]; then
        source $ENV_NAME/bin/activate && export CD_VIRTUAL_ENV="$ENV_NAME"
      fi
    fi
  fi
}

# Load auto workon cwd hook
if zstyle -t ':prezto:module:python:virtualenv' auto-switch 'yes'; then
  # Auto workon when changing directory
  add-zsh-hook chpwd _python-workon-cwd
fi

# Load PIP completion.
if (( $#commands[(i)pip(|[23])] )); then
  cache_file="${0:h}/cache.zsh"

  # Detect and use one available from among 'pip', 'pip2', 'pip3' variants
  pip_command="$commands[(i)pip(|[23])]"

  if [[ "$pip_command" -nt "$cache_file" || ! -s "$cache_file" ]]; then
    # pip is slow; cache its output. And also support 'pip2', 'pip3' variants
    $pip_command completion --zsh \
      | sed -e "s|compctl -K [-_[:alnum:]]* pip|& pip2 pip3|" >! "$cache_file" 2> /dev/null
  fi

  source "$cache_file"
  unset cache_file pip_command
fi

#
# Aliases
#

alias py='python3'
alias py2='python2'
alias py3='python3'
