# shellcheck disable=SC2148
################################################################################
# Initialization tasks and definitions needed for correct execution            #
# Common for bash and zsh                                                      #
################################################################################

# Determine shell type.
# Only bash and zsh are supported.
if [[ -n "${ZSH_VERSION}" ]]; then

    # I only tested this on 5.9
    if [[ "$(tr -d '.' <<<"${ZSH_VERSION}")" -lt '59' ]]; then
        echo "Untested zsh version: ${ZSH_VERSION}" >&2
    fi

    shell_type='zsh'
elif [[ -n "${BASH_VERSION}" ]]; then

    # I only tested this on 5.2
    if [[ "${BASH_VERSINFO[0]}${BASH_VERSINFO[1]}" -lt 52 ]]; then
        echo "Untested bash version: ${BASH_VERSION}" >&2
    fi

    shell_type='bash'
else
    shell_type='unknown'
    echo "Unsupported shell" >&2
fi

# Linux distribution family.
if [[ -f '/etc/os-release' ]]; then
    distribution_family="$(grep 'ID_LIKE' '/etc/os-release' | cut -d '=' -f 2)"
else
    echo "Can not find \"/etc/os-release\"." >&2
fi

# Check if shell is interactive.
if [[ "${-}" == *'i'* ]]; then
    is_interactive='true'
else
    is_interactive='false'
fi

# Get the keys from an associative array.
# Used for shell independent iteration of associative arrays.
# $1 is the name of the associative array.
function as_array_keys() {
    if [[ "${shell_type}" == 'bash' ]]; then
        declare -n arr="${1}"
        echo "${!arr[@]}"
    elif [[ "${shell_type}" == 'zsh' ]]; then
        # Use eval for zsh specific code so that bash formatters do not break.
        eval 'typeset -A arr=(${(@Pkv)1})'
        eval 'echo "${(k)arr}"'
    else
        # TODO handle errors where used
        die "Unsupported shell: ${shell_type}"
    fi
}

# create an alias equivalent to: $ alias $1=$2.
# $1 is the alias name.
# $2 is the command to be aliased.
# The command to be aliased can be a single command, or a command with options etc.
# In the latter case, the first word of the command string will be considered to be the main command.
function check_and_alias() {
    if [[ "${#}" -ne 2 ]]; then
        errormsg "check_and_alias() received wrong number of arguments (${#}): need 1."
        return 1
    fi

    local target_command
    target_command="$(awk '{print $1}' <<<"${2}")"

    # Check if the command to be executed exists.
    # If not, do not create the alias.
    # Note that an alias might include multiple commands:
    # Ex: alias something='command1 | command2'.
    # The existence of the second command will not be taken into account.
    if ! command -v "${target_command}" &>'/dev/null'; then
        errormsg "Command \"${target_command}\" not found, The alias \"${1}"="${2}\" will not be created"
        return 1
    fi

    # shellcheck disable=SC2139
    alias "${1}"="${2}" || echo "Failed to create alias: \"${1}"="${2}\""
}

# Import colors
. "${HOME}/.common_definitions"

################################################################################
# OMZ stuff (zsh specific)                                                     #
################################################################################

