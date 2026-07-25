#!/usr/bin/env node
// Pre-generate Twi audio for the fixed lesson vocabulary ONCE, so the app plays
// bundled files instead of calling Khaya TTS on every tap (saves API quota).
//
// It reads all app/assets/content/unit_*.json, collects the Twi strings, calls
// your backend /api/tts for each, saves clips into app/assets/audio/, and writes
// app/assets/audio/manifest.json (normalisedText -> filename) that the app reads.
//
// USAGE (run when your Khaya quota is available — e.g. after reset or on the
// Standard tier):
//   node scripts/generate_lesson_audio.mjs
//
// Re-run any time you add/edit lessons; it skips clips that already exist.

import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const APP = path.join(__dirname, "..", "app");
const CONTENT_DIR = path.join(APP, "assets", "content");
const OUT_DIR = path.join(APP, "assets", "audio");
const MANIFEST = path.join(OUT_DIR, "manifest.json");

const BACKEND = process.env.BACKEND_URL || "https://sankofa-twi.onrender.com";
const TTS_URL = `${BACKEND}/api/tts`;

const norm = (s) => s.trim().toLowerCase();

// Words whose TTS clip came out corrupted/garbled — skip bundling them so the
// app falls back to clean live audio. (Khaya mangles some very short tokens.)
const SKIP = new Set(["kɔ"]);

// Clips to FORCE-regenerate even if they already exist — use for a previously
// bad/garbled clip. Add the normalised word, re-run, and its clip is remade.
// If a regenerated clip is still wrong, move the word to SKIP instead.
const FORCE = new Set(["aane"]);

// Minimum acceptable clip size; anything smaller is treated as a bad/empty clip.
const MIN_BYTES = 6000;

// Pull every Twi string worth pre-generating from a unit's JSON.
function collectFromUnit(u) {
  const out = [];
  const push = (s) => {
    if (typeof s === "string" && s.trim()) out.push(s.trim());
  };
  const vs = u.vocabulary_spotlight;
  if (vs) {
    push(vs.headword);
    (vs.example_sentences || []).forEach(push);
  }
  (u.glossary || []).forEach((g) => {
    push(g.twi);
    push(g.audio); // per-word pronunciation override (carrier phrase), if any
  });
  // Grammar patterns are often Twi too; include short ones.
  const gm = u.grammar_mechanics;
  if (gm && Array.isArray(gm.patterns)) gm.patterns.forEach(push);
  return out;
}

function extFor(contentType) {
  if (!contentType) return "mp3";
  if (contentType.includes("wav")) return "wav";
  if (contentType.includes("mpeg") || contentType.includes("mp3")) return "mp3";
  if (contentType.includes("ogg")) return "ogg";
  return "mp3";
}

async function main() {
  if (!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR, { recursive: true });

  // Gather unique Twi strings across all units.
  const files = fs
    .readdirSync(CONTENT_DIR)
    .filter((f) => f.startsWith("unit_") && f.endsWith(".json"));
  const seen = new Set();
  const words = [];
  for (const f of files) {
    const u = JSON.parse(fs.readFileSync(path.join(CONTENT_DIR, f), "utf8"));
    for (const w of collectFromUnit(u)) {
      const k = norm(w);
      if (!seen.has(k)) {
        seen.add(k);
        words.push(w);
      }
    }
  }
  console.log(`Found ${words.length} unique Twi strings across ${files.length} units.`);

  // Load existing manifest so re-runs are incremental.
  let manifest = {};
  if (fs.existsSync(MANIFEST)) {
    try {
      manifest = JSON.parse(fs.readFileSync(MANIFEST, "utf8"));
    } catch {}
  }

  let made = 0;
  let failed = 0;
  for (const w of words) {
    const key = norm(w);
    if (SKIP.has(key)) {
      console.log(`  · skipping ${w} (uses live audio)`);
      continue;
    }
    if (!FORCE.has(key) && manifest[key]) {
      const existing = path.join(OUT_DIR, manifest[key]);
      if (fs.existsSync(existing)) continue; // already generated
    }
    if (FORCE.has(key) && manifest[key]) {
      // Remove the old (bad) clip so the fresh one replaces it.
      try {
        fs.rmSync(path.join(OUT_DIR, manifest[key]), { force: true });
      } catch {}
    }
    const slug = crypto.createHash("sha1").update(key).digest("hex").slice(0, 16);
    try {
      const res = await fetch(TTS_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ text: w, lang: "tw" }),
      });
      if (!res.ok) {
        const body = await res.text().catch(() => "");
        console.warn(`  ✗ ${w}  (HTTP ${res.status}) ${body.slice(0, 120)}`);
        failed++;
        if (res.status === 403) {
          console.error(
            "\nKhaya quota exhausted — stopping. Re-run after it resets or on a paid tier."
          );
          break;
        }
        continue;
      }
      const ext = extFor(res.headers.get("content-type"));
      const file = `${slug}.${ext}`;
      const buf = Buffer.from(await res.arrayBuffer());
      if (buf.length < MIN_BYTES) {
        console.warn(`  ✗ ${w}  (clip too small: ${buf.length}B — skipping)`);
        failed++;
        continue; // likely corrupt/empty — leave on live audio
      }
      fs.writeFileSync(path.join(OUT_DIR, file), buf);
      manifest[key] = file;
      made++;
      // Save the manifest after EVERY clip so an interruption never loses the
      // index (you can re-run to resume; existing clips are skipped).
      fs.writeFileSync(MANIFEST, JSON.stringify(manifest, null, 2));
      console.log(`  ✓ ${w} -> ${file}`);
    } catch (e) {
      console.warn(`  ✗ ${w}  (${e.message})`);
      failed++;
    }
  }

  fs.writeFileSync(MANIFEST, JSON.stringify(manifest, null, 2));
  console.log(
    `\nDone. Generated ${made} new clip(s), ${failed} failed, ${Object.keys(manifest).length} total in manifest.`
  );
  console.log("Now rebuild the app:  cd app && flutter pub get && flutter build apk --release");
}

main();
