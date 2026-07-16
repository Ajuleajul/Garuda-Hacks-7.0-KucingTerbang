/**
 * Simulates 2 devices: psychiatrist creates code, patient joins, deactivate.
 * Run: npx tsx scripts/e2e_link.ts
 */
const BASE = process.env.API_BASE_URL ?? "http://localhost:3000";

async function req(
  method: string,
  path: string,
  body?: unknown,
): Promise<{ status: number; json: any }> {
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: body ? { "Content-Type": "application/json" } : undefined,
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let json: any = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch {
    json = { raw: text };
  }
  return { status: res.status, json };
}

async function main() {
  console.log("API:", BASE);

  const health = await req("GET", "/health");
  if (health.status !== 200 || !health.json?.ok) {
    throw new Error(`Health failed: ${health.status} ${JSON.stringify(health.json)}`);
  }
  console.log("✓ health");

  const psychId = `psych-e2e-${Date.now()}`;
  const patientId = `patient-e2e-${Date.now()}`;

  const created = await req("POST", "/api/link/groups", {
    psychiatrist_id: psychId,
    psychiatrist_name: "Dr E2E",
    psychiatrist_email: "dr@e2e.test",
    name: "E2E cohort",
    expires_in_minutes: 60,
  });
  if (created.status !== 201 && created.status !== 200) {
    throw new Error(`Create failed: ${created.status} ${JSON.stringify(created.json)}`);
  }
  const code = created.json.group.code as string;
  const groupId = created.json.group.id as string;
  console.log("✓ create", code, groupId);

  const listed = await req("GET", `/api/link/groups/${psychId}`);
  if (listed.status !== 200 || !listed.json.groups?.some((g: any) => g.code === code)) {
    throw new Error(`List missing code: ${JSON.stringify(listed.json)}`);
  }
  console.log("✓ list groups");

  const joined = await req("POST", "/api/link/join", {
    patient_id: patientId,
    patient_name: "Pat E2E",
    code,
  });
  if (joined.status !== 200) {
    throw new Error(`Join failed: ${joined.status} ${JSON.stringify(joined.json)}`);
  }
  console.log("✓ join", joined.json.link?.group_code);

  const status = await req("GET", `/api/link/patient/${patientId}`);
  if (!status.json.link) {
    throw new Error(`Patient link missing: ${JSON.stringify(status.json)}`);
  }
  console.log("✓ patient status");

  const deactivated = await req("PATCH", `/api/link/groups/${groupId}`, {
    is_active: false,
  });
  if (deactivated.status !== 200 || deactivated.json.group?.is_active !== false) {
    throw new Error(`Deactivate failed: ${JSON.stringify(deactivated.json)}`);
  }
  console.log("✓ deactivate");

  const patient2 = `patient-e2e-blocked-${Date.now()}`;
  const blocked = await req("POST", "/api/link/join", {
    patient_id: patient2,
    patient_name: "Should Fail",
    code,
  });
  if (blocked.status === 200) {
    throw new Error("Join should fail on deactivated code");
  }
  console.log("✓ join blocked after deactivate", blocked.status, blocked.json?.error);

  // Reactivate + new patient
  await req("PATCH", `/api/link/groups/${groupId}`, { is_active: true });
  const joined2 = await req("POST", "/api/link/join", {
    patient_id: patient2,
    patient_name: "Pat 2",
    code,
  });
  if (joined2.status !== 200) {
    throw new Error(`Rejoin failed: ${joined2.status} ${JSON.stringify(joined2.json)}`);
  }
  console.log("✓ reactivate + second patient join");

  console.log("\nALL E2E CHECKS PASSED");
}

main().catch((e) => {
  console.error("\nE2E FAILED:", e.message ?? e);
  process.exit(1);
});
