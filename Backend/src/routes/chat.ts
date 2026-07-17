import { Router, Request, Response } from "express";

/**
 * Curamind Assist — cheapest Gemini setup (Google AI Studio, not Vertex):
 *
 * 1. Open https://aistudio.google.com/apikey -> Create API key
 * 2. Backend/.env:
 *      GEMINI_API_KEY=your_key_here
 *      GEMINI_MODEL=gemini-flash-lite-latest
 * 3. Restart: npm run dev
 *
 * gemini-flash-lite-latest always points at the cheapest Flash-Lite still
 * available (currently 3.1). Older 2.0/2.5 Flash-Lite may 404 for new keys.
 * Without GEMINI_API_KEY, this route uses a local FAQ fallback.
 */

export const chatRouter = Router();

const SYSTEM_INSTRUCTION = `You are Curamind Assist, the in-app help chatbot for Curamind.
Curamind is a clinical companion for patients and psychiatrists (not a replacement for emergency care).

Answer ONLY about how to use Curamind. Be concise, warm, and practical (English).
If the user is in crisis or wants to harm themselves, tell them to use SOS on Home or call local emergency (112) / crisis (119). Do not diagnose, prescribe, or change medication advice.

Patient app tabs:
- Home: greeting, SOS, diary/meds shortcuts, quick actions, clinician link status
- Diary: DBT cards (mood, affect, emotions, urges, triggers, skills, note) and CBT/coping logs
- Meds: view prescriptions from clinician; log taken/missed for today
- Distress: breathing, grounding, safety plan, crisis SOS (opens dialer with number prefilled — never auto-calls)
- Dashboard: personal mood × adherence charts
- Link: enter clinician join code to connect; monitoring toggle may apply
- Profile: name/photo, password, Notifications (diary + medication reminder times)

Medication reminders: Profile -> Notifications -> enable -> set diary/med times. On web, reminders fire while the tab is open; on mobile they use local notifications.

Clinician side (brief): Groups/join codes, Monitor, Dual Chart, Meds management, Export clinical PDF.

If asked something outside Curamind, politely redirect to app help topics.`;

type ChatTurn = { role: string; content: string };

function asTurns(raw: unknown): ChatTurn[] {
  if (!Array.isArray(raw)) return [];
  const out: ChatTurn[] = [];
  for (const item of raw) {
    if (!item || typeof item !== "object") continue;
    const role = String((item as { role?: unknown }).role ?? "").trim();
    const content = String((item as { content?: unknown }).content ?? "").trim();
    if (!content) continue;
    const normalized =
      role === "user" || role === "model" || role === "assistant"
        ? role === "assistant"
          ? "model"
          : role
        : "user";
    out.push({ role: normalized, content });
  }
  return out.slice(-24);
}

