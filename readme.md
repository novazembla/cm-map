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








