# REQUIRED ACTIONS - Hebrew Names Still Not Showing

## Critical: You MUST Regenerate the MBTiles File

Your current MBTiles file (`data/israel.mbtiles`) was last modified on **Jan 22, 2026**. Even if you ran the script, the file may not have been regenerated with Hebrew support.

## Step-by-Step Fix

### 1. Verify Your PBF File Has Hebrew Names

**First, check if your source OSM data actually contains Hebrew names:**

- Go to https://www.openstreetmap.org
- Navigate to a location in Israel (e.g., Jerusalem, Tel Aviv)
- Click on a place name
- Check if you see a `name:he` tag in the tags list

If there's no `name:he` tag in the OSM data, Hebrew names won't appear in your tiles.

### 2. Delete and Regenerate MBTiles

**IMPORTANT:** You must DELETE the old file and regenerate it:

```bash
cd /home/dell1/osm/tileserver_run

# Stop the tileserver first
docker compose down

# Backup the old file (optional)
mv data/israel.mbtiles data/israel.mbtiles.backup

# Regenerate with planetiler-openmaptiles
cd planetiler

# Make sure you have the PBF file path
# Replace /path/to/your/israel.osm.pbf with your actual PBF file path
./generate_mbtiles.bash /path/to/your/israel.osm.pbf ../data/israel.mbtiles
```

**Watch for this message in the output:**
```
Using planetiler-openmaptiles profile for better Hebrew name support...
```

If you see a WARNING about using basic planetiler.jar, the script didn't find planetiler-openmaptiles.jar.

### 3. Verify the Generation Command

The script should run:
```bash
java -jar planetiler-openmaptiles.jar \
  --osm-path="your_file.osm.pbf" \
  --output="../data/israel.mbtiles" \
  --languages=en,he \
  --download
```

**The `--languages=en,he` parameter is CRITICAL** - it tells planetiler to extract Hebrew names.

### 4. Restart the Tileserver

After regeneration:

```bash
cd /home/dell1/osm/tileserver_run
docker compose up -d
```

### 5. Clear Browser Cache

- Hard refresh: Ctrl+Shift+R (Linux/Windows) or Cmd+Shift+R (Mac)
- Or clear browser cache completely

### 6. Test the Map

Navigate to http://localhost:8080 and check if Hebrew names appear.

## If Still Not Working

### Check Browser Console

1. Open browser developer tools (F12)
2. Go to Console tab
3. Look for errors related to:
   - Font loading
   - Style parsing
   - Tile loading

### Verify Fonts Are Available

```bash
ls -la styles/fonts/Noto\ Sans\ Hebrew\ Regular/ | head -5
```

You should see 256 PBF files (0-255.pbf).

### Test with Simple Expression

Temporarily change one label layer in `styles/osm-bright/style.json` to test:

```json
"text-field": "{name}"
```

If this shows names (even English), then the issue is with the Hebrew field names. If it shows nothing, the tiles don't have name fields at all.

## Most Likely Causes

1. **MBTiles not regenerated** - The old file is still being used
2. **PBF file has no Hebrew names** - Source OSM data doesn't have `name:he` tags
3. **Generation failed silently** - Check the script output for errors
4. **Wrong PBF file used** - Make sure you're using the correct PBF file with Hebrew data

## Quick Verification

Run this to check when your MBTiles was last modified:

```bash
stat -c "%y" /home/dell1/osm/tileserver_run/data/israel.mbtiles
```

If it's still showing Jan 22, 2026, the file wasn't regenerated.

