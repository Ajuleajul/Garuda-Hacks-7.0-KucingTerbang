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
      include: { _count: { select: { care_links: true } } },
    });
    return res.json({
      groups: groups.map(serializeGroup),
    });
  } catch (error) {
    console.error("List groups error:", error);
    return res.status(500).json({ error: "Failed to list join groups." });
  }
});

linkRouter.patch("/groups/:groupId", async (req: Request, res: Response) => {
  const { is_active } = req.body as { is_active?: boolean };
  if (typeof is_active !== "boolean") {
    return res.status(400).json({ error: "is_active boolean required" });
  }
  try {
    const group = await prisma.joinGroup.update({
      where: { id: String(req.params.groupId ?? "") },
      data: { is_active },
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
