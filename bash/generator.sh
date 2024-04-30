#!/bin/bash

# TEST CLEAR



# Generate the base directories
function generate_base_directories() {
    echo "======== GENERATE BASE DIRECTORIES ========"

    mkdir ./project
    mkdir ./project/app
    mkdir ./project/app/models
    mkdir ./project/app/schemas
    mkdir ./project/app/cruds
    mkdir ./project/app/endpoints

    mkdir ./project/tests
    mkdir ./project/tests/unit
    mkdir ./project/tests/populate
}

# Generate the known files
function generate_base_files() {
    cp ./base/helper.temp ./project/app/helpers.py
}

# Generate the known files and directories
function generate_base_files() {

    echo "======== GENERATE BASE FILES ========"

    # Generate init files
    touch ./project/app/__init__.py
    touch ./project/app/models/__init__.py
    touch ./project/app/schemas/__init__.py
    touch ./project/app/cruds/__init__.py
    touch ./project/app/endpoints/__init__.py

    touch ./project/tests/unit/__init__.py

    # Generate predictable files
    cp ./templates/base/helpers.temp ./project/app/helpers.py
}

# Clean the template from all the unused tags
function clean_template() {

    # Removes tags
    sed -r -i -e "s/\{\{ [A-Z_]+ \}\}//g" $1

    # Removes double new lines
    # How the fuck does this work
    sed -i -e ':a;N;$!ba;s/\n\n/\n/g' $1
}

source model_generator.sh

function generate_schemas() {
    echo "======== GENERATE SCHEMA FILES ========"

    # For every instance of schemas files
    for schema in $(jq -r '.tables[] | .name ' config.json)
    do

        

        # Generating base file
        echo "> Generating schema for $schema"
        schema_lc=$(echo "$schema" | tr '[:upper:]' '[:lower:]')
        camel_case=$(echo "$schema" | sed -r "s/([a-z])([A-Z])/\1_\L\2/g; s/([A-Z])([A-Z])([a-z])/\L\1\L\2_\3/g" | tr '[:upper:]' '[:lower:]')
        file_name=./project/app/models/"$camel_case"_schemas.py
        table_name=$(jq -r '.tables[] | select(.name == "'$schema'") | .tablename ' config.json)

        schema_template=$(cat ./templates/schema_templates.txt | grep -e "<<SCHEMA_BASE>>" -A6 | tail -6)
        
        filled_schema_template=$(echo "$schema_template" | sed -r "s/\{\{ SELF_TABLE_CLASS \}\}/$schema/g")
        echo "$filled_schema_template" > ./project/app/schemas/"$camel_case"_schemas.py

        # Generating BASE

        # Generating CREATE

        # Generating READ NR

        # Generating READ WR (Needs to do 2 relationship passes, on to-from and another from-to)

        # Generating Update

    done
}

# ========== Main ========== 
# ERASE test project
if [[ "$1" == "erase" ]]; then
    rimraf ./project
    exit
fi

# BASE GEN
generate_base_directories
generate_base_files
generate_models
generate_schemas



