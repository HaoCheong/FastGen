#!/bin/bash

# Import Source

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
            rm -rf ./$OPTARG
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

# Validate Relations

# Generate the base directories

generate_base_directories

# Generate the base files

generate_base_files

# Generate the database

# Generate the Models

# Generate the cruds

# Generate Endpoints

# Generate Main Files

# Generate Fixtures

# Generate Unit Tests

# Clean up