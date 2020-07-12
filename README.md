# Laravel on Docker

<p align="center"><img src="https://res.cloudinary.com/dtfbvvkyp/image/upload/v1566331377/laravel-logolockup-cmyk-red.svg" width="400"></p>

[Dockerfile](Dockerfile) and [docker-compose](docker-compose.yaml) to develop using [Laravel framework](https://laravel.com) on [Docker](https://www.docker.com/).

The [docker-compose file](docker-compose.yaml) brings up a local environment with:

* [Laravel X.XX](https://laravel.com) - to be installed manually (see below)

* [Nginx 1.19-alpine](https://www.nginx.com/) ([config](nginx/conf.d/site.conf))

* [Postgres 12.3-alpine](https://www.postgresql.org/)

## TL;DR

```shell
# Optionally, create a new Laravel project
mkdir my-project

cd my-project
docker run --rm -v $(pwd):/app composer create-project --prefer-dist laravel/laravel .

# Copy files in this repository to your Laravel project directory
cp -r laravel-on-docker/. my-project

# Create your own .env file and update it with your config
cp .env.example .env

# Bring the environment up
docker-compose up

# Once ready, go to http://localhost:8080

# Stop and remove containers
docker-compose down
```

## About Laravel

Laravel is a web application framework with expressive, elegant syntax. We believe development must be an enjoyable and creative experience to be truly fulfilling. Laravel takes the pain out of development by easing common tasks used in many web projects, such as:

- [Simple, fast routing engine](https://laravel.com/docs/routing).
- [Powerful dependency injection container](https://laravel.com/docs/container).
- Multiple back-ends for [session](https://laravel.com/docs/session) and [cache](https://laravel.com/docs/cache) storage.
- Expressive, intuitive [database ORM](https://laravel.com/docs/eloquent).
- Database agnostic [schema migrations](https://laravel.com/docs/migrations).
- [Robust background job processing](https://laravel.com/docs/queues).
- [Real-time event broadcasting](https://laravel.com/docs/broadcasting).

Laravel is accessible, powerful, and provides tools required for large, robust applications.
