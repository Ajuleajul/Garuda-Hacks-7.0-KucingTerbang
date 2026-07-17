import { Router, Request, Response } from "express";
import { DiaryEntryKind, LinkStatus } from "@prisma/client";
import { prisma } from "../index";
import {
  decryptString,
  decryptStringList,
  encryptString,
  encryptStringList,
} from "../crypto/fieldCrypto";

export const diaryRouter = Router();

const MAX_TEXT = 1200;
const MAX_LIST = 12;

const pickString = (value: unknown, max = MAX_TEXT) => {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  if (!trimmed) return null;
  return trimmed.slice(0, max);
};

const pickScore = (value: unknown) => {
  if (typeof value !== "number" || !Number.isFinite(value)) return null;
  const rounded = Math.round(value);
  return rounded < 0 || rounded > 10 ? null : rounded;
};

const pickList = (value: unknown) => {
  if (!Array.isArray(value)) return [];
  return value
    .map((item) => pickString(item, 60))
    .filter((item): item is string => !!item)
    .slice(0, MAX_LIST);
};

const mapKind = (value: unknown) => {
  const raw = typeof value === "string" ? value.trim().toUpperCase() : "";
  if (raw === "DBT_CARD") return DiaryEntryKind.DBT_CARD;
  if (raw === "COPING") return DiaryEntryKind.COPING;
  return null;
};

const serializeEntry = (entry: {
  id: string;
  patient_id: string;
  kind: DiaryEntryKind;
  mood: number | null;
  affect_intensity: number | null;
  urge_nssi: number | null;
  urge_substance: number | null;
  emotions: string[];
  triggers: string[];
  skills: string[];
  notes: string | null;
  situation: string | null;
  thoughts: string | null;
  behavior: string | null;
  outcome: string | null;
  created_at: Date;
}) => ({
  id: entry.id,
  patient_id: entry.patient_id,
  kind: entry.kind,
  mood: entry.mood,
  affect_intensity: entry.affect_intensity,
  urge_nssi: entry.urge_nssi,
  urge_substance: entry.urge_substance,
  emotions: decryptStringList(entry.emotions),
  triggers: decryptStringList(entry.triggers),
  skills: decryptStringList(entry.skills),
  notes: decryptString(entry.notes),
  situation: decryptString(entry.situation),
  thoughts: decryptString(entry.thoughts),
  behavior: decryptString(entry.behavior),
  outcome: decryptString(entry.outcome),
  created_at: entry.created_at,
});

diaryRouter.post("/", async (req: Request, res: Response) => {
  const patientId =
    typeof req.body.patient_id === "string" ? req.body.patient_id.trim() : "";
  const kind = mapKind(req.body.kind);

  if (!patientId || !kind) {
    return res.status(400).json({ error: "patient_id and valid kind are required." });
  }

  const emotions = pickList(req.body.emotions);
  const triggers = pickList(req.body.triggers);
  const skills = pickList(req.body.skills);
  const notes = pickString(req.body.notes);
  const situation = pickString(req.body.situation);
  const thoughts = pickString(req.body.thoughts);
  const behavior = pickString(req.body.behavior);
  const outcome = pickString(req.body.outcome);

  const payload = {
    patient_id: patientId,
    kind,
    mood: pickScore(req.body.mood),
    affect_intensity: pickScore(req.body.affect_intensity),
    urge_nssi: pickScore(req.body.urge_nssi),
    urge_substance: pickScore(req.body.urge_substance),
    emotions: encryptStringList(emotions),
    triggers: encryptStringList(triggers),
    skills: encryptStringList(skills),
    notes: encryptString(notes),
    situation: encryptString(situation),
    thoughts: encryptString(thoughts),
    behavior: encryptString(behavior),
    outcome: encryptString(outcome),
  };

  if (kind === DiaryEntryKind.DBT_CARD && notes == null && emotions.length === 0 && triggers.length === 0 && skills.length === 0) {
    return res.status(400).json({ error: "DBT card needs at least one detail." });
  }

  if (kind === DiaryEntryKind.COPING && !situation && !thoughts && !behavior && !outcome) {
    return res.status(400).json({ error: "Coping entry cannot be empty." });
  }

  try {
    const entry = await prisma.diaryEntry.create({ data: payload });
    return res.status(201).json({ entry: serializeEntry(entry) });
  } catch (error) {
    console.error("Create diary entry error:", error);
    return res.status(500).json({ error: "Failed to save diary entry." });
  }
});

diaryRouter.get("/patient/:patientId", async (req: Request, res: Response) => {
  const patientId = String(req.params.patientId ?? "");
  const limitRaw = Number(req.query.limit ?? 100);
  const limit = Number.isFinite(limitRaw) ? Math.min(Math.max(limitRaw, 1), 200) : 100;

  try {
    const entries = await prisma.diaryEntry.findMany({
      where: { patient_id: patientId },
      orderBy: { created_at: "desc" },
      take: limit,
    });
    return res.json({ entries: entries.map(serializeEntry) });
  } catch (error) {
    console.error("List patient diary error:", error);
    return res.status(500).json({ error: "Failed to load diary entries." });
  }
});

diaryRouter.get("/clinician/:clinicianId/patient/:patientId", async (req: Request, res: Response) => {
  const clinicianId = String(req.params.clinicianId ?? "");
  const patientId = String(req.params.patientId ?? "");
  const limitRaw = Number(req.query.limit ?? 100);
  const limit = Number.isFinite(limitRaw) ? Math.min(Math.max(limitRaw, 1), 200) : 100;

  try {
    const link = await prisma.careLink.findFirst({
      where: {
        psychiatrist_id: clinicianId,
        patient_id: patientId,
        status: LinkStatus.ACTIVE,
      },
    });

    if (!link) {
      return res.status(403).json({ error: "No active care link for this patient." });
    }

    if (!link.monitoring_on) {
      return res.json({
        monitoring_on: false,
        entries: [],
      });
    }

    const entries = await prisma.diaryEntry.findMany({
      where: { patient_id: patientId },
      orderBy: { created_at: "desc" },
      take: limit,
    });
    return res.json({
      monitoring_on: true,
      entries: entries.map(serializeEntry),
    });
  } catch (error) {
    console.error("List clinician diary error:", error);
    return res.status(500).json({ error: "Failed to load linked patient diary." });
  }
});
