import path from "path";
import dotenv from "dotenv";
import express from "express";
import cors from "cors";
import { Pool } from "pg";
import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient } from "@prisma/client";
import { diaryRouter } from "./routes/diary";
import { linkRouter } from './routes/link';
import { medsRouter } from "./routes/meds";
import { startCronJobs } from './jobs/dailyCheck';

dotenv.config({ path: path.resolve(process.cwd(), ".env") });

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
export const prisma = new PrismaClient({ adapter });

const app = express();
const port = Number(process.env.PORT ?? 3000);

app.use(cors({ origin: true }));
app.use(express.json());

app.get("/health", (_req, res) => {
  res.json({ ok: true, service: "curamind-api" });
});
app.use("/api/diary", diaryRouter);
app.use('/api/link', linkRouter);
app.use("/api/meds", medsRouter);

startCronJobs();

app.listen(port, "0.0.0.0", () => {
  console.log(`Curamind API listening on http://0.0.0.0:${port}`);
  console.log(`  Local:   http://localhost:${port}`);
  console.log(`  Devices: set Frontend/.env API_BASE_URL=http://<your-lan-ip>:${port}`);
});