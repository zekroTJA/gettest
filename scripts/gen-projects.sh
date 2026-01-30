#!/usr/bin/env bash

export GETTEST_EDITOR=:
export GETTEST_DIR=data

gettest go "sqlite3"
gettest rust "derive macros"
gettest node "How does this language even work???"
