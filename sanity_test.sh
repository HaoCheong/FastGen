#!/bin/bash

rm -rf test_proj/

echo "======== GENERATE TEST PROJECT ========"
./generator.sh -p test_proj -c test_config.json
cd test_proj

echo "======== SETUP ENVIRONMENT ========"
python3 -m venv .venv
source .venv/bin/activate

echo "======== INSTALL AND RUN ========"
pip3 install -r requirements.txt
# python3 -m uvicorn app.main:app --reload --port 9876

echo "======== RUN TESTS ========"
cp ../test_pets_db.txt tests/unit/test_data.py
python3 -m pytest tests/unit/*_tests.py

# echo "======== ERASING ========"
# cd ../
# rm -rf test_proj/