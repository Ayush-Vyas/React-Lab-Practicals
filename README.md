# Task Management Full-Stack Application

## Practical 11: Containerization with Docker & Docker Compose

This project containerizes the complete full-stack Task Management application into a multi-container Docker architecture orchestrated with **Docker Compose**.

---

### Architecture Overview

| Service | Technology | Internal Port | Host Port | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **frontend** | React 19 + Vite (Nginx multi-stage) | 80 | `5173`, `3000` | Production SPA client with Nginx reverse proxy |
| **backend** | Node.js 20 Express REST API | 5000 | `5000` | Task Management CRUD, JWT Auth, Caching, Event Listeners |
| **mongo** | Official MongoDB 7.0 Image | 27017 | `27017` | Persistent document database |

- **Docker Bridge Network**: `app-network` allows seamless inter-service communication (backend connects to database via `mongodb://mongo:27017/taskdb`).
- **Named Persistent Volume**: `mongo-data` mounted at `/data/db` ensures database records persist across container restarts, stops, and rebuilds.

---

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (v20+ with Docker Compose v2+)
- Windows 10/11 with WSL 2 enabled

---

### Quick Start Instructions

1. **Clone and navigate to the project directory:**
   ```bash
   cd React-Lab-Practicals
   ```

2. **Build and start all services in detached mode:**
   ```bash
   docker compose up --build -d
   ```

3. **Verify running containers:**
   ```bash
   docker compose ps
   ```

4. **View live logs:**
   ```bash
   docker compose logs -f
   ```
   *(Or inspect specific service logs: `docker compose logs -f backend`)*

5. **Stop all services:**
   ```bash
   docker compose down
   ```
   *(Data will persist safely in the named volume `mongo-data`)*

---

### Application Access Endpoints

- **Frontend Application**: [http://localhost:5173](http://localhost:5173) (also available on [http://localhost:3000](http://localhost:3000))
- **Backend API Server**: [http://localhost:5000](http://localhost:5000)
- **MongoDB Database**: `mongodb://localhost:27017/taskdb`

---

### Verification & Testing Steps

1. **Verify Services Status:**
   ```bash
   docker compose ps
   ```
   Confirm all three services (`task-mongodb`, `task-backend`, `task-frontend`) report `Up` status.

2. **Verify Frontend UI:**
   Open [http://localhost:5173](http://localhost:5173) in your browser. The Task Management application should load without errors.

3. **Verify API & Database Integration:**
   - Register a new account or log in.
   - Create, view, update, and delete tasks.

4. **Verify Persistent Storage across Restarts:**
   ```bash
   # Stop and remove containers
   docker compose down

   # Restart containers
   docker compose up -d

   # Verify previous tasks remain intact in MongoDB
   docker compose ps
   ```
