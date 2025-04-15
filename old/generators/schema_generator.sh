# Schema generators - Create the necessary Schema files given the models

# Generates the Schema Files
function generate_schemas() {
    echo "======== GENERATE SCHEMA FILES ========"

    # For every instance of schemas files
    for schema in $(jq -r '.tables[] | .name ' $CONFIG_NAME)
    do
        echo "> Generating schema for $schema"

        # Process text required for file naming convention
        schema_cc=$(to_camel_case $schema)
        file_name=./$PROJECT_NAME/app/schemas/"$schema_cc"_schemas.py
        table_name=$(jq -r '.tables[] | select(.name == "'$schema'") | .tablename ' $CONFIG_NAME)

        # Generates the initial Schema based template
        schema_template=$(cat ./templates/schema_templates.txt | grep -e "<<SCHEMA_BASE>>" -A7 | tail -7)
        filled_schema_template=$(echo "$schema_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$schema/g")
        echo "$filled_schema_template" > $TEMP_TXT

        schema_base_template=$(cat ./templates/schema_templates.txt | grep -e "<<BASE_SCHEMA_CLASS>>" -A8 | tail -8)
        filled_schema_base_template=$(echo "$schema_base_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$schema/g")
        pop_file=$(awk -v var="$filled_schema_base_template" '{gsub(/{{ SCHEMAS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT
        
        ## Populate with the relevant table fields
        schema_cols=$(jq -r ' .tables[] | select(.name == "'$schema'") | .columns[] | [.column_name, .column_type] | join(",") ' $CONFIG_NAME)
        for cols in $schema_cols
        do

            schema_col_name=$(echo $cols | cut -d"," -f1)
            schema_col_type=$(echo $cols | cut -d"," -f2)

            # Add new string column in schema
            if [[ $schema_col_type == 'str' ]]
            then
                schema_column_str=$(cat ./templates/schema_templates.txt | grep -e "<<SCHEMAS_STRING>>" -A2 | tail -2)
                filled_schema_column_str=$(echo "$schema_column_str" | sed -r "s/\{\{ COLUMN_NAME \}\}/$schema_col_name/g")
                filled_schema_column_str=$(echo "$filled_schema_column_str" | sed 's/\\n/\\\\n/g')
                pop_file=$(awk -v var="$filled_schema_column_str" '{gsub(/{{ SCHEMA_TYPES }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                
            # Add new integer column in schema
            elif [[ $schema_col_type == 'int' ]]
            then
                schema_column_int=$(cat ./templates/schema_templates.txt | grep -e "<<SCHEMAS_INTEGER>>" -A2 | tail -2)
                filled_schema_column_int=$(echo "$schema_column_int" | sed -r "s/\{\{ COLUMN_NAME \}\}/$schema_col_name/g")
                filled_schema_column_int=$(echo "$filled_schema_column_int" | sed 's/\\n/\\\\n/g')
                pop_file=$(awk -v var="$filled_schema_column_int" '{gsub(/{{ SCHEMA_TYPES }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                
            # Add new json column in schema
            elif [[ $schema_col_type == 'json' ]]
            then
                schema_column_json=$(cat ./templates/schema_templates.txt | grep -e "<<SCHEMAS_JSON>>" -A2 | tail -2)
                filled_schema_column_json=$(echo "$schema_column_json" | sed -r "s/\{\{ COLUMN_NAME \}\}/$schema_col_name/g")
                filled_schema_column_json=$(echo "$filled_schema_column_json" | sed 's/\\n/\\\\n/g')
                pop_file=$(awk -v var="$filled_schema_column_json" '{gsub(/{{ SCHEMA_TYPES }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                
            # Add new datetime column in schema
            elif [[ $schema_col_type == 'datetime' ]]
            then
                schema_column_datetime=$(cat ./templates/schema_templates.txt | grep -e "<<SCHEMAS_DATETIME>>" -A2 | tail -2)
                filled_schema_column_datetime=$(echo "$schema_column_datetime" | sed -r "s/\{\{ COLUMN_NAME \}\}/$schema_col_name/g")
                filled_schema_column_datetime=$(echo "$filled_schema_column_datetime" | sed 's/\\n/\\\\n/g')
                pop_file=$(awk -v var="$filled_schema_column_datetime" '{gsub(/{{ SCHEMA_TYPES }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                
            # Relationship does not exist
            else
                echo "ERROR: RELATIONSHIP DOES NOT EXIST"
            fi
        done
        
        # Generating Create Schema
        schema_create_template=$(cat ./templates/schema_templates.txt | grep -e "<<CREATE_SCHEMA_CLASS>>" -A4 | tail -4)
        filled_schema_create_template=$(echo "$schema_create_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$schema/g")
        pop_file=$(awk -v var="$filled_schema_create_template" '{gsub(/{{ SCHEMAS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT
        

        # Generating Read NR Schema
        schema_read_nr_template=$(cat ./templates/schema_templates.txt | grep -e "<<READ_NR_SCHEMA_CLASS>>" -A4 | tail -4)
        filled_schema_read_nr_template=$(echo "$schema_read_nr_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$schema/g")
        pop_file=$(awk -v var="$filled_schema_read_nr_template" '{gsub(/{{ SCHEMAS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT
        

        # Generating READ WR (Needs to do 2 relationship passes, on to-from and another from-to)
        schema_read_wr_template=$(cat ./templates/schema_templates.txt | grep -e "<<READ_WR_SCHEMA_CLASS>>" -A6 | tail -6)
        filled_schema_read_wr_template=$(echo "$schema_read_wr_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$schema/g")
        pop_file=$(awk -v var="$filled_schema_read_wr_template" '{gsub(/{{ SCHEMAS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT
        
        
        # Relationship pass 1: To -> From
        curr_model_relations=$(jq -r ' .relationships[] | select(.table_1 == "'$schema'") | [.table_1, .table_2, .type] | join(",")' $CONFIG_NAME)
        for relation in $curr_model_relations
        do
            # Process text required for file naming convention 
            to_table=$(echo $relation | cut -d"," -f2)
            to_table_cc=$(to_camel_case $to_table)
            table_rel=$(echo $relation | cut -d"," -f3)

            # Generate WR imports base
            schema_import_rel=$(cat ./templates/schema_templates.txt | grep -e "<<WR_IMPORT>>" -A2 | tail -2)
            filled_schema_import_rel=$(echo "$schema_import_rel" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$to_table_cc/g")
            filled_schema_import_rel=$(echo "$filled_schema_import_rel" | sed -r "s/\{\{ OTHER_CLASS_STD \}\}/$to_table/g")
            pop_file=$(awk -v var="$filled_schema_import_rel\n" '{gsub(/{{ WR_IMPORTS }}/, var); print}' $TEMP_TXT)
            echo "$pop_file" > $TEMP_TXT
            
            # Generate Link WR imports for Many-To-Many
            if [[ $table_rel == 'm2m' ]]
            then
                schema_m2m_link_rel=$(cat ./templates/schema_templates.txt | grep -e "<<WR_SCHEMA_LIST>>" -A2 | tail -2)
                filled_schema_m2m_link_rel=$(echo "$schema_m2m_link_rel" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$to_table_cc/g")
                filled_schema_m2m_link_rel=$(echo "$filled_schema_m2m_link_rel" | sed -r "s/\{\{ OTHER_CLASS_STD \}\}/$to_table/g")
                pop_file=$(awk -v var="$filled_schema_m2m_link_rel\n" '{gsub(/{{ WR_SCHEMAS }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                
            # Generate Link WR imports for Many-To-One
            elif [[ $table_rel == 'm2o' ]]
            then
                schema_m2o_link_rel=$(cat ./templates/schema_templates.txt | grep -e "<<WR_SCHEMA_UNION>>" -A2 | tail -2)
                filled_schema_m2o_link_rel=$(echo "$schema_m2o_link_rel" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$to_table_cc/g")
                filled_schema_m2o_link_rel=$(echo "$filled_schema_m2o_link_rel" | sed -r "s/\{\{ OTHER_CLASS_STD \}\}/$to_table/g")
                pop_file=$(awk -v var="$filled_schema_m2o_link_rel\n" '{gsub(/{{ WR_SCHEMAS }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                
            # Generate Link WR imports for One-To-One
            elif [[ $table_rel == 'o2o' ]]
            then
                schema_o2o_link_rel=$(cat ./templates/schema_templates.txt | grep -e "<<WR_SCHEMA_UNION>>" -A2 | tail -2)
                filled_schema_o2o_link_rel=$(echo "$schema_o2o_link_rel" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$to_table_cc/g")
                filled_schema_o2o_link_rel=$(echo "$filled_schema_o2o_link_rel" | sed -r "s/\{\{ OTHER_CLASS_STD \}\}/$to_table/g")
                pop_file=$(awk -v var="$filled_schema_o2o_link_rel\n" '{gsub(/{{ WR_SCHEMAS }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                
            # Relationship does not exist
            else
                echo "ERROR: RELATIONSHIP DOES NOT EXIST"
            fi
        done

        # Relationship pass 2: From -> To
        curr_model_relations=$(jq -r ' .relationships[] | select(.table_2 == "'$schema'") | [.table_2, .table_1, .type] | join(",")' $CONFIG_NAME)
        for relation in $curr_model_relations
        do
            # Process text required for file naming convention 
            from_table=$(echo $relation | cut -d"," -f2)
            from_table_cc=$(to_camel_case $from_table)
            table_rel=$(echo $relation | cut -d"," -f3)

            schema_import_rel=$(cat ./templates/schema_templates.txt | grep -e "<<WR_IMPORT>>" -A2 | tail -2)
            filled_schema_import_rel=$(echo "$schema_import_rel" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$from_table_cc/g")
            filled_schema_import_rel=$(echo "$filled_schema_import_rel" | sed -r "s/\{\{ OTHER_CLASS_STD \}\}/$from_table/g")
            pop_file=$(awk -v var="$filled_schema_import_rel\n" '{gsub(/{{ WR_IMPORTS }}/, var); print}' $TEMP_TXT)
            echo "$pop_file" > $TEMP_TXT
        
            # Generate Reverse link WR imports for Many-To-Many
            if [[ $table_rel == 'm2m' ]]
            then
                schema_m2m_link_rel=$(cat ./templates/schema_templates.txt | grep -e "<<WR_SCHEMA_LIST>>" -A2 | tail -2)
                filled_schema_m2m_link_rel=$(echo "$schema_m2m_link_rel" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$from_table_cc/g")
                filled_schema_m2m_link_rel=$(echo "$filled_schema_m2m_link_rel" | sed -r "s/\{\{ OTHER_CLASS_STD \}\}/$from_table/g")
                pop_file=$(awk -v var="$filled_schema_m2m_link_rel\n" '{gsub(/{{ WR_SCHEMAS }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                
            # Generate Reverse link WR imports for Many-To-One
            elif [[ $table_rel == 'm2o' ]]
            then
                schema_m2o_link_rel=$(cat ./templates/schema_templates.txt | grep -e "<<WR_SCHEMA_LIST>>" -A2 | tail -2)
                filled_schema_m2o_link_rel=$(echo "$schema_m2o_link_rel" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$from_table_cc/g")
                filled_schema_m2o_link_rel=$(echo "$filled_schema_m2o_link_rel" | sed -r "s/\{\{ OTHER_CLASS_STD \}\}/$from_table/g")
                pop_file=$(awk -v var="$filled_schema_m2o_link_rel\n" '{gsub(/{{ WR_SCHEMAS }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                
            # Generate Reverse link WR imports for One-To-One
            elif [[ $table_rel == 'o2o' ]]
            then
                schema_o2o_link_rel=$(cat ./templates/schema_templates.txt | grep -e "<<WR_SCHEMA_UNION>>" -A2 | tail -2)
                filled_schema_o2o_link_rel=$(echo "$schema_o2o_link_rel" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$from_table_cc/g")
                filled_schema_o2o_link_rel=$(echo "$filled_schema_o2o_link_rel" | sed -r "s/\{\{ OTHER_CLASS_STD \}\}/$from_table/g")
                pop_file=$(awk -v var="$filled_schema_o2o_link_rel\n" '{gsub(/{{ WR_SCHEMAS }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                
            # Relationship does not exist
            else
                echo "ERROR: RELATIONSHIP DOES NOT EXIST"
            fi
            
        done

        # Generating Update Schema Class
        schema_update_template=$(cat ./templates/schema_templates.txt | grep -e "<<UPDATE_SCHEMA_CLASS>>" -A5 | tail -5)
        filled_schema_update_template=$(echo "$schema_update_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$schema/g")
        pop_file=$(awk -v var="$filled_schema_update_template" '{gsub(/{{ SCHEMAS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT       

        ## Populate with the relevant schema fields
        for cols in $schema_cols
        do
            schema_col_name=$(echo $cols | cut -d"," -f1)
            schema_col_type=$(echo $cols | cut -d"," -f2)

            # Add new string column in schema
            if [[ $schema_col_type == 'str' ]]
            then
                schema_update_str=$(cat ./templates/schema_templates.txt | grep -e "<<UPDATE_SCHEMA_STRING>>" -A2 | tail -2)
                filled_schema_update_str=$(echo "$schema_update_str" | sed -r "s/\{\{ SCHEMA_NAME \}\}/$schema_col_name/g")
                filled_schema_update_str=$(echo "$filled_schema_update_str" | sed 's/\\n/\\\\n/g')
                pop_file=$(awk -v var="$filled_schema_update_str" '{gsub(/{{ SCHEMAS_UPDATE }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                
            # Add new integer column in schema
            elif [[ $schema_col_type == 'int' ]]
            then
                schema_update_int=$(cat ./templates/schema_templates.txt | grep -e "<<UPDATE_SCHEMA_INTEGER>>" -A2 | tail -2)
                filled_schema_update_int=$(echo "$schema_update_int" | sed -r "s/\{\{ SCHEMA_NAME \}\}/$schema_col_name/g")
                filled_schema_update_int=$(echo "$filled_schema_update_int" | sed 's/\\n/\\\\n/g')
                pop_file=$(awk -v var="$filled_schema_update_int" '{gsub(/{{ SCHEMAS_UPDATE }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                
            # Add new json column in schema
            elif [[ $schema_col_type == 'json' ]]
            then
                schema_update_json=$(cat ./templates/schema_templates.txt | grep -e "<<UPDATE_SCHEMA_JSON>>" -A2 | tail -2)
                filled_schema_update_json=$(echo "$schema_update_json" | sed -r "s/\{\{ SCHEMA_NAME \}\}/$schema_col_name/g")
                filled_schema_update_json=$(echo "$filled_schema_update_json" | sed 's/\\n/\\\\n/g')
                pop_file=$(awk -v var="$filled_schema_update_json" '{gsub(/{{ SCHEMAS_UPDATE }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                
            # Add new datetime column in schema
            elif [[ $schema_col_type == 'datetime' ]]
            then
                schema_update_datetime=$(cat ./templates/schema_templates.txt | grep -e "<<UPDATE_SCHEMA_DATETIME>>" -A2 | tail -2)
                filled_schema_update_datetime=$(echo "$schema_update_datetime" | sed -r "s/\{\{ SCHEMA_NAME \}\}/$schema_col_name/g")
                filled_schema_update_datetime=$(echo "$filled_schema_update_datetime" | sed 's/\\n/\\\\n/g')
                pop_file=$(awk -v var="$filled_schema_update_datetime" '{gsub(/{{ SCHEMAS_UPDATE }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                
            # Relationship does not exist
            else
                echo "ERROR: RELATIONSHIP DOES NOT EXIST"
            fi
            
        done

        # Cleans template and writes to main file
        clean_template $TEMP_TXT
        cp $TEMP_TXT $file_name

    done
}


