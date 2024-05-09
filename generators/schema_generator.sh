function generate_schemas() {
    echo "======== GENERATE SCHEMA FILES ========"

    # For every instance of schemas files
    for schema in $(jq -r '.tables[] | .name ' $CONFIG_NAME)
    do

        # Generating base file
        echo "> Generating schema for $schema"
        schema_cc=$(echo "$schema" | sed -r "s/([a-z])([A-Z])/\1_\L\2/g; s/([A-Z])([A-Z])([a-z])/\L\1\L\2_\3/g" | tr '[:upper:]' '[:lower:]')
        file_name=./$PROJECT_NAME/app/schemas/"$schema_cc"_schemas.py
        table_name=$(jq -r '.tables[] | select(.name == "'$schema'") | .tablename ' $CONFIG_NAME)

        schema_template=$(cat ./templates/schema_templates.txt | grep -e "<<SCHEMA_BASE>>" -A7 | tail -7)
        filled_schema_template=$(echo "$schema_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$schema/g")
        echo "$filled_schema_template" > $TEMP_TXT

        # Generating BASE
        schema_base_template=$(cat ./templates/schema_templates.txt | grep -e "<<BASE_SCHEMA_CLASS>>" -A8 | tail -8)
        filled_schema_base_template=$(echo "$schema_base_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$schema/g")
        pop_file=$(awk -v var="$filled_schema_base_template" '{gsub(/{{ SCHEMAS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT
        
        
        schema_cols=$(jq -r ' .tables[] | select(.name == "'$schema'") | .columns[] | [.column_name, .column_type] | join(",") ' $CONFIG_NAME)
        for cols in $schema_cols
        do

            schema_col_name=$(echo $cols | cut -d"," -f1)
            schema_col_type=$(echo $cols | cut -d"," -f2)

            if [[ $schema_col_type == 'str' ]]
            then

                # Generate the string schema for base class
                schema_column_str=$(cat ./templates/schema_templates.txt | grep -e "<<SCHEMAS_STRING>>" -A2 | tail -2)
                filled_schema_column_str=$(echo "$schema_column_str" | sed -r "s/\{\{ COLUMN_NAME \}\}/$schema_col_name/g")
                filled_schema_column_str=$(echo "$filled_schema_column_str" | sed 's/\\n/\\\\n/g')
                pop_file=$(awk -v var="$filled_schema_column_str" '{gsub(/{{ SCHEMA_TYPES }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                

            elif [[ $schema_col_type == 'int' ]]
            then

                # Generate the integer schema for base class
                schema_column_int=$(cat ./templates/schema_templates.txt | grep -e "<<SCHEMAS_INTEGER>>" -A2 | tail -2)
                filled_schema_column_int=$(echo "$schema_column_int" | sed -r "s/\{\{ COLUMN_NAME \}\}/$schema_col_name/g")
                filled_schema_column_int=$(echo "$filled_schema_column_int" | sed 's/\\n/\\\\n/g')
                pop_file=$(awk -v var="$filled_schema_column_int" '{gsub(/{{ SCHEMA_TYPES }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                

            elif [[ $schema_col_type == 'json' ]]
            then
                
                # Generate the json schema for base class
                schema_column_json=$(cat ./templates/schema_templates.txt | grep -e "<<SCHEMAS_JSON>>" -A2 | tail -2)
                filled_schema_column_json=$(echo "$schema_column_json" | sed -r "s/\{\{ COLUMN_NAME \}\}/$schema_col_name/g")
                filled_schema_column_json=$(echo "$filled_schema_column_json" | sed 's/\\n/\\\\n/g')
                pop_file=$(awk -v var="$filled_schema_column_json" '{gsub(/{{ SCHEMA_TYPES }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                

            elif [[ $schema_col_type == 'datetime' ]]
            then    
                
                # Generate the datetime schema for base class
                schema_column_datetime=$(cat ./templates/schema_templates.txt | grep -e "<<SCHEMAS_DATETIME>>" -A2 | tail -2)
                filled_schema_column_datetime=$(echo "$schema_column_datetime" | sed -r "s/\{\{ COLUMN_NAME \}\}/$schema_col_name/g")
                filled_schema_column_datetime=$(echo "$filled_schema_column_datetime" | sed 's/\\n/\\\\n/g')
                pop_file=$(awk -v var="$filled_schema_column_datetime" '{gsub(/{{ SCHEMA_TYPES }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                

            else
                echo "ERROR: RELATIONSHIP DOES NOT EXIST"
            fi
        done
        
        # Generating CREATE
        schema_create_template=$(cat ./templates/schema_templates.txt | grep -e "<<CREATE_SCHEMA_CLASS>>" -A4 | tail -4)
        filled_schema_create_template=$(echo "$schema_create_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$schema/g")
        pop_file=$(awk -v var="$filled_schema_create_template" '{gsub(/{{ SCHEMAS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT
        

        # Generating READ NR
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
            to_table=$(echo $relation | cut -d"," -f2)
            to_table_cc=$(echo "$to_table" | sed -r "s/([a-z])([A-Z])/\1_\L\2/g; s/([A-Z])([A-Z])([a-z])/\L\1\L\2_\3/g" | tr '[:upper:]' '[:lower:]')
            table_rel=$(echo $relation | cut -d"," -f3)

            schema_import_rel=$(cat ./templates/schema_templates.txt | grep -e "<<WR_IMPORT>>" -A2 | tail -2)
            filled_schema_import_rel=$(echo "$schema_import_rel" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$to_table_cc/g")
            filled_schema_import_rel=$(echo "$filled_schema_import_rel" | sed -r "s/\{\{ OTHER_CLASS_STD \}\}/$to_table/g")
            pop_file=$(awk -v var="$filled_schema_import_rel\n" '{gsub(/{{ WR_IMPORTS }}/, var); print}' $TEMP_TXT)
            echo "$pop_file" > $TEMP_TXT
            

            if [[ $table_rel == 'm2m' ]]
            then

                # Generate Link m2m schema import
                schema_m2m_link_rel=$(cat ./templates/schema_templates.txt | grep -e "<<WR_SCHEMA_LIST>>" -A2 | tail -2)
                filled_schema_m2m_link_rel=$(echo "$schema_m2m_link_rel" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$to_table_cc/g")
                filled_schema_m2m_link_rel=$(echo "$filled_schema_m2m_link_rel" | sed -r "s/\{\{ OTHER_CLASS_STD \}\}/$to_table/g")
                pop_file=$(awk -v var="$filled_schema_m2m_link_rel\n" '{gsub(/{{ WR_SCHEMAS }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                
            
            elif [[ $table_rel == 'm2o' ]]
            then

                # Generate Link m2o schema import
                schema_m2o_link_rel=$(cat ./templates/schema_templates.txt | grep -e "<<WR_SCHEMA_UNION>>" -A2 | tail -2)
                filled_schema_m2o_link_rel=$(echo "$schema_m2o_link_rel" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$to_table_cc/g")
                filled_schema_m2o_link_rel=$(echo "$filled_schema_m2o_link_rel" | sed -r "s/\{\{ OTHER_CLASS_STD \}\}/$to_table/g")
                pop_file=$(awk -v var="$filled_schema_m2o_link_rel\n" '{gsub(/{{ WR_SCHEMAS }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                
                
            elif [[ $table_rel == 'o2o' ]]
            then

                # Generate Link o2o schema import
                schema_o2o_link_rel=$(cat ./templates/schema_templates.txt | grep -e "<<WR_SCHEMA_UNION>>" -A2 | tail -2)
                filled_schema_o2o_link_rel=$(echo "$schema_o2o_link_rel" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$to_table_cc/g")
                filled_schema_o2o_link_rel=$(echo "$filled_schema_o2o_link_rel" | sed -r "s/\{\{ OTHER_CLASS_STD \}\}/$to_table/g")
                pop_file=$(awk -v var="$filled_schema_o2o_link_rel\n" '{gsub(/{{ WR_SCHEMAS }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                

            else
                echo "ERROR: RELATIONSHIP DOES NOT EXIST"
            fi
        done

        # Relationship pass 2: From -> To
        curr_model_relations=$(jq -r ' .relationships[] | select(.table_2 == "'$schema'") | [.table_2, .table_1, .type] | join(",")' $CONFIG_NAME)
        for relation in $curr_model_relations
        do
            from_table=$(echo $relation | cut -d"," -f2)
            from_table_cc=$(echo "$from_table" | sed -r "s/([a-z])([A-Z])/\1_\L\2/g; s/([A-Z])([A-Z])([a-z])/\L\1\L\2_\3/g" | tr '[:upper:]' '[:lower:]')
            table_rel=$(echo $relation | cut -d"," -f3)

            # echo $schema, $from_table, $table_rel

            schema_import_rel=$(cat ./templates/schema_templates.txt | grep -e "<<WR_IMPORT>>" -A2 | tail -2)
            filled_schema_import_rel=$(echo "$schema_import_rel" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$from_table_cc/g")
            filled_schema_import_rel=$(echo "$filled_schema_import_rel" | sed -r "s/\{\{ OTHER_CLASS_STD \}\}/$from_table/g")
            pop_file=$(awk -v var="$filled_schema_import_rel\n" '{gsub(/{{ WR_IMPORTS }}/, var); print}' $TEMP_TXT)
            echo "$pop_file" > $TEMP_TXT
            


            if [[ $table_rel == 'm2m' ]]
            then

                # Generate Link m2m schema import
                schema_m2m_link_rel=$(cat ./templates/schema_templates.txt | grep -e "<<WR_SCHEMA_LIST>>" -A2 | tail -2)
                filled_schema_m2m_link_rel=$(echo "$schema_m2m_link_rel" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$from_table_cc/g")
                filled_schema_m2m_link_rel=$(echo "$filled_schema_m2m_link_rel" | sed -r "s/\{\{ OTHER_CLASS_STD \}\}/$from_table/g")
                pop_file=$(awk -v var="$filled_schema_m2m_link_rel\n" '{gsub(/{{ WR_SCHEMAS }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                
            
            elif [[ $table_rel == 'm2o' ]]
            then

                # Generate Link m2o schema import
                schema_m2o_link_rel=$(cat ./templates/schema_templates.txt | grep -e "<<WR_SCHEMA_LIST>>" -A2 | tail -2)
                filled_schema_m2o_link_rel=$(echo "$schema_m2o_link_rel" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$from_table_cc/g")
                filled_schema_m2o_link_rel=$(echo "$filled_schema_m2o_link_rel" | sed -r "s/\{\{ OTHER_CLASS_STD \}\}/$from_table/g")
                pop_file=$(awk -v var="$filled_schema_m2o_link_rel\n" '{gsub(/{{ WR_SCHEMAS }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                

            elif [[ $table_rel == 'o2o' ]]
            then

                # Generate Link o2o schema import
                schema_o2o_link_rel=$(cat ./templates/schema_templates.txt | grep -e "<<WR_SCHEMA_UNION>>" -A2 | tail -2)
                filled_schema_o2o_link_rel=$(echo "$schema_o2o_link_rel" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$from_table_cc/g")
                filled_schema_o2o_link_rel=$(echo "$filled_schema_o2o_link_rel" | sed -r "s/\{\{ OTHER_CLASS_STD \}\}/$from_table/g")
                pop_file=$(awk -v var="$filled_schema_o2o_link_rel\n" '{gsub(/{{ WR_SCHEMAS }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                

            else
                echo "ERROR: RELATIONSHIP DOES NOT EXIST"
            fi
            
        done

        # Generating Update
        schema_update_template=$(cat ./templates/schema_templates.txt | grep -e "<<UPDATE_SCHEMA_CLASS>>" -A5 | tail -5)
        filled_schema_update_template=$(echo "$schema_update_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$schema/g")
        pop_file=$(awk -v var="$filled_schema_update_template" '{gsub(/{{ SCHEMAS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT

        
        # echo PRE $filled_schema_update_template
        # if [[ -z "$schema_cols" ]]
        # then
        #     filled_schema_update_template=$(echo "$filled_schema_update_template" | sed -r "s/\{\{ SCHEMAS_UPDATE \}\}/pass/g")
        # fi
        
        

        for cols in $schema_cols
        do
            schema_col_name=$(echo $cols | cut -d"," -f1)
            schema_col_type=$(echo $cols | cut -d"," -f2)

            if [[ $schema_col_type == 'str' ]]
            then

                # Generate string update schema
                schema_update_str=$(cat ./templates/schema_templates.txt | grep -e "<<UPDATE_SCHEMA_STRING>>" -A2 | tail -2)
                filled_schema_update_str=$(echo "$schema_update_str" | sed -r "s/\{\{ SCHEMA_NAME \}\}/$schema_col_name/g")
                filled_schema_update_str=$(echo "$filled_schema_update_str" | sed 's/\\n/\\\\n/g')
                pop_file=$(awk -v var="$filled_schema_update_str" '{gsub(/{{ SCHEMAS_UPDATE }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                

            elif [[ $schema_col_type == 'int' ]]
            then
                
                # Generate integer update schema
                schema_update_int=$(cat ./templates/schema_templates.txt | grep -e "<<UPDATE_SCHEMA_INTEGER>>" -A2 | tail -2)
                filled_schema_update_int=$(echo "$schema_update_int" | sed -r "s/\{\{ SCHEMA_NAME \}\}/$schema_col_name/g")
                filled_schema_update_int=$(echo "$filled_schema_update_int" | sed 's/\\n/\\\\n/g')
                pop_file=$(awk -v var="$filled_schema_update_int" '{gsub(/{{ SCHEMAS_UPDATE }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                

            elif [[ $schema_col_type == 'json' ]]
            then

                # Generate json update schema
                schema_update_json=$(cat ./templates/schema_templates.txt | grep -e "<<UPDATE_SCHEMA_JSON>>" -A2 | tail -2)
                filled_schema_update_json=$(echo "$schema_update_json" | sed -r "s/\{\{ SCHEMA_NAME \}\}/$schema_col_name/g")
                filled_schema_update_json=$(echo "$filled_schema_update_json" | sed 's/\\n/\\\\n/g')
                pop_file=$(awk -v var="$filled_schema_update_json" '{gsub(/{{ SCHEMAS_UPDATE }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                

            elif [[ $schema_col_type == 'datetime' ]]
            then    
                
                # Generate datetime update schema
                schema_update_datetime=$(cat ./templates/schema_templates.txt | grep -e "<<UPDATE_SCHEMA_DATETIME>>" -A2 | tail -2)
                filled_schema_update_datetime=$(echo "$schema_update_datetime" | sed -r "s/\{\{ SCHEMA_NAME \}\}/$schema_col_name/g")
                filled_schema_update_datetime=$(echo "$filled_schema_update_datetime" | sed 's/\\n/\\\\n/g')
                pop_file=$(awk -v var="$filled_schema_update_datetime" '{gsub(/{{ SCHEMAS_UPDATE }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                

            else
                echo "ERROR: RELATIONSHIP DOES NOT EXIST"
            fi
            
        done

        clean_template $TEMP_TXT
        cp $TEMP_TXT $file_name

    done

    
}


