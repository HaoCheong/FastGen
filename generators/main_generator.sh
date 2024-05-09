# Generate remaining files
function generate_main_files() {

    proj_data=$(jq -r ' .project | [.name, .desc, .version, .database_name] | join("|")' $CONFIG_NAME)
    name=$(echo "$proj_data" | cut -d"|" -f1)
    desc=$(echo "$proj_data" | cut -d"|" -f2)
    version=$(echo "$proj_data" | cut -d"|" -f3)
    database_name=$(echo "$proj_data" | cut -d"|" -f4)

    # Generate Database
    file_name="./$PROJECT_NAME/app/database.py"
    database_template=$(cat ./templates/database_templates.txt | grep -e "<<DATABASE_BASE>>" -A16 | tail -16)
    filled_database_template=$(echo "$database_template" | sed -r "s/\{\{ DATABASE_NAME \}\}/$database_name/g")
    echo "$filled_database_template" > $TEMP_TXT
    cp $TEMP_TXT $file_name

    # Generate Metadata
    file_name="./$PROJECT_NAME/app/metadata.py"
    metadata_template=$(cat ./templates/metadata_templates.txt | grep -e "<<METADATA_BASE>>" -A15 | tail -15)
    filled_metadata_template=$(echo "$metadata_template" | sed -r "s/\{\{ PROJECT_TITLE \}\}/$name/g")
    filled_metadata_template=$(echo "$filled_metadata_template" | sed -r "s/\{\{ PROJECT_VERS \}\}/$version/g")
    filled_metadata_template=$(echo "$filled_metadata_template" | sed -r "s/\{\{ PROJECT_DESC \}\}/$desc/g")
    echo "$filled_metadata_template" > $TEMP_TXT

    IFS=$'\n'
    for metadata in $(jq -r '.tables[] | .metadata | [.name, .desc] | join("|")' $CONFIG_NAME)
    do
        title=$(echo "$metadata" | cut -d"|" -f1)
        desc=$(echo "$metadata" | cut -d"|" -f2-)

        metadata_tag_template=$(cat ./templates/metadata_templates.txt | grep -e "<<METADATA_TAG>>" -A6 | tail -6)
        filled_metadata_tag_template=$(echo "$metadata_tag_template" | sed -r "s/\{\{ METADATA_TITLE \}\}/$title/g")
        filled_metadata_tag_template=$(echo "$filled_metadata_tag_template" | sed -r "s/\{\{ METADATA_DESC \}\}/$desc/g")
        filled_metadata_tag_template=$(echo "$filled_metadata_tag_template" | sed 's/\\n/\\\\n/g')
        pop_file=$(awk -v var="$filled_metadata_tag_template" '{gsub(/{{ METADATA_TAGS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT
    done

    for metadata_assign in $(jq -r ' .relationships[] | .table_1 ' $CONFIG_NAME | sort | uniq)
    do
        meta_title=$(jq -r '.tables[] | select(.name == "'$metadata_assign'") | .metadata | .name ' $CONFIG_NAME)

        metadata_assign_tag_template=$(cat ./templates/metadata_templates.txt | grep -e "<<METADATA_ASSIGN_TAG>>" -A6 | tail -6)
        filled_metadata_assign_tag_template=$(echo "$metadata_assign_tag_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$metadata_assign/g")
        filled_metadata_assign_tag_template=$(echo "$metadata_assign_tag_template" | sed -r "s/\{\{ METADATA_TITLE \}\}/$meta_title/g")
        filled_metadata_assign_tag_template=$(echo "$filled_metadata_assign_tag_template" | sed 's/\\n/\\\\n/g')
        pop_file=$(awk -v var="$filled_metadata_assign_tag_template" '{gsub(/{{ METADATA_ASSIGN_TAGS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT
    done

    clean_template $TEMP_TXT
    cp $TEMP_TXT $file_name

    # Generate Main
    file_name="./$PROJECT_NAME/app/main.py"
    main_template=$(cat ./templates/main_templates.txt | grep -e "<<MAIN_BASE>>" -A39 | tail -39)
    echo "$main_template" > $TEMP_TXT

    for table in $(jq -r ' .tables[] | .name ' $CONFIG_NAME)
    do
        table_cc=$(echo "$table" | sed -r "s/([a-z])([A-Z])/\1_\L\2/g; s/([A-Z])([A-Z])([a-z])/\L\1\L\2_\3/g" | tr '[:upper:]' '[:lower:]')
        
        main_import_template=$(cat ./templates/main_templates.txt | grep -e "<<IMPORT_BASE>>" -A2 | tail -2)
        filled_main_import_template=$(echo "$main_import_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$table_cc/g")
        filled_main_import_template=$(echo "$filled_main_import_template" | sed 's/\\n/\\\\n/g')
        pop_file=$(awk -v var="$filled_main_import_template" '{gsub(/{{ MAIN_IMPORTS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT

        main_router_template=$(cat ./templates/main_templates.txt | grep -e "<<ROUTER_BASE>>" -A2 | tail -2)
        filled_main_router_template=$(echo "$main_router_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$table_cc/g")
        filled_main_router_template=$(echo "$filled_main_router_template" | sed 's/\\n/\\\\n/g')
        pop_file=$(awk -v var="$filled_main_router_template" '{gsub(/{{ ROUTER_INCLUDES }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT

    done

    for relation in $(jq -r ' .relationships[] | [.table_1, .table_2, .type] | join("|")' $CONFIG_NAME)
    do

        from_table=$(echo "$relation" | cut -d"|" -f1)
        from_table_cc=$(echo "$from_table" | sed -r "s/([a-z])([A-Z])/\1_\L\2/g; s/([A-Z])([A-Z])([a-z])/\L\1\L\2_\3/g" | tr '[:upper:]' '[:lower:]')
        
        to_table=$(echo "$relation" | cut -d"|" -f2)
        to_table_cc=$(echo "$to_table" | sed -r "s/([a-z])([A-Z])/\1_\L\2/g; s/([A-Z])([A-Z])([a-z])/\L\1\L\2_\3/g" | tr '[:upper:]' '[:lower:]')

        assign_import_template=$(cat ./templates/main_templates.txt | grep -e "<<IMPORT_ASSIGNMENT_BASE>>" -A2 | tail -2)
        filled_assign_import_template=$(echo "$assign_import_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$from_table_cc/g")
        filled_assign_import_template=$(echo "$filled_assign_import_template" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$to_table_cc/g")
        filled_assign_import_template=$(echo "$filled_assign_import_template" | sed 's/\\n/\\\\n/g')
        pop_file=$(awk -v var="$filled_assign_import_template" '{gsub(/{{ MAIN_IMPORTS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT

        assign_router_template=$(cat ./templates/main_templates.txt | grep -e "<<ROUTER_ASSIGNMENT_BASE>>" -A2 | tail -2)
        filled_assign_router_template=$(echo "$assign_router_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$from_table_cc/g")
        filled_assign_router_template=$(echo "$filled_assign_router_template" | sed -r "s/\{\{ OTHER_CLASS_CC \}\}/$to_table_cc/g")
        filled_assign_router_template=$(echo "$filled_assign_router_template" | sed 's/\\n/\\\\n/g')
        
        pop_file=$(awk -v var="$filled_assign_router_template" '{gsub(/{{ ROUTER_INCLUDES }}/, var); print}' $TEMP_TXT)

        echo "$pop_file" > $TEMP_TXT
    done

    clean_template $TEMP_TXT
    cp $TEMP_TXT $file_name

    # Generate Helper
    cp ./templates/helpers_templates.txt ./$PROJECT_NAME/app/helpers.py

    cp ./templates/requirements_template.txt ./$PROJECT_NAME/requirements.txt
}