# syntax=docker/dockerfile:1.7

# nginx-unprivileged variant runs as UID 101 — required for restricted PSS.
# Same image we use for the hello-nginx sanity check in personal-k8s.
FROM nginxinc/nginx-unprivileged:1.27-alpine

# Drop the default config; ours listens on 8080 and adds /healthz + cache headers.
COPY --chown=nginx:nginx nginx.conf /etc/nginx/conf.d/default.conf

# Static assets — desktop banner + mobile banner (chosen via CSS @media query)
COPY --chown=nginx:nginx index.html              /usr/share/nginx/html/
COPY --chown=nginx:nginx favicon_round.ico       /usr/share/nginx/html/
COPY --chown=nginx:nginx websitebanner.webp      /usr/share/nginx/html/
COPY --chown=nginx:nginx mobilefriendly.webp     /usr/share/nginx/html/

EXPOSE 8080