#!/bin/bash

mongo --eval  "db.events.find({},{ "message": 1, "_id": 0}).sort( { timestamp: -1 }).forEach(function(f){print(tojson(f, '', true));})" gunpla_autotest
