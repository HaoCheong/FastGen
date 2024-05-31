# Replaces all the tags of a given line with a replaced word
function tag_replace() {
    local operative_line=$1
    local tag_word=$2
    local replaced_word=$3

    local new_line=$(echo "$operative_line" | sed -r "s/\{\{ $tag_word \}\}/$replaced_word/g")
    echo "$new_line"
}

# Get the base templates and the requisite lines
function template_getter() {
    local template_file_path=$1
    local template_tag=$2
    local template_line_count=$3
    
    local template=$(cat $template_file_path | grep -e $template_tag -A$template_line_count | tail -$template_line_count)
    echo "$template"
}

# Do a newline replace
function newline_replace() {
    local final_line=$1
    res=$(echo "$final_line" | sed 's/\\n/\\\\n/g')
    echo "$res"
}

# Get all the columns for a given table
function get_table_column() {
    local table_name=$1
    local tables=$(jq -r ' .tables[] | select(.name == "'$table_name'") | .columns[] | [.column_name, .column_type] | join(",") ' $CONFIG_NAME)
    echo "$tables"
}

# Get all tables
function get_all_tables() {
    local table=$(jq -r '.tables[] | .name ' $CONFIG_NAME)
    echo "$table"
}

# Converts a given word to camel case
function to_camel_case() {
    
    local var_name=$1
    local cc_var_name=$(echo "$var_name" | sed -r "s/([a-z])([A-Z])/\1_\L\2/g; s/([A-Z])([A-Z])([a-z])/\L\1\L\2_\3/g" | tr '[:upper:]' '[:lower:]')
    echo "$cc_var_name"
}

# Validates relationship gener
function validate_rel() {
    # Check if all the fields in relationships are valid table name
    rel_tables=$(jq -r ' .relationships[] | [.table_1, .table_2] | join("\n") ' $CONFIG_NAME | sort | uniq)
    all_tables=$(get_all_tables)
    
    if [[ ! -z "$rel_tables" ]]
    then
        if grep -qvxF "$(printf '%s\n' "${all_tables[@]}")" <<< "$rel_tables"
        then
            echo "ERROR: Table in relationship does not have existing model"
            exit
        fi
    fi

    # Check if all the rels are valid (m2m, o2o, m2o)
    for rel in $(jq -r ' .relationships[] | .type ' $CONFIG_NAME | sort | uniq)
    do
        if [[ $rel != 'm2m' ]] && [[ $rel != 'm2o' ]] && [[ $rel != 'o2o' ]]
        then
            echo "ERROR: Unknown relations ship. Only allow m2m, m2o, and o2o"
            echo "$rel"
            exit
        fi
    done

    # Check if there are repeated rels
    dup_rel=$(jq -r ' .relationships[] | [.table_1, .table_2, .type] | join(",")' $CONFIG_NAME | uniq -d)
    if [[ ! -z $dup_rel ]]
    then
        echo "ERROR: Duplicate relations detected"
        echo "$dup_rel"
        exit
    fi

    # Checks if an unsupported data type was included
    for col_type in $(jq -r ' .tables[] | .columns[] | .column_type ' $CONFIG_NAME | sort | uniq)
    do 
        if [[ $col_type != 'str' ]] && [[ $col_type != 'int' ]] && [[ $col_type != 'datetime' ]] && [[ $col_type != 'json' ]]
        then
            echo "ERROR: Unsupported column type detected (str, int, datetime, json)"
            echo "$col_type"
            exit
        fi
    done
}