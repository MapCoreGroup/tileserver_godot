// Prune a tileserver-gl config to only the map data (mbtiles) actually present on disk, so the
// server starts gracefully even when some/all .mbtiles are missing (the repo does NOT ship the
// multi-GB data). Without this, a server-rendered style whose source mbtiles is missing throws an
// unhandled promise rejection and the process exits (1). Prints the pruned config path to stdout.
import fs from 'fs';

const cfgPath = process.argv[2] || '/config/config.json';
const cfg = JSON.parse(fs.readFileSync(cfgPath, 'utf8'));

// 1) keep only data sources whose mbtiles file exists
const keptData = {};
const droppedData = [];
for (const [name, src] of Object.entries(cfg.data || {})) {
  const mb = src.mbtiles || '';
  const p = mb.startsWith('/') ? mb : `/data/${mb}`;
  if (fs.existsSync(p)) keptData[name] = src;
  else droppedData.push(name);
}
cfg.data = keptData;

// 2) keep only styles whose referenced mbtiles sources are all present
const keptStyles = {};
const droppedStyles = [];
for (const [id, st] of Object.entries(cfg.styles || {})) {
  let refs = [];
  try {
    const sj = JSON.parse(fs.readFileSync(st.style, 'utf8'));
    for (const s of Object.values(sj.sources || {})) {
      const m = (s.url || '').match(/mbtiles:\/\/\{([^}]+)\}/);
      if (m) refs.push(m[1]);
    }
  } catch (e) {
    droppedStyles.push(id + ' (unreadable)');
    continue;
  }
  if (refs.every((r) => keptData[r])) keptStyles[id] = st;
  else droppedStyles.push(id);
}
cfg.styles = keptStyles;

// 3) pin the path root to '/'. The pruned config is written to /tmp, and tileserver-gl resolves a
// style's relative `sprite` path against the config file's directory. Without this, sprites declared
// as "/styles/osm-bright/sprite" resolve to /tmp/styles/... (ENOENT). Rooting at '/' makes the
// absolute container mounts (/styles, /data, /fonts) authoritative regardless of the config location.
cfg.options = cfg.options || {};
cfg.options.paths = cfg.options.paths || {};
cfg.options.paths.root = '/';

if (droppedData.length) console.error(`[prune] skipped missing data: ${droppedData.join(', ')}`);
if (droppedStyles.length) console.error(`[prune] skipped styles needing missing data: ${droppedStyles.join(', ')}`);
console.error(`[prune] serving ${Object.keys(keptData).length} data source(s), ${Object.keys(keptStyles).length} style(s)`);

const out = '/tmp/tileserver-config.json';
fs.writeFileSync(out, JSON.stringify(cfg, null, 2));
process.stdout.write(out);
