Local development instructions for urlshortener-frontend

Prerequisites
- Go (for backend) installed locally
- Docker (to run nginx) installed locally
- curl and jq (jq optional but recommended)

Run the backend locally (all mode)
- From the workspace root, run the backend in "all" mode:

      go run ../urlshortener-backend/main.go --mode=all

- Or, from the backend directory:

      cd ../urlshortener-backend
      go run ./...

Run nginx locally with Docker (mount config and public dir)
- From this directory (urlshortener-frontend), run:

      docker run --rm -p 8080:8080 \
        -v "$(pwd)/nginx.conf:/etc/nginx/conf.d/default.conf:ro" \
        -v "$(pwd)/public:/usr/share/nginx/html:ro" \
        nginx:stable

Create a shortcode (example)
- Create a shortcode by POSTing to the backend API (when backend is running on localhost:8080):

      curl -s -X POST -H "Content-Type: application/json" \
        -d '{"url":"https://example.com/long/path"}' \
        http://localhost:8080/shorten | jq

- The response JSON includes a `code` field. Use it in the next step.

Test redirect with curl
- Use the returned code to GET the shortcode (nginx will proxy to backend):

      curl -I -v --location-trusted --max-redirs 0 http://localhost:8080/<code>

- Expect a `301` response and a `Location` header containing the original long URL.

If docker or running locally isn't possible here, run the above commands on your machine.
Local testing instructions for urlshortener-frontend

This README describes how to run and test the frontend locally against a backend instance.

Prerequisites:
- Docker and docker-compose (or podman-compose) installed locally.
- A running backend service reachable at host `urlshortener-backend:8080` from the frontend container. For local testing you can run both services with docker-compose using the same network.

Quick start (docker-compose):

1. Create a `docker-compose.yml` that brings up the frontend (using the nginx container) and the backend. Example snippet:

```yaml
version: '3.7'
services:
  urlshortener-backend:
    image: urlshortener-backend:latest
    build: ../urlshortener-backend
    ports:
      - "8080:8080"

  urlshortener-frontend:
    image: nginx:stable
    ports:
      - "8080:8080"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - ./dist:/usr/share/nginx/html:ro
    depends_on:
      - urlshortener-backend

networks:
  default:
    driver: bridge
```

2. Build and start the services:

```bash
docker-compose up --build
```

3. Open a browser and visit `http://localhost:8080` to see the frontend.

Testing redirect handling locally

- To test a shortcode redirect, call the frontend with the shortcode path, e.g. `http://localhost:8080/abc123`. Nginx will proxy this to `http://urlshortener-backend:8080/abc123`.

- A convenient test script is provided at `scripts/test-redirect.sh`. Run it from the `urlshortener-frontend` directory. It will attempt to resolve a shortcode and print the HTTP redirect location.

Notes

- If your backend binds to `0.0.0.0:8080` and you map the port to the host, the docker-compose configuration above will make the backend available to the frontend container via the service name `urlshortener-backend`.
- If you run the frontend outside of Docker (for example, using host nginx), adjust `proxy_pass` in `nginx.conf` to point to the backend host/port reachable from your host.
