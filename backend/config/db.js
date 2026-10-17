const mongoose = require("mongoose");

const connectDB = async (retries = 5, delay = 3000) => {
    for (let attempt = 1; attempt <= retries; attempt++) {
        try {
            await mongoose.connect(process.env.MONGO_URI);
            console.log("✅ MongoDB Connected");
            return;
        } catch (error) {
            console.error(`MongoDB Connection Failed (attempt ${attempt}/${retries})`);
            console.error(error.message);
            if (attempt < retries) {
                console.log(`Retrying MongoDB connection in ${delay / 1000}s...`);
                await new Promise((resolve) => setTimeout(resolve, delay));
            } else {
                process.exit(1);
            }
        }
    }
};

module.exports = connectDB;