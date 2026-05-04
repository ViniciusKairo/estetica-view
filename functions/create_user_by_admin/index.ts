import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type Role = "admin" | "medico" | "paciente";

type Payload = {
  role: Role;
  email: string;
  nome: string;
  invite?: boolean;
  password?: string;
  medico?: { crm: string; especialidade?: string | null };
  paciente?: { telefone?: string | null; nascimento?: string | null; cpf?: string | null };
};

function json(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function requireAuthHeader(req: Request) {
  const auth = req.headers.get("Authorization");
  if (!auth?.startsWith("Bearer ")) throw new Error("Missing Authorization Bearer token.");
  return auth;
}

function normalizeEmail(email: string) {
  const e = (email ?? "").trim().toLowerCase();
  if (!e.includes("@")) throw new Error("Invalid email.");
  return e;
}

function randomPassword(len = 14) {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$%";
  let out = "";
  for (let i = 0; i < len; i++) out += chars[Math.floor(Math.random() * chars.length)];
  return out;
}

Deno.serve(async (req) => {
  try {
    if (req.method !== "POST") return json(405, { error: "Method not allowed" });

    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    if (!SUPABASE_URL || !SUPABASE_ANON_KEY || !SUPABASE_SERVICE_ROLE_KEY) {
      return json(500, { error: "Missing env vars." });
    }

    const authHeader = requireAuthHeader(req);

    const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userData, error: userErr } = await userClient.auth.getUser();
    if (userErr || !userData?.user) return json(401, { error: "Unauthorized" });
    const callerId = userData.user.id;

    const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    const { data: callerProfile, error: callerErr } = await adminClient
      .from("profiles")
      .select("id, role, is_active")
      .eq("id", callerId)
      .maybeSingle();

    if (callerErr) return json(500, { error: "Failed to load caller profile", details: callerErr.message });
    if (!callerProfile || callerProfile.role !== "admin" || callerProfile.is_active !== true) {
      return json(403, { error: "Forbidden: admin only" });
    }

    const payload = (await req.json()) as Payload;
    const role = payload.role;
    if (!["admin", "medico", "paciente"].includes(role)) {
      return json(400, { error: "Invalid role" });
    }

    const nome = (payload.nome ?? "").trim();
    if (nome.length < 3) return json(400, { error: "Invalid nome" });
    const email = normalizeEmail(payload.email);

    if (role === "medico") {
      if (!payload.medico?.crm?.trim()) return json(400, { error: "medico.crm is required" });
    }

    const invite = payload.invite !== false;
    let userId = "";
    let tempPassword: string | null = null;

    if (invite) {
      const { data, error } = await adminClient.auth.admin.inviteUserByEmail(email, {
        data: { nome },
      });
      if (error || !data?.user) {
        return json(400, { error: "Invite failed", details: error?.message });
      }
      userId = data.user.id;
    } else {
      tempPassword = payload.password?.trim() || randomPassword();
      const { data, error } = await adminClient.auth.admin.createUser({
        email,
        password: tempPassword,
        email_confirm: true,
        user_metadata: { nome },
      });
      if (error || !data?.user) {
        return json(400, { error: "Create user failed", details: error?.message });
      }
      userId = data.user.id;
    }

    const { error: profileErr } = await adminClient.from("profiles").upsert({
      id: userId,
      email,
      nome,
      role,
      is_active: true,
    }, { onConflict: "id" });

    if (profileErr) {
      return json(500, { error: "Failed to upsert profile", details: profileErr.message });
    }

    if (role === "medico") {
      const { error } = await adminClient.from("medicos").upsert({
        profile_id: userId,
        crm: payload.medico!.crm.trim(),
        especialidade: payload.medico?.especialidade?.trim() || null,
      }, { onConflict: "profile_id" });
      if (error) return json(500, { error: "Failed to upsert medico", details: error.message });
    }

    if (role === "paciente") {
      const { error } = await adminClient.from("pacientes").upsert({
        profile_id: userId,
        telefone: payload.paciente?.telefone?.trim() || null,
        data_nascimento: payload.paciente?.nascimento || null,
        cpf: payload.paciente?.cpf?.trim() || null,
      }, { onConflict: "profile_id" });
      if (error) return json(500, { error: "Failed to upsert paciente", details: error.message });
    }

    await adminClient.from("audit_logs").insert({
      user_id: callerId,
      action: "create",
      entity: "profiles",
      entity_id: userId,
      new_values: {
        role,
        email,
        nome,
        invite,
      },
    });

    return json(200, {
      ok: true,
      user_id: userId,
      role,
      invite,
      temp_password: tempPassword,
    });
  } catch (e) {
    return json(400, { error: String(e?.message ?? e) });
  }
});