if [[ "${shell_type}" == 'zsh' ]]; then
    # Path to your Oh My Zsh installation.
    export ZSH="${HOME}/.oh-my-zsh"

    # See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
    ZSH_THEME="strug"

    # Uncomment the following line to use case-sensitive completion.
    # CASE_SENSITIVE="true"

    # Uncomment the following line to use hyphen-insensitive completion.
    # Case-sensitive completion must be off. _ and - will be interchangeable.
    # HYPHEN_INSENSITIVE="true"

    # Uncomment one of the following lines to change the auto-update behavior
    zstyle ':omz:update' mode disabled # disable automatic updates
    # zstyle ':omz:update' mode auto      # update automatically without asking
    # zstyle ':omz:update' mode reminder  # just remind me to update when it's time

    # Uncomment the following line to change how often to auto-update (in days).
    # zstyle ':omz:update' frequency 13

    # Uncomment the following line if pasting URLs and other text is messed up.
    # DISABLE_MAGIC_FUNCTIONS="true"

    # Uncomment the following line to disable auto-setting terminal title.
    # DISABLE_AUTO_TITLE="true"

    # Uncomment the following line to enable command auto-correction.
    # ENABLE_CORRECTION="true"

    # Uncomment the following line to display red dots whilst waiting for completion.
    # You can also set it to another string to have that shown instead of the default red dots.
    # e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
    # Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
    # COMPLETION_WAITING_DOTS="true"

    # Uncomment the following line if you want to disable marking untracked files
    # under VCS as dirty. This makes repository status check for large repositories
    # much, much faster.
    # DISABLE_UNTRACKED_FILES_DIRTY="true"

    # Uncomment the following line if you want to change the command execution time
    # stamp shown in thWWWWe history command output.
    # You can set one of the optional three formats:
    # "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
    # or set a custom format using the strftime function format specifications,
    # see 'man strftime' for details.
    # HIST_STAMPS="mm/dd/yyyy"

    # Would you like to use another custom folder than $ZSH/custom?
    # ZSH_CUSTOM=/path/to/new-custom-folder

    # Which plugins would you like to load?
    # Standard plugins can be found in $ZSH/plugins/
    # Custom plugins may be added to $ZSH_CUSTOM/plugins/
    # Example format: plugins=(rails git textmate ruby lighthouse)
    # Add wisely, as too many plugins slow down shell startup.
    plugins=(
        git
        golang
        pip
        colored-man-pages
        colorize
    )

    if [[ -f "${ZSH}/oh-my-zsh.sh" ]]; then
        . "${ZSH}/oh-my-zsh.sh"
    else
        echo "Can not find and source: ${ZSH}/oh-my-zsh.sh" >&2
    fi
fi

################################################################################
# Custom settings                                                              #
################################################################################

# A lot of bash specific snippets here are taken from or inspired by
# https://github.com/ChrisTitusTech/mybash
# by https://github.com/ChrisTitusTech (Big Thanks)

# Bash specific.
if [[ "${shell_type}" == 'bash' ]]; then

    if [ -f '/etc/bashrc' ]; then
        . '/etc/bashrc'
    fi

    # Enable bash programmable completion features in interactive shells.
    if [ -f '/usr/share/bash-completion/bash_completion' ]; then
        . '/usr/share/bash-completion/bash_completion'
    elif [ -f '/etc/bash_completion' ]; then
        . '/etc/bash_completion'
    fi

    # Disable the bell.
    if [[ "${is_interactive}" == "true" ]]; then
        bind "set bell-style visible"
    fi

    # Expand the history size.
    export HISTFILESIZE=10000
    export HISTSIZE=500
    # Add timestamp to history.
    export HISTTIMEFORMAT="%F %T"

    # Don't put duplicate lines in the history and do not add lines that start with a space.
    export HISTCONTROL=erasedups:ignoredups:ignorespace

    # Check the window size after each command and,
    # if necessary, update the values of LINES and COLUMNS.
    shopt -s checkwinsize

    # Causes bash to append to history instead of overwriting it,
    # so if you start a new terminal, you have old session history.
    shopt -s histappend
    PROMPT_COMMAND='history -a'

    # Set up XDG folders,
    # TODO: add to zsh?
    export XDG_DATA_HOME="$HOME/.local/share"
    export XDG_CONFIG_HOME="$HOME/.config"
    export XDG_STATE_HOME="$HOME/.local/state"
    export XDG_CACHE_HOME="$HOME/.cache"

    # To have colors for ls and all grep commands such as grep, egrep and zgrep.
    export CLICOLOR=1
    export LS_COLORS='no=00:fi=00:di=00;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:*.xml=00;31:'

    # Color for manpages in less makes manpages a little easier to read.
    export LESS_TERMCAP_mb=$'\E[01;31m'
    export LESS_TERMCAP_md=$'\E[01;31m'
    export LESS_TERMCAP_me=$'\E[0m'
    export LESS_TERMCAP_se=$'\E[0m'
    export LESS_TERMCAP_so=$'\E[01;44;33m'
    export LESS_TERMCAP_ue=$'\E[0m'
    export LESS_TERMCAP_us=$'\E[01;32m'
