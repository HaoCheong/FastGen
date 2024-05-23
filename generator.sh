#!/bin/bash

# Importing Generator Functions
source generators/base_generator.sh
source generators/model_generator.sh
source generators/schema_generator.sh
source generators/crud_generator.sh
source generators/endpoint_generator.sh
source generators/main_generator.sh
source generators/test_generator.sh
source generators/helpers.sh

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

# ======== DATA VALIDATION ========
validate_rel

# ======== BASE GENERATORS ========
generate_base_directories
generate_base_files

# ======== CORE GENERATORS ========
generate_models
generate_schemas
generate_cruds
generate_endpoints

# ======== MAIN GENERATORS ========
generate_main_files

# ======== TEST GENERATORS ========
generate_unit_tests

# ======== CLEAN UP ========
echo "======== CLEANING UP ========"
rm $TEMP_TXT

echo "======== COMPLETE ========"
echo " - Please include 3 pieces of testing data in test/unit/test_data.py for each model"


# ======== Standardise Naming scheme (dev ref) ========
# - SELF... - Relates to the current class in question
# - OTHER... - Relates to the other, related class in question
# - ..._CLASS_CC - Camel Case version of the class name (nutrition_plan, pet)
# - ..._CLASS_STD - Standard version of the class name (NutritionPlan, Pet)
# - ..._TABLE_NAME - relates to the explicit name of the table (table_name = "xyz")
