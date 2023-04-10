# Creating Backups of PostgreSQL Database and Uploading to MinIO

Creating backups of important data is an essential part of any reliable data management system. If you are running a PostgreSQL database and looking for a way to easily back up your data and store it safely, this article will guide you through a simple process for backing up your PostgreSQL database and uploading the backup file into MinIO, an open-source object storage server.

## What is MinIO?

MinIO is a lightweight and high-performance object storage server that is compatible with Amazon S3 cloud storage service. It can be used to store unstructured data, such as photos, videos, and backup files. You can easily deploy MinIO on your own server and manage your data without relying on a third-party cloud storage service.

## Step 1: Set up PostgreSQL and MinIO with Docker Compose

Docker Compose is a popular tool for defining and running multi-container Docker applications. You can use Docker Compose to set up PostgreSQL and MinIO quickly.

Here is an example Docker Compose file that sets up PostgreSQL and MinIO:

```yaml
version: '3.7'
services:
    postgres:
        image: postgres:latest
        restart: always
        container_name: postgresql
        hostname: pgsqlprc
        environment:
          - POSTGRES_USER=root
          - POSTGRES_PASSWORD=1
        ports:
          - '5432:5432'
        volumes:
          - "postgres_data:/var/lib/postgresql/data"
    minio:
        image: quay.io/minio/minio
        volumes:
          - minio_data:/data
        environment:
          MINIO_ROOT_USER: root
          MINIO_ROOT_PASSWORD: 12345678
        ports:
          - "9999:9000"
          - "9990:9090"
        command: server --console-address ":9090" /data
volumes:
    postgres_data:
    minio_data:
```
    
    
Save the above Docker Compose file as docker-compose.yml in your desired location, then run the following command in the same directory:

```
docker-compose up -d
```

This will download the necessary images and start the PostgreSQL and MinIO containers in the background.

## Step 2: Create a backup script
To create a backup script, you can use any scripting language that you are familiar with, such as Bash or Python. In this example, we will create a Bash script.

Create a new file called backup.sh and add the following code:
```sh
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
```
Save this file as backup.sh in the same directory as your docker-compose.yml file.

## Step 3: Test the Backup Script

Before setting up a cron job to run the backup script automatically, you should test it to make sure it’s working correctly. To do this, simply run the backup script from the command line:

```sh
~$ ./backup.sh
```
This will create a backup of your PostgreSQL database and upload it to Minio.

## Step 4: Schedule a Cron Job

```
0 0 1 * * /path/to/backup.sh
```
This cron job will run the backup script at midnight on the first day of every month. You can adjust the timing and frequency by modifying the values in the cron job according to your needs.

To add the cron job, you can use the following steps:

1. Open the crontab file by running the following command:
```
~$ crontab -e
```
2. Add the above cron job to the end of the file.
3. Save and exit the crontab file.

Once the cron job is added, it will run automatically every month according to the specified schedule.

Now that you’ve tested the backup script, you can set up a cron job to run it automatically at regular intervals. For example, to run the script once


