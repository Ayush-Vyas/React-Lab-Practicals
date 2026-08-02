function validateJson(req, res, next) {

    if (
        req.method === "POST" ||
        req.method === "PUT"
    ) {

        if (!req.is("application/json")) {

            return res.status(400).json({

                message:
                    "Content-Type must be application/json",

            });

        }

    }

    next();

}

module.exports = validateJson;