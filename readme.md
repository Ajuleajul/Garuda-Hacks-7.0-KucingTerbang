# Curamind

Curamind is a clinical companion app for **patients** and **psychiatrists**, built for Garuda Hacks 7.0 by team **KucingTerbang**.

It helps patients track mood, DBT skills, coping notes, and medications day to day. Psychiatrists can link patients with join codes, monitor progress, prescribe medications, and export clinical PDF reports. Sensitive fields are encrypted at the API layer (AES-256-GCM). Auth and Postgres run on Supabase. The optional in-app helper chatbot uses Google Gemini with a local FAQ fallback.

## Roles

### Patient
- EMA diary (DBT card and coping entries)
- Medication checklist and adherence
- Distress kit, breathing, grounding, and crisis SOS (dial 119 / 112)
- Personal mood and adherence dashboard
- Join a clinician with a care code
- Curamind Assist chatbot
- Local reminders for diary and meds

### Clinician (psychiatrist)
- Create care groups and join codes (with expiry)
- Monitor linked patients (mood, diary, adherence)
- Dual correlation charts
- Prescribe and manage medications
- Export clinical PDF reports

## Tech stack

| Layer | Stack |
|-------|--------|
| App | Flutter (web, Android, desktop) |
| API | Node.js, Express, TypeScript, Prisma |
| Database / Auth | Supabase (PostgreSQL + Auth) |
| AI (optional) | Google Gemini |
| Deploy (API) | Docker / Docker Compose |

Folder names in this repo are **`Frontend`** and **`Backend`** (capital F and B). Use those paths on all platforms.

## Prerequisites

Install before setup:

