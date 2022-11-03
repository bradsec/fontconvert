#!/usr/bin/env bash

####################################################################################
## Name:          fontconvert.sh                                                  ##
## Description:   A bash script to batch convert between otf <==> ttf font types  ##
## Requirements:  Bash >= version 4 and fontforge (https://fontforge.org)         ##
####################################################################################

shopt -s nullglob
SCRIPT_PATH="$(realpath ${BASH_SOURCE:-$0})"
SCRIPT_DIR="$(dirname ${SCRIPT_PATH})"

# Set colors for use in task terminal output functions
function message_colors() {
    if [[ -t 1 ]]; then
        RED=$(printf '\033[31m')
        GREEN=$(printf '\033[32m')
        CYAN=$(printf '\033[36m')
        YELLOW=$(printf '\033[33m')
        BOLD=$(printf '\033[1m')
        RESET=$(printf '\033[0m')
    else
        RED=""
        GREEN=""
        CYAN=""
        YELLOW=""
        BOLD=""
        RESET=""
    fi
}
# Init terminal message colors
message_colors

# Terminal message output formatting
# message() function displays formatted and coloured terminal messages.
# TASK messages overwrite the same line of information.
# Usage example: message INFO "This is a information message"
function message() {
    local option=${1}
    local text=${2}
    case "${option}" in
        TASKSTART) echo -ne "[${CYAN}TASK${RESET}] ${text}";;
        TASKDONE) echo -e "\r[${GREEN}${BOLD}DONE${RESET}] ${GREEN}${text}${RESET}$(tput el)";;
        TASKFAIL) echo -e "\r[${RED}${BOLD}FAIL${RESET}] ${RED}${text}${RESET}$(tput el)";;
        TASKSKIP) echo -e "\r[${YELLOW}${BOLD}SKIP${RESET}] ${YELLOW}${text}${RESET}$(tput el)";;
        DONE) echo -e "[${GREEN}DONE${RESET}] ${GREEN}${text}${RESET}";;
        FAIL) echo -e "[${RED}${BOLD}FAIL${RESET}] ${text}";;
        INFO) echo -e "[${CYAN}INFO${RESET}] ${text}";;
        INFOFULL) echo -e "[${CYAN}INFO${RESET}] ${CYAN}${text}${RESET}";;
        WARN) echo -e "[${YELLOW}WARN${RESET}] ${text}";;
        WARNFULL) echo -e "[${YELLOW}WARN${RESET}] ${YELLOW}${text}${RESET}";;
        USER) echo -e "[${GREEN}USER${RESET}] ${text}";;
        DBUG) echo -e "[${YELLOW}${BOLD}DBUG${RESET}] ${YELLOW}${text}${RESET}";;
        *) echo -e "${text}";;
    esac
}

function command_exists() {
    command -v "${@}" >/dev/null 2>&1
}

function show_usage() {
    cat <<EOF
Usage:

    Run script using: ${YELLOW}./fontconvert.sh${RESET} or ${YELLOW}bash fontconvert.sh${RESET}

    Source files to be converted need to be in [${CYAN}${config[srcDir]}${RESET}].

    .ttf files will be converted to .otf
    .otf files will be converted to .ttf

    New files will be saved in [${GREEN}${config[dstDir]}${RESET}].

    Bad or corrupt source files will be moved to [${RED}${config[badDir]}${RESET}].
EOF
exit 0
}

function convert_font() {
    srcFile="${1}"
    filename="${srcFile##*/}"
    case "${srcFile: -4}" in
        ".otf") ext=".ttf";;
        ".OTF") ext=".ttf";;
        ".ttf") ext=".otf";;
        ".TTF") ext=".otf";;
    esac

    if [[ ${config[cleanName]} == true ]]; then
        # Clean up new font filename and convert to lowercase
        newName=$(echo "${filename%%.*}" | sed 's/[^a-zA-Z0-9]//g')
        newName=${newName,,}
    else
        newName=${filename%%.*}
    fi

    dstFile="${config[dstDir]}/${newName}${ext}"
    # Run conversion using fontforge
    if [[ ! -f "${dstFile}" ]]; then
        if fontforge -lang=ff -c 'Open($1); Generate($2); Close();' "${srcFile}" "${dstFile}" >/dev/null 2>&1; then
            message TASKDONE "File converted: ${dstFile}"
        else
            message TASKFAIL "Unable to convert file: ${srcFile} (invalid or corrupted font file)."
            badFile="${config[badDir]}/${filename}"
            message FAIL "Bad/corrupt source file moved to: ${badFile}"
            mv "${srcFile}" "${badFile}"
        fi
    else
        message TASKSKIP "Destination file: ${dstFile} already exists."
    fi
}

function process_files() {
    message INFO "Checking for font files in source path: ${config[srcDir]}..."
    counter=0
    for file in "${@}"; do
        filename=${file##*/}
        fileLower=${file,,}
        if [[ "${fileLower: -4}" == ".otf" ]] || [[ "${fileLower: -4}" == ".ttf" ]]; then
            ((++counter))
            message INFO "Processing font file: ${file}..."
            message TASKSTART "Converting font file: ${file}..."
            convert_font "${file}"
        fi
    done
    [[ ${counter} == 1 ]] && fileWord="file" || fileWord="files"
    if [[ ${counter} == 0 ]]; then
        message INFO "No source font files found."
    else
        message INFO "${counter} ${fileWord} processed."
    fi
}

function main() {
    # Configuration settings
    declare -A config
    config=(
        [srcDir]="${SCRIPT_DIR}/src"
        [dstDir]="${SCRIPT_DIR}/dst"
        [badDir]="${SCRIPT_DIR}/bad"
        [maxDepth]=1
        [cleanName]=true
    )

    clear
    echo -e "\n${GREEN}FONT${BOLD}CONVERT${RESET}${GREEN} (for use with fontforge)${RESET}\n"

    if ! command_exists "fontforge"; then
        message FAIL "Required package/command ${YELLOW}fontforge${RESET} not found."
        message INFO "Install fontforge prior to running script."
        message INFO "Linux: ${YELLOW}sudo apt install fontforge${RESET}"
        message INFO "macOS: ${YELLOW}brew install fontforge${RESET}"
        exit 1
    fi

    # Get command line options flags
    [[ "${1}" == "--help" ]] && show_usage
    [[ "${1}" == "--usage" ]] && show_usage

    currentDir=${config[srcDir]}
    for i in $(seq ${config[maxDepth]}); do
        currentDir+=/**
        process_files ${currentDir[@]}
    done
}

main "${@}"