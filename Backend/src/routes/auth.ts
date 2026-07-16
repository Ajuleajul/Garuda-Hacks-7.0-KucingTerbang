import { Router, Request, Response } from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { Role } from "../../generated/prisma/client";
import { prisma } from "../prisma";

const router = Router();

type AuthBody = {
  email?: string;
  password?: string;
  full_name?: string;
  role?: string;
};

function mapRole(role?: string): Role | null {
  if (!role) return null;
  const normalized = role.trim().toUpperCase();
  if (normalized === "PASIEN" || normalized === "PATIENT") return Role.PASIEN;
  if (
    normalized === "PSIKIATER" ||
    normalized === "PSYCHIATRIST" ||
    normalized === "CLINICIAN"
  ) {
    return Role.PSIKIATER;
  }
  return null;
}

function publicUser(user: {
  id: string;
  email: string;
  full_name: string;
  role: Role;
  created_at: Date;
}) {
  return {
    id: user.id,
    email: user.email,
    full_name: user.full_name,
    role: user.role,
    created_at: user.created_at,
  };
}

function signToken(userId: string, role: Role) {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    throw new Error("JWT_SECRET is not set");
  }
  return jwt.sign({ sub: userId, role }, secret, { expiresIn: "7d" });
}

router.post("/register", async (req: Request, res: Response) => {
  try {
    const { email, password, full_name, role } = req.body as AuthBody;

    if (!email?.trim() || !password || !full_name?.trim() || !role) {
      return res.status(400).json({
        message: "email, password, full_name, and role are required",
      });
    }

    if (password.length < 6) {
      return res
        .status(400)
        .json({ message: "Password must be at least 6 characters" });
    }

    const mappedRole = mapRole(role);
    if (!mappedRole) {
      return res.status(400).json({
        message: 'role must be "PASIEN" or "PSIKIATER"',
      });
    }

    const existing = await prisma.user.findUnique({
      where: { email: email.trim().toLowerCase() },
    });
    if (existing) {
      return res.status(409).json({ message: "Email is already registered" });
    }

    const password_hash = await bcrypt.hash(password, 10);
    const user = await prisma.user.create({
      data: {
        email: email.trim().toLowerCase(),
        full_name: full_name.trim(),
        password_hash,
        role: mappedRole,
      },
    });

    const token = signToken(user.id, user.role);
    return res.status(201).json({
      token,
      user: publicUser(user),
    });
  } catch (error) {
    console.error("POST /auth/register", error);
    return res.status(500).json({ message: "Registration failed" });
  }
});

router.post("/login", async (req: Request, res: Response) => {
  try {
    const { email, password, role } = req.body as AuthBody;

    if (!email?.trim() || !password) {
      return res
        .status(400)
        .json({ message: "email and password are required" });
    }

    const user = await prisma.user.findUnique({
      where: { email: email.trim().toLowerCase() },
    });

    if (!user) {
      return res.status(401).json({ message: "Invalid email or password" });
    }

    const ok = await bcrypt.compare(password, user.password_hash);
    if (!ok) {
      return res.status(401).json({ message: "Invalid email or password" });
    }

    if (role) {
      const mappedRole = mapRole(role);
      if (mappedRole && user.role !== mappedRole) {
        return res.status(403).json({
          message: `This account is registered as ${user.role}`,
        });
      }
    }

    const token = signToken(user.id, user.role);
    return res.json({
      token,
      user: publicUser(user),
    });
  } catch (error) {
    console.error("POST /auth/login", error);
    return res.status(500).json({ message: "Login failed" });
  }
});

router.get("/me", async (req: Request, res: Response) => {
  try {
    const header = req.headers.authorization;
    if (!header?.startsWith("Bearer ")) {
      return res.status(401).json({ message: "Missing token" });
    }

    const secret = process.env.JWT_SECRET;
    if (!secret) {
      return res.status(500).json({ message: "JWT_SECRET is not set" });
    }

    const token = header.slice("Bearer ".length);
    const payload = jwt.verify(token, secret) as { sub: string };
    const user = await prisma.user.findUnique({ where: { id: payload.sub } });
    if (!user) {
      return res.status(401).json({ message: "User not found" });
    }

    return res.json({ user: publicUser(user) });
  } catch {
    return res.status(401).json({ message: "Invalid token" });
  }
});

export default router;
