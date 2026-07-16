import path from "path";
import dotenv from "dotenv";
import express from "express";
import cors from "cors";
import authRouter from "./routes/auth";

dotenv.config({ path: path.resolve(process.cwd(), ".env") });
dotenv.config({ path: path.resolve(process.cwd(), "env") });

const app = express();
const port = Number(process.env.PORT ?? 3000);

app.use(cors());
app.use(express.json());

app.get("/health", (_req, res) => {
  res.json({ ok: true, service: "curamind-api" });
});

app.use("/auth", authRouter);

app.listen(port, () => {
  console.log(`Curamind API listening on http://localhost:${port}`);
});
