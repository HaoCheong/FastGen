# Base generators - Lay out the initial directories and default files 

# Generates the base directories required
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


# Generate the known required files and directories
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

# Clean the template
function clean_template() {

    # Removes trailing tags
    sed -r -i -e "s/\{\{ [A-Z_]+ \}\}//g" $1

    # Removes triple new lines
    # How the fuck does this work?
    sed -i -e ':a;N;$!ba;s/\n\n\n/\n/g' $1
}