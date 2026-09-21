const express = require("express");
const router = express.Router();
const cache = require("../config/cache");
const authMiddleware = require("../middleware/auth");

// GET /api/cache/stats
router.get("/stats", authMiddleware, (req, res) => {
    const stats = cache.getCustomStats();
    res.status(200).json({
        hits: stats.hits,
        misses: stats.misses
    });
});

module.exports = router;
