# browser-use-openrouter-rest-api
REST API for browseruse

Build and run:
```
docker compose up -d --build
```

Example request:
```
curl -X POST http://localhost:25000/run -H "Content-Type: application/json" -d '{"task": "PAK vs SL live score"}'
```

amd64 docker continer image: https://hub.docker.com/repository/docker/theapu/browser-use-openrouter-rest-api/general
