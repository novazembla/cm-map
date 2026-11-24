# CultureMap map server: nginx serving the style, tiles, glyphs and sprites of this repo.
# Build context is the repo root; .dockerignore sends only docker/ to the daemon.
#   target `server`: config only; the repo is mounted read-only at /srv/map (see compose.yaml).
#   target `subset`: a staged subset (docker/stage.py -> docker/subset/) baked in, for tests.
FROM nginx:1.29-alpine AS server
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
RUN mkdir -p /srv/map
EXPOSE 80
HEALTHCHECK --interval=2s --timeout=2s --retries=10 CMD wget -qO- http://127.0.0.1/health || exit 1

FROM server AS subset
COPY docker/subset/ /srv/map/
