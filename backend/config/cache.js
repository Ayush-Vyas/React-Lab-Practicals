const NodeCache = require("node-cache");

const cache = new NodeCache({
    stdTTL: 60
});

let cacheHits = 0;
let cacheMisses = 0;

cache.incrementHits = () => {
    cacheHits++;
};

cache.incrementMisses = () => {
    cacheMisses++;
};

cache.getCustomStats = () => ({
    hits: cacheHits,
    misses: cacheMisses
});

cache.resetCustomStats = () => {
    cacheHits = 0;
    cacheMisses = 0;
};

module.exports = cache;
