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

# Generate the known files
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


function generate_models() {
    echo "======== GENERATE MODELS FILES ========"

    # For every instance 
}
# Start with model

# Generate

# ========== Main ========== 
# ERASE
if [[ "$1" == "erase" ]]; then
    rimraf ./project
    exit
fi

# BASE GEN
generate_base_directories
generate_base_files