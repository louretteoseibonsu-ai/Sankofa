import express from "express";
import path from "path";
import fs from "fs";
import { GoogleGenAI } from "@google/genai";
import dotenv from "dotenv";

dotenv.config();

// Support knowledge base — the SINGLE source of truth for the in-app support
// chatbot. Loaded once at startup from docs/support_kb.md. To update the bot's
// answers, edit that file and redeploy the server.
let SUPPORT_KB = "";
try {
  SUPPORT_KB = fs.readFileSync(
    path.join(process.cwd(), "docs", "support_kb.md"),
    "utf8"
  );
  console.log(`Loaded support_kb.md (${SUPPORT_KB.length} chars).`);
} catch (e) {
  console.warn("support_kb.md not found — using minimal fallback.");
  SUPPORT_KB =
    "You help Sankofa Twi users. If you are unsure, tell them to email sankofa@aparato.ai.";
}

const app = express();
// Hosts (Render, Cloud Run, etc.) inject the port via env; fall back to 3000 locally.
const PORT = Number(process.env.PORT) || 3000;

// Initialize Gemini SDK with telemetry header
const ai = new GoogleGenAI({
  apiKey: process.env.GEMINI_API_KEY,
  vertexai: false, // force the Gemini Developer API (API-key auth); never fall back to Vertex/ADC
  httpOptions: {
    headers: {
      "User-Agent": "aistudio-build",
    },
  },
});

// Khaya (GhanaNLP) — purpose-built translation + Twi TTS for Ghanaian languages.
const KHAYA_KEY = process.env.KHAYA_API_KEY;
const KHAYA_BASE = "https://translation-api.ghananlp.org";

app.use(express.json());

// API Endpoints
// Twi Tutor Conversation Endpoint
app.post("/api/tutor", async (req, res) => {
  try {
    const { message, history } = req.body;

    if (!message) {
      return res.status(400).json({ error: "Message is required" });
    }
    if (!process.env.GEMINI_API_KEY) {
      return res
        .status(500)
        .json({ error: "GEMINI_API_KEY is not configured on the server (Sankofa AI tutor)." });
    }

    const systemInstruction = `
      You are "Sankofa AI", a friendly, patient, and highly expert Twi language teacher and Akan cultural ambassador.
      Your goal is to help users learn Twi (specifically Asante Twi, which is the most widely spoken dialect) and understand Akan culture (e.g., Adinkra symbols, naming traditions, historical context).

      Guidelines:
      1. Keep your tone warm, encouraging, and informative.
      2. When writing Twi, always provide the English translation and a simple phonetic pronunciation guide in brackets if helpful.
         Example: "Akwaaba" [Ah-kwaa-bah] - Welcome.
      3. If the user asks for a translation, explain any interesting grammar patterns, prefixes, or verbs.
      4. If the user makes a mistake in Twi, gently correct them and praise their attempt.
      5. Share short cultural tips when relevant (e.g., how elders are addressed, day names, etc.).
      6. Use basic Twi greetings in your responses to immerse the user (e.g., "Mema wo akye" - Good morning, "Medaase" - Thank you).
      7. Keep explanations relatively concise and easy to understand for beginners.
    `;

    // Reconstruct the chat with the provided history
    const chat = ai.chats.create({
      model: "gemini-3.5-flash",
      config: {
        systemInstruction,
        temperature: 0.7,
      },
      history: history || [],
    });

    const response = await chat.sendMessage({ message });
    const reply = response.text;

    // Get the updated history
    const updatedHistory = await chat.getHistory();

    res.json({ reply, history: updatedHistory });
  } catch (error: any) {
    console.error("Error in /api/tutor:", error);
    res.status(500).json({ error: error.message || "Failed to generate tutor response" });
  }
});

// Support Chatbot Endpoint — answers from the Sankofa Twi knowledge base only.
app.post("/api/support", async (req, res) => {
  try {
    const { message, history } = req.body;
    if (!message) {
      return res.status(400).json({ error: "Message is required" });
    }
    if (!process.env.GEMINI_API_KEY) {
      return res
        .status(500)
        .json({ error: "GEMINI_API_KEY is not configured on the server (support)." });
    }

    const systemInstruction = `You are the Lead Customer Success Assistant for
"Sankofa Twi", a mobile app for learning the Akan/Twi language. Answer questions
using ONLY the knowledge base below. Be professional, warm and encouraging, in
simple plain language. Keep answers concise; use short bullet steps for "how
do I…" questions; always end with a brief, supportive closing.

If a question is NOT covered by the knowledge base, do not invent anything — say
exactly: "I'm not quite sure about that. Let me connect you to a member of our
human support team," and give the email sankofa@aparato.ai. Escalate to that
email immediately if the user is frustrated or unresolved after two attempts.

The knowledge base may contain internal "maintainer notes" — treat those as
context for yourself, never repeat them to the user.

=== KNOWLEDGE BASE (docs/support_kb.md) ===
${SUPPORT_KB}`;

    const chat = ai.chats.create({
      model: "gemini-3.5-flash",
      config: { systemInstruction, temperature: 0.4 },
      history: history || [],
    });

    const response = await chat.sendMessage({ message });
    const reply = response.text;
    const updatedHistory = await chat.getHistory();
    res.json({ reply, history: updatedHistory });
  } catch (error: any) {
    console.error("Error in /api/support:", error);
    res.status(500).json({ error: error.message || "Failed to generate support response" });
  }
});

