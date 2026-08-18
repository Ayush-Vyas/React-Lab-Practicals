const cors = require("cors");

require("dotenv").config();

const express = require("express");

const connectDB = require("./config/db");

const logger = require("./middleware/logger");

const validateJson = require("./middleware/validateJson");

const errorHandler = require("./middleware/errorHandler");

const taskRoutes = require("./routes/tasks");

const authRoutes = require("./routes/auth");

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

app.listen(PORT, () => {

    console.log(`🚀 Server running on http://localhost:${PORT}`);

});