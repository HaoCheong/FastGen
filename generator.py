#!/usr/bin/python3

import json
import re
import os

CONFIG_PATH = "./test.json"
BASE_PATH = "./test_proj"

def read_json(config_path):
    config = None
    with open(config_path, "r") as js:
        config = json.load(js)
        return config

def generate_baseline_dir(base):
    print("======== GENERATE BASELINE DIR ========")
    
    # Generate app baseline
    os.mkdir(f"{base}/app")
    os.mkdir(f"{base}/app/models")
    os.mkdir(f"{base}/app/schemas")
    os.mkdir(f"{base}/app/cruds") 
    os.mkdir(f"{base}/app/endpoints")
    os.mkdir(f"{base}/app/db")

    # Generate test baseline
    # os.mkdir(f"{base}/tests")
    # os.mkdir(f"{base}/tests/populate")
    # os.mkdir(f"{base}/tests/unit")

def tag_replace(file_lines, tag, content):
    ''' Replace a template tag in a file with the content (which is a list of lines to replace it with) '''
    search_tag = "{{ " + tag + " }}"
    new_lines = []
    for line in file_lines:
        new_line = line.replace(search_tag, "".join(content))
        new_lines.append(new_line)

    return new_lines

def tag_remove(file_lines):

    # TODO - Not working perfectly...
    ''' Remove all unused tags '''

    cleaned_lines = []
    for line in file_lines:
        cleaned_line = line
        if re.match(r'\{\{ [A-Z_]+ \}\}', line):
            cleaned_line = re.sub(r'\{\{ [A-Z_]+ \}\}', "", line)
        
        cleaned_lines.append(cleaned_line)   
    
    return cleaned_lines

def generate_models(path, config):

    # For every "Table" in config, it generates the a model file
    all_tables = config['tables'].keys()
    
    # Formats of lines required
    COLUMN_FORMAT = "\n    {} = Column({})"

    new_lines = []

    # Loop through all tables and generate base templates
    for table in all_tables:
        table_obj = config['tables'][table]
        # Replace all the standards
        with open("./templates/model_template", 'r', encoding='utf-8') as t:
            lines = t.readlines()
            new_lines = tag_replace(lines, "CLASS_NAME", [table_obj['name']])
            new_lines = tag_replace(new_lines, "TABLE_NAME", [table_obj['tablename']])

        # Generate all the field columns
        column_line = []
        for column in table_obj['columns']:
            line = ""
            if column['column_type'] == "str":
                line = COLUMN_FORMAT.format(column['column_name'], "String")
            elif column['column_type'] == 'int':
                line = COLUMN_FORMAT.format(column['column_name'], "Integer")

            column_line.append(line)
        
        new_lines = tag_replace(new_lines, "COLUMNS", ["".join(column_line)])

def generate_schemas(path, config):
    pass

def generate_base_cruds(path, config):
    pass

def generate_rel_cruds(path, config):
    pass

def generate_base_endpoints(path, config):
    pass

def generate_rel_endpoints(path, config):
    pass

def generate_main(path, config):
    pass

def generate_database(path, config):
    pass

def generate_helper(path, config):
    pass


if __name__ == "__main__":

    # Get config
    config = read_json(CONFIG_PATH)

    # TODO - Validate Values

    # Generate Base directories Directories (app/crudsd)
    # generate_baseline_dir(BASE_PATH)
    
    # # Generate Models
    generate_models(BASE_PATH, config)

    # tag_replace("ASSOCIATE", [])