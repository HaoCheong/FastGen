#!/bin/bash

# Importing Generator Functions
source generators/helpers.sh
source generators/base_generators.sh
# source generators/model_generators.sh
# source generators/crud_generators.sh
# source generators/endpoint_generators.sh
# source generators/main_generators.sh
# source generators/test_generators.sh


# Master project variables
CONFIG_NAME=""
PROJECT_NAME=""

# In memory temp file to improve storage health
TEMP_TXT=/dev/shm/temp.txt

# Option Handling
OPTIND=1
OPTIONS="p:c:E:h"

while getopts "$OPTIONS" opt; do
    case $opt in
        c) # Read a passed in configuration file
            echo $OPTARG
            CONFIG_NAME=$OPTARG
            ;;
        p) # Specifies value of variable $PROJECT_NAME 
            echo $OPTARG
            PROJECT_NAME=$OPTARG
            ;;
        E) # Completely deletes an existing project of name $PROJECT_NAME
            echo Deleting \"$OPTARG\" 
            rimraf ./$OPTARG
            exit 1
            ;;
        h) # Help command for usage
            echo "USAGE: fastGen -p <project-name> -c <config-file>"
            echo "USAGE: fastGen -E <project-name-to-delete>"
            exit 1
            ;;
        \?) # Invalid option shows usage
            echo "USAGE: fastGen -p <project-name> -c <config-file>"
            echo "USAGE: fastGen -E <project-name-to-delete>"
            exit 1
            ;;
    esac
done
shift "$((OPTIND-1))"

function main {
    # ========== VALIDATE INPUTS ==========
    validate_input

    # ========== GENERATE BASE FILES ==========
    generate_base_directories
    generate_base_files
}

main
