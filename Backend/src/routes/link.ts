import { Router, Request, Response } from "express";
import { prisma } from "../index";
import { LinkStatus } from "@prisma/client";

export const linkRouter = Router();

const generateCode = () => {
  const chunk = () =>
    Math.random().toString(36).substring(2, 6).toUpperCase();
  return `CURA-${chunk()}`;
};

/** Allowed expiry presets in minutes. null / 0 = never. */
const ALLOWED_EXPIRY_MINUTES = new Set([15, 60, 1440, 10080]);

const resolveExpiresAt = (expires_in_minutes?: number | null): Date | null => {
  if (
    expires_in_minutes == null ||
    expires_in_minutes === 0 ||
    !Number.isFinite(expires_in_minutes)
  ) {
    return null;
  }
  if (!ALLOWED_EXPIRY_MINUTES.has(expires_in_minutes)) {
    throw new Error("INVALID_EXPIRY");
  }
  return new Date(Date.now() + expires_in_minutes * 60 * 1000);
};

const isExpired = (expiresAt: Date | null | undefined) =>
  !!expiresAt && expiresAt.getTime() <= Date.now();

const serializeGroup = (group: {
  id: string;
  code: string;
  name: string;
  is_active: boolean;
  expires_at: Date | null;
  created_at: Date;
  psychiatrist_id: string;
  psychiatrist_name: string | null;
  psychiatrist_email: string | null;
  _count?: { care_links: number };
  member_count?: number;
}) => ({
  id: group.id,
  code: group.code,
  name: group.name,
  is_active: group.is_active,
  expires_at: group.expires_at,
  is_expired: isExpired(group.expires_at),
  member_count: group._count?.care_links ?? group.member_count ?? 0,
  created_at: group.created_at,
  psychiatrist_id: group.psychiatrist_id,
  psychiatrist_name: group.psychiatrist_name,
  psychiatrist_email: group.psychiatrist_email,
});

/** Create a join group (1 group = 1 code). Psychiatrist may own many. */
linkRouter.post("/groups", async (req: Request, res: Response) => {
  const {
    psychiatrist_id,
    psychiatrist_name,
    psychiatrist_email,
    name,
    expires_in_minutes,
  } = req.body as {
    psychiatrist_id?: string;
    psychiatrist_name?: string;
    psychiatrist_email?: string;
    name?: string;
    expires_in_minutes?: number | null;
  };

  if (!psychiatrist_id) {
    return res.status(400).json({ error: "psychiatrist_id is required" });
  }

  let expiresAt: Date | null;
  try {
    expiresAt = resolveExpiresAt(expires_in_minutes);
  } catch {
    return res.status(400).json({
      error: "expires_in_minutes must be 15, 60, 1440, 10080, or null (never).",
    });
  }

  try {
    let code = generateCode();
    for (let i = 0; i < 8; i++) {
      const exists = await prisma.joinGroup.findUnique({ where: { code } });
      if (!exists) break;
      code = generateCode();
    }

    const group = await prisma.joinGroup.create({
      data: {
        psychiatrist_id,
        psychiatrist_name: psychiatrist_name?.trim() || null,
        psychiatrist_email: psychiatrist_email?.trim() || null,
        code,
        name: (name?.trim() || "Care group").slice(0, 80),
        is_active: true,
        expires_at: expiresAt,
      },
      include: {
        _count: { select: { care_links: true } },
      },
    });

    return res.status(201).json({
      message: "Join group created",
      group: serializeGroup(group),
    });
  } catch (error) {
    console.error("Create group error:", error);
    return res.status(500).json({ error: "Failed to create join group." });
  }
});

