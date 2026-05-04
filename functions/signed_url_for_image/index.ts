import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type Payload = {
  image_id?: string;
  storage_path?: string;
  expires_in?: number;
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
    const BUCKET = Deno.env.get("IMAGES_BUCKET") ?? "procedure-images";

    const authHeader = requireAuthHeader(req);

    const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userData, error: userErr } = await userClient.auth.getUser();
    if (userErr || !userData?.user) return json(401, { error: "Unauthorized" });
    const uid = userData.user.id;

    const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const { data: profile, error: profileErr } = await adminClient
      .from("profiles")
      .select("role,is_active")
      .eq("id", uid)
      .maybeSingle();

    if (profileErr) return json(500, { error: "Profile lookup failed", details: profileErr.message });
    if (!profile || profile.is_active !== true) return json(403, { error: "Inactive or missing profile" });

    const payload = (await req.json()) as Payload;
    const expiresIn = Math.max(60, Math.min(payload.expires_in ?? 300, 3600));

    let imageRow:
      | { id: string; procedure_id: string; storage_path: string; medico_id: string; paciente_id: string }
      | null = null;

    if (payload.image_id) {
      const { data, error } = await adminClient
        .from("procedure_images")
        .select(`
          id,
          procedure_id,
          storage_path,
          procedures!inner(medico_id,paciente_id)
        `)
        .eq("id", payload.image_id)
        .maybeSingle();

      if (error) return json(500, { error: "Image lookup failed", details: error.message });
      if (!data) return json(404, { error: "Image not found" });

      imageRow = {
        id: data.id,
        procedure_id: data.procedure_id,
        storage_path: data.storage_path,
        medico_id: data.procedures.medico_id,
        paciente_id: data.procedures.paciente_id,
      };
    } else if (payload.storage_path) {
      const { data, error } = await adminClient
        .from("procedure_images")
        .select(`
          id,
          procedure_id,
          storage_path,
          procedures!inner(medico_id,paciente_id)
        `)
        .eq("storage_path", payload.storage_path)
        .maybeSingle();

      if (error) return json(500, { error: "Image lookup failed", details: error.message });
      if (!data) return json(404, { error: "Image not found" });

      imageRow = {
        id: data.id,
        procedure_id: data.procedure_id,
        storage_path: data.storage_path,
        medico_id: data.procedures.medico_id,
        paciente_id: data.procedures.paciente_id,
      };
    } else {
      return json(400, { error: "Provide image_id or storage_path" });
    }

    if (profile.role === "admin") {
      // full access
    } else if (profile.role === "medico") {
      const { data: medico } = await adminClient
        .from("medicos")
        .select("id")
        .eq("profile_id", uid)
        .maybeSingle();
      if (!medico || medico.id !== imageRow.medico_id) {
        return json(403, { error: "Forbidden" });
      }
    } else {
      const { data: paciente } = await adminClient
        .from("pacientes")
        .select("id")
        .eq("profile_id", uid)
        .maybeSingle();
      if (!paciente) return json(403, { error: "Forbidden" });

      const { data: reqRow, error } = await adminClient
        .from("image_access_requests")
        .select("id")
        .eq("procedure_id", imageRow.procedure_id)
        .eq("paciente_id", paciente.id)
        .eq("status", "aprovado")
        .maybeSingle();

      if (error) return json(500, { error: "Access check failed", details: error.message });
      if (!reqRow) return json(403, { error: "Not approved" });
    }

    const { data: signed, error: signErr } = await adminClient.storage
      .from(BUCKET)
      .createSignedUrl(imageRow.storage_path, expiresIn);

    if (signErr || !signed?.signedUrl) {
      return json(500, { error: "Signed URL failed", details: signErr?.message });
    }

    return json(200, {
      ok: true,
      bucket: BUCKET,
      image_id: imageRow.id,
      storage_path: imageRow.storage_path,
      expires_in: expiresIn,
      signed_url: signed.signedUrl,
    });
  } catch (e) {
    return json(400, { error: String(e?.message ?? e) });
  }
});
