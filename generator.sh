#!/bin/bash

# TEST CLEAR

TEMP_TXT=/dev/shm/temp.txt

# Generate the base directories
function generate_base_directories() {
    echo "======== GENERATE BASE DIRECTORIES ========"

    mkdir ./project
    mkdir ./project/app
    mkdir ./project/app/models
    mkdir ./project/app/cruds
    mkdir ./project/app/schemas
    mkdir ./project/app/endpoints
    mkdir ./project/app/db

    mkdir ./project/tests
    mkdir ./project/tests/unit
    mkdir ./project/tests/populate
}


# Generate the known files and directories
function generate_base_files() {

    echo "======== GENERATE BASE FILES ========"

    # Generate init files
    touch ./project/app/__init__.py
    touch ./project/app/models/__init__.py
    touch ./project/app/cruds/__init__.py
    touch ./project/app/schemas/__init__.py
    touch ./project/app/endpoints/__init__.py

    touch ./project/tests/unit/__init__.py

    
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

    echo "Success"
    exit
}

source generators/model_generator.sh
source generators/schema_generator.sh
source generators/crud_generator.sh
source generators/endpoint_generator.sh
source generators/main_generator.sh

# ========== Main ========== 
# ERASE test project
if [[ "$1" == "erase" ]]; then
    rimraf ./project
    exit
fi

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