linkRouter.get("/groups/:psychiatristId", async (req: Request, res: Response) => {
  try {
    const groups = await prisma.joinGroup.findMany({
      where: { psychiatrist_id: String(req.params.psychiatristId ?? "") },
      orderBy: { created_at: "desc" },
      include: {
        _count: { select: { care_links: true } },
        care_links: {
          orderBy: { created_at: "desc" },
          take: 8,
          select: {
            patient_id: true,
            patient_name: true,
          },
        },
      },
    });
    return res.json({
      groups: groups.map((g) => ({
        ...serializeGroup(g),
        members_preview: g.care_links.map((l) => ({
          patient_id: l.patient_id,
          patient_name: l.patient_name ?? "Patient",
        })),
      })),
    });
  } catch (error) {
    console.error("List groups error:", error);
    return res.status(500).json({ error: "Failed to list join groups." });
  }
});

linkRouter.get("/groups/:groupId/members", async (req: Request, res: Response) => {
  const groupId = String(req.params.groupId ?? "");
  const psychiatristId =
    typeof req.query.psychiatrist_id === "string"
      ? req.query.psychiatrist_id
      : "";

  if (!groupId) {
    return res.status(400).json({ error: "groupId is required." });
  }

  try {
    const group = await prisma.joinGroup.findUnique({ where: { id: groupId } });
    if (!group) {
      return res.status(404).json({ error: "Join group not found." });
    }
    if (psychiatristId && group.psychiatrist_id !== psychiatristId) {
      return res.status(403).json({ error: "Not allowed to view this group." });
    }

    const links = await prisma.careLink.findMany({
      where: { join_group_id: groupId },
      orderBy: { created_at: "desc" },
    });

    const patientIds = links.map((l) => l.patient_id);
    const users =
      patientIds.length > 0
        ? await prisma.user.findMany({ where: { id: { in: patientIds } } })
        : [];
    const userById = Object.fromEntries(users.map((u) => [u.id, u]));

    const meds =
      patientIds.length > 0
        ? await prisma.medication.findMany({
            where: {
              patient_id: { in: patientIds },
              is_active: true,
            },
            orderBy: { created_at: "desc" },
          })
        : [];

    const diaryCounts =
      patientIds.length > 0
        ? await prisma.diaryEntry.groupBy({
            by: ["patient_id"],
            where: { patient_id: { in: patientIds } },
            _count: { _all: true },
          })
        : [];
    const diaryByPatient = Object.fromEntries(
      diaryCounts.map((d) => [d.patient_id, d._count._all]),
    );

    const medsByPatient = new Map<string, typeof meds>();
    for (const m of meds) {
      const list = medsByPatient.get(m.patient_id) ?? [];
      list.push(m);
      medsByPatient.set(m.patient_id, list);
    }

    return res.json({
      group: serializeGroup({
        ...group,
        member_count: links.length,
      }),
      members: links.map((l) => {
        const user = userById[l.patient_id];
        const patientMeds = medsByPatient.get(l.patient_id) ?? [];
        return {
          link_id: l.id,
          patient_id: l.patient_id,
          patient_name: l.patient_name ?? user?.full_name ?? "Patient",
          email: user?.email ?? null,
          status: l.status,
          monitoring_on: l.monitoring_on,
          linked_at: l.created_at,
          diary_entries: diaryByPatient[l.patient_id] ?? 0,
          active_meds_count: patientMeds.length,
          medications: patientMeds.map((m) => ({
            id: m.id,
            name: m.name,
            dosage_and_freq: m.dosage_and_freq,
            is_active: m.is_active,
            created_at: m.created_at,
          })),
        };
      }),
    });
  } catch (error) {
    console.error("List group members error:", error);
    return res.status(500).json({ error: "Failed to list group members." });
  }
});

