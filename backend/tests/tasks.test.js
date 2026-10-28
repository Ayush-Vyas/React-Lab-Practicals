const { describe, it, before, after } = require("node:test");
const assert = require("node:assert");
const http = require("node:http");
const jwt = require("jsonwebtoken");
const mongoose = require("mongoose");
const app = require("../app");

describe("Practical 12: Automated API Test Suite", () => {
    let server;
    let baseUrl;
    let validToken;

    before(async () => {
        // Start server on an ephemeral port
        server = http.createServer(app);
        await new Promise((resolve) => server.listen(0, resolve));
        const port = server.address().port;
        baseUrl = `http://localhost:${port}`;

        // Create a valid JWT token for authenticated routes
        const secret = process.env.JWT_SECRET || "practical7_super_secret_key_2026";
        validToken = jwt.sign(
            { userId: "test_user_ci", email: "ci_tester@example.com" },
            secret,
            { expiresIn: "1h" }
        );
    });

    after(async () => {
        if (server) {
            await new Promise((resolve) => server.close(resolve));
        }
        if (mongoose.connection && mongoose.connection.readyState !== 0) {
            await mongoose.connection.close();
        }
    });

    it("GET /tasks without authorization header should return 401 Unauthorized", async () => {
        const response = await fetch(`${baseUrl}/tasks`, {
            method: "GET",
            headers: { "Content-Type": "application/json" }
        });

        assert.strictEqual(response.status, 401, "Expected HTTP 401 status code");
        const data = await response.json();
        assert.strictEqual(data.message, "Authorization token is required");
    });

    it("POST /tasks without title should return 400 Bad Request", async () => {
        const response = await fetch(`${baseUrl}/tasks`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "Authorization": `Bearer ${validToken}`
            },
            body: JSON.stringify({
                description: "Task without a title",
                priority: "high"
            })
        });

        assert.strictEqual(response.status, 400, "Expected HTTP 400 status code");
        const data = await response.json();
        assert.strictEqual(data.message, "Title is required");
    });

    it("GET /api/cache/stats with valid token should return 200 with cache metrics", async () => {
        const response = await fetch(`${baseUrl}/api/cache/stats`, {
            method: "GET",
            headers: {
                "Content-Type": "application/json",
                "Authorization": `Bearer ${validToken}`
            }
        });

        assert.strictEqual(response.status, 200, "Expected HTTP 200 status code");
        const data = await response.json();
        assert.ok(typeof data.hits === "number", "Response should include numeric hits");
        assert.ok(typeof data.misses === "number", "Response should include numeric misses");
    });

    it("POST /api/ai/generate-description without title should return 400 Bad Request", async () => {
        const response = await fetch(`${baseUrl}/api/ai/generate-description`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({})
        });

        assert.strictEqual(response.status, 400, "Expected HTTP 400 status code");
        const data = await response.json();
        assert.strictEqual(data.message, "Task title is required to generate description.");
    });
});
