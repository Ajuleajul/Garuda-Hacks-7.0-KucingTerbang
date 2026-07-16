-- CreateEnum
CREATE TYPE "Role" AS ENUM ('PASIEN', 'PSIKIATER');

-- CreateEnum
CREATE TYPE "LinkStatus" AS ENUM ('PENDING', 'ACTIVE');

-- CreateEnum
CREATE TYPE "LogStatus" AS ENUM ('TAKEN', 'MISSED');

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "full_name" TEXT NOT NULL,
    "role" "Role" NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MoodLog" (
    "id" TEXT NOT NULL,
    "patient_id" TEXT NOT NULL,
    "mood_score" INTEGER NOT NULL,
    "triggers" TEXT[],
    "urge_intensity" INTEGER NOT NULL,
    "coping_journal" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "MoodLog_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PatientPsychiatristLink" (
    "id" TEXT NOT NULL,
    "patient_id" TEXT NOT NULL,
    "psychiatrist_id" TEXT NOT NULL,
    "status" "LinkStatus" NOT NULL DEFAULT 'PENDING',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PatientPsychiatristLink_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Medication" (
    "id" TEXT NOT NULL,
    "patient_id" TEXT NOT NULL,
    "psychiatrist_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "dosage_and_freq" TEXT NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Medication_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MedicationLog" (
    "id" TEXT NOT NULL,
    "medication_id" TEXT NOT NULL,
    "patient_id" TEXT NOT NULL,
    "status" "LogStatus" NOT NULL,
    "logged_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "MedicationLog_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SessionNote" (
    "id" TEXT NOT NULL,
    "patient_id" TEXT NOT NULL,
    "psychiatrist_id" TEXT NOT NULL,
    "clinical_notes" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SessionNote_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- AddForeignKey
ALTER TABLE "MoodLog" ADD CONSTRAINT "MoodLog_patient_id_fkey" FOREIGN KEY ("patient_id") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PatientPsychiatristLink" ADD CONSTRAINT "PatientPsychiatristLink_patient_id_fkey" FOREIGN KEY ("patient_id") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PatientPsychiatristLink" ADD CONSTRAINT "PatientPsychiatristLink_psychiatrist_id_fkey" FOREIGN KEY ("psychiatrist_id") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Medication" ADD CONSTRAINT "Medication_patient_id_fkey" FOREIGN KEY ("patient_id") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Medication" ADD CONSTRAINT "Medication_psychiatrist_id_fkey" FOREIGN KEY ("psychiatrist_id") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MedicationLog" ADD CONSTRAINT "MedicationLog_medication_id_fkey" FOREIGN KEY ("medication_id") REFERENCES "Medication"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MedicationLog" ADD CONSTRAINT "MedicationLog_patient_id_fkey" FOREIGN KEY ("patient_id") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SessionNote" ADD CONSTRAINT "SessionNote_patient_id_fkey" FOREIGN KEY ("patient_id") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SessionNote" ADD CONSTRAINT "SessionNote_psychiatrist_id_fkey" FOREIGN KEY ("psychiatrist_id") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
