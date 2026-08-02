const express = require("express");

const logger = require("./middleware/logger");

const validateJson = require("./middleware/validateJson");

const errorHandler = require("./middleware/errorHandler");

const taskRoutes = require("./routes/tasks");

const app = express();

app.use(express.json());

app.use(logger);

app.use(validateJson);

app.use("/tasks", taskRoutes);

// 404 Route

app.use((req, res) => {

    res.status(404).json({

        message: "Route Not Found",

    });

});

// Global Error Handler

app.use(errorHandler);

const PORT = 5000;

app.listen(PORT, () => {

    console.log(

        `Server running on http://localhost:${PORT}`

    );

});