linkRouter.patch("/groups/:groupId", async (req: Request, res: Response) => {
  const { is_active, name, psychiatrist_id } = req.body as {
    is_active?: boolean;
    name?: string;
    psychiatrist_id?: string;
  };

  if (typeof is_active !== "boolean" && typeof name !== "string") {
    return res.status(400).json({
      error: "Provide is_active (boolean) and/or name (string).",
    });
  }

  const groupId = String(req.params.groupId ?? "");
  if (!groupId) {
    return res.status(400).json({ error: "groupId is required." });
  }

  try {
    const existing = await prisma.joinGroup.findUnique({ where: { id: groupId } });
    if (!existing) {
      return res.status(404).json({ error: "Join group not found." });
    }
    if (psychiatrist_id && existing.psychiatrist_id !== psychiatrist_id) {
      return res.status(403).json({ error: "Not allowed to update this group." });
    }

    const data: { is_active?: boolean; name?: string } = {};
    if (typeof is_active === "boolean") data.is_active = is_active;
    if (typeof name === "string") {
      const trimmed = name.trim();
      if (!trimmed) {
        return res.status(400).json({ error: "name cannot be empty." });
      }
      data.name = trimmed.slice(0, 80);
    }

    const group = await prisma.joinGroup.update({
      where: { id: groupId },
      data,
      include: { _count: { select: { care_links: true } } },
    });
    return res.json({
      group: serializeGroup(group),
    });
  } catch (error) {
    console.error("Patch group error:", error);
    return res.status(500).json({ error: "Failed to update join group." });
  }
});

linkRouter.post("/groups/:groupId/regenerate", async (req: Request, res: Response) => {
  const groupId = String(req.params.groupId ?? "");
  const {
    psychiatrist_id,
    expires_in_minutes,
  } = req.body as {
    psychiatrist_id?: string;
    expires_in_minutes?: number | null;
  };

  if (!groupId) {
    return res.status(400).json({ error: "groupId is required." });
  }
  if (!psychiatrist_id) {
    return res.status(400).json({ error: "psychiatrist_id is required." });
  }

  let expiresAt: Date | null;
  try {
    expiresAt = resolveExpiresAt(expires_in_minutes);
  } catch {
    return res.status(400).json({
      error: "expires_in_minutes must be 15, 60, 1440, 10080, or null (never).",
    });
  }

  try {
    const existing = await prisma.joinGroup.findUnique({ where: { id: groupId } });
    if (!existing) {
      return res.status(404).json({ error: "Join group not found." });
    }
    if (existing.psychiatrist_id !== psychiatrist_id) {
      return res.status(403).json({ error: "Not allowed to regenerate this code." });
    }

    let code = generateCode();
    for (let i = 0; i < 8; i++) {
      const taken = await prisma.joinGroup.findUnique({ where: { code } });
      if (!taken) break;
      code = generateCode();
    }

    const group = await prisma.joinGroup.update({
      where: { id: groupId },
      data: {
        code,
        expires_at: expiresAt,
        is_active: true,
      },
      include: { _count: { select: { care_links: true } } },
    });

    return res.json({
      message: "Invite code regenerated.",
      group: serializeGroup(group),
    });
  } catch (error) {
    console.error("Regenerate group code error:", error);
    return res.status(500).json({ error: "Failed to regenerate join code." });
  }
});

linkRouter.delete("/groups/:groupId", async (req: Request, res: Response) => {
  const groupId = String(req.params.groupId ?? "");
  const psychiatristId =
    typeof req.query.psychiatrist_id === "string"
      ? req.query.psychiatrist_id
      : typeof req.body?.psychiatrist_id === "string"
        ? req.body.psychiatrist_id
        : "";

  if (!groupId) {
    return res.status(400).json({ error: "groupId is required." });
  }

  try {
    const group = await prisma.joinGroup.findUnique({ where: { id: groupId } });
    if (!group) {
      return res.status(404).json({ error: "Join group not found." });
    }
    if (psychiatristId && group.psychiatrist_id !== psychiatristId) {
      return res.status(403).json({ error: "Not allowed to delete this group." });
    }

    await prisma.joinGroup.delete({ where: { id: groupId } });

    return res.json({
      message: "Join code deleted. Existing patient links are unchanged.",
      id: groupId,
    });
  } catch (error) {
    console.error("Delete group error:", error);
    return res.status(500).json({ error: "Failed to delete join group." });
  }
});

