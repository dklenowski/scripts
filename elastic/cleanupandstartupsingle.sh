#!/bin/bash

export ES_DIR=/opt/elasticsearch-1.2.1

rm -rf $ES_DIR/logs/*
rm -rf $ES_DIR/data/*

$ES_DIR/bin/elasticsearch -d -Des.config=$ES_DIR/config/single.yml
