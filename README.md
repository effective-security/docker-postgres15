# docker-postgres15

Docker images for Postgres SQL

## Setup

To build the image

```.sh
docker build --no-cache --progress=plain -t effectivesecurity/postgres15 .
```

## Creating a database at launch

You can create a postgresql superuser at launch by specifying `POSTGRES_USER` and `POSTGRES_PASSWORD` variables. You may also create a database by using `POSTGRES_DB`.

```.sh
docker run --name postgresql15 -d \
-e 'POSTGRES_USER=username' \
-e 'POSTGRES_PASSWORD=postgres' \
-e 'POSTGRES_DB=my_database' \
effectivesecurity/postgres15
```

To connect to your database with your newly created user:

```.sh
psql -U username -h $(docker inspect --format {{.NetworkSettings.IPAddress}} postgresql15)
```
