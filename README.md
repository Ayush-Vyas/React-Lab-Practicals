# Task Management Full-Stack Application

[![CI Pipeline](https://github.com/Ayush-Vyas/React-Lab-Practicals/actions/workflows/ci.yml/badge.svg)](https://github.com/Ayush-Vyas/React-Lab-Practicals/actions/workflows/ci.yml)

## Overview

A robust full-stack Task Management application featuring React 19, Express.js REST API, MongoDB/Mongoose persistence, JWT authentication, server-side caching, Docker Compose containerization, GitHub Actions CI/CD pipeline, and AI-powered task description generation.

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

---

## Practical 12: Continuous Integration & Delivery (CI/CD)

- **Workflow File**: `.github/workflows/ci.yml`
- **Trigger**: Automatic on pushes and pull requests to `main`
- **Execution Environment**: `ubuntu-latest` with Node.js 20 and MongoDB 7.0 container service
- **Automated Test Suite**: Node.js native test runner verifying authentication guards, input validation, and API endpoints:
  - `GET /tasks` unauthorized access rejection (401)
  - `POST /tasks` validation rejection for missing title (400)
  - `GET /api/cache/stats` cache performance metrics (200)
  - `POST /api/ai/generate-description` title validation (400)
- **Local Test Command**: `npm test`

---

## Practical 13: AI Task Description Generator

- **Backend Route**: `POST /api/ai/generate-description`
- **Provider Support**: Google Gemini API (`GEMINI_API_KEY`) and OpenAI (`OPENAI_API_KEY`)
- **Security**: All API keys stored exclusively in backend `.env` (gitignored), placeholder template provided in `.env.example`
- **Frontend Features**:
  - One-click "✨ Generate Description (AI)" button in the Task Creation form
  - Title presence verification and overwrite protection for existing descriptions
  - Dynamic loading state with visual indicator during API calls
  - Prominent AI content disclaimer ensuring human review before task submission
  - Graceful fallback and error messaging without interrupting core CRUD operations

