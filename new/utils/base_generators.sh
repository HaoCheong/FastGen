function generate_base_directories {

    proj_name=$1

    # Make the base directories

    mkdir $proj_name
    mkdir $proj_name/app
    mkdir $proj_name/app/cruds
    mkdir $proj_name/app/endpoints
    mkdir $proj_name/app/models
    mkdir $proj_name/app/database
    mkdir $proj_name/app/config
    mkdir $proj_name/app/log
    
    mkdir $proj_name/tests
    mkdir $proj_name/tests/fixtures
    mkdir $proj_name/tests/unit

    mkdir $proj_name/utils
}

function generate_base_files {

    proj_name=$1

    # Generate init files
    touch ./$proj_name/app/__init__.py
    touch ./$proj_name/app/models/__init__.py
    touch ./$proj_name/app/cruds/__init__.py
    touch ./$proj_name/app/endpoints/__init__.py

    touch ./$proj_name/tests/unit/__init__.py

}