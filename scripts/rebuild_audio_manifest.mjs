#!/usr/bin/env node
// Rebuilds app/assets/audio/manifest.json from clips that already exist on disk
// (no API calls). Useful if generate_lesson_audio.mjs was interrupted before it
// wrote the manifest. Recomputes each word's filename hash and maps it to the
// clip file if that file is present.
//
// USAGE:  node scripts/rebuild_audio_manifest.mjs

import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const APP = path.join(__dirname, "..", "app");
const CONTENT_DIR = path.join(APP, "assets", "content");
const OUT_DIR = path.join(APP, "assets", "audio");
const MANIFEST = path.join(OUT_DIR, "manifest.json");

const norm = (s) => s.trim().toLowerCase();

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
  (u.glossary || []).forEach((g) => push(g.twi));
  const gm = u.grammar_mechanics;
  if (gm && Array.isArray(gm.patterns)) gm.patterns.forEach(push);
  return out;
}

const existing = new Set(fs.readdirSync(OUT_DIR));
const files = fs
  .readdirSync(CONTENT_DIR)
  .filter((f) => f.startsWith("unit_") && f.endsWith(".json"));

const manifest = {};
const exts = ["wav", "mp3", "ogg"];
let matched = 0;
let missing = 0;

for (const f of files) {
  const u = JSON.parse(fs.readFileSync(path.join(CONTENT_DIR, f), "utf8"));
  for (const w of collectFromUnit(u)) {
    const key = norm(w);
    if (manifest[key]) continue;
    const slug = crypto.createHash("sha1").update(key).digest("hex").slice(0, 16);
    const hit = exts.map((e) => `${slug}.${e}`).find((name) => existing.has(name));
    if (hit) {
      manifest[key] = hit;
      matched++;
    } else {
      missing++;
    }
  }
}

fs.writeFileSync(MANIFEST, JSON.stringify(manifest, null, 2));
console.log(
  `Rebuilt manifest: ${matched} words mapped, ${missing} without a clip. ` +
    `Total entries: ${Object.keys(manifest).length}.`
);
