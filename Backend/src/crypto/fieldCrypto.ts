import { createCipheriv, createDecipheriv, randomBytes, scryptSync } from "crypto";

const PREFIX = "enc:v1:";
const IV_LEN = 12;
const TAG_LEN = 16;

let cachedKey: Buffer | null = null;

function resolveKey(): Buffer {
  if (cachedKey) return cachedKey;
  const raw = (process.env.DATA_ENCRYPTION_KEY ?? "").trim();
  if (!raw) {
    throw new Error(
      "DATA_ENCRYPTION_KEY is required (32+ char secret for AES-256-GCM).",
    );
  }
  if (/^[0-9a-fA-F]{64}$/.test(raw)) {
    cachedKey = Buffer.from(raw, "hex");
    return cachedKey;
  }
  cachedKey = scryptSync(raw, "curamind-phi-v1", 32);
  return cachedKey;
}

export function isEncrypted(value: string | null | undefined): boolean {
  return typeof value === "string" && value.startsWith(PREFIX);
}

export function encryptString(plain: string | null | undefined): string | null {
  if (plain == null) return null;
  const text = String(plain);
  if (!text) return text;
  if (isEncrypted(text)) return text;

  const key = resolveKey();
  const iv = randomBytes(IV_LEN);
  const cipher = createCipheriv("aes-256-gcm", key, iv);
  const enc = Buffer.concat([cipher.update(text, "utf8"), cipher.final()]);
  const tag = cipher.getAuthTag();
  return PREFIX + Buffer.concat([iv, tag, enc]).toString("base64url");
}

export function decryptString(value: string | null | undefined): string | null {
  if (value == null) return null;
  const text = String(value);
  if (!text) return text;
  if (!isEncrypted(text)) return text;

  try {
    const raw = Buffer.from(text.slice(PREFIX.length), "base64url");
    if (raw.length <= IV_LEN + TAG_LEN) return text;
    const iv = raw.subarray(0, IV_LEN);
    const tag = raw.subarray(IV_LEN, IV_LEN + TAG_LEN);
    const data = raw.subarray(IV_LEN + TAG_LEN);
    const key = resolveKey();
    const decipher = createDecipheriv("aes-256-gcm", key, iv);
    decipher.setAuthTag(tag);
    return Buffer.concat([decipher.update(data), decipher.final()]).toString(
      "utf8",
    );
  } catch (err) {
    console.warn("[crypto] decrypt failed; returning opaque value");
    return text;
  }
}

export function encryptStringList(values: string[] | null | undefined): string[] {
  if (!values?.length) return [];
  return values.map((v) => encryptString(v) ?? v);
}

export function decryptStringList(values: string[] | null | undefined): string[] {
  if (!values?.length) return [];
  return values.map((v) => decryptString(v) ?? v);
}

export function assertEncryptionReady(): void {
  resolveKey();
  const probe = encryptString("curamind-probe");
  const back = decryptString(probe);
  if (back !== "curamind-probe") {
    throw new Error("DATA_ENCRYPTION_KEY self-check failed.");
  }
}
