/* Forge's browser client uses only the Supabase publishable key. */
window.ForgeCloud = (() => {
  const URL = 'https://bfwuuxamiuapfuxzfieu.supabase.co';
  const PUBLISHABLE_KEY = 'sb_publishable_nKFbw_7H6i6gKW0D2Qfa6Q_F2ZPAQUF';
  const client = window.supabase.createClient(URL, PUBLISHABLE_KEY, {
    auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true }
  });
  let exerciseIds;

  function fail(result) {
    if (result.error) throw result.error;
    return result.data;
  }

  async function getExerciseIds() {
    if (exerciseIds) return exerciseIds;
    const rows = fail(await client.from('exercises').select('id,name').eq('is_published', true));
    exerciseIds = Object.fromEntries(rows.map(row => [row.name, row.id]));
    return exerciseIds;
  }

  async function loadExerciseVideos() {
    const result = await client.from('exercises')
      .select('name,exercise_videos(id,kind,title,playback_url,poster_url,duration_seconds)')
      .eq('is_published', true)
      .order('sort_order', { referencedTable: 'exercise_videos', ascending: true });
    return fail(result).map(exercise => ({
      ...exercise,
      exercise_videos: (exercise.exercise_videos || []).filter(video => video.playback_url)
    }));
  }

  async function load() {
    const [routineResult, workoutResult] = await Promise.all([
      client.from('routines').select('id,name,description,routine_exercises(position,exercise:exercises(name))').order('created_at'),
      client.from('workouts').select('id,name,started_at,ended_at,notes,workout_exercises(id,position,exercise:exercises(name),workout_sets(set_number,reps,weight))').order('started_at', { ascending: false })
    ]);
    const routines = fail(routineResult).map(r => ({
      id: r.id,
      cloudId: r.id,
      name: r.name,
      description: r.description || '',
      exercises: (r.routine_exercises || []).sort((a, b) => a.position - b.position).map(x => x.exercise.name)
    }));
    const workouts = fail(workoutResult).map(w => ({
      id: w.id,
      cloudId: w.id,
      name: w.name,
      startedAt: new Date(w.started_at).getTime(),
      endedAt: w.ended_at ? new Date(w.ended_at).getTime() : null,
      notes: w.notes || '',
      exercises: (w.workout_exercises || []).sort((a, b) => a.position - b.position).map(e => ({
        name: e.exercise.name,
        sets: (e.workout_sets || []).sort((a, b) => a.set_number - b.set_number).map(s => ({ weight: s.weight ?? '', reps: s.reps ?? '' }))
      }))
    }));
    return { routines, workouts };
  }

  async function saveRoutine(r, position, ids) {
    const payload = { name: r.name, description: r.description || '', is_public: false };
    if (r.cloudId) payload.id = r.cloudId;
    const routine = fail(await client.from('routines').upsert(payload).select('id').single());
    r.cloudId = r.id = routine.id;
    const items = r.exercises.map((name, i) => {
      if (!ids[name]) throw new Error(`Exercise “${name}” is not in the online catalog yet.`);
      return { routine_id: routine.id, exercise_id: ids[name], position: i };
    });
    if (items.length) fail(await client.from('routine_exercises').upsert(items, { onConflict: 'routine_id,position' }));
    return routine.id;
  }

  async function saveWorkout(w, ids) {
    const payload = {
      name: w.name || 'Workout',
      started_at: new Date(w.startedAt).toISOString(),
      ended_at: w.endedAt ? new Date(w.endedAt).toISOString() : null,
      notes: w.notes || null
    };
    if (w.cloudId) payload.id = w.cloudId;
    const workout = fail(await client.from('workouts').upsert(payload).select('id').single());
    w.cloudId = w.id = workout.id;
    const exerciseRows = [];
    for (const [position, exercise] of w.exercises.entries()) {
      if (!ids[exercise.name]) throw new Error(`Exercise “${exercise.name}” is not in the online catalog yet.`);
      const row = fail(await client.from('workout_exercises').upsert({ workout_id: workout.id, exercise_id: ids[exercise.name], position }, { onConflict: 'workout_id,position' }).select('id').single());
      exerciseRows.push(...exercise.sets.map((set, index) => ({
        workout_exercise_id: row.id,
        set_number: index + 1,
        weight: set.weight === '' ? null : Number(set.weight),
        reps: set.reps === '' ? null : Number(set.reps)
      })));
    }
    if (exerciseRows.length) fail(await client.from('workout_sets').upsert(exerciseRows, { onConflict: 'workout_exercise_id,set_number' }));
  }

  async function sync(localState) {
    const remote = await load();
    const ids = await getExerciseIds();
    for (const [i, routine] of localState.routines.entries()) {
      await saveRoutine(routine, i, ids);
    }
    for (const workout of localState.workouts) {
      await saveWorkout(workout, ids);
    }
    return localState;
  }

  async function signUp(email, password) {
    return client.auth.signUp({ email, password, options: { emailRedirectTo: location.href.split('#')[0].split('?')[0] } });
  }
  async function signIn(email, password) { return client.auth.signInWithPassword({ email, password }); }
  async function signInWith(provider) {
    return client.auth.signInWithOAuth({ provider, options: { redirectTo: location.href.split('#')[0].split('?')[0] } });
  }

  return { client, load, sync, loadExerciseVideos, signUp, signIn, signInWith };
})();
