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

# Generate remaining files
function generate_main_files() {

    proj_data=$(jq -r ' .project | [.name, .desc, .version, .database_name] | join("|")' config.json)
    name=$(echo "$proj_data" | cut -d"|" -f1)
    desc=$(echo "$proj_data" | cut -d"|" -f2)
    version=$(echo "$proj_data" | cut -d"|" -f3)
    database_name=$(echo "$proj_data" | cut -d"|" -f4)

    # Generate Database
    file_name="./project/app/database.py"
    database_template=$(cat ./templates/database_templates.txt | grep -e "<<DATABASE_BASE>>" -A16 | tail -16)
    filled_database_template=$(echo "$database_template" | sed -r "s/\{\{ DATABASE_NAME \}\}/$database_name/g")
    echo "$filled_database_template" > $TEMP_TXT
    cp $TEMP_TXT $file_name

    # Generate Metadata
    file_name="./project/app/metadata.py"
    metadata_template=$(cat ./templates/metadata_templates.txt | grep -e "<<METADATA_BASE>>" -A15 | tail -15)
    filled_metadata_template=$(echo "$metadata_template" | sed -r "s/\{\{ PROJECT_TITLE \}\}/$name/g")
    filled_metadata_template=$(echo "$filled_metadata_template" | sed -r "s/\{\{ PROJECT_VERS \}\}/$version/g")
    filled_metadata_template=$(echo "$filled_metadata_template" | sed -r "s/\{\{ PROJECT_DESC \}\}/$desc/g")
    echo "$filled_metadata_template" > $TEMP_TXT

    IFS=$'\n'
    for metadata in $(jq -r '.tables[] | .metadata | [.name, .desc] | join("|")' config.json)
    do
        title=$(echo "$metadata" | cut -d"|" -f1)
        desc=$(echo "$metadata" | cut -d"|" -f2-)

        metadata_tag_template=$(cat ./templates/metadata_templates.txt | grep -e "<<METADATA_TAG>>" -A6 | tail -6)
        filled_metadata_tag_template=$(echo "$metadata_tag_template" | sed -r "s/\{\{ METADATA_TITLE \}\}/$title/g")
        filled_metadata_tag_template=$(echo "$filled_metadata_tag_template" | sed -r "s/\{\{ METADATA_DESC \}\}/$desc/g")
        filled_metadata_tag_template=$(echo "$filled_metadata_tag_template" | sed 's/\\n/\\\\n/g')
        pop_file=$(awk -v var="$filled_metadata_tag_template" '{gsub(/{{ METADATA_TAGS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT
    done

    for metadata_assign in $(jq -r ' .relationships[] | .table_1 ' config.json | sort | uniq)
    do

        metadata_assign_tag_template=$(cat ./templates/metadata_templates.txt | grep -e "<<METADATA_ASSIGN_TAG>>" -A6 | tail -6)
        filled_metadata_assign_tag_template=$(echo "$metadata_assign_tag_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$metadata_assign/g")
        filled_metadata_assign_tag_template=$(echo "$filled_metadata_assign_tag_template" | sed 's/\\n/\\\\n/g')
        pop_file=$(awk -v var="$filled_metadata_assign_tag_template" '{gsub(/{{ METADATA_ASSIGN_TAGS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT
    done

    clean_template $TEMP_TXT
    cp $TEMP_TXT $file_name

    # Generate Main
    file_name="./project/app/main.py"
    main_template=$(cat ./templates/main_templates.txt | grep -e "<<MAIN_BASE>>" -A37 | tail -37)
    echo "$main_template" > $TEMP_TXT

    for table in $(jq -r ' .tables[] | .name ' config.json)
    do
        table_cc=$(echo "$table" | sed -r "s/([a-z])([A-Z])/\1_\L\2/g; s/([A-Z])([A-Z])([a-z])/\L\1\L\2_\3/g" | tr '[:upper:]' '[:lower:]')
        
        main_import_template=$(cat ./templates/main_templates.txt | grep -e "<<IMPORT_BASE>>" -A2 | tail -2)
        filled_main_import_template=$(echo "$main_import_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$table_cc/g")
        filled_main_import_template=$(echo "$filled_main_import_template" | sed 's/\\n/\\\\n/g')
        pop_file=$(awk -v var="$filled_main_import_template" '{gsub(/{{ MAIN_IMPORTS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT

        main_router_template=$(cat ./templates/main_templates.txt | grep -e "<<ROUTER_BASE>>" -A2 | tail -2)
        filled_main_router_template=$(echo "$main_router_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$table_cc/g")
        filled_main_router_template=$(echo "$filled_main_router_template" | sed 's/\\n/\\\\n/g')
        pop_file=$(awk -v var="$filled_main_router_template" '{gsub(/{{ ROUTER_INCLUDES }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT
    done

    clean_template $TEMP_TXT
    cp $TEMP_TXT $file_name

    # Generate Helper
    cp ./templates/helpers_templates.txt ./project/app/helpers.py
}

source model_generator.sh
source schema_generator.sh
source crud_generator.sh
source endpoint_generator.sh

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
generate_cruds
generate_endpoints

generate_main_files



# CLEAN UP
echo "======== CLEANING UP ========"
rm $TEMP_TXT

echo "======== COMPLETE ========"



# ====== Standardise Name ======
# - SELF... - Relates to the current class in question
# - OTHER... - Relates to the other, related class in question
# - ..._CLASS_CC - Camel Case version of the class name (nutrition_plan, pet)
# - ..._CLASS_STD - Standard version of the class name (NutritionPlan, Pet)
# - ..._TABLE_NAME - relates to the explicit name of the table (table_name = "xyz")
