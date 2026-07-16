import 'dotenv/config';
import { Pool } from 'pg';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient, Role, LinkStatus, LogStatus } from '@prisma/client';

const connectionString = process.env.DATABASE_URL;
const pool = new Pool({ connectionString });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
    console.log('starting seeding...');
    const dr = await prisma.user.create({
        data: {
            email: 'doctor@garudahacks.com',
            full_name: 'Dr. Alan Psikiater',
            role: Role.PSIKIATER,
        },
    });

    const patient = await prisma.user.create({
        data: {
            email: 'patient@garudahacks.com',
            full_name: 'Budi Pasien',
            role: Role.PASIEN,
        },
    });

    await prisma.patientPsychiatristLink.create({
        data: {
            patient_id: patient.id,
            psychiatrist_id: dr.id,
            status: LinkStatus.ACTIVE,
        },
    });

    const med = await prisma.medication.create({
        data: {
            patient_id: patient.id,
            psychiatrist_id: dr.id,
            name: 'Lithium (Mood Stabilizer)',
            dosage_and_freq: '300mg - Malam',
            is_active: true,
        },
    });

    const today = new Date();
    for (let i = 0; i < 3; i++) {
        const logDate = new Date(today);
        logDate.setDate(today.getDate() - i);

        await prisma.moodLog.create({
            data: {
                patient_id: patient.id,
                mood_score: Math.floor(Math.random() * 5) + 1,
                triggers: ['Stress tugas', 'Kurang tidur'],
                urge_intensity: Math.floor(Math.random() * 5) + 1,
                coping_journal: 'Mencoba latihan pernapasan.',
                created_at: logDate,
            },
        });

        await prisma.medicationLog.create({
            data: {
                medication_id: med.id,
                patient_id: patient.id,
                status: i % 2 === 0 ? LogStatus.TAKEN : LogStatus.MISSED,
                logged_at: logDate,
            },
        });
    }

    console.log('seeding selesai!');
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });