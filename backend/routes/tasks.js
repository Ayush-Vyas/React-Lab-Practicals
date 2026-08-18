const express = require("express");

const router = express.Router();

const Task = require("../models/Task");

const authMiddleware = require("../middleware/auth");
const validateTask = require("../middleware/validateTask");

router.use(authMiddleware);

// GET ALL TASKS
router.get("/", async (req, res) => {

    try {

        const tasks = await Task.find();

        res.status(200).json(tasks);

    } catch (error) {

        res.status(500).json({
            message: error.message
        });

    }

});

// GET TASK BY ID
router.get("/:id", async (req, res) => {

    try {

        const task = await Task.findById(req.params.id);

        if (!task) {

            return res.status(404).json({
                message: "Task not found"
            });

        }

        res.status(200).json(task);

    } catch (error) {

        res.status(404).json({
            message: "Invalid Task ID"
        });

    }

});

// CREATE TASK
router.post("/", validateTask, async (req, res) => {

    try {

        const task = await Task.create(req.body);

        res.status(201).json(task);

    } catch (error) {

        res.status(400).json({
            message: error.message
        });

    }

});

// UPDATE TASK
router.put("/:id", validateTask, async (req, res) => {

    try {

        const task = await Task.findByIdAndUpdate(

            req.params.id,

            req.body,

            {
                new: true,
                runValidators: true
            }

        );

        if (!task) {

            return res.status(404).json({
                message: "Task not found"
            });

        }

        res.status(200).json(task);

    } catch (error) {

        res.status(400).json({
            message: error.message
        });

    }

});

// DELETE TASK
router.delete("/:id", async (req, res) => {

    try {

        const task = await Task.findByIdAndDelete(req.params.id);

        if (!task) {

            return res.status(404).json({
                message: "Task not found"
            });

        }

        res.status(200).json({
            message: "Task deleted successfully"
        });

    } catch (error) {

        res.status(400).json({
            message: error.message
        });

    }

});

module.exports = router;