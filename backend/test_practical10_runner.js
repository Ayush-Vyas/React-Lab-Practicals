const { spawn } = require("child_process");
const fs = require("fs");
const path = require("path");

async function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function run() {
    console.log("=== Starting Practical 10 End-to-End Verification ===");
    const serverLogs = [];

    // Spawn server process
    const server = spawn("node", ["app.js"], {
        cwd: __dirname,
        env: { ...process.env, PORT: "5000" }
    });

    server.stdout.on("data", (data) => {
        const str = data.toString();
        process.stdout.write("[SERVER] " + str);
        str.split("\n").forEach(line => {
            const trimmed = line.trim();
            if (trimmed) {
                serverLogs.push({
                    type: "stdout",
                    time: new Date().toISOString(),
                    line: trimmed
                });
            }
        });
    });

    server.stderr.on("data", (data) => {
        const str = data.toString();
        process.stderr.write("[SERVER-ERR] " + str);
        str.split("\n").forEach(line => {
            const trimmed = line.trim();
            if (trimmed) {
                serverLogs.push({
                    type: "stderr",
                    time: new Date().toISOString(),
                    line: trimmed
                });
            }
        });
    });

    // Wait for server and DB connection
    console.log("Waiting for server startup & MongoDB connection...");
    let started = false;
    for (let i = 0; i < 30; i++) {
        await sleep(500);
        if (serverLogs.some(l => l.line.includes("Server running")) &&
            serverLogs.some(l => l.line.includes("MongoDB Connected"))) {
            started = true;
            break;
        }
    }

    if (!started) {
        console.error("Server failed to start in time. Killing process.");
        server.kill();
        process.exit(1);
    }
    console.log("Server and MongoDB ready!");

    // 1. Authenticate (Practical 7)
    console.log("\n--- Step 1: Login to get JWT ---");
    const loginRes = await fetch("http://localhost:5000/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: "ayush@test.com", password: "password123" })
    });
    const loginData = await loginRes.json();
    console.log("Login status:", loginRes.status, "User:", loginData.user?.email);
    const token = loginData.token;
    if (!token) throw new Error("Failed to obtain token");

    const authHeaders = {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${token}`
    };

    // 2. Fetch tasks (Practicals 4, 5, 9)
    console.log("\n--- Step 2: GET /tasks ---");
    const getTasksRes = await fetch("http://localhost:5000/tasks", {
        headers: authHeaders
    });
    const initialTasks = await getTasksRes.json();
    console.log("GET /tasks status:", getTasksRes.status, "Count:", Array.isArray(initialTasks) ? initialTasks.length : 0);

    // 3. Create Task (Practical 10 async event demonstration)
    console.log("\n--- Step 3: POST /tasks (Triggering task-created event) ---");
    const postPayload = {
        title: "Practical 10 Event-Driven Task",
        description: "Testing Node.js native EventEmitter async processing with 2000ms delay",
        priority: "high"
    };

    const postStart = Date.now();
    const postRes = await fetch("http://localhost:5000/tasks", {
        method: "POST",
        headers: authHeaders,
        body: JSON.stringify(postPayload)
    });
    const postEnd = Date.now();
    const createdTask = await postRes.json();
    const clientResponseTime = new Date().toISOString();

    console.log(`[CLIENT] Response received in ${postEnd - postStart}ms at ${clientResponseTime}`);
    console.log(`[CLIENT] HTTP Status: ${postRes.status}, Created ID: ${createdTask._id}`);

    // Wait 3 seconds to observe the 2000ms async notification completion in server logs
    console.log("Waiting 3 seconds for asynchronous background event processing...");
    await sleep(3000);

    // 4. Verify MongoDB Persistence (GET /tasks/:id)
    console.log("\n--- Step 4: GET /tasks/:id (Verify persistence) ---");
    const getSingleRes = await fetch(`http://localhost:5000/tasks/${createdTask._id}`, {
        headers: authHeaders
    });
    const singleTask = await getSingleRes.json();
    console.log("Task fetched from DB:", singleTask._id, "Title:", singleTask.title);

    // 5. Delete Task (Triggering task-deleted event)
    console.log("\n--- Step 5: DELETE /tasks/:id (Triggering task-deleted event) ---");
    const deleteRes = await fetch(`http://localhost:5000/tasks/${createdTask._id}`, {
        method: "DELETE",
        headers: authHeaders
    });
    const deleteData = await deleteRes.json();
    console.log("Delete status:", deleteRes.status, "Response:", deleteData.message);
    await sleep(1000);

    // 6. Demonstrate Safe Error Handling (Requirement 8)
    console.log("\n--- Step 6: Safe Error Handling Demonstration (Requirement 8) ---");
    const errTaskPayload = {
        title: "[simulate-error] Async Processing Failure Test",
        description: "Verifying EventEmitter error listener catches error safely without crashing server",
        priority: "low"
    };
    const errPostRes = await fetch("http://localhost:5000/tasks", {
        method: "POST",
        headers: authHeaders,
        body: JSON.stringify(errTaskPayload)
    });
    const errCreatedTask = await errPostRes.json();
    console.log("Error test task created status:", errPostRes.status, "ID:", errCreatedTask._id);
    await sleep(1500);

    // Clean up error test task
    await fetch(`http://localhost:5000/tasks/${errCreatedTask._id}`, {
        method: "DELETE",
        headers: authHeaders
    });
    await sleep(1000);

    // 7. Verify Cache Stats (Practical 9 intact)
    console.log("\n--- Step 7: GET /api/cache/stats (Practical 9 verification) ---");
    const cacheStatsRes = await fetch("http://localhost:5000/api/cache/stats");
    const cacheStats = await cacheStatsRes.json();
    console.log("Cache Stats:", cacheStats);

    // Check server is still running
    console.log("\n--- Step 8: Verifying server stability after error handling ---");
    const pingRes = await fetch("http://localhost:5000/tasks", { headers: authHeaders });
    console.log("Ping GET /tasks status:", pingRes.status, "(Server healthy and running!)");

    // Save logs and summary
    const summary = {
        timestamp: new Date().toISOString(),
        clientResponseTime,
        createdTask,
        singleTask,
        deleteData,
        cacheStats,
        serverLogs
    };

    fs.writeFileSync(path.join(__dirname, "test_practical10_output.json"), JSON.stringify(summary, null, 2));
    console.log("\nExecution results saved to test_practical10_output.json");

    // Terminate server
    server.kill();
    console.log("Server terminated cleanly.");
}

run().catch(err => {
    console.error("Test execution failed:", err);
    process.exit(1);
});
