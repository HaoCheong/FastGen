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

function newline_replace() {
    local final_line=$1
    res=$(echo "$final_line" | sed 's/\\n/\\\\n/g')
    echo "$res"
}

# 
function get_table_column() {
    local table_name=$1
    local tables=$(jq -r ' .tables[] | select(.name == "'$table_name'") | .columns[] | [.column_name, .column_type] | join(",") ' $CONFIG_NAME)
    echo "$tables"
}

function get_all_tables() {
    local table=$(jq -r '.tables[] | .name ' $CONFIG_NAME)
    echo "$table"
}

# function get_relation_ship() {
#     local inv_flag=$1 # Dictates if it is table_1 -> table_2 or the inverse table_2 to table_1
#     if [[ $inv_flag == 1 ]]; then
#         echo
#     else

#     fi
# }

# Converts a given word to camel case
function to_camel_case() {
    
    local var_name=$1
    local cc_var_name=$(echo "$var_name" | sed -r "s/([a-z])([A-Z])/\1_\L\2/g; s/([A-Z])([A-Z])([a-z])/\L\1\L\2_\3/g" | tr '[:upper:]' '[:lower:]')
    echo "$cc_var_name"
}