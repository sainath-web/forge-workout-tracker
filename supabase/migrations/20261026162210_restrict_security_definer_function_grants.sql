-- Keep the auth trigger helper private while preserving the public aggregate
-- reaction-count RPC used by exercise pages.
revoke all on function public.handle_new_user() from public, anon, authenticated;
revoke all on function public.get_exercise_reaction_counts(uuid[]) from public;
grant execute on function public.get_exercise_reaction_counts(uuid[]) to anon, authenticated;

