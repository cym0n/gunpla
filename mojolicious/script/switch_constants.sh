#!/bin/bash
cd "$(dirname "$0")"
rm ../lib/Gunpla/Constants.pm
ln -s Constants_$1.pm ../lib/Gunpla/Constants.pm