1. [Git](https://git-scm.com/)
2. [Node.js](https://nodejs.org/) 20+ (LTS recommended)
3. [Flutter](https://docs.flutter.dev/get-started/install) 3.x (Dart SDK matching `pubspec.yaml`)
4. A [Supabase](https://supabase.com/) project
5. (Optional) [Docker Desktop](https://www.docker.com/products/docker-desktop/) if you run the API in a container
6. (Optional) [Google AI Studio](https://aistudio.google.com/apikey) API key for the chatbot

Verify:

```powershell
git --version
node -v
npm -v
flutter doctor
```

## 1. Clone the repo

```powershell
git clone https://github.com/Ajuleajul/Garuda-Hacks-7.0-KucingTerbang.git
cd Garuda-Hacks-7.0-KucingTerbang
```

## 2. Supabase

1. Create a project in the Supabase dashboard.
2. Open **Project Settings > API** and copy:
   - Project URL
   - `anon` public key
3. Open **Project Settings > Database** and copy the Postgres connection string (`DATABASE_URL`). Prefer the URI that works from your machine (often the pooled or direct connection as shown in Supabase).
4. Under **Authentication > URL Configuration**, add redirect URLs you will use, for example:
   - `curamind://auth-callback`
   - `http://localhost:*/auth-callback` (Flutter web / local)
5. Apply the database schema from this repo (Prisma). From `Backend` after env is set (next section):

```powershell
cd Backend
npx prisma generate
npx prisma db push
```

Or use existing migrations if your team prefers:

```powershell
npx prisma migrate deploy
```

Optional seed:

```powershell
npx prisma db seed
```

## 3. Backend setup

```powershell
cd Backend
copy .env.example .env
npm install
```

Edit `Backend/.env`:

| Variable | Required | Notes |
|----------|----------|--------|
| `DATABASE_URL` | Yes | Supabase Postgres URI |
| `DATA_ENCRYPTION_KEY` | Yes | Secret for AES-256-GCM. Use a long random string, or 64 hex chars |
| `PORT` | No | Default `3000` |
| `JWT_SECRET` | Recommended | Keep a stable secret for the environment |
| `GEMINI_API_KEY` | No | Chatbot; without it, FAQ fallback is used |
| `GEMINI_MODEL` | No | Default `gemini-flash-lite-latest` |
| `PUBLIC_API_URL` | No | Public URL after deploy |

Generate an encryption key (example):

```powershell
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

Paste the output into `DATA_ENCRYPTION_KEY`. Keep the same key across all API instances once patient data is encrypted. Changing it later will break decryption of existing rows.

Generate Prisma client and sync schema:

```powershell
npx prisma generate
npx prisma db push
```

### Run API (local Node)

```powershell
cd Backend
npm run dev
```

Health check: open [http://localhost:3000/health](http://localhost:3000/health). You should see `ok: true` and `encryption: "aes-256-gcm"`.

### Run API (Docker)

1. Start Docker Desktop and wait until it is ready.
2. Ensure `Backend/.env` is filled.
3. Run:

```powershell
cd Backend
.\scripts\docker-up.ps1
```

Or:

```powershell
cd Backend
docker compose up -d --build
```

Useful commands:

```powershell
docker compose logs -f api
docker compose restart api
docker compose down
```

## 4. Frontend setup

```powershell
cd Frontend
copy .env.example .env
flutter pub get
```

Edit `Frontend/.env`:

| Variable | Required | Notes |
|----------|----------|--------|
| `SUPABASE_URL` | Yes | From Supabase project settings |
| `SUPABASE_ANON_KEY` | Yes | Anon / public key |
| `SUPABASE_AUTH_REDIRECT` | Yes | Must match Supabase redirect allow list |
| `API_BASE_URL` | No | Leave empty for defaults (see below) |

### API URL defaults (when `API_BASE_URL` is empty)

| Platform | Default |
|----------|---------|
| Chrome / web | `http://localhost:3000` |
| Windows / macOS / Linux / iOS simulator | `http://localhost:3000` |
| Android emulator | `http://10.0.2.2:3000` |
| Physical phone on same Wi-Fi | Set `API_BASE_URL` to your PC LAN IP, e.g. `http://192.168.1.20:3000` |

### Run the app

Chrome:

```powershell
cd Frontend
flutter run -d chrome
```

Android emulator (API must be running on the PC):

```powershell
cd Frontend
flutter run -d emulator-5554
```

List devices:

```powershell
flutter devices
```

## 5. Quick start (both together)

Terminal 1:

```powershell
cd Backend
npm run dev
```

Terminal 2:

```powershell
cd Frontend
flutter run -d chrome
```

Or use VS Code / Cursor task **Curamind: backend + flutter chrome**.

Optional one-shot script from repo root (Windows):

```powershell
.\scripts\start-dev.ps1 chrome
```

## 6. First-time account flow

1. Register as **patient** or **psychiatrist** in the app (Supabase Auth).
2. Confirm email if your Supabase project requires it.
3. As psychiatrist: open **Groups**, create a group, generate a join code.
4. As patient: open **Link**, paste the code, join.
5. Psychiatrist can prescribe meds and monitor; patient can log diary and mark meds taken.

## Project structure

```
Garuda-Hacks-7.0-KucingTerbang/
  Frontend/          Flutter app
  Backend/           Express API, Prisma, Docker
  scripts/           Local helper scripts
  SUMMARY.md         Project summary and team notes
```

## Troubleshooting

| Problem | What to try |
|---------|-------------|
| `/health` fails | Start Backend (`npm run dev` or Docker). Check port 3000 is free. |
| Flutter cannot reach API on Android emulator | Do not set `API_BASE_URL`, or use `http://10.0.2.2:3000`. |
| Flutter cannot reach API on physical phone | Set `API_BASE_URL` to your PC LAN IP and allow firewall on port 3000. |
| Auth / redirect errors | Align `SUPABASE_AUTH_REDIRECT` with Supabase Auth URL settings. |
| Encryption errors on API start | Set a non-empty `DATA_ENCRYPTION_KEY` in `Backend/.env`. |
| Docker build fails | Open Docker Desktop until status is green, then rerun `docker-up.ps1`. |
| Wrong folder name on Mac/Linux | Use `Frontend` and `Backend` exactly (capital letters). |

## License

Hackathon project for Garuda Hacks 7.0. See repository and third-party package licenses for dependencies.
