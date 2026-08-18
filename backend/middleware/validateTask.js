const validateTask = (req, res, next) => {

    const { title, description, completed, priority } = req.body;

    // Title validation
    if (title === undefined || title === null || title === "") {

        return res.status(400).json({
            message: "Title is required"
        });

    }

    if (typeof title !== "string") {

        return res.status(400).json({
            message: "Title must be a string"
        });

    }

    if (title.trim().length === 0) {

        return res.status(400).json({
            message: "Title cannot be empty"
        });

    }

    // Description validation
    if (
        description !== undefined &&
        typeof description !== "string"
    ) {

        return res.status(400).json({
            message: "Description must be a string"
        });

    }

    // Completed validation
    if (
        completed !== undefined &&
        typeof completed !== "boolean"
    ) {

        return res.status(400).json({
            message: "Completed must be a boolean"
        });

    }

    // Priority validation
    if (
        priority !== undefined &&
        !["low", "medium", "high"].includes(priority)
    ) {

        return res.status(400).json({
            message: "Priority must be low, medium, or high"
        });

    }

    next();

};

module.exports = validateTask;