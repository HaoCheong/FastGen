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

# Generate necessary files from model
function generate_models() {
    echo "======== GENERATE MODELS FILES ========"

    # For every instance
    for model in $(jq -r '.tables[] | .name ' config.json)
    do
        echo "> Generating model for $model"
        model_lc=$(echo "$model" | tr '[:upper:]' '[:lower:]')
        file_name=./project/app/models/"$model_lc"_model.py

        # Create default template
        model_template=$(cat ./templates/model_templates.txt | grep -e "<<MODEL_BASE>>" -A16 | tail -16)
        echo "$model_template" > ./project/app/models/"$model_lc"_model.py

        # Add the one offs replacements
        sed -r -i "s/\{\{ CLASS_NAME \}\}/$model/g" $file_name
        sed -r -i "s/\{\{ TABLE_NAME \}\}/$model_lc/g" $file_name

        # Create get all the column
        model_cols=$(jq -r ' .tables[] | select(.name == "'$model'") | .columns[] | [.column_name, .column_type] | join(",") ' config.json)

        for cols in $model_cols
        do
            # echo $cols
            model_col_name=$(echo $cols | cut -d"," -f1)
            model_col_type=$(echo $cols | cut -d"," -f2)

            if [[ $model_col_type == 'str' ]]
            then
                # Add new string column in model
                model_column_str=$(cat ./templates/model_templates.txt | grep -e "<<COLUMN_STRING>>" -A2 | tail -2)
                filled_model_column_str=$(echo "$model_column_str" | sed -r "s/\{\{ COLUMN_NAME \}\}/$model_col_name/g")
                filled_model_column_str=$(echo "$filled_model_column_str" | sed 's/\\n/\\\\n/g')
                awk -v var="$filled_model_column_str" '{gsub(/{{ COLUMNS }}/, var); print}' $file_name > temp.txt
                cat temp.txt > $file_name
                
            elif [[ $model_col_type == 'int' ]]
            then
                # Add new integer column in model
                model_column_int=$(cat ./templates/model_templates.txt | grep -e "<<COLUMN_INTEGER>>" -A2 | tail -2)
                filled_model_column_int=$(echo "$model_column_int" | sed -r "s/\{\{ COLUMN_NAME \}\}/$model_col_name/g")
                filled_model_column_int=$(echo "$filled_model_column_int" | sed -r 's/\\n/\\\\n/g')
                awk -v var="$filled_model_column_int" '{gsub(/{{ COLUMNS }}/, var); print}' $file_name > temp.txt
                cat temp.txt > $file_name

            elif [[ $model_col_type == 'json' ]]
            then
                # Add new json column in model
                model_column_json=$(cat ./templates/model_templates.txt | grep -e "<<COLUMN_JSON>>" -A2 | tail -2)
                filled_model_column_json=$(echo "$model_column_json" | sed -r "s/\{\{ COLUMN_NAME \}\}/$model_col_name/g")
                filled_model_column_json=$(echo "$filled_model_column_json" | sed -r 's/\\n/\\\\n/g')
                awk -v var="$filled_model_column_json" '{gsub(/{{ COLUMNS }}/, var); print}' $file_name > temp.txt
                cat temp.txt > $file_name

            elif [[ $model_col_type == 'datetime' ]]
            then
                # Add new datetime column in model
                model_column_datetime=$(cat ./templates/model_templates.txt | grep -e "<<COLUMN_DATETIME>>" -A2 | tail -2)
                filled_model_column_datetime=$(echo "$model_column_datetime" | sed -r "s/\{\{ COLUMN_NAME \}\}/$model_col_name/g")
                filled_model_column_datetime=$(echo "$filled_model_column_datetime" | sed -r 's/\\n/\\\\n/g')
                awk -v var="$filled_model_column_datetime" '{gsub(/{{ COLUMNS }}/, var); print}' $file_name > temp.txt
                cat temp.txt > $file_name 
            fi
        done

        # Relationship first pass - Get all the table_1 of the current table being created
        curr_model_relations=$(jq -r ' .relationships[] | select(.table_1 == "'$model'") | [.table_1, .table_2, .type] | join(",")' config.json)
        for relation in $curr_model_relations
        do
            to_table=$(echo $relation | cut -d"," -f2)
            to_table_lc=$(echo "$to_table" | tr '[:upper:]' '[:lower:]')
            table_rel=$(echo $relation | cut -d"," -f3)

            if [[ $table_rel == 'm2m' ]]
            then
                assoc_table_class="$model""$to_table"Association
                assoc_table_name_lc="$model_lc"_"$to_table_lc"_association

                # Generate the self class m2m relation
                model_m2m_rel=$(cat ./templates/model_templates.txt | grep -e "<<REL_MANY_TO_MANY>>" -A5 | tail -5)
                filled_model_m2m_rel=$(echo "$model_m2m_rel" | sed -r "s/\{\{ MANY_TABLE_NAME \}\}/$to_table_lc/g")
                filled_model_m2m_rel=$(echo "$filled_model_m2m_rel" | sed -r "s/\{\{ MANY_TABLE_CLASS \}\}/$model/g")
                filled_model_m2m_rel=$(echo "$filled_model_m2m_rel" | sed -r "s/\{\{ ASSOC_TABLE_NAME \}\}/$assoc_table_name_lc/g")
                filled_model_m2m_rel=$(echo "$filled_model_m2m_rel" | sed -r "s/\{\{ SELF_POP_FIELD \}\}/$model_lc/g")
                filled_model_m2m_rel=$(echo "$filled_model_m2m_rel" | sed 's/\\n/\\\\n/g')
                awk -v var="$filled_model_m2m_rel\n" '{gsub(/{{ RELATION }}/, var); print}' $file_name > temp.txt
                cat temp.txt > $file_name

                # Generate association table
                assoc_table=$(cat ./templates/model_templates.txt | grep -e "<<ASSOC_TABLE>>" -A7 | tail -7)
                filled_assoc_table=$(echo "$assoc_table" | sed -r "s/\{\{ SELF_CLASS \}\}/$model/g")
                filled_assoc_table=$(echo "$filled_assoc_table" | sed -r "s/\{\{ OTHER_CLASS \}\}/$to_table/g")
                filled_assoc_table=$(echo "$filled_assoc_table" | sed -r "s/\{\{ SELF_TABLE_NAME \}\}/$model_lc/g")
                filled_assoc_table=$(echo "$filled_assoc_table" | sed -r "s/\{\{ OTHER_TABLE_NAME \}\}/$to_table_lc/g")
                filled_assoc_table=$(echo "$filled_assoc_table" | sed 's/\\n/\\\\n/g')
                awk -v var="$filled_assoc_table\n" '{gsub(/{{ ASSOCIATION_OBJECT }}/, var); print}' $file_name > temp.txt
                cat temp.txt > $file_name

            elif [[ $table_rel == 'm2o' ]]
            then

                # Generate the self class m2o relation
                model_m2o_rel=$(cat ./templates/model_templates.txt | grep -e "<<REL_MANY_TO_ONE>>" -A5 | tail -5)
                filled_model_m2o_rel=$(echo "$model_m2o_rel" | sed -r "s/\{\{ MANY_TABLE_NAME \}\}/$to_table_lc/g")
                filled_model_m2o_rel=$(echo "$filled_model_m2o_rel" | sed -r "s/\{\{ SELF_POP_FIELD \}\}/$model_lc/g")
                filled_model_m2o_rel=$(echo "$filled_model_m2o_rel" | sed -r "s/\{\{ MANY_TABLE_CLASS \}\}/$to_table/g")
                filled_model_m2o_rel=$(echo "$filled_model_m2o_rel" | sed 's/\\n/\\\\n/g')
                awk -v var="$filled_model_m2o_rel\n" '{gsub(/{{ RELATION }}/, var); print}' $file_name > temp.txt
                cat temp.txt > $file_name

            elif [[ $table_rel == 'o2o' ]]
            then

                # Generate the self class o2o relation
                model_o2o_rel=$(cat ./templates/model_templates.txt | grep -e "<<REL_ONE_TO_ONE>>" -A4 | tail -4)
                filled_model_o2o_rel=$(echo "$model_o2o_rel" | sed -r "s/\{\{ ONE_TABLE_NAME \}\}/$to_table_lc/g")
                filled_model_o2o_rel=$(echo "$filled_model_o2o_rel" | sed -r "s/\{\{ ONE_TABLE_CLASS \}\}/$to_table/g")
                filled_model_o2o_rel=$(echo "$filled_model_o2o_rel" | sed 's/\\n/\\\\n/g')
                awk -v var="$filled_model_o2o_rel\n" '{gsub(/{{ RELATION }}/, var); print}' $file_name > temp.txt
                cat temp.txt > $file_name

            else
                echo "ERROR: RELATIONSHIP DOES NOT EXIST"
            fi

        done

        # Relationship second pass - Get all the table_2 of the current table being created
        curr_model_relations=$(jq -r ' .relationships[] | select(.table_2 == "'$model'") | [.table_2, .table_1, .type] | join(",")' config.json)
        for relation in $curr_model_relations
        do
            from_table=$(echo $relation | cut -d"," -f2)
            table_rel=$(echo $relation | cut -d"," -f3)

            echo PASS 2 $from_table $table_rel
        done

        clean_template $file_name
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


