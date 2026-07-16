import { Router, Request, Response } from 'express';
import { prisma } from '../index';

export const linkRouter = Router();

const activeInviteCodes = new Map<string, string>();

const generateCode = () => {
    return Math.random().toString(36).substring(2, 8).toUpperCase();
};

linkRouter.post('/generate', (req: Request, res: Response) => {
    const { psychiatrist_id } = req.body;

    if (!psychiatrist_id) {
        return res.status(400).json({ error: "psychiatrist_id is required" });
    }

    const newCode = generateCode();

    activeInviteCodes.set(newCode, psychiatrist_id);

    setTimeout(() => {
        activeInviteCodes.delete(newCode);
    }, 10 * 60 * 1000);

    res.json({
        message: "Invite code generated successfully",
        code: newCode,
        expires_in_minutes: 10
    });
});

linkRouter.post('/verify', async (req: Request, res: Response) => {
    const { patient_id, code } = req.body;

    if (!patient_id || !code) {
        return res.status(400).json({ error: "patient_id and code are required" });
    }

    const upperCode = code.toUpperCase();

    const psychiatrist_id = activeInviteCodes.get(upperCode);

    if (!psychiatrist_id) {
        return res.status(404).json({ error: "Invalid or expired invite code." });
    }

    try {
        const newLink = await prisma.patientPsychiatristLink.create({
            data: {
                patient_id: patient_id,
                psychiatrist_id: psychiatrist_id,
                status: 'ACTIVE',
            },
        });

        activeInviteCodes.delete(upperCode);

        res.json({
            message: "Successfully linked with psychiatrist!",
            link: newLink
        });

    } catch (error) {
        console.error("Database Error:", error);
        res.status(500).json({ error: "Failed to create connection in the database." });
    }
});

export { activeInviteCodes };

