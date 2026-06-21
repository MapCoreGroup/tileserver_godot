# Diagnostic Steps for Hebrew Names Issue

## Current Status
- ✅ planetiler-openmaptiles.jar is present
- ✅ Style.json has been updated with Hebrew-priority expressions
- ❌ Hebrew names still not displaying
- ⚠️ MBTiles was last modified: Jan 22, 2026 (may need regeneration)

## Critical Issue: MBTiles Regeneration Required

The MBTiles file (`data/israel.mbtiles`) was last modified on **Jan 22, 2026 at 17:00**. 

**You MUST regenerate the MBTiles file** with planetiler-openmaptiles.jar for Hebrew names to work.

### Step 1: Verify Your PBF File Has Hebrew Names

First, check if your source OSM PBF file contains Hebrew names:

```bash
# If you have osmium-tool installed:
osmium tags-filter your_file.osm.pbf n/name:he -o hebrew_names.osm.pbf

# Or use grep (if PBF is text-readable, which it usually isn't)
# Better: Check on OpenStreetMap website if your area has name:he tags
```

### Step 2: Regenerate MBTiles with Hebrew Support

**IMPORTANT:** Delete the old MBTiles file and regenerate it:

```bash
cd /home/dell1/osm/tileserver_run

# Backup the old file (optional)
mv data/israel.mbtiles data/israel.mbtiles.backup

# Regenerate with planetiler-openmaptiles
cd planetiler
./generate_mbtiles.bash /path/to/your/israel.osm.pbf ../data/israel.mbtiles
```

**Verify the output shows:**
```
Using planetiler-openmaptiles profile for better Hebrew name support...
```

### Step 3: Check What Fields Are Actually in the Tiles

After regeneration, you can inspect the tiles to see what name fields exist:

```bash
# If you have mb-util or other tools:
# Extract a tile and inspect its properties
```

### Step 4: Test with Simple Expression First

If regeneration doesn't work, let's test with a simpler expression. The current style uses:

```json
"text-field": [
  "coalesce",
  ["get", "name:he"],
  ["get", "name:nonlatin"], 
  ["get", "name:latin"],
  ["get", "name"]
]
```

Try temporarily changing one layer to just `{name}` to see if ANY names show up:

```json
"text-field": "{name}"
```

If this works, then the issue is with the field names. If it doesn't work, the tiles might not have name fields at all.

### Step 5: Verify Style is Loading

1. Open browser developer tools (F12)
2. Go to Network tab
3. Reload the map
4. Check if style.json loads successfully
5. Look for any JavaScript errors in Console tab

### Step 6: Check Font Loading

Hebrew fonts must be available. Verify:

```bash
ls -la styles/fonts/Noto\ Sans\ Hebrew\ Regular/ | head -5
```

The fonts should be in PBF format (256 files per font).

### Step 7: Alternative Expression Syntax

If coalesce doesn't work, try using the `format` function:

```json
"text-field": [
  "format",
  ["coalesce", ["get", "name:he"], ["get", "name:nonlatin"], ["get", "name:latin"], ["get", "name"]]
]
```

Or try a simpler fallback:

```json
"text-field": ["get", "name:he"]
```

Then add fallbacks if needed.

## Most Likely Issue

Based on the evidence:
1. **The MBTiles was NOT regenerated** with planetiler-openmaptiles.jar after the style changes
2. The old MBTiles file doesn't contain Hebrew name fields (`name:he`)
3. The expressions are correct, but they can't find Hebrew names because they don't exist in the tiles

**Solution: Regenerate the MBTiles file NOW.**

