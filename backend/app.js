require("dotenv").config();

// DNS resolution: override DNS servers for MongoDB Atlas SRV lookups on local networks, while preserving Docker internal resolution
if (process.env.MONGO_URI && process.env.MONGO_URI.startsWith("mongodb+srv://")) {
    const dns = require("dns");
    dns.setServers(["8.8.8.8", "1.1.1.1"]);
}

const cors = require("cors");

const express = require("express");

const connectDB = require("./config/db");

const logger = require("./middleware/logger");

const validateJson = require("./middleware/validateJson");

const errorHandler = require("./middleware/errorHandler");

// Practical 10: Import event listeners once at server startup
require("./listeners");

const taskRoutes = require("./routes/tasks");

const authRoutes = require("./routes/auth");

const cacheRoutes = require("./routes/cacheStats");

const aiRoutes = require("./routes/ai");

const app = express();

app.use(cors());

// Connect MongoDB
connectDB();

// Middleware
app.use(express.json());

app.use(logger);

app.use(validateJson);

// Routes
app.use("/tasks", taskRoutes);
app.use("/auth", authRoutes);
app.use("/api/cache", cacheRoutes);
app.use("/api/ai", aiRoutes);

// 404 Handler
app.use((req, res) => {

    res.status(404).json({

        message: "Route Not Found"

    });

});

// Global Error Handler
app.use(errorHandler);

// Start Server
const PORT = process.env.PORT || 5000;

if (require.main === module) {
    app.listen(PORT, () => {
        console.log(`🚀 Server running on http://localhost:${PORT}`);
    });
}

module.exports = app;