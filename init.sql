CREATE TABLE IF NOT EXISTS projects (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tasks (
  id SERIAL PRIMARY KEY,
  project_id INT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  done BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO projects (name) VALUES ('Example Project') ON CONFLICT DO NOTHING;
INSERT INTO tasks (project_id, title, done)
SELECT p.id, 'First task', false FROM projects p WHERE p.name='Example Project' LIMIT 1;
