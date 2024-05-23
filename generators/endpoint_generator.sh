# Endpoint generators - Create the necessary endpoint router files given the models

# Generate the endpoints
function generate_endpoints() {
    
    echo "======== GENERATE CRUD FILES ========"
    
    # Iterate over each model to generate a endpoint per model
    for endpoint in $(jq -r '.tables[] | .name ' $CONFIG_NAME)
    do
        echo "> Generating Endpoints for $endpoint"

        # Process text required for file naming convention
        endpoint_cc=$(to_camel_case $endpoint)
        file_name=./$PROJECT_NAME/app/endpoints/"$endpoint_cc"_endpoints.py
        table_name=$(jq -r '.tables[] | select(.name == "'$endpoint'") | .tablename ' $CONFIG_NAME)
        meta_table_name=$(jq -r '.tables[] | select(.name == "'$endpoint'") | .metadata | .name ' $CONFIG_NAME)

        # Generates the initial Endpoint based template
        endpoint_template=$(cat ./templates/endpoint_templates.txt | grep -e "<<ENDPOINT_BASE>>" -A12 | tail -12)
        echo "$endpoint_template" > $TEMP_TXT
        sed -r -i "s/\{\{ SELF_CLASS_CC \}\}/$endpoint_cc/g" $TEMP_TXT

        # Generate Create Endpoint Functions
        endpoint_create_template=$(cat ./templates/endpoint_templates.txt | grep -e "<<ENDPOINT_CREATE>>" -A5 | tail -5)
        filled_endpoint_create_template=$(echo "$endpoint_create_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$endpoint_cc/g")
        filled_endpoint_create_template=$(echo "$filled_endpoint_create_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$endpoint/g")
        filled_endpoint_create_template=$(echo "$filled_endpoint_create_template" | sed -r "s/\{\{ META_TABLE_NAME \}\}/$meta_table_name/g")
        pop_file=$(awk -v var="$filled_endpoint_create_template" '{gsub(/{{ ENDPOINT_INSERT }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT

        # Generate Get All Endpoint Functions
        endpoint_get_all_template=$(cat ./templates/endpoint_templates.txt | grep -e "<<ENDPOINT_GET_ALL>>" -A6 | tail -6)
        filled_endpoint_get_all_template=$(echo "$endpoint_get_all_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$endpoint_cc/g")
        filled_endpoint_get_all_template=$(echo "$filled_endpoint_get_all_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$endpoint/g")
        filled_endpoint_get_all_template=$(echo "$filled_endpoint_get_all_template" | sed -r "s/\{\{ META_TABLE_NAME \}\}/$meta_table_name/g")
        pop_file=$(awk -v var="$filled_endpoint_get_all_template" '{gsub(/{{ ENDPOINT_INSERT }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT

        # Generate Get By ID Endpoint Functions
        endpoint_get_by_id_template=$(cat ./templates/endpoint_templates.txt | grep -e "<<ENDPOINT_GET_BY_ID>>" -A9 | tail -9)
        filled_endpoint_get_by_id_template=$(echo "$endpoint_get_by_id_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$endpoint_cc/g")
        filled_endpoint_get_by_id_template=$(echo "$filled_endpoint_get_by_id_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$endpoint/g")
        filled_endpoint_get_by_id_template=$(echo "$filled_endpoint_get_by_id_template" | sed -r "s/\{\{ META_TABLE_NAME \}\}/$meta_table_name/g")
        pop_file=$(awk -v var="$filled_endpoint_get_by_id_template" '{gsub(/{{ ENDPOINT_INSERT }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT
        
        # Generate Update Endpoint Functions
        endpoint_update_template=$(cat ./templates/endpoint_templates.txt | grep -e "<<ENDPOINT_UPDATE>>" -A9 | tail -9)
        filled_endpoint_update_template=$(echo "$endpoint_update_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$endpoint_cc/g")
        filled_endpoint_update_template=$(echo "$filled_endpoint_update_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$endpoint/g")
        filled_endpoint_update_template=$(echo "$filled_endpoint_update_template" | sed -r "s/\{\{ META_TABLE_NAME \}\}/$meta_table_name/g")
        pop_file=$(awk -v var="$filled_endpoint_update_template" '{gsub(/{{ ENDPOINT_INSERT }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT

        # Generate Delete Endpoint Functions
        endpoint_delete_template=$(cat ./templates/endpoint_templates.txt | grep -e "<<ENDPOINT_DELETE>>" -A9 | tail -9)
        filled_endpoint_delete_template=$(echo "$endpoint_delete_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$endpoint_cc/g")
        filled_endpoint_delete_template=$(echo "$filled_endpoint_delete_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$endpoint/g")
        filled_endpoint_delete_template=$(echo "$filled_endpoint_delete_template" | sed -r "s/\{\{ META_TABLE_NAME \}\}/$meta_table_name/g")
        pop_file=$(awk -v var="$filled_endpoint_delete_template" '{gsub(/{{ ENDPOINT_INSERT }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT

        # Cleans template and writes to main file
        clean_template $TEMP_TXT
        cp $TEMP_TXT $file_name

        # Generate the assignment Endpoints files (Only one relationship pass)
        curr_endpoint_relations=$(jq -r ' .relationships[] | select(.table_1 == "'$endpoint'") | [.table_1, .table_2, .type] | join(",")' $CONFIG_NAME)
        for relation in $curr_endpoint_relations
        do
            # Process text required for file naming convention 
            to_table=$(echo $relation | cut -d"," -f2)
            to_table_cc=$(to_camel_case $to_table)
            assign_file_name=./$PROJECT_NAME/app/endpoints/"$endpoint_cc"_"$to_table_cc"_assign_endpoints.py
            table_rel=$(echo $relation | cut -d"," -f3)

            echo ">> Generating Assignments Endpoints for $to_table"

            # Generate initial ASSIGNMENT CRUD Template
            endpoint_assign_template=$(cat ./templates/endpoint_templates.txt | grep -e "<<ENDPOINT_ASSIGN_BASE>>" -A14 | tail -14)
            echo "$endpoint_assign_template" > $TEMP_TXT
            sed -r -i "s/\{\{ SELF_CLASS_CC \}\}/$endpoint_cc/g" $TEMP_TXT
            sed -r -i "s/\{\{ OTHER_CLASS_CC \}\}/$to_table_cc/g" $TEMP_TXT

            # Generating Endpoint for Many-To-Many Relations
            if [[ $table_rel == 'm2m' ]]
            then
                assign_m2m_endpoint_template=$(cat ./templates/endpoint_templates.txt | grep -e "<<ENDPOINT_ASSIGN_m2m>>" -A33 | tail -33)
                filled_assign_m2m_endpoint_template=$(echo "$assign_m2m_endpoint_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$endpoint_cc/g")
                filled_assign_m2m_endpoint_template=$(echo "$filled_assign_m2m_endpoint_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$endpoint/g")
                filled_assign_m2m_endpoint_template=$(echo "$filled_assign_m2m_endpoint_template" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$to_table_cc/g")
                filled_assign_m2m_endpoint_template=$(echo "$filled_assign_m2m_endpoint_template" | sed -r "s/\{\{ OTHER_CLASS_STD \}\}/$to_table/g")
                filled_assign_m2m_endpoint_template=$(echo "$filled_assign_m2m_endpoint_template" | sed -r "s/\{\{ META_TABLE_NAME \}\}/$meta_table_name/g")
                pop_file=$(awk -v var="$filled_assign_m2m_endpoint_template" '{gsub(/{{ ENDPOINT_ASSIGN_INSERT }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT

            # Generating Endpoint for Many-To-One Relations
            elif [[ $table_rel == 'm2o' ]]
            then
                assign_m2o_endpoint_template=$(cat ./templates/endpoint_templates.txt | grep -e "<<ENDPOINT_ASSIGN_m2o>>" -A33 | tail -33)
                filled_assign_m2o_endpoint_template=$(echo "$assign_m2o_endpoint_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$endpoint_cc/g")
                filled_assign_m2o_endpoint_template=$(echo "$filled_assign_m2o_endpoint_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$endpoint/g")
                filled_assign_m2o_endpoint_template=$(echo "$filled_assign_m2o_endpoint_template" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$to_table_cc/g")
                filled_assign_m2o_endpoint_template=$(echo "$filled_assign_m2o_endpoint_template" | sed -r "s/\{\{ OTHER_CLASS_STD \}\}/$to_table/g")
                filled_assign_m2o_endpoint_template=$(echo "$filled_assign_m2o_endpoint_template" | sed -r "s/\{\{ META_TABLE_NAME \}\}/$meta_table_name/g")
                pop_file=$(awk -v var="$filled_assign_m2o_endpoint_template" '{gsub(/{{ ENDPOINT_ASSIGN_INSERT }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT

            # Generating Endpoint for One-To-One Relations 
            elif [[ $table_rel == 'o2o' ]]
            then
                assign_o2o_endpoint_template=$(cat ./templates/endpoint_templates.txt | grep -e "<<ENDPOINT_ASSIGN_o2o>>" -A29 | tail -29)
                filled_assign_o2o_endpoint_template=$(echo "$assign_o2o_endpoint_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$endpoint_cc/g")
                filled_assign_o2o_endpoint_template=$(echo "$filled_assign_o2o_endpoint_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$endpoint/g")
                filled_assign_o2o_endpoint_template=$(echo "$filled_assign_o2o_endpoint_template" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$to_table_cc/g")
                filled_assign_o2o_endpoint_template=$(echo "$filled_assign_o2o_endpoint_template" | sed -r "s/\{\{ OTHER_CLASS_STD \}\}/$to_table/g")
                filled_assign_o2o_endpoint_template=$(echo "$filled_assign_o2o_endpoint_template" | sed -r "s/\{\{ META_TABLE_NAME \}\}/$meta_table_name/g")
                pop_file=$(awk -v var="$filled_assign_o2o_endpoint_template" '{gsub(/{{ ENDPOINT_ASSIGN_INSERT }}/, var); print}' $TEMP_TXT)
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