#!/bin/bash
WORKDIR=$HOME/projects/gunpla
docker rm whitebase;
docker run -d --name whitebase \
           -p=7900:7900 \
           -v=$WORKDIR/mojolicious:/opt/mojolicious \
           -v=$WORKDIR/stand-alone:/opt/stand-alone \
           gunpla

