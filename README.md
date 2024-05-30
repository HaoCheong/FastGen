# FastGen - A FastAPI auto generator

FastGen acts as an automatic boilerplate generator to create basic CRUD apps given a configuration file. 
Idea is to reduce the unneccessary time spent required scaffolding application while avoiding typically human error pitfall.

This will generate the bare necessities and produce a functioning CRUD app. However, several key features of a production ready webapp are not present and should be adjusted accordingly. Features such as:

- Security features (Authenticated + Authorised access to endpoints)
- Unique business logic functions
- Enforcement of constraints necessary to various more complex database
- Reverse Proxy
- Using any other enterprise database management system (PostgreSQL, MySQL, SQL Server, etc.)
	- *SQLAlchemy does provide several configurable options for different DBMS.*

## Notable Files and Directories

### `generators/`

The directory contains all the generators which programmatically update the templates to reflect the configuration file

### `templates/`

The directory contains all the templates of standard fastAPI classes and code required to create the tables

### `generator.sh`

The main trigger file to call and generate the project

## Setup

The script depends on providing a configuration file containing the structure of the models that are to be generated. See the following example (snippet of of test_config.json provided).

```json
{
	"project": {
		"name": "Pets FastAPI",
		"desc": "Project for FastAPI to test",
		"version": "0.0.1",
		"database_name": "pets"
	},
	"tables": [
		{ 
			"name": "Pet",
			"tablename": "pets",
			"metadata": {
				"name": "Pet",
				"desc": "Operations with Pets Owner"
			},
			"columns": [
				{ 
					"column_name": "name",
					"column_type": "str"
				},
				// ** Other column types **
			]
		},
		{ 
			"name": "Owner",
			"tablename": "owners",
			"metadata": {
				"name": "Owner",
				"desc": "Operations with Pets Owners"
			},
			"columns": [
				{ 
					"column_name": "name",
					"column_type": "str"
				},
				// ** Other column types **
			]
		},
		{ 
			"name": "Trainer",
			"tablename": "trainers",
			"metadata": {
				"name": "Trainer",
				"desc": "Operations with Pets Trainers"
			},
			"columns": [
				{ 
					"column_name": "name",
					"column_type": "str"
				},
				// ** Other column types **
			]
		},
		{ 
			"name": "NutritionPlan",
			"tablename": "nutrition_plans",
			"metadata": {
				"name": "NutritionPlan",
				"desc": "Operations with Pets Nutrition Plan"
			},
			"columns": [
				{ 
					"column_name": "name",
					"column_type": "str"
				},
				// ** Other column types **
			]
		}
	],
	"relationships": [
		{
			"table_1": "Pet",
			"table_2": "Owner",
			"type": "m2o"
		},
		{
			"table_1": "Pet",
			"table_2": "Trainer",
			"type": "m2m"
		},
		{
			"table_1": "Pet",
			"table_2": "NutritionPlan",
			"type": "o2o"
		},
		// ** Other possible relationships **
	]
}
```

> As of now, only 4 data types are partially supported (more may come in the future):
> - int: Integer
> - str: String
> - datetime: Date time
> - json: JSON

Relationships are supported and represented as such
```json
// Usage: table_1 has a type relationship with table_2

{
	"table_1": "Pet",
	"table_2": "Owner",
	"type": "m2o"
}

// Pet has a many-to-one type relationship with Owner
```

> Only 3 relationships are supported:
> - Many to Many -> m2m
> - Many to One -> m2o
> - One to One -> o2o


## Usage

### Generating

After a configuration json is created to match the model. Run the following command
```bash
./generator.sh -p <PROJECT_NAME> -c <CONFIGURATION_JSON_FILE>
```

This will generate a directory `<PROJECT_NAME>` using the the provided `<CONFIGURATION_JSON_FILE>`

The following are generated:
- **Model Files**: Models files required to create tables in the database
- **Schema Files**: Schema files for enforced data typing
- **Crud Files**: Interface files to the database layer
- **Endpoint Files**: The endpoint triggers for each model
- **Database Files**: The engine and creation system for the database (uses SQLAlchemy and defaults to using SQLITE configuration)
- **Metadata Files**: Files related to the swagger documentation
- **Test Files**: Files regarding unit testing and configuration

A test configuration `test_config.json` has already a sample setup to have a look

### Running the project

#### Setup Up


While in the root project directory using the bash terminal, assuming your have not yet created a virtual environment start a virtual environment (`.venv`). You only need to be created on the first time.

```bash 
python3 -m venv .venv
```

To start the environment, run the following command
```bash
source .venv/bin/activate
```

Install the dependencies

```bash
pip3 install -r requirements.txt
```

To deactivate the environment after finishing, run the following command

```bash
deactivate
```

#### Starting the project

After setting up the environment and activating it. Run the following command to start the web server

```bash
python3 -m uvicorn app.main:app --reload --port 9876 
```

This will start the webserver pointing at port 9876.

Afterwards you can access the generated documentation on the following webpage: [http:/127.0.0.1:9876/docs](http:/127.0.0.1:9876/docs)



## Testing

Unit test will automatically generate. However, **test data must be provided** in the `test/unit/test_data.py` file. Test data should reflect the what is to be expected to be used in production. 3 should be sufficient.

#### Set up

Setup process is identical to the project setup. Navigate to `Usage -> Running Project -> Setup`
#### Running the test
After setting up the environment and activating it. Run the following command to start the web server

```bash
python3 -m pytest test/unit/*_tests.py 
```

This will start the run all generated basic unit test.

## Sanity Check

A Sanity Test Script has been created to ensure the application works correctly. To check, run the following command

```bash
./sanity_test.sh test_project test_config.json sample_data.txt
```

The script will create a test project using the provided test_config.json and start the application on [http://127.0.0.1:9876](http://127.0.0.1:9876) and on exit, will run the generated unit tests.