const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

const User = require("../models/User");
const authMiddleware = require("../middleware/auth");

const router = express.Router();

// REGISTER
router.post("/register", async (req, res) => {

    try {

        const { name, email, password } = req.body;

        // Validate required fields
        if (!name || !email || !password) {

            return res.status(400).json({
                message: "Name, email and password are required"
            });

        }

        // Validate password length
        if (password.length < 6) {

            return res.status(400).json({
                message: "Password must be at least 6 characters"
            });

        }

        // Check if email already exists
        const existingUser = await User.findOne({ email });

        if (existingUser) {

            return res.status(409).json({
                message: "User with this email already exists"
            });

        }

        // Hash password
        const hashedPassword = await bcrypt.hash(password, 10);

        // Save user
        const user = await User.create({
            name,
            email,
            password: hashedPassword
        });

        // Never send password back
        res.status(201).json({
            message: "User registered successfully",
            user: {
                id: user._id,
                name: user.name,
                email: user.email
            }
        });

    } catch (error) {

        res.status(500).json({
            message: error.message
        });

    }

});

module.exports = router;

// LOGIN
router.post("/login", async (req, res) => {

    try {

        const { email, password } = req.body;

        // Validate required fields
        if (!email || !password) {

            return res.status(400).json({
                message: "Email and password are required"
            });

        }

        // Find user
        const user = await User.findOne({ email });

        if (!user) {

            return res.status(401).json({
                message: "Invalid email or password"
            });

        }

        // Compare password with hashed password
        const isPasswordCorrect = await bcrypt.compare(
            password,
            user.password
        );

        if (!isPasswordCorrect) {

            return res.status(401).json({
                message: "Invalid email or password"
            });

        }

        // Generate JWT
        const token = jwt.sign(
            {
                userId: user._id,
                email: user.email
            },
            process.env.JWT_SECRET,
            {
                expiresIn: "1h"
            }
        );

        res.status(200).json({
            message: "Login successful",
            token,
            user: {
                id: user._id,
                name: user.name,
                email: user.email
            }
        });

    } catch (error) {

        res.status(500).json({
            message: error.message
        });

    }

});

// GET CURRENT USER
router.get("/me", authMiddleware, async (req, res) => {

    try {

        const user = await User.findById(req.user.userId)
            .select("-password");

        if (!user) {

            return res.status(404).json({
                message: "User not found"
            });

        }

        res.status(200).json({
            user
        });

    } catch (error) {

        res.status(500).json({
            message: error.message
        });

    }

});