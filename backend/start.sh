#!/bin/bash
cd /Users/gaurav/phodex/backend
exec python3.11 -m uvicorn app.main:app --host 0.0.0.0 --port 8000
