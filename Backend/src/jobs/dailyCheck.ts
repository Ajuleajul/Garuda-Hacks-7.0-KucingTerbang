import cron from 'node-cron';
import { prisma } from '../index';

export const startCronJobs = () => {
    cron.schedule('0 20 * * *', async () => {
        console.log('[CRON] Starting evening check for missed logs...');

        try {
            const todayStart = new Date();
            todayStart.setHours(0, 0, 0, 0);

            const todayEnd = new Date();
            todayEnd.setHours(23, 59, 59, 999);

            const patients = await prisma.user.findMany({
                where: { role: 'PATIENT' }
            });

            console.log(`[CRON] Checking logs for ${patients.length} active patients...`);

            for (const patient of patients) {
                const todaysMood = await prisma.moodLog.findFirst({
                    where: {
                        patient_id: patient.id,
                        created_at: {
                            gte: todayStart,
                            lte: todayEnd,
                        },
                    },
                });

                const todaysMedication = await prisma.medicationLog.findFirst({
                    where: {
                        patient_id: patient.id,
                        logged_at: {
                            gte: todayStart,
                            lte: todayEnd,
                        },
                    },
                });

                if (!todaysMood) {
                    console.log(`[ATTENTION] Patient ${patient.full_name} (${patient.id}) missed their MOOD log today.`);
                    // wip, implement notification
                }

                if (!todaysMedication) {
                    console.log(`[ATTENTION] Patient ${patient.full_name} (${patient.id}) missed their MEDICATION log today.`);
                }
            }

            console.log('[CRON] Evening check completed successfully.');
        } catch (error) {
            console.error('[CRON] Error running daily check:', error);
        }
    });

    console.log('Background jobs initialized.');
};