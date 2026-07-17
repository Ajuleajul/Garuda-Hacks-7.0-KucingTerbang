import path from "path";
import dotenv from "dotenv";
import express from "express";
import cors from "cors";
import { Pool } from "pg";
import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient } from "@prisma/client";
import { diaryRouter } from "./routes/diary";
import { linkRouter } from "./routes/link";
import { medsRouter } from "./routes/meds";
import { chatRouter } from "./routes/chat";
import { startCronJobs } from "./jobs/dailyCheck";
import { assertEncryptionReady } from "./crypto/fieldCrypto";

dotenv.config({ path: path.resolve(process.cwd(), ".env") });

try {
  assertEncryptionReady();
  console.log("Field encryption: AES-256-GCM ready");
} catch (err) {
  console.error("Field encryption failed:", err);
  process.exit(1);
}

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
export const prisma = new PrismaClient({ adapter });

const app = express();
const port = Number(process.env.PORT ?? 3000);

app.use(cors({ origin: true }));
app.use(express.json({ limit: "1mb" }));

app.get("/health", (_req, res) => {
  res.json({
    ok: true,
    service: "curamind-api",
    encryption: "aes-256-gcm",
    gemini: Boolean((process.env.GEMINI_API_KEY ?? "").trim()),
  });
});
app.use("/api/diary", diaryRouter);
app.use("/api/link", linkRouter);
app.use("/api/meds", medsRouter);
app.use("/api/chat", chatRouter);

startCronJobs();

app.listen(port, "0.0.0.0", () => {
  console.log(`Curamind API listening on http://0.0.0.0:${port}`);
  console.log(`  Local:   http://localhost:${port}`);
  if (process.env.PUBLIC_API_URL) {
    console.log(`  Public:  ${process.env.PUBLIC_API_URL}`);
  }
});
