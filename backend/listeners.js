const taskEvents = require("./events");

// 1. Error Listener (safely logs errors without crashing the server)
taskEvents.on("error", (error) => {
    console.error(`[TaskEvents] [Error Handled Safely] ${new Date().toISOString()}: ${error.message || error}`);
});

// 2. task-created Listener
taskEvents.on("task-created", (data, extraUser) => {
    try {
        const task = (data && data.task) ? data.task : data;
        const user = (data && data.user) ? data.user : (extraUser || task?.assignedUser || "ayushvyas172@gmail.com");
        const title = task?.title || "Untitled Task";
        const startTimestamp = new Date().toISOString();

        console.log(`[Notification] task-created handler started at ${startTimestamp}`);
        console.log(`[Notification] Task Title: "${title}"`);
        console.log(`[Notification] Assigned User: ${user}`);

        // Demonstrate safe error handling through EventEmitter without affecting API response (Requirement 8)
        if (task?.simulateError || (title && title.includes("[simulate-error]"))) {
            taskEvents.emit("error", new Error(`Simulated async background processing error for task: "${title}"`));
            return;
        }

        // Artificial 2-second delay to clearly show asynchronous background processing
        setTimeout(() => {
            try {
                const completionTimestamp = new Date().toISOString();
                console.log(`[Notification] task-created handler completed at ${completionTimestamp}`);
                console.log(`[Notification] Background notification sent for task: "${title}" to ${user}`);
            } catch (innerErr) {
                taskEvents.emit("error", innerErr);
            }
        }, 2000);
    } catch (err) {
        taskEvents.emit("error", err);
    }
});

// 3. task-deleted Listener
taskEvents.on("task-deleted", (data) => {
    try {
        const task = (data && data.task) ? data.task : data;
        const timestamp = data?.deletedAt || new Date().toISOString();
        const user = data?.user || "ayushvyas172@gmail.com";
        const taskId = task?._id || data?.id || "N/A";
        const title = task?.title || "Deleted Task";

        console.log(`[Notification] task-deleted event received at ${timestamp}`);
        console.log(`[Notification] Task Deleted: ID=${taskId}, Title="${title}"`);
        console.log(`[Notification] Action Performed By User: ${user}`);
    } catch (err) {
        taskEvents.emit("error", err);
    }
});

console.log("⚡ [TaskEvents] Event listeners registered successfully (task-created, task-deleted, error)");

module.exports = taskEvents;
