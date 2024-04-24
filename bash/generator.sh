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
    for model in $(jq -r '.tables[] | .name ' config.json)
    do
        echo "> Generating model for $model"
        model_lc=$(echo "$model" | tr '[:upper:]' '[:lower:]')
        file_name=./project/app/models/"$model_lc"_model.py

        # Create default template
        model_template=$(cat ./templates/model_templates.txt | grep -e "<<MODEL_BASE>>" -A16 | tail -15)
        echo "$model_template" > ./project/app/models/"$model_lc"_model.py



        # Create get all the column
        model_cols=$(jq -r ' .tables[] | select(.name == "'$model'") | .columns[] | [.column_name, .column_type] | join(",") ' config.json)

        for cols in $model_cols
        do
            # echo $cols
            model_col_name=$(echo $cols | cut -d"," -f1)
            model_col_type=$(echo $cols | cut -d"," -f2)

            if [[ $model_col_type == 'str' ]]
            then
                model_column_str=$(cat ./templates/model_templates.txt | grep -e "<<COLUMN_STRING>>" -A2 | tail -2)
                filled_model_column_str=$(echo "$model_column_str" | sed -r "s/\{\{ COLUMN_NAME \}\}/$model_col_name/g")
                filled_model_column_str=$(echo "$filled_model_column_str" | sed 's/\\n/\\\\n/g')

                awk -v var="$filled_model_column_str" '{gsub(/{{ COLUMNS }}/, var); print}' $file_name > temp.txt
                cat temp.txt > $file_name
                
            elif [[ $model_col_type == 'int' ]]
            then

                model_column_int=$(cat ./templates/model_templates.txt | grep -e "<<COLUMN_INTEGER>>" -A2 | tail -2)
                filled_model_column_int=$(echo "$model_column_int" | sed -r "s/\{\{ COLUMN_NAME \}\}/$model_col_name/g")
                filled_model_column_int=$(echo "$filled_model_column_int" | sed -r 's/\\n/\\\\n/g')

                awk -v var="$filled_model_column_int" '{gsub(/{{ COLUMNS }}/, var); print}' $file_name > temp.txt
                cat temp.txt > $file_name
            fi
        done
    done

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
generate_models