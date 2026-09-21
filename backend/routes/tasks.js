const express = require("express");

const router = express.Router();

const Task = require("../models/Task");
const cache = require("../config/cache");

const authMiddleware = require("../middleware/auth");
const validateTask = require("../middleware/validateTask");

router.use(authMiddleware);

// GET ALL TASKS (Cached with "all_tasks")
router.get("/", async (req, res) => {

    try {

        const cachedTasks = cache.get("all_tasks");

        if (cachedTasks) {
            cache.incrementHits();
            return res.status(200).json(cachedTasks);
        }

        cache.incrementMisses();
        const tasks = await Task.find();

        cache.set("all_tasks", tasks);

        res.status(200).json(tasks);

    } catch (error) {

        res.status(500).json({
            message: error.message
        });

    }

});

// GET TASK BY ID (Cached with "task_<id>")
router.get("/:id", async (req, res) => {

    try {

        const cacheKey = `task_${req.params.id}`;
        const cachedTask = cache.get(cacheKey);

        if (cachedTask) {
            cache.incrementHits();
            return res.status(200).json(cachedTask);
        }

        cache.incrementMisses();
        const task = await Task.findById(req.params.id);

        if (!task) {

            return res.status(404).json({
                message: "Task not found"
            });

        }

        cache.set(cacheKey, task);

        res.status(200).json(task);

    } catch (error) {

        res.status(404).json({
            message: "Invalid Task ID"
        });

    }

});

// CREATE TASK (Invalidates "all_tasks")
router.post("/", validateTask, async (req, res) => {

    try {

        const task = await Task.create(req.body);

        // Invalidate all_tasks cache only after successful database write
        cache.del("all_tasks");

        res.status(201).json(task);

    } catch (error) {

        res.status(400).json({
            message: error.message
        });

    }

});

// UPDATE TASK (Invalidates "all_tasks" and "task_<id>")
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

        // Invalidate both caches only after successful database update
        cache.del("all_tasks");
        cache.del(`task_${req.params.id}`);

        res.status(200).json(task);

    } catch (error) {

        res.status(400).json({
            message: error.message
        });

    }

});

// DELETE TASK (Invalidates "all_tasks" and "task_<id>")
router.delete("/:id", async (req, res) => {

    try {

        const task = await Task.findByIdAndDelete(req.params.id);

        if (!task) {

            return res.status(404).json({
                message: "Task not found"
            });

        }

        // Invalidate both caches only after successful database deletion
        cache.del("all_tasks");
        cache.del(`task_${req.params.id}`);

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