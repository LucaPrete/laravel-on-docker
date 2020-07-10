# Laravel on Docker

Dockerfile and docker-compose to develop using Laravel framework on Docker.

The docker-compose file brings up a local environment with:

* Laravel (files in this repo should be copied in your Laravel project folder)

* Nginx ([config](nginx/conf.d/site.conf))

* Postgres 12

How to:

```shell
# Create your own .env file and update it with your config
cp .env.example .env

# Bring the environment up
docker-compose up

# Once ready, go to http://localhost:8080

# Stop and remove containers
docker-compose down
```
