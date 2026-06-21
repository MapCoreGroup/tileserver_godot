# Hebrew Names Display Fix

## Problem
Hebrew names were not displaying on the map - only digits and occasional English text were visible.

## Root Cause
1. The style.json was using `{name:nonlatin}` which may not be populated with Hebrew names
2. The MBTiles might not have been generated with proper Hebrew language support
3. The style needed to explicitly prioritize Hebrew names using expression syntax

## Changes Made

### 1. Updated style.json
All label layers have been updated to use a fallback expression that prioritizes Hebrew names:
```json
"text-field": ["coalesce", ["get", "name:he"], ["get", "name:nonlatin"], ["get", "name:latin"], ["get", "name"]]
```

This expression tries fields in this order:
1. `name:he` - Hebrew name (highest priority)
2. `name:nonlatin` - Non-Latin name
3. `name:latin` - Latin transliteration
4. `name` - Default name field

**Updated layers:**
- All place layers (city, town, village, state, country, continent)
- Waterway and water name layers
- POI (Point of Interest) layers

### 2. Updated generate_mbtiles.bash
- Added warning when using basic planetiler.jar
- Emphasized need for planetiler-openmaptiles.jar for proper Hebrew support

## What You Need to Do

### Step 1: Download planetiler-openmaptiles.jar (REQUIRED)
```bash
cd planetiler
wget https://github.com/openmaptiles/planetiler-openmaptiles/releases/latest/download/planetiler-openmaptiles.jar
```

### Step 2: Regenerate Your MBTiles
You MUST regenerate your MBTiles file with the updated script to include Hebrew names:
```bash
cd planetiler
./generate_mbtiles.bash your_file.osm.pbf ../data/your_file.mbtiles
```

**Important:** The old MBTiles file was likely generated without Hebrew language support. You need to regenerate it.

### Step 3: Restart the Tileserver
Restart your tileserver to pick up the updated style.json:
```bash
docker compose down
docker compose up
```

Or if using the bash script:
```bash
# Stop the server (Ctrl+C if running)
./run_docker.bash
```

### Step 4: Clear Browser Cache
Clear your browser cache or do a hard refresh (Ctrl+Shift+R) to ensure the new style is loaded.

## Verification

After regenerating and restarting, you should see:
- Hebrew place names (cities, towns, villages)
- Hebrew POI names
- Hebrew waterway/water body names
- Fallback to English/Latin when Hebrew names are not available

## Troubleshooting

If Hebrew names still don't appear:

1. **Verify your OSM .PBF file contains Hebrew names:**
   - Check that your source OSM data has `name:he` tags
   - You can inspect the PBF file or check on OpenStreetMap website

2. **Verify planetiler-openmaptiles was used:**
   - Check the generation script output - it should say "Using planetiler-openmaptiles profile"
   - If it says "WARNING: Using basic planetiler.jar", you need to download planetiler-openmaptiles.jar

3. **Check the MBTiles contains Hebrew data:**
   - You can use tools like `mb-util` or `tile-join` to inspect the tiles
   - Or check in the browser developer tools network tab when loading tiles

4. **Verify fonts are available:**
   - The style uses "Noto Sans Hebrew Regular" - ensure these fonts are in `/styles/fonts/`
   - Check that fonts are properly mounted in Docker (they should be based on your docker-compose.yml)

5. **Check browser console for errors:**
   - Open browser developer tools (F12)
   - Look for any font loading errors or style parsing errors

## Technical Details

The style now uses MapLibre GL expression syntax with `coalesce` to try multiple name fields in order of preference. This ensures Hebrew names are displayed when available, with graceful fallback to other name variants.

