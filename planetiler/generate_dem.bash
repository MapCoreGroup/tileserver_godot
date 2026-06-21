#!/bin/bash
#
# Generate a Terrain-RGB elevation MBTiles for use as a `raster-dem` /
# elevation source in the tileserver (e.g. consumed by a Godot 3D client).
#
# Output tiles are PNG (lossless) encoded with the Mapbox Terrain-RGB scheme:
#   height_m = -10000 + ((R*65536 + G*256 + B) * 0.1)
#
# Requirements (install once):
#   pip install --user elevation rio-rgbify rasterio
#   plus GDAL command line tools (gdalbuildvrt, gdal_translate)
#
# Usage:
#   ./generate_dem.bash <output.mbtiles> <left> <bottom> <right> <top> [maxzoom]
# Example (Israel):
#   ./generate_dem.bash ../data/israel_dem.mbtiles 34.0 29.4 36.3 33.7 13

set -euo pipefail

if [ "$#" -lt 5 ]; then
  echo "Usage: $0 <output.mbtiles> <left> <bottom> <right> <top> [maxzoom]"
  exit 1
fi

OUTPUT_FILE=$1
LEFT=$2
BOTTOM=$3
RIGHT=$4
TOP=$5
MAXZOOM=${6:-13}   # SRTM1 is ~30m; above ~z13 it is just upsampled
MINZOOM=7

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# eio (elevation) refuses to download more than 9 SRTM tiles at once, so we
# clip in latitude bands of 2 degrees and merge the results with GDAL.
echo "Downloading/clipping SRTM1 in latitude bands ($BOTTOM..$TOP)..."
band_bottom=$(python3 -c "import math;print(math.floor($BOTTOM))")
top_ceil=$(python3 -c "import math;print(math.ceil($TOP))")
i=0
parts=()
while [ "$band_bottom" -lt "$top_ceil" ]; do
  band_top=$((band_bottom + 2))
  part="$TMPDIR/dem_$i.tif"
  eio --product SRTM1 clip -o "$part" --bounds "$LEFT" "$band_bottom" "$RIGHT" "$band_top"
  parts+=("$part")
  band_bottom=$band_top
  i=$((i + 1))
done

echo "Merging ${#parts[@]} band(s)..."
gdalbuildvrt "$TMPDIR/merged.vrt" "${parts[@]}"
gdal_translate -of GTiff -co COMPRESS=DEFLATE \
  -projwin "$LEFT" "$TOP" "$RIGHT" "$BOTTOM" \
  "$TMPDIR/merged.vrt" "$TMPDIR/merged.tif"

# SRTM marks sea / voids as NoData (-32768). Replace with 0 (sea level) so the
# Terrain-RGB encoding does not produce absurd heights over water/edges.
echo "Filling NoData with sea level (0)..."
gdal_calc.py -A "$TMPDIR/merged.tif" --outfile="$TMPDIR/filled.tif" \
  --calc="A*(A!=-32768)" --co COMPRESS=DEFLATE --quiet

echo "Encoding Terrain-RGB MBTiles -> $OUTPUT_FILE (z$MINZOOM-$MAXZOOM)..."
rm -f "$OUTPUT_FILE"
rio rgbify -b -10000 -i 0.1 \
  --min-z "$MINZOOM" --max-z "$MAXZOOM" --format png \
  "$TMPDIR/filled.tif" "$OUTPUT_FILE"

if [ ! -f "$OUTPUT_FILE" ]; then
  echo "Failed to generate DEM MBTiles."
  exit 1
fi

# rio-rgbify writes only minimal metadata; set a clean, single-row set so the
# tileserver can build a correct TileJSON (bounds / zoom range / encoding).
echo "Writing MBTiles metadata..."
CX=$(python3 -c "print(($LEFT+$RIGHT)/2)")
CY=$(python3 -c "print(($BOTTOM+$TOP)/2)")
sqlite3 "$OUTPUT_FILE" "DELETE FROM metadata;
INSERT INTO metadata (name,value) VALUES
 ('name','$(basename "$OUTPUT_FILE" .mbtiles)'),
 ('description','Terrain-RGB elevation (SRTM1 30m, Mapbox encoding)'),
 ('format','png'),
 ('type','baselayer'),
 ('version','1'),
 ('minzoom','$MINZOOM'),
 ('maxzoom','$MAXZOOM'),
 ('bounds','$LEFT,$BOTTOM,$RIGHT,$TOP'),
 ('center','$CX,$CY,$MAXZOOM'),
 ('encoding','mapbox');"

echo "DEM MBTiles generated successfully: $OUTPUT_FILE"
