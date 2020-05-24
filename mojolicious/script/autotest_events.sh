#!/bin/bash

mongo --eval "db.events.find({},{ "message": 1, "_id": 0}).sort( { timestamp: -1 }).pretty()" gunpla_autotest
