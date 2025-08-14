// web/client/src/App.jsx
import React, { useState, useEffect } from 'react'

export default function App() {
  const [token, setToken] = useState(null)
  const [form, setForm] = useState({ username: '', password: '' })
  const [tables, setTables] = useState(null)
  const [projects, setProjects] = useState([])
  const [newProject, setNewProject] = useState('')

  async function login(e) {
    e.preventDefault()
    const res = await fetch('/api/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(form)
    })
    const data = await res.json()
    if (res.ok) {
      setToken(data.token)
      loadOverview()
      loadProjects()
    } else {
      alert(data.error || 'Login failed')
    }
  }

  async function loadOverview() {
    const res = await fetch('/api/overview/tables')
    if (res.ok) setTables(await res.json())
  }

  async function loadProjects() {
    const res = await fetch('/api/projects')
    if (res.ok) setProjects(await res.json())
  }

  async function createProject(e) {
    e.preventDefault()
    if (!newProject.trim()) return
    const res = await fetch('/api/projects', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: newProject.trim() })
    })
    const data = await res.json()
    if (res.ok) {
      setNewProject('')
      await loadProjects()
      await loadOverview()
    } else {
      alert(data.error || 'Create failed')
    }
  }

  useEffect(() => {
    if (token) {
      loadOverview()
      loadProjects()
    }
  }, [token])

  if (!token) {
    return (
      <div style={{ maxWidth: 360, margin: '4rem auto', fontFamily: 'sans-serif' }}>
        <h2>Login</h2>
        <form onSubmit={login}>
          <div>
            <label>Username</label><br/>
            <input value={form.username} onChange={e=>setForm(f=>({...f, username:e.target.value}))} required />
          </div>
          <div style={{ marginTop: 8 }}>
            <label>Password</label><br/>
            <input type="password" value={form.password} onChange={e=>setForm(f=>({...f, password:e.target.value}))} required />
          </div>
          <button style={{ marginTop: 12 }} type="submit">Sign in</button>
        </form>
      </div>
    )
  }

  return (
    <div style={{ padding: 20, fontFamily: 'sans-serif' }}>
      <h2>API Explorer & Tables</h2>

      <section style={{ marginBottom: 24 }}>
        <h3>Available APIs</h3>
        <ul>
          <li>GET <code>/api/projects</code> — list projects</li>
          <li>POST <code>/api/projects</code> — create project (body: {"{ name }"})</li>
          <li>GET <code>/api/overview/tables</code> — show all tables</li>
        </ul>
      </section>

      <section style={{ marginBottom: 24 }}>
        <h3>Create Project (Sample Write)</h3>
        <form onSubmit={createProject}>
          <input placeholder="Project name" value={newProject} onChange={e=>setNewProject(e.target.value)} />
          <button type="submit" style={{ marginLeft: 8 }}>Create</button>
        </form>
      </section>

      <section style={{ marginBottom: 24 }}>
        <h3>Projects (Sample Read)</h3>
        <pre>{JSON.stringify(projects, null, 2)}</pre>
      </section>

      <section>
        <h3>Tables Snapshot</h3>
        <pre>{JSON.stringify(tables, null, 2)}</pre>
      </section>
    </div>
  )
}
