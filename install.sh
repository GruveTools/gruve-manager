#!/usr/bin/env bash

{ # this ensures the entire script is downloaded #

gruve_has() {
  type "$1" > /dev/null 2>&1
}

gruve_install_dir() {
  printf %s "${GRUVE_DIR:-"$HOME/gruve-client"}"
}

gruve_latest_version() {
  echo "master"
}

#
# Outputs the location to Gruve depending on:
# * The availability of $GRUVE_SOURCE
# * The method used ("script" or "git" in the script, defaults to "git")
# GRUVE_SOURCE always takes precedence unless the method is "script-gruve-exec"
#
gruve_source() {
  local GRUVE_METHOD
  GRUVE_METHOD="$1"
  local GRUVE_SOURCE_URL
  GRUVE_SOURCE_URL="$GRUVE_SOURCE"
  GRUVE_SOURCE_URL="https://github.com/GruveTools/gruve-client.git"
  echo "$GRUVE_SOURCE_URL"
}

gruve_download() {
  if gruve_has "curl"; then
    curl --compressed -q "$@"
  elif gruve_has "wget"; then
    # Emulate curl with wget
    ARGS=$(echo "$*" | command sed -e 's/--progress-bar /--progress=bar /' \
                           -e 's/-L //' \
                           -e 's/--compressed //' \
                           -e 's/-I /--server-response /' \
                           -e 's/-s /-q /' \
                           -e 's/-o /-O /' \
                           -e 's/-C - /-c /')
    # shellcheck disable=SC2086
    eval wget $ARGS
  fi
}

install_gruve_from_git() {
  local INSTALL_DIR
  INSTALL_DIR="$(gruve_install_dir)"

  if [ -d "$INSTALL_DIR/.git" ]; then
    echo "=> Gruve is already installed in $INSTALL_DIR, trying to update using git"
    command printf '\r=> '
    command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" fetch origin tag "$(gruve_latest_version)" --depth=1 2> /dev/null || {
      echo >&2 "Failed to update Gruve, run 'git fetch' in $INSTALL_DIR yourself."
      exit 1
    }
  else
    # Cloning to $INSTALL_DIR
    echo "=> Downloading Gruve from git to '$INSTALL_DIR'"
    command printf '\r=> '
    mkdir -p "${INSTALL_DIR}"
    if [ "$(ls -A "${INSTALL_DIR}")" ]; then
      command git init "${INSTALL_DIR}" || {
        echo >&2 'Failed to initialize Gruve repo. Please report this!'
        exit 2
      }
      command git --git-dir="${INSTALL_DIR}/.git" remote add origin "$(gruve_source)" 2> /dev/null \
        || command git --git-dir="${INSTALL_DIR}/.git" remote set-url origin "$(gruve_source)" || {
        echo >&2 'Failed to add remote "origin" (or set the URL). Please report this!'
        exit 2
      }
      command git --git-dir="${INSTALL_DIR}/.git" fetch origin tag "$(gruve_latest_version)" --depth=1 || {
        echo >&2 'Failed to fetch origin with tags. Please report this!'
        exit 2
      }
    else
      command git clone "$(gruve_source)" -b "$(gruve_latest_version)" --depth=1 "${INSTALL_DIR}" || {
        echo >&2 'Failed to clone Gruve repo. Please report this!'
        exit 2
      }
    fi
  fi
  command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" checkout -f --quiet "$(gruve_latest_version)"
  if [ ! -z "$(command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" show-ref refs/heads/master)" ]; then
    if command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" branch --quiet 2>/dev/null; then
      command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" branch --quiet -D master >/dev/null 2>&1
    else
      echo >&2 "Your version of git is out of date. Please update it!"
      command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" branch -D master >/dev/null 2>&1
    fi
  fi

  echo "=> Compressing and cleaning up git repository"
  if ! command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" reflog expire --expire=now --all; then
    echo >&2 "Your version of git is out of date. Please update it!"
  fi
  if ! command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" gc --auto --aggressive --prune=now ; then
    echo >&2 "Your version of git is out of date. Please update it!"
  fi
  return
}

gruve_try_profile() {
  if [ -z "${1-}" ] || [ ! -f "${1}" ]; then
    return 1
  fi
  echo "${1}"
}

