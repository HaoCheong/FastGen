#!/usr/bin/python3

import json
import os

CONFIG_PATH = "./config.json"
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

def tag_replace(file, tag, content):
    ''' Replace a template tag in a file with the content (which is a list of lines to replace it with) '''
    search_tag = "{{ " + tag + " }}"
    print("search_tag", search_tag)



def generate_models(path, config):

    # For every "Table" in config, it generates the a model file
    all_tables = config['tables']
    all_relationships = config['relationships']
    
    for table in all_tables:
        # Write out all the base none relation 
        pass

        # Write out all the relation

    pass

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

    # # Generate Base directories Directories (app/crudsd)
    # generate_baseline_dir(BASE_PATH)
    
    # # Generate Models
    # generate_models(BASE_PATH, config)

    # tag_replace("ASSOCIATE", [])