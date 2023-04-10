#!/bin/bash

# Get the container ID of the PostgreSQL container
CONTAINER_ID=$(docker-compose ps -q postgres)

# Create a timestamp for the backup filename
TIMESTAMP=$(date +%Y%m%d%H%M%S)

MINIO_ENDPOINT="localhost:9999"
MINIO_ACCESS_KEY="backup"
MINIO_SECRET_KEY="12345678"

# Set the bucket and object key for the upload
BUCKET_NAME="backup"



FILE_PATH="mydatabase_$TIMESTAMP.dump"

OBJECT_KEY=$FILE_PATH


host=localhost:9999
s3_key=root
s3_secret=12345678

resource="/${BUCKET_NAME}/${OBJECT_KEY}"
content_type="application/octet-stream"
date=`date -R`
_signature="PUT\n\n${content_type}\n${date}\n${resource}"
signature=`echo -en ${_signature} | openssl sha1 -hmac ${s3_secret} -binary | base64`


#Run the pg_dump command to create a backup file
docker exec $CONTAINER_ID pg_dump -U root -Fc postgres > $FILE_PATH 2>&1  ; curl -X PUT -T "${FILE_PATH}" \
          -H "Host: ${host}" \
          -H "Date: ${date}" \
          -H "Content-Type: ${content_type}" \
          -H "Authorization: AWS ${s3_key}:${signature}" \
          http://${host}${resource}
