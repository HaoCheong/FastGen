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
    cp ./templates/helpers_templates.txt ./project/app/helpers.py
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
source schema_generator.sh

# Generate all the required crud functions
# function generate_cruds() {


    
#     echo "======== GENERATE CRUD FILES ========"
    
#     for crud in $(jq -r '.tables[] | .name ' config.json)
#     do
#         echo "> Generating CRUDs for $crud"
#         crud_lc=$(echo "$crud" | tr '[:upper:]' '[:lower:]')
#         camel_case=$(echo "$crud" | sed -r "s/([a-z])([A-Z])/\1_\L\2/g; s/([A-Z])([A-Z])([a-z])/\L\1\L\2_\3/g" | tr '[:upper:]' '[:lower:]')
#         file_name=./project/app/cruds/"$camel_case"_cruds.py
#         table_name=$(jq -r '.tables[] | select(.name == "'$crud'") | .tablename ' config.json)


#     done


#     ## Populate the base files

#     # Generate the assignment files
#     curr_model_relations=$(jq -r ' .relationships[] | select(.table_2 == "'$model'") | [.table_2, .table_1, .type] | join(",")' config.json)
#     for relation in $curr_model_relations
#     do
#         from_table=$(echo $relation | cut -d"," -f2)
#         from_table_lc=$(echo "$from_table" | tr '[:upper:]' '[:lower:]')
#         table_rel=$(echo $relation | cut -d"," -f3)
#     done

#     ## Populate the assignment files
# }


# ========== Main ========== 
# ERASE test project
if [[ "$1" == "erase" ]]; then
    rimraf ./project
    exit
fi

# BASE GEN
generate_base_directories
generate_base_files

# generate_models
generate_schemas



