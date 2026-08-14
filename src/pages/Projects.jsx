import { useEffect, useState } from "react";
import Loading from "../components/Loading";
import ErrorMessage from "../components/ErrorMessage";

const API_URL = "http://localhost:5000/tasks";

function Projects() {
  const [tasks, setTasks] = useState([]);

  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [priority, setPriority] = useState("medium");

  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [error, setError] = useState(null);
  const [message, setMessage] = useState("");

  // GET TASKS
  const fetchTasks = async () => {
    try {
      setLoading(true);
      setError(null);

      const response = await fetch(API_URL);

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
    fetchTasks();
  }, []);

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

      const response = await fetch(API_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          title,
          description,
          priority,
        }),
      });

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
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          completed: !task.completed,
        }),
      });

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
      });

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

  if (loading) {
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
          <span className="eyebrow">FULL STACK PRACTICAL 06</span>

          <h1>Task Management</h1>

          <p>
            Manage your tasks with React, Express, MongoDB and Mongoose.
          </p>
        </div>

        <div className="task-count">
          <strong>{tasks.length}</strong>
          <span>Total Tasks</span>
        </div>
      </section>

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

          <div className="form-group">
            <label>Description</label>

            <textarea
              placeholder="Describe what needs to be completed..."
              value={description}
              onChange={(e) => setDescription(e.target.value)}
            />
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
    </main>
  );
}

export default Projects;