insert into public.exercises (slug, name, primary_muscle, is_published) values
  ('barbell-bench-press', 'Barbell Bench Press', 'Chest', true),
  ('incline-dumbbell-press', 'Incline Dumbbell Press', 'Chest', true),
  ('cable-fly', 'Cable Fly', 'Chest', true),
  ('barbell-back-squat', 'Barbell Back Squat', 'Legs', true),
  ('romanian-deadlift', 'Romanian Deadlift', 'Legs', true),
  ('leg-press', 'Leg Press', 'Legs', true),
  ('leg-curl', 'Leg Curl', 'Legs', true),
  ('deadlift', 'Deadlift', 'Back', true),
  ('lat-pulldown', 'Lat Pulldown', 'Back', true),
  ('seated-cable-row', 'Seated Cable Row', 'Back', true),
  ('pull-up', 'Pull-Up', 'Back', true),
  ('overhead-press', 'Overhead Press', 'Shoulders', true),
  ('lateral-raise', 'Lateral Raise', 'Shoulders', true),
  ('face-pull', 'Face Pull', 'Shoulders', true),
  ('barbell-curl', 'Barbell Curl', 'Arms', true),
  ('triceps-pushdown', 'Triceps Pushdown', 'Arms', true),
  ('dumbbell-curl', 'Dumbbell Curl', 'Arms', true),
  ('plank', 'Plank', 'Core', true),
  ('hanging-knee-raise', 'Hanging Knee Raise', 'Core', true)
on conflict (slug) do update set is_published = true;

