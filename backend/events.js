const EventEmitter = require("events");

class TaskEvents extends EventEmitter {}

// Export singleton instance
const taskEvents = new TaskEvents();

module.exports = taskEvents;