fi

################################################################################
# Exports and global state settings                                            #
################################################################################

export EDITOR='/usr/bin/nvim'
export VISUAL='/usr/bin/nvim'

# Private binaries.
export PATH="${HOME}/bin:${PATH}"

# Extra security.
umask 0077

################################################################################
# Aliases                                                                      #
################################################################################

check_and_alias 'cp' 'cp -i'
check_and_alias 'mv' 'mv -i'
check_and_alias 'ls' 'ls -lh --color'
check_and_alias 'grep' 'grep -In --color'
check_and_alias 'mkdir' 'mkdir -p'
check_and_alias 'df' 'df -h'
check_and_alias 'free' 'free -h'
check_and_alias 'ps' 'ps auxf'

check_and_alias 'gtls' 'git tag -l --sort=taggerdate'
check_and_alias 'py' 'python3'
check_and_alias 'code' 'vscodium' && check_and_alias 'c' 'vscodium'
check_and_alias 'vim' 'nvim' && check_and_alias 'vi' 'nvim' && check_and_alias 'e' 'nvim'

# Search command line history
check_and_alias 'h' 'history | grep -i'
# Search running processes
check_and_alias 'p' 'ps aux | grep '
# Show open ports
check_and_alias 'openports' 'netstat -nape --inet'

# Full system upgrade: Distribution dependent.
if [[ -n "${distribution_family}" ]]; then
    case "${distribution_family}" in
    'arch') check_and_alias 'u' 'sudo pacman -Syuu' ;;
    'debian') check_and_alias 'u' 'sudo apt-get update && sudo apt-get full-upgrade' ;;
    *) echo "Unsupported distribution. The \"u\" alias will be left undefined" ;;
    esac
else
    echo "Undefined distribution. The \"u\" alias will be left undefined"
fi

################################################################################
# Git functions and definitions                                                #
################################################################################

lan_repo_dir="${HOME}/src/pi"
remote_repo_dir="${HOME}/src/gh"

# List of repositories to which the following functions will apply.
declare -A local_repos=(
    ['git@github.com:Jakub-Kapusta/dotfiles-and-settings.git']="${remote_repo_dir}/dotfiles-and-settings"
)

# Update all local git repos.
function pull() {
    for url in $(as_array_keys 'local_repos'); do
        local target_directory="${local_repos[${url}]}"

        if [[ ! -d "${target_directory}" ]]; then
            errormsg "${target_directory} does not exist!"
            continue
        fi

        (
            cd "${target_directory}" || die "Could not cd into ${target_directory}!"
            purplemsg "$(pwd)"

            if ! git rev-parse --is-inside-work-tree &>'/dev/null'; then
                errormsg "$(pwd) is not part of a git repo!"
                return 1
            fi

            if [[ -z "$(git status --porcelain)" ]]; then
                git pull
                return 0
            fi

            yellowmsg "${target_directory} needs attention before a safe pull can be made"
        )
    done
}

# Clone all personal git repos into their respective directories.
function clone() {
    for url in $(as_array_keys 'local_repos'); do
        local target_directory="${local_repos[${url}]}"

        if [[ -d "${target_directory}" ]]; then
            errormsg "${target_directory} directory already exists"
            continue
        else
            mkdir -p "${target_directory}"
        fi

        if ! (
            cd "${target_directory}" || die "Could not cd into ${target_directory}!"
            purplemsg "Attempting to clone ${url} into ${target_directory}"

            if ! git clone "${url}" "${target_directory}"; then
                errormsg "Something went wrong when attempting to clone ${url} into ${target_directory}"
                return 1
            fi

        ); then
            # Remove unused directory.
            rmdir "${target_directory}" || errormsg "Failed to rmdir ${target_directory}"
        fi
    done
}

