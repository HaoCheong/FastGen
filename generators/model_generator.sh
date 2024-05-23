# Model generators - Create the necessary Model files for given the models

# Generates the Model Files
function generate_models() {
    echo "======== GENERATE MODELS FILES ========"

    # Iterate over each model to generate a file per model
    for model in $(get_all_tables)
    do

        echo "> Generating model for $model"

        # Process text required for file naming convention 
        model_cc=$(to_camel_case $model)
        file_name=./$PROJECT_NAME/app/models/"$model_cc"_model.py
        table_name=$(jq -r '.tables[] | select(.name == "'$model'") | .tablename ' $CONFIG_NAME)

        # Generates the initial Model based template
        model_template=$(cat ./templates/model_templates.txt | grep -e "<<MODEL_BASE>>" -A16 | tail -16)
        echo "$model_template" > $TEMP_TXT
        sed -r -i "s/\{\{ SELF_CLASS_STD \}\}/$model/g" $TEMP_TXT
        sed -r -i "s/\{\{ TABLE_NAME \}\}/$table_name/g" $TEMP_TXT

        ## Populate with the relevant table column fields
        model_cols=$(get_table_column $model)
        for cols in $model_cols
        do
            # Get column name and type
            model_col_name=$(echo $cols | cut -d"," -f1)
            model_col_type=$(echo $cols | cut -d"," -f2)
            
            # Add new string column in model
            if [[ $model_col_type == 'str' ]]
            then
                model_column_str=$(cat ./templates/model_templates.txt | grep -e "<<COLUMN_STRING>>" -A2 | tail -2)
                filled_model_column_str=$(echo "$model_column_str" | sed -r "s/\{\{ COLUMN_NAME \}\}/$model_col_name/g")
                filled_model_column_str=$(echo "$filled_model_column_str" | sed 's/\\n/\\\\n/g')
                pop_file=$(awk -v var="$filled_model_column_str" '{gsub(/{{ COLUMNS }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT

            # Add new integer column in model
            elif [[ $model_col_type == 'int' ]]
            then
                # Add new integer column in model
                model_column_int=$(cat ./templates/model_templates.txt | grep -e "<<COLUMN_INTEGER>>" -A2 | tail -2)
                filled_model_column_int=$(echo "$model_column_int" | sed -r "s/\{\{ COLUMN_NAME \}\}/$model_col_name/g")
                filled_model_column_int=$(echo "$filled_model_column_int" | sed -r 's/\\n/\\\\n/g')
                pop_file=$(awk -v var="$filled_model_column_int" '{gsub(/{{ COLUMNS }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                
            # Add new json column in model
            elif [[ $model_col_type == 'json' ]]
            then
                model_column_json=$(cat ./templates/model_templates.txt | grep -e "<<COLUMN_JSON>>" -A2 | tail -2)
                filled_model_column_json=$(echo "$model_column_json" | sed -r "s/\{\{ COLUMN_NAME \}\}/$model_col_name/g")
                filled_model_column_json=$(echo "$filled_model_column_json" | sed -r 's/\\n/\\\\n/g')
                pop_file=$(awk -v var="$filled_model_column_json" '{gsub(/{{ COLUMNS }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                
            # Add new datetime column in model
            elif [[ $model_col_type == 'datetime' ]]
            then
                model_column_datetime=$(cat ./templates/model_templates.txt | grep -e "<<COLUMN_DATETIME>>" -A2 | tail -2)
                filled_model_column_datetime=$(echo "$model_column_datetime" | sed -r "s/\{\{ COLUMN_NAME \}\}/$model_col_name/g")
                filled_model_column_datetime=$(echo "$filled_model_column_datetime" | sed -r 's/\\n/\\\\n/g')
                pop_file=$(awk -v var="$filled_model_column_datetime" '{gsub(/{{ COLUMNS }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
            fi
        done

        # Relationship first pass - Get all the table_1 of the current table being created
        curr_model_relations=$(jq -r ' .relationships[] | select(.table_1 == "'$model'") | [.table_1, .table_2, .type] | join(",")' $CONFIG_NAME)
        for relation in $curr_model_relations
        do

            # Process text required for file naming convention
            to_table=$(echo $relation | cut -d"," -f2)
            to_table_cc=$(to_camel_case $to_table)
            to_table_name=$(jq -r ' .tables[] | select(.name == "'$to_table'") | .tablename' $CONFIG_NAME)
            table_rel=$(echo $relation | cut -d"," -f3)

            # Generating Model for Many-To-Many Relations
            if [[ $table_rel == 'm2m' ]]
            then
                assoc_table_class="$model""$to_table"Association
                assoc_table_name_lc="$model_cc"_"$to_table_cc"_association

                # Generate the self class Many-To-Many relation
                model_m2m_rel=$(cat ./templates/model_templates.txt | grep -e "<<REL_MANY_TO_MANY>>" -A5 | tail -5)
                filled_model_m2m_rel=$(echo "$model_m2m_rel" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$to_table_cc/g")
                filled_model_m2m_rel=$(echo "$filled_model_m2m_rel" | sed -r "s/\{\{ OTHER_CLASS_STD \}\}/$to_table/g")
                filled_model_m2m_rel=$(echo "$filled_model_m2m_rel" | sed -r "s/\{\{ ASSOC_CLASS_CC \}\}/$assoc_table_name_lc/g")
                filled_model_m2m_rel=$(echo "$filled_model_m2m_rel" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$model_cc/g")
                filled_model_m2m_rel=$(echo "$filled_model_m2m_rel" | sed 's/\\n/\\\\n/g')
                pop_file=$(awk -v var="$filled_model_m2m_rel\n" '{gsub(/{{ RELATION }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                
                # Generate association table
                assoc_table=$(cat ./templates/model_templates.txt | grep -e "<<ASSOC_TABLE>>" -A7 | tail -7)
                filled_assoc_table=$(echo "$assoc_table" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$model/g")
                filled_assoc_table=$(echo "$filled_assoc_table" | sed -r "s/\{\{ OTHER_CLASS_STD \}\}/$to_table/g")
                filled_assoc_table=$(echo "$filled_assoc_table" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$model_cc/g")
                filled_assoc_table=$(echo "$filled_assoc_table" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$to_table_cc/g")
                filled_assoc_table=$(echo "$filled_assoc_table" | sed -r "s/\{\{ SELF_TABLE_NAME \}\}/$table_name/g")
                filled_assoc_table=$(echo "$filled_assoc_table" | sed -r "s/\{\{ OTHER_TABLE_NAME \}\}/$to_table_name/g")
                filled_assoc_table=$(echo "$filled_assoc_table" | sed 's/\\n/\\\\n/g')
                pop_file=$(awk -v var="$filled_assoc_table\n" '{gsub(/{{ ASSOCIATION_OBJECT }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                
            # Generating Model for Many-To-One Relations
            elif [[ $table_rel == 'm2o' ]]
            then
                model_m2o_rel=$(cat ./templates/model_templates.txt | grep -e "<<REL_MANY_TO_ONE>>" -A5 | tail -5)
                filled_model_m2o_rel=$(echo "$model_m2o_rel" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$to_table_cc/g")
                filled_model_m2o_rel=$(echo "$filled_model_m2o_rel" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$model_cc/g")
                filled_model_m2o_rel=$(echo "$filled_model_m2o_rel" | sed -r "s/\{\{ OTHER_CLASS_STD \}\}/$to_table/g")
                filled_model_m2o_rel=$(echo "$filled_model_m2o_rel" | sed -r "s/\{\{ OTHER_TABLE_NAME \}\}/$to_table_name/g")
                filled_model_m2o_rel=$(echo "$filled_model_m2o_rel" | sed 's/\\n/\\\\n/g')
                pop_file=$(awk -v var="$filled_model_m2o_rel\n" '{gsub(/{{ RELATION }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                
            # Generating Model for One-To-One Relations
            elif [[ $table_rel == 'o2o' ]]
            then
                model_o2o_rel=$(cat ./templates/model_templates.txt | grep -e "<<REL_ONE_TO_ONE>>" -A4 | tail -4)
                filled_model_o2o_rel=$(echo "$model_o2o_rel" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$to_table_cc/g")
                filled_model_o2o_rel=$(echo "$filled_model_o2o_rel" | sed -r "s/\{\{ OTHER_CLASS_STD \}\}/$to_table/g")
                filled_model_o2o_rel=$(echo "$filled_model_o2o_rel" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$model_cc/g")
                filled_model_o2o_rel=$(echo "$filled_model_o2o_rel" | sed -r "s/\{\{ OTHER_TABLE_NAME \}\}/$to_table_name/g")
                filled_model_o2o_rel=$(echo "$filled_model_o2o_rel" | sed 's/\\n/\\\\n/g')
                pop_file=$(awk -v var="$filled_model_o2o_rel\n" '{gsub(/{{ RELATION }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                
            # Relationship does not exist
            else
                echo "ERROR: RELATIONSHIP DOES NOT EXIST"
            fi
        done

        # Relationship second pass - Get all the table_2 of the current table being created
        curr_model_relations=$(jq -r ' .relationships[] | select(.table_2 == "'$model'") | [.table_2, .table_1, .type] | join(",")' $CONFIG_NAME)
        for relation in $curr_model_relations
        do
            # Process text required for file naming convention 
            from_table=$(echo $relation | cut -d"," -f2)
            from_table_cc=$(to_camel_case $from_table)
            table_rel=$(echo $relation | cut -d"," -f3)

            # Generating Link Models for Many-To-Many Relations
            if [[ $table_rel == 'm2m' ]]
            then
                model_m2m_link_rel=$(cat ./templates/model_templates.txt | grep -e "<<LINK_REL_MANY_TO_MANY>>" -A3 | tail -3)
                filled_model_m2m_link_rel=$(echo "$model_m2m_link_rel" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$from_table_cc/g")
                filled_model_m2m_link_rel=$(echo "$filled_model_m2m_link_rel" | sed -r "s/\{\{ OTHER_CLASS_STD \}\}/$from_table/g")
                filled_model_m2m_link_rel=$(echo "$filled_model_m2m_link_rel" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$model_cc/g")
                pop_file=$(awk -v var="$filled_model_m2m_link_rel\n" '{gsub(/{{ RELATION }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                
            # Generating Link Models for Many-To-One Relations
            elif [[ $table_rel == 'm2o' ]]
            then
                model_m2o_link_rel=$(cat ./templates/model_templates.txt | grep -e "<<LINK_REL_MANY_TO_ONE>>" -A3 | tail -3)
                filled_model_m2o_link_rel=$(echo "$model_m2o_link_rel" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$from_table_cc/g")
                filled_model_m2o_link_rel=$(echo "$filled_model_m2o_link_rel" | sed -r "s/\{\{ OTHER_CLASS_STD \}\}/$from_table/g")
                filled_model_m2o_link_rel=$(echo "$filled_model_m2o_link_rel" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$model_cc/g")
                pop_file=$(awk -v var="$filled_model_m2o_link_rel\n" '{gsub(/{{ RELATION }}/, var); print}' $TEMP_TXT)
                echo "$pop_file" > $TEMP_TXT
                
            # Generating Link Models for One-To-One Relations
            elif [[ $table_rel == 'o2o' ]]
            then
                model_o2o_link_rel=$(cat ./templates/model_templates.txt | grep -e "<<LINK_REL_ONE_TO_ONE>>" -A3 | tail -3)
                filled_model_o2o_link_rel=$(echo "$model_o2o_link_rel" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$from_table_cc/g")
                filled_model_o2o_link_rel=$(echo "$filled_model_o2o_link_rel" | sed -r "s/\{\{ OTHER_CLASS_STD \}\}/$from_table/g")
                filled_model_o2o_link_rel=$(echo "$filled_model_o2o_link_rel" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$model_cc/g")
                pop_file=$(awk -v var="$filled_model_o2o_link_rel\n" '{gsub(/{{ RELATION }}/, var); print}' $TEMP_TXT)
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

# A lot of repeated code because of similar sed (can be refactored)