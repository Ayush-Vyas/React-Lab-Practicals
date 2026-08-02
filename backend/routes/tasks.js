const express = require("express");

const router = express.Router();

let tasks = require("../data/tasks");

// GET

router.get("/", (req, res) => {

    res.status(200).json(tasks);

});

// POST

router.post("/", (req, res) => {

    const task = {

        id: Date.now(),

        title: req.body.title,

        completed: false,

    };

    tasks.push(task);

    res.status(201).json(task);

});

// PUT

router.put("/:id", (req, res) => {

    const id = Number(req.params.id);

    const task = tasks.find(t => t.id === id);

    if (!task) {

        return res.status(404).json({

            message: "Task not found",

        });

    }

    task.title = req.body.title;

    task.completed = req.body.completed;

    res.status(200).json(task);

});

// DELETE

router.delete("/:id", (req, res) => {

    const id = Number(req.params.id);

    const index = tasks.findIndex(

        t => t.id === id

    );

    if (index === -1) {

        return res.status(404).json({

            message: "Task not found",

        });

    }

    tasks.splice(index, 1);

    res.status(200).json({

        message: "Task deleted",

    });

});

module.exports = router;