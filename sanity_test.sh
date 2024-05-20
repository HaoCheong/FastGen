#!/bin/bash

PROJECT_NAME=$1
CONFIG_NAME=$2
TEST_FILE=$3

rm -rf $PROJECT_NAME/
rm -rf .venv/

echo "======== GENERATE TEST PROJECT ========"
./generator.sh -p $PROJECT_NAME -c $CONFIG_NAME
cd $PROJECT_NAME/

echo "======== SETUP ENVIRONMENT ========"
python3 -m venv .venv
source .venv/bin/activate

# echo "======== INSTALL AND RUN ========"
pip3 install -r requirements.txt
python3 -m uvicorn app.main:app --reload --port 9876

# echo "======== RUN TESTS ========"
cp ../$TEST_FILE tests/unit/test_data.py
python3 -m pytest tests/unit/*_tests.py
