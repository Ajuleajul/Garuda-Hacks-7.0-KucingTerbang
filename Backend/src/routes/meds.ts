import { Router, Request, Response } from "express";
import { LinkStatus, LogStatus } from "@prisma/client";
import { prisma } from "../index";

export const medsRouter = Router();

const dayKey = (d = new Date()) => {
  const y = d.getUTCFullYear();
  const m = String(d.getUTCMonth() + 1).padStart(2, "0");
  const day = String(d.getUTCDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
};

const serializeMed = (
  med: {
    id: string;
    patient_id: string;
    patient_name: string | null;
    psychiatrist_id: string;
    name: string;
    dosage_and_freq: string;
    is_active: boolean;
    created_at: Date;
  },
  todayLog?: { id: string; status: LogStatus; logged_at: Date } | null,
) => ({
  id: med.id,
  patient_id: med.patient_id,
  patient_name: med.patient_name,
  psychiatrist_id: med.psychiatrist_id,
  name: med.name,
  dosage_and_freq: med.dosage_and_freq,
  is_active: med.is_active,
  created_at: med.created_at,
  today_status: todayLog?.status ?? null,
  today_logged_at: todayLog?.logged_at ?? null,
  today_log_id: todayLog?.id ?? null,
});

medsRouter.get("/clinician/:clinicianId/patients", async (req: Request, res: Response) => {
  const clinicianId = String(req.params.clinicianId ?? "");
  try {
    const links = await prisma.careLink.findMany({
      where: {
        psychiatrist_id: clinicianId,
        status: LinkStatus.ACTIVE,
      },
      orderBy: { created_at: "desc" },
    });
    const groupIds = [
      ...new Set(
        links
          .map((l) => l.join_group_id)
          .filter((id): id is string => typeof id === "string" && id.length > 0),
      ),
    ];
    const groups = groupIds.length
      ? await prisma.joinGroup.findMany({ where: { id: { in: groupIds } } })
      : [];
    const groupById = Object.fromEntries(groups.map((g) => [g.id, g]));
    return res.json({
      patients: links.map((l) => {
        const g = l.join_group_id ? groupById[l.join_group_id] : undefined;
        return {
          patient_id: l.patient_id,
          patient_name: l.patient_name ?? "Patient",
          monitoring_on: l.monitoring_on,
          linked_at: l.created_at,
          group_id: l.join_group_id,
          group_code: g?.code ?? null,
          group_name: g?.name ?? null,
        };
      }),
    });
  } catch (error) {
    console.error("List clinician patients error:", error);
    return res.status(500).json({ error: "Failed to list patients." });
  }
});

medsRouter.get("/clinician/:clinicianId", async (req: Request, res: Response) => {
  const clinicianId = String(req.params.clinicianId ?? "");
  try {
    const meds = await prisma.medication.findMany({
      where: { psychiatrist_id: clinicianId },
      orderBy: { created_at: "desc" },
    });
    return res.json({
      medications: meds.map((m) => serializeMed(m)),
    });
  } catch (error) {
    console.error("List clinician meds error:", error);
    return res.status(500).json({ error: "Failed to list medications." });
  }
});

medsRouter.post("/", async (req: Request, res: Response) => {
  const {
    psychiatrist_id,
    patient_id,
    patient_name,
    name,
    dosage_and_freq,
  } = req.body as {
    psychiatrist_id?: string;
    patient_id?: string;
    patient_name?: string;
    name?: string;
    dosage_and_freq?: string;
  };

  if (!psychiatrist_id || !patient_id || !name?.trim() || !dosage_and_freq?.trim()) {
    return res.status(400).json({
      error: "psychiatrist_id, patient_id, name, and dosage_and_freq are required.",
    });
  }

  try {
    const link = await prisma.careLink.findFirst({
      where: {
        psychiatrist_id,
        patient_id,
        status: LinkStatus.ACTIVE,
      },
    });
    if (!link) {
      return res.status(403).json({
        error: "Patient is not linked to this clinician.",
      });
    }

    const med = await prisma.medication.create({
      data: {
        psychiatrist_id,
        patient_id,
        patient_name: (patient_name?.trim() || link.patient_name || "Patient").slice(0, 120),
        name: name.trim().slice(0, 120),
        dosage_and_freq: dosage_and_freq.trim().slice(0, 200),
        is_active: true,
      },
    });
    return res.status(201).json({ medication: serializeMed(med) });
  } catch (error) {
    console.error("Create medication error:", error);
    return res.status(500).json({ error: "Failed to prescribe medication." });
  }
});

medsRouter.patch("/:medId", async (req: Request, res: Response) => {
  const medId = String(req.params.medId ?? "");
  const { is_active, name, dosage_and_freq } = req.body as {
    is_active?: boolean;
    name?: string;
    dosage_and_freq?: string;
  };

  try {
    const med = await prisma.medication.update({
      where: { id: medId },
      data: {
        ...(typeof is_active === "boolean" ? { is_active } : {}),
        ...(name?.trim() ? { name: name.trim().slice(0, 120) } : {}),
        ...(dosage_and_freq?.trim()
          ? { dosage_and_freq: dosage_and_freq.trim().slice(0, 200) }
          : {}),
      },
    });
    return res.json({ medication: serializeMed(med) });
  } catch (error) {
    console.error("Patch medication error:", error);
    return res.status(500).json({ error: "Failed to update medication." });
  }
});

medsRouter.get("/patient/:patientId", async (req: Request, res: Response) => {
  const patientId = String(req.params.patientId ?? "");
  const key = dayKey();
  try {
    const link = await prisma.careLink.findUnique({
      where: { patient_id: patientId },
    });
    const linked = !!link && link.status === LinkStatus.ACTIVE;

    const meds = await prisma.medication.findMany({
      where: { patient_id: patientId, is_active: true },
      orderBy: { created_at: "desc" },
      include: {
        logs: {
          where: { day_key: key },
          take: 1,
        },
      },
    });

    const taken = meds.filter((m) => m.logs[0]?.status === LogStatus.TAKEN).length;
    const missed = meds.filter((m) => m.logs[0]?.status === LogStatus.MISSED).length;
    const due = meds.length - taken - missed;
    const logged = taken + missed;
    const adherence_pct = logged === 0 ? 0 : Math.round((taken / logged) * 100);

    let clinician_name: string | null = null;
    let group_name: string | null = null;
    if (link) {
      if (link.join_group_id) {
        const group = await prisma.joinGroup.findUnique({
          where: { id: link.join_group_id },
        });
        clinician_name = group?.psychiatrist_name ?? null;
        group_name = group?.name ?? null;
      }
      if (!clinician_name) {
        const user = await prisma.user.findUnique({
          where: { id: link.psychiatrist_id },
        });
        clinician_name = user?.full_name ?? "Clinician";
      }
      group_name = group_name ?? "Care group";
    }

    return res.json({
      day_key: key,
      linked,
      clinician_name,
      group_name,
      stats: {
        active: meds.length,
        due,
        taken,
        missed,
        adherence_pct,
      },
      medications: meds.map((m) => serializeMed(m, m.logs[0] ?? null)),
    });
  } catch (error) {
    console.error("List patient meds error:", error);
    return res.status(500).json({ error: "Failed to load medications." });
  }
});

medsRouter.get("/patient/:patientId/stats", async (req: Request, res: Response) => {
  const patientId = String(req.params.patientId ?? "");
  const daysRaw = Number(req.query.days ?? 7);
  const days = Number.isFinite(daysRaw) ? Math.min(Math.max(Math.floor(daysRaw), 1), 90) : 7;

  try {
    const since = new Date();
    since.setUTCDate(since.getUTCDate() - (days - 1));
    since.setUTCHours(0, 0, 0, 0);

    const activeMeds = await prisma.medication.count({
      where: { patient_id: patientId, is_active: true },
    });

    const logs = await prisma.medicationLog.findMany({
      where: {
        patient_id: patientId,
        logged_at: { gte: since },
      },
      select: { status: true, day_key: true },
    });

    const taken = logs.filter((l) => l.status === LogStatus.TAKEN).length;
    const missed = logs.filter((l) => l.status === LogStatus.MISSED).length;
    const logged = taken + missed;
    const adherence_pct = logged === 0 ? 0 : Math.round((taken / logged) * 100);

    const byDay: Record<string, { taken: number; missed: number }> = {};
    for (const l of logs) {
      if (!byDay[l.day_key]) byDay[l.day_key] = { taken: 0, missed: 0 };
      if (l.status === LogStatus.TAKEN) byDay[l.day_key].taken += 1;
      else byDay[l.day_key].missed += 1;
    }

    return res.json({
      days,
      active_meds: activeMeds,
      taken,
      missed,
      logged,
      adherence_pct,
      by_day: Object.entries(byDay)
        .sort(([a], [b]) => a.localeCompare(b))
        .map(([day_key, v]) => ({ day_key, ...v })),
    });
  } catch (error) {
    console.error("Patient meds stats error:", error);
    return res.status(500).json({ error: "Failed to load medication stats." });
  }
});

medsRouter.post("/:medId/log", async (req: Request, res: Response) => {
  const medId = String(req.params.medId ?? "");
  const { patient_id, status } = req.body as {
    patient_id?: string;
    status?: string;
  };

  if (!patient_id) {
    return res.status(400).json({ error: "patient_id is required." });
  }
  const next =
    status === "TAKEN"
      ? LogStatus.TAKEN
      : status === "MISSED"
        ? LogStatus.MISSED
        : null;
  if (!next) {
    return res.status(400).json({ error: "status must be TAKEN or MISSED." });
  }

  try {
    const med = await prisma.medication.findFirst({
      where: { id: medId, patient_id, is_active: true },
    });
    if (!med) {
      return res.status(404).json({ error: "Medication not found." });
    }

    const key = dayKey();
    const log = await prisma.medicationLog.upsert({
      where: {
        medication_id_day_key: {
          medication_id: medId,
          day_key: key,
        },
      },
      create: {
        medication_id: medId,
        patient_id,
        status: next,
        day_key: key,
      },
      update: {
        status: next,
        logged_at: new Date(),
      },
    });

    return res.json({
      medication: serializeMed(med, log),
    });
  } catch (error) {
    console.error("Log medication error:", error);
    return res.status(500).json({ error: "Failed to log medication." });
  }
});

medsRouter.delete("/:medId/log", async (req: Request, res: Response) => {
  const medId = String(req.params.medId ?? "");
  const patientId =
    typeof req.query.patient_id === "string"
      ? req.query.patient_id
      : typeof req.body?.patient_id === "string"
        ? req.body.patient_id
        : "";

  if (!patientId) {
    return res.status(400).json({ error: "patient_id is required." });
  }

  try {
    const med = await prisma.medication.findFirst({
      where: { id: medId, patient_id: patientId, is_active: true },
    });
    if (!med) {
      return res.status(404).json({ error: "Medication not found." });
    }

    const key = dayKey();
    await prisma.medicationLog.deleteMany({
      where: { medication_id: medId, day_key: key, patient_id: patientId },
    });

    return res.json({ medication: serializeMed(med, null) });
  } catch (error) {
    console.error("Clear medication log error:", error);
    return res.status(500).json({ error: "Failed to clear medication log." });
  }
});