function localReply(lastUser: string): string {
  const q = lastUser.toLowerCase();

  if (
    /(suicid|kill myself|self.?harm|want to die|emergency|crisis|sos)/i.test(q)
  ) {
    return (
      "If you feel unsafe right now, open SOS on Home (or Distress -> crisis) " +
      "and use the dialer for 112 / 119, or contact someone you trust. " +
      "Curamind won’t place the call for you — you choose when to dial. " +
      "I’m here for app help; for medical emergencies please use local emergency services."
    );
  }

  if (/diar|dbt|mood|cbt|log today/i.test(q)) {
    return (
      "To log a diary entry: open the Diary tab -> pick a DBT card (mood, emotions, " +
      "urges, triggers, skills, short note) or a CBT/coping log -> save. " +
      "From Home you can also tap “Log today’s diary”. Entries help your linked " +
      "clinician when monitoring is on."
    );
  }

  if (/remind|notif|alarm|notification/i.test(q)) {
    return (
      "Medication & diary reminders live under Profile -> Notifications. " +
      "Turn on Enable notifications, allow permission, set diary time and dose times, " +
      "then optionally tap Send test notification. Med reminders only fire when you " +
      "have active prescriptions. On Chrome/web, keep the tab open around the alarm minute."
    );
  }

  if (/med|pill|prescription|dose|adhere/i.test(q)) {
    return (
      "Open the Meds tab to see prescriptions your clinician assigned and mark " +
      "today’s doses (taken / missed). Adherence also shows on Dashboard. " +
      "Reminders are configured in Profile -> Notifications — I can’t change your " +
      "prescription; ask your clinician for dose changes."
    );
  }

  if (/distress|breath|ground|safety plan|kit/i.test(q)) {
    return (
      "Distress kit has breathing, grounding, and your safety plan. " +
      "Crisis SOS opens calm steps plus safe-person / 119 / 112 — taps open the " +
      "phone dialer with the number filled in; nothing auto-calls."
    );
  }

  if (/link|clinician|psychiatr|join.?code|code/i.test(q)) {
    return (
      "To link a clinician: open the Link tab -> enter the join code they shared " +
      "from their Groups page. Once linked you can see connection status on Home. " +
      "Monitoring controls whether they can view your diary trends."
    );
  }

  if (/dashboard|chart|graph|trend/i.test(q)) {
    return (
      "Dashboard shows your personal mood and medication adherence trends. " +
      "Open it from the Dashboard tab or Quick actions on Home."
    );
  }

  if (/profile|password|photo|account/i.test(q)) {
    return (
      "Profile lets you update your name and photo, change password, configure " +
      "Notifications, and sign out."
    );
  }

  if (/tab|navigat|where|how.*(use|open|find)|feature|app/i.test(q)) {
    return (
      "Patient navigation: Home · Diary · Meds · Distress · Dashboard · Link · Profile. " +
      "Ask me about any of those — e.g. diary logging, meds, reminders, distress SOS, " +
      "or linking your clinician."
    );
  }

  return (
    "I can help with Curamind features: Diary, Meds, reminders (Profile -> Notifications), " +
    "Distress / SOS, Dashboard, and linking a clinician. What would you like to do?"
  );
}

async function geminiReply(turns: ChatTurn[]): Promise<string | null> {
  const apiKey = (process.env.GEMINI_API_KEY ?? "").trim();
  if (!apiKey) return null;

  const model = (process.env.GEMINI_MODEL ?? "gemini-flash-lite-latest").trim();
  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/` +
    `${encodeURIComponent(model)}:generateContent?key=${encodeURIComponent(apiKey)}`;

  const contents = turns.map((t) => ({
    role: t.role === "user" ? "user" : "model",
    parts: [{ text: t.content }],
  }));

  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      systemInstruction: {
        parts: [{ text: SYSTEM_INSTRUCTION }],
      },
      contents,
      generationConfig: {
        temperature: 0.4,
        maxOutputTokens: 512,
      },
    }),
  });

  const data = (await res.json()) as {
    error?: { message?: string };
    candidates?: Array<{
      content?: { parts?: Array<{ text?: string }> };
    }>;
  };

  if (!res.ok) {
    throw new Error(data.error?.message ?? `Gemini HTTP ${res.status}`);
  }

  const text = data.candidates?.[0]?.content?.parts
    ?.map((p) => p.text ?? "")
    .join("")
    .trim();

  return text || null;
}

chatRouter.post("/", async (req: Request, res: Response) => {
  try {
    const turns = asTurns(req.body?.messages);
    if (turns.length === 0) {
      return res.status(400).json({ error: "messages array is required." });
    }

    const lastUser =
      [...turns].reverse().find((t) => t.role === "user")?.content ?? "";

    let reply: string | null = null;
    let source: "gemini" | "local" = "local";

    try {
      reply = await geminiReply(turns);
      if (reply) source = "gemini";
    } catch (err) {
      console.warn("[chat] Gemini failed, using local fallback:", err);
    }

    if (!reply) {
      reply = localReply(lastUser);
      source = "local";
    }

    return res.json({
      reply,
      source,
      model:
        source === "gemini"
          ? process.env.GEMINI_MODEL ?? "gemini-flash-lite-latest"
          : "local-faq",
    });
  } catch (err) {
    console.error("[chat]", err);
    return res.status(500).json({ error: "Chat failed." });
  }
});