#
# Detect profile file if not specified as environment variable
# (eg: PROFILE=~/.myprofile)
# The echo'ed path is guaranteed to be an existing file
# Otherwise, an empty string is returned
#
gruve_detect_profile() {
  if [ -n "${PROFILE}" ] && [ -f "${PROFILE}" ]; then
    echo "${PROFILE}"
    return
  fi

  local DETECTED_PROFILE
  DETECTED_PROFILE=''
  local SHELLTYPE
  SHELLTYPE="$(basename "/$SHELL")"

  if [ "$SHELLTYPE" = "bash" ]; then
    if [ -f "$HOME/.bashrc" ]; then
      DETECTED_PROFILE="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
      DETECTED_PROFILE="$HOME/.bash_profile"
    fi
  elif [ "$SHELLTYPE" = "zsh" ]; then
    DETECTED_PROFILE="$HOME/.zshrc"
  fi

  if [ -z "$DETECTED_PROFILE" ]; then
    for EACH_PROFILE in ".profile" ".bashrc" ".bash_profile" ".zshrc"
    do
      if DETECTED_PROFILE="$(gruve_try_profile "${HOME}/${EACH_PROFILE}")"; then
        break
      fi
    done
  fi

  if [ ! -z "$DETECTED_PROFILE" ]; then
    echo "$DETECTED_PROFILE"
  fi
}

gruve_do_install() {
  install_gruve_from_git

  echo

  local GRUVE_PROFILE
  GRUVE_PROFILE="$(gruve_detect_profile)"
  local PROFILE_INSTALL_DIR
  PROFILE_INSTALL_DIR="$(gruve_install_dir| sed "s:^$HOME:\$HOME:")"

  SOURCE_STR="\\nPATH=\"\$PATH:${PROFILE_INSTALL_DIR}\" # This loads Gruve\\n"
  #SOURCE_STR="\\nexport GRUVE_DIR=\"${PROFILE_INSTALL_DIR}\"\\n[ -s \"\$GRUVE_DIR/gruve-client\" ] && \\. \"\$GRUVE_DIR/gruve-client\"  # This loads Gruve\\n"
  # shellcheck disable=SC2016
  BASH_OR_ZSH=false

  if [ -z "${GRUVE_PROFILE-}" ] ; then
    local TRIED_PROFILE
    if [ -n "${PROFILE}" ]; then
      TRIED_PROFILE="${GRUVE_PROFILE} (as defined in \$PROFILE), "
    fi
    echo "=> Profile not found. Tried ${TRIED_PROFILE-}~/.bashrc, ~/.bash_profile, ~/.zshrc, and ~/.profile."
    echo "=> Create one of them and run this script again"
    echo "   OR"
    echo "=> Append the following lines to the correct file yourself:"
    command printf "${SOURCE_STR}"
  else
    BASH_OR_ZSH=true
    if ! command grep -qc '/gruve-client' "$GRUVE_PROFILE"; then
      echo "=> Appending Gruve source string to $GRUVE_PROFILE"
      command printf "${SOURCE_STR}" >> "$GRUVE_PROFILE"
    else
      echo "=> Gruve source string already in ${GRUVE_PROFILE}"
    fi
    # shellcheck disable=SC2016
  fi

  if ! command crontab -l | grep -qc '/gruve-client'; then
    echo "=> Appending Gruve to crontab"
    command crontab -l > gruve.cron && echo "* * * * * ${PROFILE_INSTALL_DIR}/gruve-client 2>&1 > /dev/null" >> gruve.cron && crontab gruve.cron && rm gruve.cron
    #command printf "${SOURCE_STR}" >> "$GRUVE_PROFILE"
  else
    echo "=> Gruve already in crontab"
  fi

  command ~/gruve-client --setup "${PROFILE_INSTALL_DIR}/"

  echo "=> Adding web dashboard server to start up, ethos user password required..."
  command sudo sed -i 's/exit 0/su - ethos -c "screen -dm -S web php -S 0.0.0.0:8080 -t \/home\/ethos\/gruve-client\/web\/"\n\nexit 0/' /etc/rc.local
  command screen -dm -S web php -S 0.0.0.0:8080 -t /home/ethos/gruve-client/web/

  # Source Gruve
  # shellcheck source=/dev/null
  #\. "$(gruve_install_dir)/gruve-client"

  gruve_reset

  #echo "=> Close and reopen your terminal to start using Gruve or run the following to use it now:"
  #command printf "${SOURCE_STR}"
}

#
# Unsets the various functions defined
# during the execution of the install script
#
gruve_reset() {
  unset -f gruve_has gruve_install_dir gruve_latest_version \
    gruve_source gruve_download install_gruve_from_git \
    gruve_try_profile gruve_detect_profile \
    gruve_do_install gruve_reset
}

[ "_$GRUVE_ENV" = "_testing" ] || gruve_do_install

} # this ensures the entire script is downloaded #
