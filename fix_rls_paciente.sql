-- =============================================================
-- FIX: Permitir que pacientes leiam dados necessários para
--      exibir nome do médico e tipo do procedimento
-- =============================================================
-- Problema: as policies atuais impedem o paciente de acessar
-- as tabelas 'medicos', 'profiles' e 'tipos_procedimento' via
-- join, fazendo os campos retornarem null.
-- =============================================================

-- 1) PROFILES: ampliar para que pacientes possam ler o profile
--    do médico vinculado a procedimentos deles.
drop policy if exists "profiles_select_policy" on public.profiles;

create policy "profiles_select_policy"
on public.profiles
for select
to authenticated
using (
  public.current_user_is_active()
  and (
    public.is_admin()
    or id = public.current_profile_id()
    -- Paciente pode ler o profile de médicos vinculados aos seus procedimentos
    or (
      public.is_paciente()
      and exists (
        select 1
        from public.procedimentos_realizados pr
        join public.medicos m on m.id = pr.medico_id
        where pr.paciente_id = public.current_paciente_id()
          and m.profile_id = profiles.id
          and pr.is_active = true
      )
    )
    -- Médico pode ler o profile de seus pacientes
    or (
      public.is_medico()
      and exists (
        select 1
        from public.paciente_medico pm
        join public.pacientes pac on pac.id = pm.paciente_id
        where pm.medico_id = public.current_medico_id()
          and pac.profile_id = profiles.id
          and pm.is_active = true
      )
    )
  )
);

-- 2) MEDICOS: ampliar para que pacientes possam ler médicos
--    vinculados aos seus procedimentos.
drop policy if exists "medicos_select_policy" on public.medicos;

create policy "medicos_select_policy"
on public.medicos
for select
to authenticated
using (
  public.current_user_is_active()
  and (
    public.is_admin()
    or profile_id = public.current_profile_id()
    -- Paciente pode ler o médico vinculado a um procedimento seu
    or (
      public.is_paciente()
      and exists (
        select 1
        from public.procedimentos_realizados pr
        where pr.medico_id = medicos.id
          and pr.paciente_id = public.current_paciente_id()
          and pr.is_active = true
      )
    )
  )
);

-- 3) TIPOS_PROCEDIMENTO: ampliar para que pacientes também
--    possam ler os tipos (read-only).
drop policy if exists "tipos_procedimento_select_policy" on public.tipos_procedimento;

create policy "tipos_procedimento_select_policy"
on public.tipos_procedimento
for select
to authenticated
using (
  public.current_user_is_active()
  and (
    public.is_admin()
    or public.is_medico()
    or public.is_paciente()  -- paciente pode ler os tipos (somente leitura)
  )
);