// Translation Endpoint — powered by Khaya (GhanaNLP), purpose-built for Ghanaian languages.
app.post("/api/translate", async (req, res) => {
  try {
    const { text, mode } = req.body; // mode: 'en-to-twi' or 'twi-to-en'
    if (!text) {
      return res.status(400).json({ error: "Text is required" });
    }
    if (!KHAYA_KEY) {
      return res.status(500).json({ error: "KHAYA_API_KEY is not configured on the server." });
    }

    const lang = mode === "twi-to-en" ? "tw-en" : "en-tw";

    const khayaRes = await fetch(`${KHAYA_BASE}/v1/translate`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Ocp-Apim-Subscription-Key": KHAYA_KEY,
      },
      body: JSON.stringify({ in: text, lang }),
    });

    if (!khayaRes.ok) {
      const detail = await khayaRes.text();
      console.error("Khaya translate error:", khayaRes.status, detail);
      return res
        .status(khayaRes.status)
        .json({ error: `Khaya translation failed (${khayaRes.status})`, detail });
    }

    // Khaya returns the translated text (a JSON string, or an object).
    const data: any = await khayaRes.json();
    const translation =
      typeof data === "string" ? data : data?.translatedText ?? data?.text ?? String(data);
    res.json({ translation, lang, source: "khaya" });
  } catch (error: any) {
    console.error("Error in /api/translate:", error);
    res.status(500).json({ error: error.message || "Failed to translate text" });
  }
});

// Text-to-Speech Endpoint — Khaya Twi TTS, so Twi text is spoken in Twi (not an English voice).
app.post("/api/tts", async (req, res) => {
  try {
    const { text, lang, speaker } = req.body;
    if (!text) {
      return res.status(400).json({ error: "Text is required" });
    }
    if (!KHAYA_KEY) {
      return res.status(500).json({ error: "KHAYA_API_KEY is not configured on the server." });
    }

    // Khaya TTS expects a Ghanaian-voice speaker_id (e.g. twi_speaker_4..9).
    const body = {
      text,
      language: lang || "tw",
      speaker_id: speaker || "twi_speaker_4",
    };
    console.log("Khaya TTS request:", { ...body, text: text.slice(0, 40) });

    const khayaRes = await fetch(`${KHAYA_BASE}/tts/v1/tts`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Ocp-Apim-Subscription-Key": KHAYA_KEY,
      },
      body: JSON.stringify(body),
    });

    if (!khayaRes.ok) {
      const detail = await khayaRes.text();
      console.error("Khaya TTS error:", khayaRes.status, detail);
      return res.status(khayaRes.status).json({ error: `Khaya TTS failed (${khayaRes.status})`, detail });
    }

    const audio = Buffer.from(await khayaRes.arrayBuffer());
    res.setHeader("Content-Type", "audio/wav");
    res.send(audio);
  } catch (error: any) {
    console.error("Error in /api/tts:", error);
    res.status(500).json({ error: error.message || "Failed to synthesize speech" });
  }
});

// ── Public web pages (landing + legal) ─────────────────────────────────────
// Served from /web BEFORE the SPA static handler, so they replace the old web
// UI without touching the API routes above.
const WEB_DIR = path.join(process.cwd(), "web");
app.get(["/", "/index.html"], (_req, res) =>
  res.sendFile(path.join(WEB_DIR, "landing.html"))
);
app.get("/privacy", (_req, res) =>
  res.sendFile(path.join(WEB_DIR, "privacy.html"))
);
app.get("/terms", (_req, res) => res.sendFile(path.join(WEB_DIR, "terms.html")));
// Serve static assets from /web (favicon, images, etc.).
app.use(express.static(WEB_DIR));

// Start Vite in dev mode, serve static files in production
async function start() {
  if (process.env.NODE_ENV !== "production") {
    // Dynamic import so production never requires "vite" (a devDependency).
    const { createServer: createViteServer } = await import("vite");
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: "spa",
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(process.cwd(), "dist");
    app.use(express.static(distPath));
    app.get("*", (req, res) => {
      res.sendFile(path.join(distPath, "index.html"));
    });
  }

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`SankofaTwi server running on http://localhost:${PORT}`);
  });
}

start();
