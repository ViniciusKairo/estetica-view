import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type Payload = {
  to_user: string;
  title: string;
  body: string;
  type?: "solicitacao" | "aprovacao" | "reprovacao" | "sistema";
  entity_id?: string | null;
  entity_type?: string | null;
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

Deno.serve(async (req) => {
  try {
    if (req.method !== "POST") return json(405, { error: "Method not allowed" });

    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const authHeader = requireAuthHeader(req);

    const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userData, error: userErr } = await userClient.auth.getUser();
    if (userErr || !userData?.user) return json(401, { error: "Unauthorized" });
    const callerId = userData.user.id;

    const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const { data: callerProfile } = await adminClient
      .from("profiles")
      .select("role, is_active")
      .eq("id", callerId)
      .maybeSingle();

    if (!callerProfile || callerProfile.role !== "admin" || callerProfile.is_active !== true) {
      return json(403, { error: "Forbidden: admin only" });
    }

    const payload = (await req.json()) as Payload;
    const title = (payload.title ?? "").trim();
    const body = (payload.body ?? "").trim();
    if (!payload.to_user) return json(400, { error: "to_user is required" });
    if (title.length < 2) return json(400, { error: "Invalid title" });
    if (body.length < 2) return json(400, { error: "Invalid body" });

    const { data: row, error } = await adminClient
      .from("notifications")
      .insert({
        user_id: payload.to_user,
        title,
        body,
        type: payload.type ?? "sistema",
        entity_id: payload.entity_id ?? null,
        entity_type: payload.entity_type ?? null,
      })
      .select("id")
      .single();

    if (error || !row) return json(500, { error: "Insert failed", details: error?.message });

    await adminClient.from("audit_logs").insert({
      user_id: callerId,
      action: "create",
      entity: "notifications",
      entity_id: row.id,
      new_values: {
        to_user: payload.to_user,
        title,
        type: payload.type ?? "sistema",
        entity_id: payload.entity_id ?? null,
        entity_type: payload.entity_type ?? null,
      },
    });

    return json(200, { ok: true, notification_id: row.id });
  } catch (e) {
    return json(400, { error: String(e?.message ?? e) });
  }
});
