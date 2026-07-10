#!/bin/bash

#
# COLORS
#
green="\e[0;92m"
red="\e[0;91m"
reset="\e[0m"

#
# VARIABLES
#
script_path="$(realpath -- "$0")"
script_parent_dir="$(dirname -- "${script_path}")"
log_file="${script_path}.log"

#
# FUNCTIONS
#
print-help() {
    echo ""
    echo -e "${green}[ USAGE ]${reset}"
    echo "    $0 [options]"
    echo ""
    echo -e "${green}[ AVAILABLE OPTIONS ]${reset}"
    echo "    --help                : Print the current help message"
    echo "    --all                 : Configure all available apps"
    # Add your option descriptions here
    echo ""
    echo -e "${green}[EXIT CODES]${reset}"
    echo "    0    : Success"
    echo "    1    : Unknown or no argument"
    echo "    2    : Error while pushd to or popd from the script parent directory"
    echo "    3    : Error while popd from an app directory"
    echo ""
}

try-pushd() {
    local app="$1"
    local return_code=0
    if ! pushd "${app}" &>> "${log_file}"
    then
        echo -e "${red}FAILURE${reset} ]"
        echo "${red}Could not move to ${app}'s directory.${reset} Skipping." | tee --append "${log_file}" >&2
        return_code=1
    fi

    return $return_code
}

try-sudo() {
    local app="$1"
    local return_code=0
    if ! sudo --validate
    then
        echo -e "${red}Could not use sudo to configure ${app}.${reset} Skipping." | tee --append "${log_file}" >&2
        return_code=1
    fi
    
    return $return_code
}

check-directory() {
    local app="$1"
    local path="$2"
    local return_code=0
    if ! [ -d "${path}" ]
    then
        echo -e "${red}FAILURE${reset} ]"
        echo -e "${red}Could not find ${path}.${reset} Try launching ${app} once first." | tee --append "${log_file}" >&2
        return_code=1
    fi

    return $return_code
}

configure-app() {
    local app="$1"
    local check_dir="$2"
    local dir_to_check="$3"
    local app_uppercase
    app_uppercase="$(echo "${app}" | tr "[:lower:]" "[:upper:]")"

    { 
        echo ""
        echo "--------------------"
        echo ""
        echo "[ ${app_uppercase} ]" 
    } >> "${log_file}"
    echo -n "[ ${app_uppercase}... "

    if ! ${check_dir} || check-directory "${app}" "${dir_to_check}"
    then
        if try-pushd "${app}"
        then
            "configure-${app}"
            if popd &>> "${log_file}"
            then 
                echo -e "${green}OK${reset} ]"
            else
                echo -e "${red}FATAL ERROR${reset} ]"
                exit 3
            fi
        fi
    fi
}

#
# APP CONFIGURATION FUNCTIONS
# Add your configuration functions here
#

#
# BEGIN
#

# Testing if could move to the script directory
if ! pushd "${script_parent_dir}" &> "${log_file}"
then
    echo -e "${red}Could not move to ${script_parent_dir}. Exiting.${reset}" | tee --append "${log_file}" >&2
    exit 2
fi

if [ $# -eq 0 ]
then
    print-help
    exit 1
fi

# Handle options
for opt in "$@"
do
    case "${opt}" in
    "--help")
        print-help
        exit 0
        ;;
        
    "--all")
        # Configure all only if --all is the only argument
        if [ $# -eq 1 ]
        then
            bash "${script_path}"    # <= Add your option here
        else 
            echo "There are other arguments than --all. Skipping --all argument"
        fi
        ;;
    # Add your options here
    *)
        echo -e "${red}Unknown argument : ${opt}${reset}" >&2
        print-help
        exit 1
        ;;
    esac
done

#
# END
#
if ! popd &>> "${log_file}"
then
    echo -e "${red}Could not leave ${script_parent_dir}. Exiting.${reset}" | tee --append "${log_file}" >&2
    exit 2
else
    exit 0
fi

