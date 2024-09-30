#!/usr/bin/env bash

##############################
# Mostly inspired by:
# https://betterdev.blog/minimal-safe-bash-script-template/
# https://github.com/m-radzikowski
##############################

# Customize setting based on needs.
set -o pipefail
#set -o nounset

# Enable cleanup.
trap cleanup SIGINT SIGTERM ERR EXIT

# The directory in which the current script is located.
# Symbolic links are read and the real path is used.
# Change this behavior if needed.
script_dir="$(dirname "$(readlink -f "${0}")")"

# The filename of the current script.
# Symbolic links are read and the real name is used.
# Change this behavior if needed.
script_name="$(basename "$(readlink -f "${0}")")"

# Use this to show script usage when called with -h or --help.
usage() {
    cat <<EOF
Usage: ${script_name} [-h] [-v] [-f] -p param_value arg1 [arg2...]

Script description here.

Options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info (set xtrace)
-f, --flag      Some flag description
-p, --param     Some param description
EOF
    exit
}

cleanup() {
    trap - SIGINT SIGTERM ERR EXIT
    # script cleanup here
}

## Setup colors
if [[ -t 1 ]] && [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    declare -A colors=(
        [noformat]='\033[0m'
        [red]='\033[0;31m'
        [green]='\033[0;32m'
        [orange]='\033[0;33m'
        [blue]='\033[0;34m'
        [purple]='\033[0;35m'
        [cyan]='\033[0;36m'
        [yellow]='\033[1;33m'
        [white]='\033[0;97m'
    )
else
    declare -A colors=(
        [noformat]=''
        [red]=''
        [green]=''
        [orange]=''
        [blue]=''
        [purple]=''
        [cyan]=''
        [yellow]=''
        [white]=''
    )
fi

# Print error message and exit 1
# Must be independent of other functions.
function die() {
    if [[ "${#}" -ne 1 ]]; then
        echo -e "${colors[red]}Wrong use of die()!${colors[noformat]}" >&2
    else
        echo -e "${colors[red]}${1}${colors[noformat]}" >&2
    fi
    exit 1
}

# Generic message function.
function print_msg() {
    local color_name="${1}"
    local message="${2}"
    if [[ -z "${colors[${color_name}]}" ]]; then
        echo -e "${colors[red]}Invalid color name: ${color_name}${colors[noformat]}"
        return 1
    fi
    echo -e "${colors[${color_name}]}${message}${colors[noformat]}"
}

# Print a color-coded message based on the function called.
function errormsg() { print_msg "red" "${1}"; }
function successmsg() { print_msg "green" "${1}"; }
function orangemsg() { print_msg "orange" "${1}"; }
function bluemsg() { print_msg "blue" "${1}"; }
function purplemsg() { print_msg "purple" "${1}"; }
function cyanmsg() { print_msg "cyan" "${1}"; }
function yellowmsg() { print_msg "yellow" "${1}"; }
function whitemsg() { print_msg "white" "${1}"; }

# Test colored output.
function _test_colors() {
    errormsg "errormsg()"
    successmsg "successmsg()"
    orangemsg "orangemsg()"
    bluemsg "bluemsg()"
    purplemsg "purplemsg()"
    cyanmsg "cyanmsg()"
    yellowmsg "yellowmsg()"
    whitemsg "whitemsg()"
}

parse_params() {
    # default values of variables set from params
    flag=0
    param=''

    while :; do
        case "${1-}" in
        -h | --help) usage ;;
        -v | --verbose) set -o xtrace ;;
        --no-color) NO_COLOR='true' ;;
        -f | --flag) flag=1 ;; # example flag
        -p | --param)          # example named parameter
            param="${2-}"
            shift
            ;;
        -?*) die "Unknown option: ${1}" ;;
        *) break ;;
        esac
        shift
    done

    args=("$@")

    #Check required params and arguments
    if [[ -z "${param-}" ]]; then
        die "Missing required parameter: param"
    fi
    if [[ ${#args[@]} -eq 0 ]]; then
        die "Missing script arguments"
    fi
    return 0
}

parse_params "${@}"
setup_colors

# Script logic here
