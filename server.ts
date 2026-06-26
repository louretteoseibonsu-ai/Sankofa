import express from "express";
import path from "path";
import { createServer as createViteServer } from "vite";
import { GoogleGenAI } from "@google/genai";
import dotenv from "dotenv";

dotenv.config();

const app = express();
const PORT = 3000;

// Initialize Gemini SDK with telemetry header
const ai = new GoogleGenAI({
  apiKey: process.env.GEMINI_API_KEY,
  httpOptions: {
    headers: {
      "User-Agent": "aistudio-build",
    },
  },
});

app.use(express.json());

// API Endpoints
// Twi Tutor Conversation Endpoint
app.post("/api/tutor", async (req, res) => {
  try {
    const { message, history } = req.body;

    if (!message) {
      return res.status(400).json({ error: "Message is required" });
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

// Translation & Explainer Endpoint
app.post("/api/translate", async (req, res) => {
  try {
    const { text, mode } = req.body; // mode: 'en-to-twi' or 'twi-to-en'

    if (!text) {
      return res.status(400).json({ error: "Text is required" });
    }

    const directionPrompt =
      mode === "twi-to-en"
        ? `Translate this Twi text into English: "${text}"`
        : `Translate this English text into Asante Twi: "${text}"`;

    const prompt = `
      Perform a high-quality translation and grammatical breakdown.

      Task: ${directionPrompt}

      Format the output as a clean JSON object with the following fields:
      - translation: string (the direct translated text)
      - pronunciation: string (a phonetic pronunciation guide, e.g., "Ah-kwaa-bah")
      - literalMeaning: string (the word-by-word literal meaning if different from common translation)
      - breakdown: array of objects, where each object has:
        * word: string (the Twi word or root)
        * meaning: string (the English meaning / grammatical role)
      - explanation: string (a brief 1-2 sentence explanation of any idioms, cultural contexts, or grammar rules used)

      Only return valid JSON matching this schema. No markdown formatting around the JSON, no backticks, just raw JSON.
    `;

    const response = await ai.models.generateContent({
      model: "gemini-3.5-flash",
      contents: prompt,
      config: {
        responseMimeType: "application/json",
      },
    });

    const resultText = response.text || "{}";
    const data = JSON.parse(resultText.trim());
    res.json(data);
  } catch (error: any) {
    console.error("Error in /api/translate:", error);
    res.status(500).json({ error: error.message || "Failed to translate text" });
  }
});

// Start Vite in dev mode, serve static files in production
async function start() {
  if (process.env.NODE_ENV !== "production") {
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
