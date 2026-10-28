import { useEffect, useState } from "react";
import Loading from "../components/Loading";
import ErrorMessage from "../components/ErrorMessage";
import { TASKS_API_URL as API_URL, AI_API_URL } from "../config/api";

const getAuthHeaders = () => {
  const token =
    typeof window !== "undefined"
      ? new URLSearchParams(window.location.search).get("token") ||
        localStorage.getItem("token")
      : null;

  return {
    "Content-Type": "application/json",
    Authorization: `Bearer ${token}`,
  };
};

const handleUnauthorized = (response) => {
  if (response.status === 401) {
    localStorage.removeItem("token");
    localStorage.removeItem("user");

    window.location.href = "/login";

    return true;
  }

  return false;
};

function Projects() {
  const [activeTab, setActiveTab] = useState("tasks"); // "tasks" | "github"

  const [tasks, setTasks] = useState([]);

  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [priority, setPriority] = useState("medium");

  // Practical 13: AI Task Description Generation State
  const [aiLoading, setAiLoading] = useState(false);
  const [aiError, setAiError] = useState("");
  const [aiDisclaimer, setAiDisclaimer] = useState("");

  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [error, setError] = useState(null);
  const [message, setMessage] = useState("");

  // Practical 03: GitHub REST API Consumption State
  const [repos, setRepos] = useState([]);
  const [reposLoading, setReposLoading] = useState(false);
  const [reposError, setReposError] = useState("");
  const [search, setSearch] = useState("");

  const fetchRepos = () => {
    setReposLoading(true);
    setReposError("");

    fetch("https://api.github.com/users/Ayush-Vyas/repos")
      .then((response) => {
        if (!response.ok) {
          throw new Error("Failed to fetch repositories.");
        }
        return response.json();
      })
      .then((data) => {
        setRepos(Array.isArray(data) ? data : []);
      })
      .catch((err) => {
        setReposError(err.message);
      })
      .finally(() => {
        setReposLoading(false);
      });
  };

  useEffect(() => {
    if (activeTab === "github" && repos.length === 0) {
      fetchRepos();
    }
  }, [activeTab]);

  // GET TASKS
  const fetchTasks = async () => {
    try {
      setLoading(true);
      setError(null);

      const response = await fetch(API_URL, {
  headers: getAuthHeaders(),
});

if (handleUnauthorized(response)) {
  return;
}

if (!response.ok) {
  throw new Error("Failed to fetch tasks");
}

      const data = await response.json();
      setTasks(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (typeof window !== "undefined") {
      const p = new URLSearchParams(window.location.search);
      if (p.get("token")) localStorage.setItem("token", p.get("token"));
      if (p.get("title")) setTitle(p.get("title"));
      if (p.get("description")) setDescription(p.get("description"));
      if (p.get("error")) setAiError(p.get("error"));
      if (p.get("disclaimer")) setAiDisclaimer(p.get("disclaimer"));
    }
    fetchTasks();
  }, []);

  // Practical 13: Generate AI Description
  const generateAiDescription = async () => {
    if (!title.trim()) {
      setAiError("Please enter a task title first so the AI can generate a description.");
      return;
    }

    if (description.trim()) {
      const confirmOverwrite = window.confirm(
        "A description is already written. Do you want to overwrite it with an AI-generated suggestion?"
      );
      if (!confirmOverwrite) {
        return;
      }
    }

    try {
      setAiLoading(true);
      setAiError("");
      setAiDisclaimer("");

      const response = await fetch(AI_API_URL, {
        method: "POST",
        headers: getAuthHeaders(),
        body: JSON.stringify({ title: title.trim() }),
      });

      const data = await response.json().catch(() => ({}));

      if (!response.ok) {
        throw new Error(data.message || `AI generation failed (status ${response.status})`);
      }

      if (data.description) {
        setDescription(data.description);
        setAiDisclaimer(
          data.disclaimer || "AI-generated suggestion. Please review and edit before saving."
        );
      } else {
        throw new Error("No description suggestion returned by the AI provider.");
      }
    } catch (err) {
      setAiError(err.message || "Failed to generate AI description. You can write it manually.");
    } finally {
      setAiLoading(false);
    }
  };

  // CREATE TASK
  const createTask = async (e) => {
    e.preventDefault();

    if (!title.trim()) {
      setError("Task title is required.");
      return;
    }

    try {
      setActionLoading(true);
      setError(null);
      setMessage("");
      setAiError("");
      setAiDisclaimer("");

      const response = await fetch(API_URL, {
  method: "POST",
  headers: getAuthHeaders(),
  body: JSON.stringify({
    title,
    description,
    priority,
  }),
});

if (handleUnauthorized(response)) {
  return;
}

const data = await response.json();

      if (!response.ok) {
        throw new Error(data.message || "Failed to create task");
      }

      setTitle("");
      setDescription("");
      setPriority("medium");

      setMessage("Task created successfully!");

      await fetchTasks();
    } catch (err) {
      setError(err.message);
    } finally {
      setActionLoading(false);
    }
  };

  // UPDATE TASK
  const toggleTask = async (task) => {
    try {
      setActionLoading(true);
      setError(null);
      setMessage("");

      const response = await fetch(`${API_URL}/${task._id}`, {
  method: "PUT",
  headers: getAuthHeaders(),
  body: JSON.stringify({
    completed: !task.completed,
  }),
});

if (handleUnauthorized(response)) {
  return;
}

const data = await response.json();

      if (!response.ok) {
        throw new Error(data.message || "Failed to update task");
      }

      setMessage("Task updated successfully!");

      await fetchTasks();
    } catch (err) {
      setError(err.message);
    } finally {
      setActionLoading(false);
    }
  };

  // DELETE TASK
  const deleteTask = async (id) => {
    const confirmed = window.confirm(
      "Are you sure you want to delete this task?"
    );

    if (!confirmed) return;

    try {
      setActionLoading(true);
      setError(null);
      setMessage("");

      const response = await fetch(`${API_URL}/${id}`, {
  method: "DELETE",
  headers: getAuthHeaders(),
});

if (handleUnauthorized(response)) {
  return;
}

const data = await response.json();

      if (!response.ok) {
        throw new Error(data.message || "Failed to delete task");
      }

      setMessage("Task deleted successfully!");

      await fetchTasks();
    } catch (err) {
      setError(err.message);
    } finally {
      setActionLoading(false);
    }
  };

  if (loading && activeTab === "tasks") {
    return (
      <main className="page-shell">
        <Loading />
      </main>
    );
  }

  return (
    <main className="page-shell">
      <section className="tasks-header">
        <div>
          <span className="eyebrow">
            {activeTab === "tasks" ? "FULL STACK PRACTICAL 06" : "REST API PRACTICAL 03"}
          </span>

          <h1>{activeTab === "tasks" ? "Task Management" : "GitHub Repositories"}</h1>

          <p>
            {activeTab === "tasks"
              ? "Manage your tasks with React, Express, MongoDB and Mongoose."
              : "Live REST API consumption using GitHub Public API with search, loading, and error states."}
          </p>
        </div>

        <div style={{ display: "flex", gap: "10px", alignItems: "center" }}>
          <button
            type="button"
            className={activeTab === "tasks" ? "primary-button" : "complete-button"}
            onClick={() => setActiveTab("tasks")}
            style={{ padding: "8px 16px", fontSize: "0.9rem" }}
          >
            📋 Tasks
          </button>
          <button
            type="button"
            className={activeTab === "github" ? "primary-button" : "complete-button"}
            onClick={() => setActiveTab("github")}
            style={{ padding: "8px 16px", fontSize: "0.9rem" }}
          >
            🐙 GitHub Repos
          </button>
        </div>
      </section>

      {/* PRACTICAL 03: GITHUB REPOSITORIES REST API VIEW */}
      {activeTab === "github" ? (
        <section className="create-task-card">
          <div className="section-title">
            <div className="section-icon">🐙</div>
            <div>
              <span className="eyebrow">PRACTICAL 03 — REST API CONSUMPTION</span>
              <h2>GitHub Repositories</h2>
              <p>Live GitHub REST API data fetched from https://api.github.com/users/Ayush-Vyas/repos</p>
            </div>
          </div>

          <div className="form-group full-width" style={{ marginTop: "15px" }}>
            <label>Search Repositories</label>
            <input
              type="text"
              placeholder="Search repository by name..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>

          {reposLoading && <Loading />}

          {reposError && (
            <ErrorMessage
              message={reposError}
              retry={fetchRepos}
            />
          )}

          {!reposLoading && !reposError && (
            <div style={{ marginTop: "20px" }}>
              {repos
                .filter((repo) =>
                  repo.name.toLowerCase().includes(search.toLowerCase())
                )
                .map((repo) => (
                  <article key={repo.id} className="repo">
                    <h3>{repo.name}</h3>
                    <p>⭐ Stars : {repo.stargazers_count}</p>
                    <a
                      href={repo.html_url}
                      target="_blank"
                      rel="noreferrer"
                    >
                      {repo.html_url}
                    </a>
                  </article>
                ))}
            </div>
          )}
        </section>
      ) : (
        <>
          {message && (
            <div className="success-message">
              <span>✓</span>
              {message}
            </div>
          )}

          {error && (
            <ErrorMessage
              message={error}
              retry={fetchTasks}
            />
          )}

          {/* CREATE TASK */}
          <section className="create-task-card">
            <div className="section-title">
              <div className="section-icon">＋</div>

              <div>
                <h2>Create New Task</h2>
                <p>Add a new task to your MongoDB database.</p>
              </div>
            </div>

            <form onSubmit={createTask} className="task-form">
              <div className="form-group full-width">
                <label>Task Title</label>

                <input
                  type="text"
                  placeholder="e.g. Complete React Practical"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                />
              </div>

              <div className="form-group full-width">
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "6px" }}>
                  <label style={{ margin: 0 }}>Description</label>
                  <button
                    type="button"
                    onClick={generateAiDescription}
                    disabled={aiLoading || actionLoading}
                    className="ai-generate-button"
                    title="Generate description automatically from title using AI"
                    style={{
                      display: "inline-flex",
                      alignItems: "center",
                      gap: "6px",
                      background: "linear-gradient(135deg, #6366f1 0%, #a855f7 100%)",
                      color: "#ffffff",
                      border: "none",
                      borderRadius: "6px",
                      padding: "5px 12px",
                      fontSize: "0.82rem",
                      fontWeight: "600",
                      cursor: aiLoading ? "wait" : "pointer",
                      boxShadow: "0 2px 4px rgba(99, 102, 241, 0.25)",
                      transition: "opacity 0.2s ease"
                    }}
                  >
                    {aiLoading ? (
                      <>
                        <span style={{ display: "inline-block", width: "11px", height: "11px", border: "2px solid #ffffff", borderTopColor: "transparent", borderRadius: "50%", animation: "spin 0.8s linear infinite" }} />
                        Generating...
                      </>
                    ) : (
                      <>
                        <span>✨</span> Generate Description (AI)
                      </>
                    )}
                  </button>
                </div>

                <textarea
                  placeholder="Describe what needs to be completed..."
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  rows={4}
                />

                {aiDisclaimer && (
                  <div
                    className="ai-disclaimer-box"
                    style={{
                      marginTop: "8px",
                      padding: "8px 12px",
                      background: "rgba(99, 102, 241, 0.08)",
                      border: "1px solid rgba(99, 102, 241, 0.25)",
                      borderRadius: "6px",
                      fontSize: "0.82rem",
                      color: "#818cf8",
                      display: "flex",
                      alignItems: "flex-start",
                      gap: "8px"
                    }}
                  >
                    <span>ℹ️</span>
                    <span>
                      <strong>AI Disclaimer:</strong> {aiDisclaimer}
                    </span>
                  </div>
                )}

                {aiError && (
                  <div
                    className="ai-error-box"
                    style={{
                      marginTop: "8px",
                      padding: "8px 12px",
                      background: "rgba(239, 68, 68, 0.08)",
                      border: "1px solid rgba(239, 68, 68, 0.25)",
                      borderRadius: "6px",
                      fontSize: "0.82rem",
                      color: "#f87171",
                      display: "flex",
                      alignItems: "flex-start",
                      gap: "8px"
                    }}
                  >
                    <span>⚠️</span>
                    <span>
                      <strong>AI Note:</strong> {aiError}
                    </span>
                  </div>
                )}
              </div>

              <div className="form-group">
                <label>Priority</label>

                <select
                  value={priority}
                  onChange={(e) => setPriority(e.target.value)}
                >
                  <option value="low">Low Priority</option>
                  <option value="medium">Medium Priority</option>
                  <option value="high">High Priority</option>
                </select>
              </div>

              <button
                type="submit"
                className="primary-button"
                disabled={actionLoading}
              >
                {actionLoading ? "Creating..." : "Create Task"}
              </button>
            </form>
          </section>

          {/* TASK LIST */}
          <section className="task-list-section">
            <div className="list-heading">
              <div>
                <span className="eyebrow">YOUR WORK</span>
                <h2>Your Tasks</h2>
              </div>

              <span className="task-badge">
                {tasks.length} {tasks.length === 1 ? "Task" : "Tasks"}
              </span>
            </div>

            {tasks.length === 0 ? (
              <div className="empty-state">
                <div className="empty-icon">✓</div>

                <h3>No tasks yet</h3>

                <p>
                  Create your first task above and it will appear here.
                </p>
              </div>
            ) : (
              <div className="task-grid">
                {tasks.map((task) => (
                  <article
                    className={`task-card ${
                      task.completed ? "completed-task" : ""
                    }`}
                    key={task._id}
                  >
                    <div className="task-card-top">
                      <span
                        className={`priority priority-${task.priority}`}
                      >
                        {task.priority}
                      </span>

                      <span
                        className={`status ${
                          task.completed ? "status-completed" : "status-pending"
                        }`}
                      >
                        {task.completed ? "Completed" : "Pending"}
                      </span>
                    </div>

                    <h3>{task.title}</h3>

                    <p className="task-description">
                      {task.description || "No description provided."}
                    </p>

                    <div className="task-date">
                      Created{" "}
                      {new Date(task.createdAt).toLocaleDateString()}
                    </div>

                    <div className="task-actions">
                      <button
                        className="complete-button"
                        onClick={() => toggleTask(task)}
                        disabled={actionLoading}
                      >
                        {task.completed
                          ? "Mark Pending"
                          : "Mark Complete"}
                      </button>

                      <button
                        className="delete-button"
                        onClick={() => deleteTask(task._id)}
                        disabled={actionLoading}
                      >
                        Delete
                      </button>
                    </div>
                  </article>
                ))}
              </div>
            )}
          </section>
        </>
      )}
    </main>
  );
}

export default Projects;