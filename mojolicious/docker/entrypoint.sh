mongod --config /etc/mongod.conf --fork --logpath /var/log/mongodb.log
cd /opt/mojolicious
script/gunpla.pl init docker
hypnotoad script/gunpla_server
script/gunpla.pl daemon docker --log=/var/log/gunpla-docker.log 2>/var/log/gunpla-docker.log
