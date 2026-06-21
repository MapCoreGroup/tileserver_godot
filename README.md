# TileServer &trade;
## General

`TileServer`&trade; is an open-source map server made for vector tiles, and able to render into raster tiles with MapLibre GL Native engine on the server side.

It provides maps to web and mobile applications. Supported are MapLibre GL JS, Android SDK, iOS SDK, Leaflet, OpenLayers, HighDPI/Retina, GIS via WMTS, etc.

In ***EVPS*** we are using the mbtiles maps and data that are generated from Open Street Map (OSM) source.

## Setting up
### Using an existing mntiles data file
1. Copy the file into the ./data folder
2. If your data file is not /data/israel.mbtiles  then issue the following command: 
```bash
sed -i 's:data/israel.mbtiles:data/your_file:g' run_docker.bash
```
- Where your_file is the correct .mbitles file.

### Creating your own mbtiles data from osm.pbf file
1. Download the file in osm.pbf format from OSM download site such as (https://download.geofabrik.de/)
3. Let say the name of the file is your_file.osm.pbf
2. Issue the commands:
```bash
mkdir data
cd platiler
generate_mbtiles ~/Downloads/your_file.osm.pbf ../data/your_file.mbtiles
cd ..
sed -i 's:data/israel.mbtiles:data/your_file:g' run_docker.bash
```

#### Generating MBTiles with Hebrew Names
To generate MBTiles that include Hebrew names from your .PBF file:

1. **Ensure your OSM .PBF file contains Hebrew name tags** (`name:he`). Most OSM data for Israel already includes these.

2. **For best results, use planetiler-openmaptiles** (recommended for Hebrew support):
   ```bash
   cd planetiler
   wget https://github.com/openmaptiles/planetiler-openmaptiles/releases/latest/download/planetiler-openmaptiles.jar
   # The generate_mbtiles script will automatically detect and use it
   ```

3. **Generate the MBTiles**:
   ```bash
   cd planetiler
   ./generate_mbtiles.bash your_file.osm.pbf ../data/your_file.mbtiles
   ```

4. **Hebrew names will be included** in the generated tiles as `name:he` fields. The style.json is already configured to display non-Latin names (which includes Hebrew) using the `{name:nonlatin}` field.

5. **Font support**: The style already includes Hebrew-capable fonts (Noto Sans Hebrew Regular/Bold) in the fonts directory, so Hebrew text should render correctly.

**Note**: If Hebrew names don't appear, verify that:
- Your source OSM data contains `name:he` tags
- The style layers are using `{name:nonlatin}` or `{name:he}` in their text-field properties
- Hebrew fonts are properly mounted in the Docker container

# Running the tileserver
## Activating the server's docker
The tileserver is multiplatform docker, So it can run both is x64 as well as in arm64 architectures. 

### Using a bash script
In order to run as a bash issue the command:
```bash
./run_docker
```

### Using docker compose
In order to run within docker composer issue the following command:
```bash
docker compose up
```

In order to stop it eigther use Ctrl+C or use the following command:
```bash
docker compose down
```

## Browse into the server's data
Using the browser navigate to http://localhost:8080
