# Make the tiles a stable, reproducible source

## Problem
The tiles in `berlin/` and the OpenStreetMap extracts in `data/` are gitignored. They exist only on the owner's machine, and the tiles were generated in 2021. A fresh clone of `cm-map` has no map data, so the map server (`docker compose up -d`) serves nothing. A second machine or a future CI cannot run `cm-frontend` or `cm-monorepo` browser tests that use the map.

## Goal
Anyone with access can get the exact tiles the apps and tests use, with one documented command.

## Options
- **Registry image:** push an image with the tiles baked in (`docker/Dockerfile`, target `subset` or a full-data target) to a private registry, tagged by tile version.
- **Stored artefact:** keep `berlin/` as Git LFS or as a release file of `cm-map`, versioned.
- **Rebuild:** pin an OpenStreetMap extract (file and checksum) and the tilemaker config, and document the rebuild. The output changes whenever the extract changes, so this needs the pinned extract to be stored too.

## Notes
- The fonts (Berlin Type) belong to the client; using them in private images is allowed.
- The OpenStreetMap data needs the credit "© OpenStreetMap contributors".
- Until this is done: keep a backup copy of `berlin/`.