linkRouter.post("/join", async (req: Request, res: Response) => {
  const { patient_id, patient_name, code } = req.body as {
    patient_id?: string;
    patient_name?: string;
    code?: string;
  };

  if (!patient_id || !code) {
    return res.status(400).json({ error: "patient_id and code are required" });
  }

  const upper = code.trim().toUpperCase();

  try {
    const existing = await prisma.careLink.findUnique({
      where: { patient_id },
    });
    if (existing) {
      return res.status(409).json({
        error: "You are already linked to a psychiatrist. Disconnect first.",
      });
    }

    const group = await prisma.joinGroup.findUnique({ where: { code: upper } });

    if (!group || !group.is_active) {
      return res.status(404).json({ error: "Invalid or inactive join code." });
    }

    if (isExpired(group.expires_at)) {
      return res.status(410).json({
        error: "This join code has expired. Ask your psychiatrist for a new one.",
      });
    }

    const link = await prisma.careLink.create({
      data: {
        patient_id,
        patient_name: patient_name?.trim() || null,
        psychiatrist_id: group.psychiatrist_id,
        join_group_id: group.id,
        status: LinkStatus.ACTIVE,
        monitoring_on: true,
      },
    });

    return res.json({
      message: "Successfully linked with psychiatrist",
      link: {
        id: link.id,
        status: link.status,
        monitoring_on: link.monitoring_on,
        linked_at: link.created_at,
        group_code: group.code,
        group_name: group.name,
        psychiatrist: {
          id: group.psychiatrist_id,
          full_name: group.psychiatrist_name ?? "Clinician",
          email: group.psychiatrist_email ?? "",
        },
      },
    });
  } catch (error) {
    console.error("Join error:", error);
    return res.status(500).json({ error: "Failed to join care group." });
  }
});

linkRouter.get("/patient/:patientId", async (req: Request, res: Response) => {
  try {
    const link = await prisma.careLink.findUnique({
      where: { patient_id: String(req.params.patientId ?? "") },
    });
    if (!link) return res.json({ link: null });

    const group = link.join_group_id
      ? await prisma.joinGroup.findUnique({ where: { id: link.join_group_id } })
      : null;

    let clinicianName = group?.psychiatrist_name ?? null;
    let clinicianEmail = group?.psychiatrist_email ?? null;
    if (!clinicianName) {
      const user = await prisma.user.findUnique({
        where: { id: link.psychiatrist_id },
      });
      clinicianName = user?.full_name ?? "Clinician";
      clinicianEmail = user?.email ?? "";
    }

    return res.json({
      link: {
        id: link.id,
        status: link.status,
        monitoring_on: link.monitoring_on,
        linked_at: link.created_at,
        group_code: group?.code ?? "",
        group_name: group?.name ?? "Care group",
        psychiatrist: {
          id: link.psychiatrist_id,
          full_name: clinicianName,
          email: clinicianEmail ?? "",
        },
      },
    });
  } catch (error) {
    console.error("Get patient link error:", error);
    return res.status(500).json({ error: "Failed to load link." });
  }
});

linkRouter.patch("/patient/:patientId/monitoring", async (req: Request, res: Response) => {
  const { monitoring_on } = req.body as { monitoring_on?: boolean };
  if (typeof monitoring_on !== "boolean") {
    return res.status(400).json({ error: "monitoring_on boolean required" });
  }
  try {
    const link = await prisma.careLink.update({
      where: { patient_id: String(req.params.patientId ?? "") },
      data: { monitoring_on },
    });
    const group = link.join_group_id
      ? await prisma.joinGroup.findUnique({ where: { id: link.join_group_id } })
      : null;
    return res.json({
      link: {
        id: link.id,
        status: link.status,
        monitoring_on: link.monitoring_on,
        group_code: group?.code ?? "",
        group_name: group?.name ?? "Care group",
      },
    });
  } catch (error) {
    console.error("Patch monitoring error:", error);
    return res.status(500).json({ error: "Failed to update monitoring." });
  }
});

linkRouter.delete("/patient/:patientId", async (req: Request, res: Response) => {
  try {
    await prisma.careLink.delete({
      where: { patient_id: String(req.params.patientId ?? "") },
    });
    return res.json({ message: "Disconnected" });
  } catch (error) {
    console.error("Disconnect error:", error);
    return res.status(500).json({ error: "Failed to disconnect." });
  }
});
