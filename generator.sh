#!/bin/bash

# TEST CLEAR

TEMP_TXT=/dev/shm/temp.txt

# Generate the base directories
function generate_base_directories() {
    echo "======== GENERATE BASE DIRECTORIES ========"

    mkdir ./$PROJECT_NAME
    mkdir ./$PROJECT_NAME/app
    mkdir ./$PROJECT_NAME/app/models
    mkdir ./$PROJECT_NAME/app/cruds
    mkdir ./$PROJECT_NAME/app/schemas
    mkdir ./$PROJECT_NAME/app/endpoints
    mkdir ./$PROJECT_NAME/app/db

    mkdir ./$PROJECT_NAME/tests
    mkdir ./$PROJECT_NAME/tests/unit
    mkdir ./$PROJECT_NAME/tests/populate
}


# Generate the known files and directories
function generate_base_files() {

    echo "======== GENERATE BASE FILES ========"

    # Generate init files
    touch ./$PROJECT_NAME/app/__init__.py
    touch ./$PROJECT_NAME/app/models/__init__.py
    touch ./$PROJECT_NAME/app/cruds/__init__.py
    touch ./$PROJECT_NAME/app/schemas/__init__.py
    touch ./$PROJECT_NAME/app/endpoints/__init__.py

    touch ./$PROJECT_NAME/tests/unit/__init__.py

    
}

# Clean the template from all the unused tags
function clean_template() {

    # Removes tags
    sed -r -i -e "s/\{\{ [A-Z_]+ \}\}//g" $1

    # Removes double new lines
    # How the fuck does this work
    sed -i -e ':a;N;$!ba;s/\n\n\n/\n/g' $1
}

function validate_rel() {
    # Check if all the fields in relationships are valid table name
    rel_tables=$(jq -r ' .relationships[] | [.table_1, .table_2] | join("\n") ' config.json | sort | uniq)
    all_tables=$(jq -r ' .tables[] | .name' config.json)
    if grep -qvxF "$(printf '%s\n' "${all_tables[@]}")" <<< "$rel_tables"
    then
        echo "ERROR: Table in relationship does not have existing model"
        exit
    fi

    # Check if all the rels are valid (m2m, o2o, m2o)
    for rel in $(jq -r ' .relationships[] | .type ' config.json | sort | uniq)
    do
        if [[ $rel != 'm2m' ]] && [[ $rel != 'm2o' ]] && [[ $rel != 'o2o' ]]
        then
            echo "ERROR: Unknown relations ship. Only allow m2m, m2o, and o2o"
            echo "$rel"
            exit
        fi
    done

    # Check if there are repeated rels
    dup_rel=$(jq -r ' .relationships[] | [.table_1, .table_2, .type] | join(",")' config.json | uniq -d)
    if [[ ! -z $dup_rel ]]
    then
        echo "ERROR: Duplicate relations detected"
        echo "$dup_rel"
        exit
    fi

}

source generators/model_generator.sh
source generators/schema_generator.sh
source generators/crud_generator.sh
source generators/endpoint_generator.sh
source generators/main_generator.sh

# OPTION HANDLING
OPTIND=1
OPTIONS="p:c:E:h"

CONFIG_NAME=""
PROJECT_NAME=""

while getopts "$OPTIONS" opt; do
    case $opt in
        c) # Pass in the config file required
            echo $OPTARG
            CONFIG_NAME=$OPTARG
            ;;
        p) # Specifies name of the $PROJECT_NAME 
            echo $OPTARG
            PROJECT_NAME=$OPTARG
            ;;
        E) # Completely deletes the specific $PROJECT_NAME
            echo Deleting \"$OPTARG\" 
            rimraf ./$OPTARG
            exit 1
            ;;
        h) # Completely deletes the specific $PROJECT_NAME
            echo "USAGE: fastGen -p <$PROJECT_NAME-name> -c <config-file>"
            echo "USAGE: fastGen -E <$PROJECT_NAME-name-to-delete>"
            exit 1
            ;;
        \?) # Invalid option was specified
            echo "USAGE: fastGen -p <$PROJECT_NAME-name> -c <config-file>"
            echo "USAGE: fastGen -E <$PROJECT_NAME-name-to-delete>"
            exit 1
            ;;
    esac
done

shift "$((OPTIND-1))"

# DATA VALIDATION
validate_rel

# BASE GEN
generate_base_directories
generate_base_files

generate_models
generate_schemas
generate_cruds
generate_endpoints

generate_main_files


# CLEAN UP
echo "======== CLEANING UP ========"
autopep8 -i -r .
rm $TEMP_TXT


echo "======== COMPLETE ========"



# ====== Standardise Name ======
# - SELF... - Relates to the current class in question
# - OTHER... - Relates to the other, related class in question
# - ..._CLASS_CC - Camel Case version of the class name (nutrition_plan, pet)
# - ..._CLASS_STD - Standard version of the class name (NutritionPlan, Pet)
# - ..._TABLE_NAME - relates to the explicit name of the table (table_name = "xyz")
