import { useState } from "react";
import { useNavigate } from "react-router-dom";

const API_URL = "http://localhost:5000/auth/login";

function Login() {
  const navigate = useNavigate();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");

  const handleLogin = async (e) => {
    e.preventDefault();

    setError("");
    setMessage("");

    if (!email.trim() || !password) {
      setError("Email and password are required.");
      return;
    }

    try {
      setLoading(true);

      const response = await fetch(API_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          email,
          password,
        }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.message || "Login failed");
      }

      // Store JWT
      localStorage.setItem("token", data.token);

      // Store logged-in user
      localStorage.setItem(
        "user",
        JSON.stringify(data.user)
      );

      setMessage("Login successful!");

      navigate("/projects");

    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <main className="page-shell">
      <section className="create-task-card">

        <div className="section-title">
          <div className="section-icon">🔐</div>

          <div>
            <span className="eyebrow">PRACTICAL 07</span>

            <h2>Login</h2>

            <p>
              Login to access your protected tasks.
            </p>
          </div>
        </div>

        {error && (
          <div className="error-message">
            {error}
          </div>
        )}

        {message && (
          <div className="success-message">
            {message}
          </div>
        )}

        <form
          onSubmit={handleLogin}
          className="task-form"
        >

          <div className="form-group full-width">
            <label>Email</label>

            <input
              type="email"
              placeholder="Enter your email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
            />
          </div>

          <div className="form-group full-width">
            <label>Password</label>

            <input
              type="password"
              placeholder="Enter your password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
          </div>

          <button
            type="submit"
            className="primary-button"
            disabled={loading}
          >
            {loading ? "Logging in..." : "Login"}
          </button>

        </form>

      </section>
    </main>
  );
}

export default Login;