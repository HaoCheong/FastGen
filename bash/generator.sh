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

    # Generate predictable files
    cp ./templates/helpers_templates.txt ./project/app/helpers.py
}

# Clean the template from all the unused tags
function clean_template() {

    # Removes tags
    sed -r -i -e "s/\{\{ [A-Z_]+ \}\}//g" $1

    # Removes double new lines
    # How the fuck does this work
    sed -i -e ':a;N;$!ba;s/\n\n\n/\n/g' $1
}

source model_generator.sh
source schema_generator.sh

# Generate all the required crud functions
    function generate_cruds() {
        
        echo "======== GENERATE CRUD FILES ========"
        
        for crud in $(jq -r '.tables[] | .name ' config.json)
        do
            echo "> Generating CRUDs for $crud"
            crud_cc=$(echo "$crud" | sed -r "s/([a-z])([A-Z])/\1_\L\2/g; s/([A-Z])([A-Z])([a-z])/\L\1\L\2_\3/g" | tr '[:upper:]' '[:lower:]')
            file_name=./project/app/cruds/"$crud_cc"_cruds.py
            table_name=$(jq -r '.tables[] | select(.name == "'$crud'") | .tablename ' config.json)

            crud_template=$(cat ./templates/crud_templates.txt | grep -e "<<CRUD_BASE>>" -A5 | tail -5)
            echo "$crud_template" > $TEMP_TXT

            sed -r -i "s/\{\{ SELF_CLASS_CC \}\}/$crud_cc/g" $TEMP_TXT

            # Generate Create
            crud_base_template=$(cat ./templates/crud_templates.txt | grep -e "<<CRUD_CREATE>>" -A11 | tail -11)
            filled_crud_base_template=$(echo "$crud_base_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$crud_cc/g")
            filled_crud_base_template=$(echo "$filled_crud_base_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$crud/g")
            pop_file=$(awk -v var="$filled_crud_base_template" '{gsub(/{{ CRUDS }}/, var); print}' $TEMP_TXT)
            echo "$pop_file" > $TEMP_TXT

            crud_cols=$(jq -r ' .tables[] | select(.name == "'$crud'") | .columns[] | [.column_name, .column_type] | join(",") ' config.json)
            for col in $crud_cols
            do

                crud_col_name=$(echo $col | cut -d"," -f1)

                # Generate fields into field
                crud_field=$(cat ./templates/crud_templates.txt | grep -e "<<CREATE_FIELD>>" -A2 | tail -2)
                filled_crud_field=$(echo "$crud_field" | sed -r "s/\{\{ FIELD_NAME \}\}/$crud_col_name/g")
                filled_crud_field=$(echo "$filled_crud_field" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$crud_cc/g")
                filled_crud_field=$(echo "$filled_crud_field" | sed 's/\\n/\\\\n/g')
                pop_file=$(awk -v var="$filled_crud_field" '{gsub(/{{ CRUD_FIELDS }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT

            done

            # Generate Get All
            crud_get_all_template=$(cat ./templates/crud_templates.txt | grep -e "<<CRUD_GET_ALL>>" -A4 | tail -4)
            filled_crud_get_all_template=$(echo "$crud_get_all_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$crud_cc/g")
            filled_crud_get_all_template=$(echo "$filled_crud_get_all_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$crud/g")
            pop_file=$(awk -v var="$filled_crud_get_all_template" '{gsub(/{{ CRUDS }}/, var); print}' $TEMP_TXT)
            echo "$pop_file" > $TEMP_TXT

            # Generate Get By ID
            crud_get_by_id_template=$(cat ./templates/crud_templates.txt | grep -e "<<CRUD_GET_BY_ID>>" -A4 | tail -4)
            filled_crud_get_by_id_template=$(echo "$crud_get_by_id_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$crud_cc/g")
            filled_crud_get_by_id_template=$(echo "$filled_crud_get_by_id_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$crud/g")
            pop_file=$(awk -v var="$filled_crud_get_by_id_template" '{gsub(/{{ CRUDS }}/, var); print}' $TEMP_TXT)
            echo "$pop_file" > $TEMP_TXT
            
            # Generate Update
            crud_update_template=$(cat ./templates/crud_templates.txt | grep -e "<<CRUD_UPDATE>>" -A16 | tail -16)
            filled_crud_update_template=$(echo "$crud_update_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$crud_cc/g")
            filled_crud_update_template=$(echo "$filled_crud_update_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$crud/g")
            pop_file=$(awk -v var="$filled_crud_update_template" '{gsub(/{{ CRUDS }}/, var); print}' $TEMP_TXT)
            echo "$pop_file" > $TEMP_TXT

            # Generate Delete
            crud_delete_template=$(cat ./templates/crud_templates.txt | grep -e "<<CRUD_DELETE>>" -A8 | tail -8)
            filled_delete_template=$(echo "$delete_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$crud_cc/g")
            filled_delete_template=$(echo "$filled_delete_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$crud/g")
            pop_file=$(awk -v var="$filled_delete_template" '{gsub(/{{ CRUDS }}/, var); print}' $TEMP_TXT)
            echo "$pop_file" > $TEMP_TXT

            clean_template $TEMP_TXT
            cp $TEMP_TXT $file_name

            # Generate the assignment files
            curr_crud_relations=$(jq -r ' .relationships[] | select(.table_1 == "'$crud'") | [.table_1, .table_2, .type] | join(",")' config.json)
            for relation in $curr_crud_relations
            do
                
                to_table=$(echo $relation | cut -d"," -f2)
                to_table_cc=$(echo "$to_table" | sed -r "s/([a-z])([A-Z])/\1_\L\2/g; s/([A-Z])([A-Z])([a-z])/\L\1\L\2_\3/g" | tr '[:upper:]' '[:lower:]')
                assign_file_name=./project/app/cruds/"$crud_cc"_"$to_table_cc"_assign.py
                table_rel=$(echo $relation | cut -d"," -f3)

                echo ">> Generating Assignments for $to_table"

                crud_assign_template=$(cat ./templates/crud_templates.txt | grep -e "<<ASSIGNMENT_BASE>>" -A5 | tail -5)
                echo "$crud_assign_template" > $TEMP_TXT
                sed -r -i "s/\{\{ SELF_CLASS_CC \}\}/$crud_cc/g" $TEMP_TXT
                sed -r -i "s/\{\{ OTHER_CLASS_CC \}\}/$to_table_cc/g" $TEMP_TXT

                if [[ $table_rel == 'm2m' ]]
                then


                    assign_m2m_template=$(cat ./templates/crud_templates.txt | grep -e "<<ASSIGNMENT_m2m>>" -A33 | tail -33)
                    filled_assign_m2m_template=$(echo "$assign_m2m_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$crud_cc/g")
                    filled_assign_m2m_template=$(echo "$filled_assign_m2m_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$crud/g")
                    filled_assign_m2m_template=$(echo "$filled_assign_m2m_template" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$to_table_cc/g")
                    filled_assign_m2m_template=$(echo "$filled_assign_m2m_template" | sed -r "s/\{\{ OTHER_CLASS_STD \}\}/$to_table/g")
                    pop_file=$(awk -v var="$filled_assign_m2m_template" '{gsub(/{{ ASSIGNMENT_INSERT }}/, var); print}' $TEMP_TXT)
                    echo "$pop_file" > $TEMP_TXT

                elif [[ $table_rel == 'm2o' ]]
                then


                    assign_m2o_template=$(cat ./templates/crud_templates.txt | grep -e "<<ASSIGNMENT_m2o>>" -A35 | tail -35)
                    filled_assign_m2o_template=$(echo "$assign_m2o_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$crud_cc/g")
                    filled_assign_m2o_template=$(echo "$filled_assign_m2o_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$crud/g")
                    filled_assign_m2o_template=$(echo "$filled_assign_m2o_template" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$to_table_cc/g")
                    filled_assign_m2o_template=$(echo "$filled_assign_m2o_template" | sed -r "s/\{\{ OTHER_CLASS_STD \}\}/$to_table/g")
                    pop_file=$(awk -v var="$filled_assign_m2o_template" '{gsub(/{{ ASSIGNMENT_INSERT }}/, var); print}' $TEMP_TXT)
                    echo "$pop_file" > $TEMP_TXT

                elif [[ $table_rel == 'o2o' ]]
                then


                    assign_o2o_template=$(cat ./templates/crud_templates.txt | grep -e "<<ASSIGNMENT_o2o>>" -A32 | tail -32)
                    filled_assign_o2o_template=$(echo "$assign_o2o_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$crud_cc/g")
                    filled_assign_o2o_template=$(echo "$filled_assign_o2o_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$crud/g")
                    filled_assign_o2o_template=$(echo "$filled_assign_o2o_template" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$to_table_cc/g")
                    filled_assign_o2o_template=$(echo "$filled_assign_o2o_template" | sed -r "s/\{\{ OTHER_CLASS_STD \}\}/$to_table/g")
                    pop_file=$(awk -v var="$filled_assign_o2o_template" '{gsub(/{{ ASSIGNMENT_INSERT }}/, var); print}' $TEMP_TXT)
                    echo "$pop_file" > $TEMP_TXT

                else
                    echo "ERROR: RELATIONSHIP DOES NOT EXIST"
                fi

                clean_template $TEMP_TXT
                cp $TEMP_TXT $assign_file_name
            done
        done


        ## Populate the base files

        
        
        
        ## Populate the assignment files
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
generate_cruds


# CLEAN UP
rm $TEMP_TXT





# ====== Standardise Name ======
# - SELF... - Relates to the current class in question
# - OTHER... - Relates to the other, related class in question
# - ..._CLASS_CC - Camel Case version of the class name (nutrition_plan, pet)
# - ..._CLASS_STD - Standard version of the class name (NutritionPlan, Pet)
# - ..._TABLE_NAME - relates to the explicit name of the table (table_name = "xyz")
