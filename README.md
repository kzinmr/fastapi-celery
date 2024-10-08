# FastAPI and Celery demo

Derived from the following demo:
- https://github.com/testdrivenio/fastapi-celery

Packages and Python runtime are managed by [uv](https://docs.astral.sh/uv/):
- https://github.com/astral-sh/uv-docker-example/


## development

- build

```
docker compose up --build
```

- watch to debug

```
docker compose up --watch
```

- run in container

```
docker run -it $(docker build -q .) /bin/bash
```
