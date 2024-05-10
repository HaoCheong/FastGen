#!/bin/bash

echo "======== GENERATE TEST PROJECT ========"
./generator.sh -p test_proj -c test_config.json
cd test_proj

echo "======== SETUP ENVIRONMENT ========"
python3 -m venv .venv
source .venv/bin/activate

echo "======== INSTALL AND RUN ========"
pip3 install -r requirements.txt
python3 -m uvicorn app.main:app --reload --port 9876