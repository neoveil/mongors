#!/bin/sh
set -e

LOCALHOST="${HOST:-localhost}"
REPLICA_SET="${REPLICA_SET_NAME:-rs0}"

mongod --dbpath /var/lib/mongo1 --logpath /var/log/mongo1/mongod.log --port 27017 --bind_ip_all --replSet "${REPLICA_SET}" --fork
mongod --dbpath /var/lib/mongo2 --logpath /var/log/mongo2/mongod.log --port 27018 --bind_ip_all --replSet "${REPLICA_SET}" --fork
mongod --dbpath /var/lib/mongo3 --logpath /var/log/mongo3/mongod.log --port 27019 --bind_ip_all --replSet "${REPLICA_SET}" --fork

wait-for-it "${LOCALHOST}:27017" -t 0 -q
wait-for-it "${LOCALHOST}:27018" -t 0 -q
wait-for-it "${LOCALHOST}:27019" -t 0 -q

mongosh --eval "\
  disableTelemetry(); \
  try { \
    rs.status(); \
    print('replica set up and running!'); \
  } catch (e) { \
    print('initializing replica set...'); \
    rs.initiate({ \
      '_id': '${REPLICA_SET}', \
      'members': [ \
        { '_id': 0, 'host': '${LOCALHOST}:27017', 'priority': 2 }, \
        { '_id': 1, 'host': '${LOCALHOST}:27018', 'priority': 0 }, \
        { '_id': 2, 'host': '${LOCALHOST}:27019', 'priority': 0 } \
      ] \
    }); \
    print('replica set up and running!'); \
  }"

tail -f /var/log/mongo1/mongod.log /var/log/mongo2/mongod.log /var/log/mongo3/mongod.log
