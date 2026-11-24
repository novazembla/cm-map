# Info
https://tilemaker.org/

Tutorial: https://blog.kleunen.nl/blog/tilemaker-generate-map

# Install or download tilemaker
Build
https://github.com/systemed/tilemaker/blob/master/docs/INSTALL.md#macos

Download Binary
https://github.com/systemed/tilemaker/releases

And copy `tilemaker` binary file into `bin` folder

# Get OSM Data
You can use: https://export.hotosm.org/en/v3/ or 
https://download.geofabrik.de/europe/germany.html

Download coastlines as described here: https://blog.kleunen.nl/blog/tilemaker-generate-map

Download land polygons and put it in 
https://osmdata.openstreetmap.de/data/land-polygons.html

Place into data folder
```
data/yourdata.osm.pbf
data/coastline/...
data/landcover/... [if needed]
```

# Creaate custom font glyps if needed
Using node-fontnik: https://github.com/mapbox/node-fontnik/blob/master/bin/build-glyphs


https://github.com/mapbox/node-fontnik/tree/master/scripts
In fontnik folder: 
```
bin/build-glyphs ./BerlinType/BerlinTypeOffice-Regular.ttf ./BerlinTypePBF/
```

# Maputnik Style editor
https://maputnik.github.io/editor/#17.07/52.527671/13.415746

# OSM Liberty Style as base style
https://github.com/maputnik/osm-liberty, https://maputnik.github.io/osm-liberty/

# Icons and sprites Sprites 
The Icon SVGs will be converted by spritezero to one .png file. The used icons are a combination of svg styles and configured with maki,
A few icons provided by OSM Liberty in the `svgs_not_in_iconset` folder and a few BVG related icons in the `bvg` folder. 

To create the sprites copy all three folders in one and then run the spritezero command below (in the `sprites` folder). 

But use npm install -g @beyondtracks/spritezero-cli to install spritezero-cli

*Please Note*
We could not get spritezero running on node 16 so we had to use node 14 using `nvm`

```
nvm use 14
npm install -g @beyondtracks/spritezero-cli
```

```
spritezero berlin svgs/
spritezero --retina berlin@2x svgs/
```

# Build command

First configure `config/config-berlin.json` to have the correct tile url

```
"tiles": ["http://example.com/berlin/{z}/{x}/{y}.pbf"],
```

then build the tiles

```
[./bin/]tilemaker --input data/yourdata.osm.pbf --output berlin --process ./config/process-berlin.lua --config ./config/config-berlin.json
```

Finally you'll have to edit, there is a bug in the code open `berlin/metadata.json` and remove the second `,"bounds":[0.0,0.0,0.0,0.0]`


# TODO: 
- Street and background colours
- Icons
- Public transport
- Where is the airport icon ...


./bin/tilemaker --input data/brandenburg-latest.osm.pbf --output berlin --process ./config/process-berlin.lua --config ./config/config-berlin.json

OR

tilemaker --input data/brandenburg-latest.osm.pbf --output berlin --process ./config/process-berlin.lua --config ./config/config-berlin.json








# Local map server (Docker)

For local development, `cm-frontend` and the `cm-monorepo` admin app load the map from a local container.
The container is a static nginx server. It serves this repo as it is, read-only.

## What it does

- It serves the style, the tile metadata, the vector tiles, the glyphs and the sprites.
- The style files and `berlin/metadata.json` contain production URLs. The server rewrites them in each response to the host the browser asked for, e.g. `http://127.0.0.1:4590`. The files on disk stay unchanged.
- Every response allows all origins (CORS `*`) and is not cached.
- Tiles and glyphs are sent as `application/x-protobuf`, without compression.
- A tile that does not exist returns `204` (an empty tile, no error in the browser).
- Everything else returns `404`. It does not serve `data/`, `config/`, `docker/` or `.git`.

## Before you start

The tiles in `berlin/` are not in git (`berlin/*` is in `.gitignore`). The folder has to exist on your machine. Build it with tilemaker as described above, or copy it from someone who has it.

## Start, stop, check

Run these in the root of `cm-map`. You need Docker.

```
docker compose up -d        # start on http://127.0.0.1:4590
docker compose down         # stop and remove the container
curl -s http://127.0.0.1:4590/health
curl -s http://127.0.0.1:4590/culturemap.json | head -c 300
```

The first `up` builds the image `cm-map:server`. After a change in `docker/`, run `docker compose up -d --build`.
The server only listens on `127.0.0.1`, port 4590.

## URLs

| URL | Content |
|---|---|
| `/culturemap.json` | the style (production style, URLs rewritten) |
| `/style.json` | the same style |
| `/culturemap-local.json` | the dev style (URLs rewritten) |
| `/berlin/metadata.json` | the tile metadata (TileJSON) |
| `/berlin/{z}/{x}/{y}.pbf` | vector tiles, zoom 0 to 14 |
| `/fonts/{fontstack}/{range}.pbf` | glyphs, e.g. `/fonts/Berlin%20Type%20Regular/0-255.pbf` |
| `/sprites/berlin.json`, `/sprites/berlin.png` | sprites (also `berlin@2x.*`) |
| `/health` | `ok` |

## Use it from the apps

`cm-frontend`:

```
NEXT_PUBLIC_MAP_JSON_URL=http://127.0.0.1:4590/culturemap.json
```

`cm-monorepo` admin app:

```
VITE_MAP_JSON=http://127.0.0.1:4590/culturemap.json
```

Both values are read when the app starts or builds. Restart the dev server after a change.

## Subset image for tests (optional)

Tests can use an image with a small part of the map baked in. It needs no mount and starts in about a second.

```
python3 -I docker/stage.py                                  # cm-frontend map area, zoom 0-14 (about 120 MB)
python3 -I docker/stage.py --bbox 13.40,52.49,13.59,52.56   # small area (about 12 MB)
docker build -f docker/Dockerfile --target subset -t cm-map:subset .
docker run -d --rm --name cm-map-subset -p 127.0.0.1:4590:80 cm-map:subset
```

`docker/stage.py` copies the styles, the metadata, the fonts the style uses, the sprites and the tiles inside the area into `docker/subset/` (not in git). It only adds files. To change the area, delete `docker/subset/` first.
Tiles outside the area return `204`, so the map stays empty there without errors.

## Files

- `compose.yaml`: starts the server for local development.
- `docker/Dockerfile`: the image. Target `server` (for the mount) and target `subset` (data baked in).
- `docker/nginx.conf`: the server config (URL rewriting, headers, content types).
- `docker/stage.py`: copies a subset for the `subset` image.
- `.dockerignore`: sends only `docker/` to Docker, never `data/`, `berlin/` or `.git`.

## Licences

The map uses OpenStreetMap data. Show "© OpenStreetMap contributors" on the map. See `LICENSE.md`.
Check the licence of the Berlin Type fonts before you publish an image that contains them.
