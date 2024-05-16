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
    rel_tables=$(jq -r ' .relationships[] | [.table_1, .table_2] | join("\n") ' $CONFIG_NAME | sort | uniq)
    all_tables=$(get_all_tables)
    
    if grep -qvxF "$(printf '%s\n' "${all_tables[@]}")" <<< "$rel_tables"
    then
        echo "ERROR: Table in relationship does not have existing model"
        exit
    fi
    # Check if all the rels are valid (m2m, o2o, m2o)
    for rel in $(jq -r ' .relationships[] | .type ' $CONFIG_NAME | sort | uniq)
    do
        if [[ $rel != 'm2m' ]] && [[ $rel != 'm2o' ]] && [[ $rel != 'o2o' ]]
        then
            echo "ERROR: Unknown relations ship. Only allow m2m, m2o, and o2o"
            echo "$rel"
            exit
        fi
    done

    # Check if there are repeated rels
    dup_rel=$(jq -r ' .relationships[] | [.table_1, .table_2, .type] | join(",")' $CONFIG_NAME | uniq -d)
    if [[ ! -z $dup_rel ]]
    then
        echo "ERROR: Duplicate relations detected"
        echo "$dup_rel"
        exit
    fi
}