# Status of all local repos.
function status() {
    for url in $(as_array_keys 'local_repos'); do
        local target_directory="${local_repos[${url}]}"

        if [[ ! -d "${target_directory}" ]]; then
            errormsg "No such directory: ${target_directory}"
            continue
        fi

        (
            cd "${target_directory}" || die "Could not cd into ${target_directory}!"

            if ! git rev-parse --is-inside-work-tree &>'/dev/null'; then
                errormsg "Not part of a git repo: ${PWD}"
                return 1
            fi

            if [[ -z "$(git status --porcelain)" ]]; then
                successmsg "Up to date: ${target_directory}"
                return 0
            fi

            yellowmsg "Needs attention: $(pwd)"
            git status
        )
    done
}

# Add everything.
function add() {
    for url in $(as_array_keys 'local_repos'); do
        local target_directory="${local_repos[${url}]}"

        if [[ ! -d "${target_directory}" ]]; then
            errormsg "${target_directory} does not exist!"
            continue
        fi

        (
            cd "${target_directory}" || die "Could not cd into ${target_directory}!"
            purplemsg "$(pwd)"

            if ! git rev-parse --is-inside-work-tree &>'/dev/null'; then
                errormsg "${PWD} is not part of a git repo!"
                return 1
            fi

            git add .
        )
    done
}

# Push all repos.
function push() {
    for url in $(as_array_keys 'local_repos'); do
        local target_directory="${local_repos[${url}]}"

        if [[ ! -d "${target_directory}" ]]; then
            errormsg "${target_directory} does not exist!"
            continue
        fi

        (
            cd "${repo_dir}" || die "Could not cd into ${target_directory}!"
            purplemsg "${PWD}"

            if ! git rev-parse --is-inside-work-tree &>'/dev/null'; then
                errormsg "${PWD} is not part of a git repo!"
                return 1
            fi

            if [[ "$(git status)" == *'Your branch is ahead of'* ]]; then
                git push
            fi
        )
    done
}

# Commit and push everything, everywhere.
# Optionally, pass the commit message as $1.
function fpushall() {
    if [[ "${#}" -gt 1 ]]; then
        errormsg "Unsupported number of arguments: need 1 but received ${#}"
        return 1
    fi

    for url in $(as_array_keys 'local_repos'); do
        local target_directory="${local_repos[${url}]}"

        if [[ ! -d "${target_directory}" ]]; then
            errormsg "${target_directory} does not exist!"
            continue
        fi

        (
            cd "${target_directory}" || die "Could not cd into ${target_directory}!"

            if ! git rev-parse --is-inside-work-tree &>'/dev/null'; then
                errormsg "${PWD} is not part of a git repo!"
                return 1
            fi

            purplemsg "$(pwd)"
            commit_message="${1:-'Update'}"

            if [[ -n "$(git status --porcelain)" ]]; then
                git add -A && git commit -m "${commit_message}"
            fi

            if [[ "$(git status)" == *'Your branch is ahead of'* ]]; then
                git push
            fi
        )
    done
}

# Commit and push everything, in current repo.
# Optionally, pass the commit message as $1.
function fpush() {
    if [[ "${#}" -gt 1 ]]; then
        errormsg "Unsupported number of arguments: need 1 but received ${#}"
        return 1
    fi

    if ! git rev-parse --is-inside-work-tree &>'/dev/null'; then
        errormsg "${PWD} is not part of a git repo!"
        return 1
    fi

    commit_message="${1:-'Update'}"

    if [[ -n "$(git status --porcelain)" ]]; then
        git add -A && git commit -m "${commit_message}"
    fi

    if [[ "$(git status)" == *'Your branch is ahead of'* ]]; then
        git push
    fi
}

################################################################################
# Reminders that show up every time we launch a shell                          #
################################################################################
systemctl --failed
