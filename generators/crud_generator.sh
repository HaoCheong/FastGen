# CRUD generators - Create the necessary CRUD files given the models

# Generates the CRUD Files
function generate_cruds() {
    
    echo "======== GENERATE CRUD FILES ========"
    
    # Iterate over each model to generate a crud per model
    for crud in $(jq -r '.tables[] | .name ' $CONFIG_NAME)
    do
        echo "> Generating CRUDs for $crud"

        # Process text required for file naming convention 
        crud_cc=$(to_camel_case $crud)
        file_name=./$PROJECT_NAME/app/cruds/"$crud_cc"_cruds.py
        table_name=$(jq -r '.tables[] | select(.name == "'$crud'") | .tablename ' $CONFIG_NAME)

        # Generates the initial CRUD based template
        crud_template=$(cat ./templates/crud_templates.txt | grep -e "<<CRUD_BASE>>" -A5 | tail -5)
        echo "$crud_template" > $TEMP_TXT
        sed -r -i "s/\{\{ SELF_CLASS_CC \}\}/$crud_cc/g" $TEMP_TXT

        # Generate Create CRUD Functions
        crud_base_template=$(cat ./templates/crud_templates.txt | grep -e "<<CRUD_CREATE>>" -A11 | tail -11)
        filled_crud_base_template=$(echo "$crud_base_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$crud_cc/g")
        filled_crud_base_template=$(echo "$filled_crud_base_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$crud/g")
        pop_file=$(awk -v var="$filled_crud_base_template" '{gsub(/{{ CRUDS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT

        ## Populate with the relevant table fields
        crud_cols=$(jq -r ' .tables[] | select(.name == "'$crud'") | .columns[] | [.column_name, .column_type] | join(",") ' $CONFIG_NAME)
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

        # Generate Get All CRUD Functions
        crud_get_all_template=$(cat ./templates/crud_templates.txt | grep -e "<<CRUD_GET_ALL>>" -A4 | tail -4)
        filled_crud_get_all_template=$(echo "$crud_get_all_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$crud_cc/g")
        filled_crud_get_all_template=$(echo "$filled_crud_get_all_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$crud/g")
        pop_file=$(awk -v var="$filled_crud_get_all_template" '{gsub(/{{ CRUDS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT

        # Generate Get By ID CRUD Functions
        crud_get_by_id_template=$(cat ./templates/crud_templates.txt | grep -e "<<CRUD_GET_BY_ID>>" -A4 | tail -4)
        filled_crud_get_by_id_template=$(echo "$crud_get_by_id_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$crud_cc/g")
        filled_crud_get_by_id_template=$(echo "$filled_crud_get_by_id_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$crud/g")
        pop_file=$(awk -v var="$filled_crud_get_by_id_template" '{gsub(/{{ CRUDS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT
        
        # Generate Update CRUD Functions
        crud_update_template=$(cat ./templates/crud_templates.txt | grep -e "<<CRUD_UPDATE>>" -A16 | tail -16)
        filled_crud_update_template=$(echo "$crud_update_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$crud_cc/g")
        filled_crud_update_template=$(echo "$filled_crud_update_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$crud/g")
        pop_file=$(awk -v var="$filled_crud_update_template" '{gsub(/{{ CRUDS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT

        # Generate Delete CRUD Functions
        crud_delete_template=$(cat ./templates/crud_templates.txt | grep -e "<<CRUD_DELETE>>" -A8 | tail -8)
        filled_crud_delete_template=$(echo "$crud_delete_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$crud_cc/g")
        filled_crud_delete_template=$(echo "$filled_crud_delete_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$crud/g")
        pop_file=$(awk -v var="$filled_crud_delete_template" '{gsub(/{{ CRUDS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT
        
        # Cleans template and writes to main file
        clean_template $TEMP_TXT
        cp $TEMP_TXT $file_name

        # Generate the assignment CRUD files (Only one relationship pass)
        curr_crud_relations=$(jq -r ' .relationships[] | select(.table_1 == "'$crud'") | [.table_1, .table_2, .type] | join(",")' $CONFIG_NAME)
        for relation in $curr_crud_relations
        do
            # Process text required for file naming convention 
            to_table=$(echo $relation | cut -d"," -f2)
            to_table_cc=$(to_camel_case $to_table)
            assign_file_name=./$PROJECT_NAME/app/cruds/"$crud_cc"_"$to_table_cc"_assign.py
            table_rel=$(echo $relation | cut -d"," -f3)

            echo ">> Generating Assignments Operations for $to_table"

            # Generate initial ASSIGNMENT CRUD Template
            crud_assign_template=$(cat ./templates/crud_templates.txt | grep -e "<<ASSIGNMENT_BASE>>" -A5 | tail -5)
            echo "$crud_assign_template" > $TEMP_TXT
            sed -r -i "s/\{\{ SELF_CLASS_CC \}\}/$crud_cc/g" $TEMP_TXT
            sed -r -i "s/\{\{ OTHER_CLASS_CC \}\}/$to_table_cc/g" $TEMP_TXT

            # Generating CRUDS for Many-To-Many Relations
            if [[ $table_rel == 'm2m' ]]
            then
                assign_m2m_template=$(cat ./templates/crud_templates.txt | grep -e "<<ASSIGNMENT_m2m>>" -A33 | tail -33)
                filled_assign_m2m_template=$(echo "$assign_m2m_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$crud_cc/g")
                filled_assign_m2m_template=$(echo "$filled_assign_m2m_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$crud/g")
                filled_assign_m2m_template=$(echo "$filled_assign_m2m_template" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$to_table_cc/g")
                filled_assign_m2m_template=$(echo "$filled_assign_m2m_template" | sed -r "s/\{\{ OTHER_CLASS_STD \}\}/$to_table/g")
                pop_file=$(awk -v var="$filled_assign_m2m_template" '{gsub(/{{ ASSIGNMENT_INSERT }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT

            # Generating CRUDS for Many-To-One Relations
            elif [[ $table_rel == 'm2o' ]]
            then
                assign_m2o_template=$(cat ./templates/crud_templates.txt | grep -e "<<ASSIGNMENT_m2o>>" -A35 | tail -35)
                filled_assign_m2o_template=$(echo "$assign_m2o_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$crud_cc/g")
                filled_assign_m2o_template=$(echo "$filled_assign_m2o_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$crud/g")
                filled_assign_m2o_template=$(echo "$filled_assign_m2o_template" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$to_table_cc/g")
                filled_assign_m2o_template=$(echo "$filled_assign_m2o_template" | sed -r "s/\{\{ OTHER_CLASS_STD \}\}/$to_table/g")
                pop_file=$(awk -v var="$filled_assign_m2o_template" '{gsub(/{{ ASSIGNMENT_INSERT }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT

            # Generating CRUDS for One-To-One Relations
            elif [[ $table_rel == 'o2o' ]]
            then
                assign_o2o_template=$(cat ./templates/crud_templates.txt | grep -e "<<ASSIGNMENT_o2o>>" -A32 | tail -32)
                filled_assign_o2o_template=$(echo "$assign_o2o_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$crud_cc/g")
                filled_assign_o2o_template=$(echo "$filled_assign_o2o_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$crud/g")
                filled_assign_o2o_template=$(echo "$filled_assign_o2o_template" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$to_table_cc/g")
                filled_assign_o2o_template=$(echo "$filled_assign_o2o_template" | sed -r "s/\{\{ OTHER_CLASS_STD \}\}/$to_table/g")
                pop_file=$(awk -v var="$filled_assign_o2o_template" '{gsub(/{{ ASSIGNMENT_INSERT }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT

            # Relationship does not exist
            else
                echo "ERROR: RELATIONSHIP DOES NOT EXIST"
            fi

            # Cleans template and writes to main file
            clean_template $TEMP_TXT
            cp $TEMP_TXT $assign_file_name

        done
    done
}