#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <input.osm.pbf> <output.mbtiles>"
  exit 1
fi

# Input and output file paths
INPUT_FILE=$1
OUTPUT_FILE=$2

# Check if Planetiler is available
PLANETILER_JAR="planetiler.jar"
if [ ! -f "$PLANETILER_JAR" ]; then
  echo "Planetiler jar not found. Downloading..."
  wget https://github.com/onthegomap/planetiler/releases/latest/download/planetiler.jar -O "$PLANETILER_JAR"
fi

# Check if planetiler-openmaptiles profile is available
# This profile is required for proper OpenMapTiles schema with Hebrew name support
OPENMAPTILES_JAR="planetiler-openmaptiles.jar"
USE_OPENMAPTILES=false

if [ -f "$OPENMAPTILES_JAR" ]; then
  USE_OPENMAPTILES=true
  echo "Using planetiler-openmaptiles profile for better Hebrew name support..."
elif command -v wget &> /dev/null; then
  echo "Note: For better Hebrew name support, consider using planetiler-openmaptiles:"
  echo "  wget https://github.com/openmaptiles/planetiler-openmaptiles/releases/latest/download/planetiler-openmaptiles.jar"
  echo "  Place it in the same directory as this script."
fi

# Run Planetiler to generate MBTiles with Hebrew language support
# For OpenMapTiles schema, Hebrew names are included as name:he fields
if [ "$USE_OPENMAPTILES" = true ]; then
  # Use planetiler-openmaptiles which has better language support
  java -jar "$OPENMAPTILES_JAR" \
    --osm-path="$INPUT_FILE" \
    --output="$OUTPUT_FILE" \
    --languages=en,he \
    --download
else
  # Use basic planetiler (WARNING: may not generate OpenMapTiles schema)
  # For Hebrew names to work properly, you MUST use planetiler-openmaptiles.jar
  echo "WARNING: Using basic planetiler.jar which may not support OpenMapTiles schema."
  echo "         Hebrew names may not be extracted correctly."
  echo "         Please download planetiler-openmaptiles.jar for proper Hebrew support."
java -jar "$PLANETILER_JAR" \
  --osm-path="$INPUT_FILE" \
  --output="$OUTPUT_FILE" \
  --download
fi

# Check if the output file was created successfully
if [ -f "$OUTPUT_FILE" ]; then
  echo "MBTiles file generated successfully: $OUTPUT_FILE"
else
  echo "Failed to generate MBTiles file."
  exit 1
fi
