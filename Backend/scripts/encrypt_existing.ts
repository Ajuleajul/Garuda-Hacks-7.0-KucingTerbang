import path from "path";
import dotenv from "dotenv";
import { Pool } from "pg";
import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient } from "@prisma/client";
import {
  encryptString,
  encryptStringList,
  isEncrypted,
  assertEncryptionReady,
} from "../src/crypto/fieldCrypto";

dotenv.config({ path: path.resolve(process.cwd(), ".env") });
assertEncryptionReady();

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const prisma = new PrismaClient({ adapter: new PrismaPg(pool) });

async function main() {
  let diary = 0;
  let meds = 0;
  let links = 0;
  let groups = 0;

  const entries = await prisma.diaryEntry.findMany();
  for (const e of entries) {
    const data: Record<string, unknown> = {};
    if (e.notes && !isEncrypted(e.notes)) data.notes = encryptString(e.notes);
    if (e.situation && !isEncrypted(e.situation))
      data.situation = encryptString(e.situation);
    if (e.thoughts && !isEncrypted(e.thoughts))
      data.thoughts = encryptString(e.thoughts);
    if (e.behavior && !isEncrypted(e.behavior))
      data.behavior = encryptString(e.behavior);
    if (e.outcome && !isEncrypted(e.outcome))
      data.outcome = encryptString(e.outcome);
    if (e.emotions.some((x) => !isEncrypted(x)))
      data.emotions = encryptStringList(e.emotions);
    if (e.triggers.some((x) => !isEncrypted(x)))
      data.triggers = encryptStringList(e.triggers);
    if (e.skills.some((x) => !isEncrypted(x)))
      data.skills = encryptStringList(e.skills);
    if (Object.keys(data).length) {
      await prisma.diaryEntry.update({ where: { id: e.id }, data });
      diary++;
    }
  }

  const medications = await prisma.medication.findMany();
  for (const m of medications) {
    const data: Record<string, unknown> = {};
    if (m.name && !isEncrypted(m.name)) data.name = encryptString(m.name);
    if (m.dosage_and_freq && !isEncrypted(m.dosage_and_freq))
      data.dosage_and_freq = encryptString(m.dosage_and_freq);
    if (m.patient_name && !isEncrypted(m.patient_name))
      data.patient_name = encryptString(m.patient_name);
    if (Object.keys(data).length) {
      await prisma.medication.update({ where: { id: m.id }, data });
      meds++;
    }
  }

  const careLinks = await prisma.careLink.findMany();
  for (const l of careLinks) {
    if (l.patient_name && !isEncrypted(l.patient_name)) {
      await prisma.careLink.update({
        where: { id: l.id },
        data: { patient_name: encryptString(l.patient_name) },
      });
      links++;
    }
  }

  const joinGroups = await prisma.joinGroup.findMany();
  for (const g of joinGroups) {
    const data: Record<string, unknown> = {};
    if (g.psychiatrist_name && !isEncrypted(g.psychiatrist_name))
      data.psychiatrist_name = encryptString(g.psychiatrist_name);
    if (g.psychiatrist_email && !isEncrypted(g.psychiatrist_email))
      data.psychiatrist_email = encryptString(g.psychiatrist_email);
    if (Object.keys(data).length) {
      await prisma.joinGroup.update({ where: { id: g.id }, data });
      groups++;
    }
  }

  console.log(
    `Re-encrypted plaintext rows → diary:${diary} meds:${meds} links:${links} groups:${groups}`,
  );
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
    await pool.end();
  });
