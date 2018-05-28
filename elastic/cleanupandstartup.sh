#!/bin/bash

export ES_DIR=/opt/elasticsearch-1.2.1

rm -rf $ES_DIR/logs/*
rm -rf $ES_DIR/data/*

$ES_DIR/bin/elasticsearch -Des.config=$ES_DIR/config/es1.yml
sleep 2
$ES_DIR/bin/elasticsearch -Des.config=$ES_DIR/config/es2.yml
sleep 2
$ES_DIR/bin/elasticsearch -Des.config=$ES_DIR/config/es3.yml
