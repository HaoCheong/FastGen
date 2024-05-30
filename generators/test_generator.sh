# Generate Unit Tests template
function generate_unit_tests() {
    echo "======== GENERATE UNIT TESTS ========"

    # Generate Conf Test, configuration file containing pytest fixtures
    proj_data=$(jq -r ' .project | [.name, .desc, .version, .database_name] | join("|")' $CONFIG_NAME)
    database_name=$(echo "$proj_data" | cut -d"|" -f4)

    echo "> Generate Conftest Base"

    # Generates the initial conf file base template
    file_name="./$PROJECT_NAME/tests/unit/conftest.py"
    conftest_template=$(cat ./templates/unit_test_templates.txt | grep -e "<<CONFTEST_BASE>>" -A50 | tail -50)
    filled_conftest_template=$(echo "$conftest_template" | sed -r "s/\{\{ DATABASE_NAME \}\}/$database_name/g")
    echo "$filled_conftest_template" > $TEMP_TXT

    # Iterate over each model to generate fixture per model
    for unit in $(jq -r '.tables[] | .name ' $CONFIG_NAME)
    do
        echo ">> Generate Conftest Line for $unit"

        # Process text required for file naming convention 
        unit_cc=$(echo "$unit" | sed -r "s/([a-z])([A-Z])/\1_\L\2/g; s/([A-Z])([A-Z])([a-z])/\L\1\L\2_\3/g" | tr '[:upper:]' '[:lower:]')
        
        # Generates the fixture per model 
        fixture_template=$(cat ./templates/unit_test_templates.txt | grep -e "<<TEST_FIXTURE>>" -A5 | tail -5)
        filled_fixture_template=$(echo "$fixture_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$unit_cc/g")
        pop_file=$(awk -v var="$filled_fixture_template" '{gsub(/{{ TEST_DATA_FIXTURE }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT

    done

    # Cleans template and writes to main file
    clean_template $TEMP_TXT
    cp $TEMP_TXT $file_name

    # Generate Wrappers file, containing API wrappers
    echo "> Generate Wrapper Base"

    # Generates the initial wrapper file base template
    file_name="./$PROJECT_NAME/tests/unit/wrappers.py"
    wrapper_template=$(cat ./templates/unit_test_templates.txt | grep -e "<<WRAPPER_BASE>>" -A19 | tail -19)
    echo "$wrapper_template" > $TEMP_TXT

    # Iterate over each model to generate fixture per model
    for unit in $(jq -r '.tables[] | .name ' $CONFIG_NAME)
    do
        echo ">> Generate Wrappers for $unit"

        unit_cc=$(echo "$unit" | sed -r "s/([a-z])([A-Z])/\1_\L\2/g; s/([A-Z])([A-Z])([a-z])/\L\1\L\2_\3/g" | tr '[:upper:]' '[:lower:]')
          
        # Generate Comment Header
        comment_header_wrapper_template=$(cat ./templates/unit_test_templates.txt | grep -e "<<COMMENT_HEADING_WRAPPER>>" -A3 | tail -3)
        filled_comment_header_wrapper_template=$(echo "$comment_header_wrapper_template" | sed -r "s/\{\{ SELF_CLASS_STD \}\}/$unit/g")
        pop_file=$(awk -v var="$filled_comment_header_wrapper_template" '{gsub(/{{ WRAPPERS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT

        # Generate Create Wrapper
        create_wrapper_template=$(cat ./templates/unit_test_templates.txt | grep -e "<<CREATE_WRAPPER>>" -A6 | tail -6)
        filled_create_wrapper_template=$(echo "$create_wrapper_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$unit_cc/g")
        pop_file=$(awk -v var="$filled_create_wrapper_template" '{gsub(/{{ WRAPPERS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT

        # Generate Get All Wrapper
        get_all_wrapper_template=$(cat ./templates/unit_test_templates.txt | grep -e "<<GET_ALL_WRAPPER>>" -A6 | tail -6)
        filled_get_all_wrapper_template=$(echo "$get_all_wrapper_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$unit_cc/g")
        pop_file=$(awk -v var="$filled_get_all_wrapper_template" '{gsub(/{{ WRAPPERS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT

        # Generate Get By ID Wrapper
        get_by_id_wrapper_template=$(cat ./templates/unit_test_templates.txt | grep -e "<<GET_BY_ID_WRAPPER>>" -A6 | tail -6)
        filled_get_by_id_wrapper_template=$(echo "$get_by_id_wrapper_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$unit_cc/g")
        pop_file=$(awk -v var="$filled_get_by_id_wrapper_template" '{gsub(/{{ WRAPPERS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT

        # Generate Update Wrapper
        update_wrapper_template=$(cat ./templates/unit_test_templates.txt | grep -e "<<UPDATE_WRAPPER>>" -A6 | tail -6)
        filled_update_wrapper_template=$(echo "$update_wrapper_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$unit_cc/g")
        pop_file=$(awk -v var="$filled_update_wrapper_template" '{gsub(/{{ WRAPPERS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT

        # Generate Delete Wrapper
        delete_wrapper_template=$(cat ./templates/unit_test_templates.txt | grep -e "<<DELETE_WRAPPER>>" -A6 | tail -6)
        filled_delete_wrapper_template=$(echo "$delete_wrapper_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$unit_cc/g")
        pop_file=$(awk -v var="$filled_delete_wrapper_template" '{gsub(/{{ WRAPPERS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT
        
    done

    # Cleans template and writes to main file
    clean_template $TEMP_TXT
    cp $TEMP_TXT $file_name

    echo "> Generate Test Data Base"

    # Generate Test Data base template, data has to created by users afterwards
    file_name="./$PROJECT_NAME/tests/unit/test_data.py"
    test_data_template=$(cat ./templates/unit_test_templates.txt | grep -e "<<TEST_DATA_BASE>>" -A3 | tail -3)
    echo "$test_data_template" > $TEMP_TXT

    # Iterate over each model to generate test data function per model
    for unit in $(jq -r '.tables[] | .name ' $CONFIG_NAME)
    do
        echo ">> Generate Test Data for $unit"

        # Process text required for file naming convention 
        unit_cc=$(echo "$unit" | sed -r "s/([a-z])([A-Z])/\1_\L\2/g; s/([A-Z])([A-Z])([a-z])/\L\1\L\2_\3/g" | tr '[:upper:]' '[:lower:]')
        
        # Generates the test data template function
        test_data_template=$(cat ./templates/unit_test_templates.txt | grep -e "<<TEST_DATA_FUNC>>" -A6 | tail -6)
        filled_test_data_template=$(echo "$test_data_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$unit_cc/g")
        pop_file=$(awk -v var="$filled_test_data_template" '{gsub(/{{ TEST_DATA_FUNCS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT
    done

    # Cleans template and writes to main file
    clean_template $TEMP_TXT
    cp $TEMP_TXT $file_name

    # Generate Unit Tests
    for unit in $(jq -r '.tables[] | .name ' $CONFIG_NAME)
    do
        echo ">> Generate Unit Tests for $unit"
        unit_cc=$(echo "$unit" | sed -r "s/([a-z])([A-Z])/\1_\L\2/g; s/([A-Z])([A-Z])([a-z])/\L\1\L\2_\3/g" | tr '[:upper:]' '[:lower:]')
        
        # Create the Base File
        file_name=./$PROJECT_NAME/tests/unit/"$unit_cc"_tests.py
        unit_template=$(cat ./templates/unit_test_templates.txt | grep -e "<<UNIT_TEST_BASE>>" -A4 | tail -4)
        echo "$unit_template" > $TEMP_TXT

        # Create the CREATE Unit Tests
        create_unit_test_template=$(cat ./templates/unit_test_templates.txt | grep -e "<<CREATE_UNIT_TEST>>" -A5 | tail -5)
        filled_create_unit_test_template=$(echo "$create_unit_test_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$unit_cc/g")
        pop_file=$(awk -v var="$filled_create_unit_test_template" '{gsub(/{{ UNIT_TESTS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT

        # Create the GET ALL Unit Tests
        get_all_unit_test_template=$(cat ./templates/unit_test_templates.txt | grep -e "<<GET_ALL_UNIT_TEST>>" -A16 | tail -16)
        filled_get_all_unit_test_template=$(echo "$get_all_unit_test_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$unit_cc/g")
        pop_file=$(awk -v var="$filled_get_all_unit_test_template" '{gsub(/{{ UNIT_TESTS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT

        # Create the VALID GET BY ID Unit Tests
        valid_get_by_id_unit_test_template=$(cat ./templates/unit_test_templates.txt | grep -e "<<VALID_GET_BY_ID_UNIT_TEST>>" -A13 | tail -13)
        filled_valid_get_by_id_unit_test_template=$(echo "$valid_get_by_id_unit_test_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$unit_cc/g")
        pop_file=$(awk -v var="$filled_valid_get_by_id_unit_test_template" '{gsub(/{{ UNIT_TESTS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT

        # Create the INVALID GET BY ID Unit Tests
        invalid_get_by_id_unit_test_template=$(cat ./templates/unit_test_templates.txt | grep -e "<<INVALID_GET_BY_ID_UNIT_TEST>>" -A7 | tail -7)
        filled_invalid_get_by_id_unit_test_template=$(echo "$invalid_get_by_id_unit_test_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$unit_cc/g")
        pop_file=$(awk -v var="$filled_invalid_get_by_id_unit_test_template" '{gsub(/{{ UNIT_TESTS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT

        # Create the VALID DELETE Unit Tests
        valid_delete_unit_test_template=$(cat ./templates/unit_test_templates.txt | grep -e "<<VALID_DELETE_UNIT_TEST>>" -A7 | tail -7)
        filled_valid_delete_unit_test_template=$(echo "$valid_delete_unit_test_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$unit_cc/g")
        pop_file=$(awk -v var="$filled_valid_delete_unit_test_template" '{gsub(/{{ UNIT_TESTS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT

        # Create the INVALID DELETE Unit Tests
        invalid_delete_unit_test_template=$(cat ./templates/unit_test_templates.txt | grep -e "<<INVALID_DELETE_UNIT_TEST>>" -A8 | tail -8)
        filled_invalid_delete_unit_test_template=$(echo "$invalid_delete_unit_test_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$unit_cc/g")
        pop_file=$(awk -v var="$filled_invalid_delete_unit_test_template" '{gsub(/{{ UNIT_TESTS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT

        # Create the VALID UPDATE Unit Tests
        valid_update_unit_test_template=$(cat ./templates/unit_test_templates.txt | grep -e "<<VALID_UPDATE_UNIT_TEST>>" -A27 | tail -27)
        filled_valid_update_unit_test_template=$(echo "$valid_update_unit_test_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$unit_cc/g")
        pop_file=$(awk -v var="$filled_valid_update_unit_test_template" '{gsub(/{{ UNIT_TESTS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT

        # Create the INVALID UPDATE Unit Tests
        invalid_update_unit_test_template=$(cat ./templates/unit_test_templates.txt | grep -e "<<INVALID_UPDATE_UNIT_TEST>>" -A19 | tail -19)
        filled_invalid_update_unit_test_template=$(echo "$invalid_update_unit_test_template" | sed -r "s/\{\{ SELF_CLASS_CC \}\}/$unit_cc/g")
        pop_file=$(awk -v var="$filled_invalid_update_unit_test_template" '{gsub(/{{ UNIT_TESTS }}/, var); print}' $TEMP_TXT)
        echo "$pop_file" > $TEMP_TXT

        # Cleans template and writes to main file
        clean_template $TEMP_TXT
        cp $TEMP_TXT $file_name

    done
}
