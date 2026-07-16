import path from "path";
import dotenv from "dotenv";
import express from "express";
import cors from "cors";
import { Pool } from "pg";
import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient } from "@prisma/client";
import { linkRouter } from './routes/link';
import { startCronJobs } from './jobs/dailyCheck';

dotenv.config({ path: path.resolve(process.cwd(), ".env") });

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
export const prisma = new PrismaClient({ adapter });

const app = express();
const port = Number(process.env.PORT ?? 3000);

app.use(cors());
app.use(express.json());

app.get("/health", (_req, res) => {
  res.json({ ok: true, service: "curamind-api" });
});
app.use('/api/link', linkRouter);

startCronJobs();

app.listen(port, () => {
  console.log(`Curamind API listening on http://localhost:${port}`);
});