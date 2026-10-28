const express = require("express");
const router = express.Router();

/**
 * Practical 13: AI Task Description Generator
 * POST /api/ai/generate-description
 * Body: { title: string }
 */
router.post("/generate-description", async (req, res) => {
    try {
        const { title } = req.body || {};

        if (!title || typeof title !== "string" || !title.trim()) {
            return res.status(400).json({
                message: "Task title is required to generate description."
            });
        }

        const trimmedTitle = title.trim();

        const geminiKey = process.env.GEMINI_API_KEY;
        const openAiKey = process.env.OPENAI_API_KEY;

        if (!geminiKey && !openAiKey) {
            return res.status(503).json({
                message: "AI service is not configured. Please configure GEMINI_API_KEY or OPENAI_API_KEY in backend .env file.",
                code: "AI_KEY_NOT_CONFIGURED"
            });
        }

        const disclaimer = "AI-generated suggestion. Please review, edit, or adjust before saving.";

        // Provider 1: Google Gemini
        if (geminiKey) {
            const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${geminiKey}`;
            const prompt = `You are a helpful task management assistant. Generate a concise, clear, and actionable task description (2 to 4 sentences or bullet points) for a task titled: "${trimmedTitle}". Only return the description text itself. Do not include markdown headers, quotes, or code blocks.`;

            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), 10000);

            try {
                const response = await fetch(endpoint, {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({
                        contents: [
                            {
                                parts: [{ text: prompt }]
                            }
                        ]
                    }),
                    signal: controller.signal
                });

                clearTimeout(timeoutId);

                if (!response.ok) {
                    const errBody = await response.text();
                    console.error("[AI] Gemini provider error:", response.status, errBody);
                    return res.status(502).json({
                        message: `AI provider error (${response.status}). Please verify your GEMINI_API_KEY.`,
                        code: "PROVIDER_ERROR"
                    });
                }

                const data = await response.json();
                const text = data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim();

                if (!text) {
                    return res.status(502).json({
                        message: "AI provider returned an empty response. Please write description manually.",
                        code: "EMPTY_AI_RESPONSE"
                    });
                }

                return res.status(200).json({
                    description: text,
                    disclaimer,
                    provider: "gemini"
                });
            } catch (fetchErr) {
                clearTimeout(timeoutId);
                if (fetchErr.name === "AbortError") {
                    return res.status(504).json({
                        message: "AI generation request timed out after 10 seconds. Please try again or write description manually.",
                        code: "TIMEOUT"
                    });
                }
                throw fetchErr;
            }
        }

        // Provider 2: OpenAI
        if (openAiKey) {
            const endpoint = "https://api.openai.com/v1/chat/completions";
            const prompt = `Generate a concise, clear, and actionable task description (2 to 4 sentences or bullet points) for a task titled: "${trimmedTitle}". Only return the description text itself.`;

            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), 10000);

            try {
                const response = await fetch(endpoint, {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json",
                        "Authorization": `Bearer ${openAiKey}`
                    },
                    body: JSON.stringify({
                        model: "gpt-4o-mini",
                        messages: [
                            { role: "system", content: "You are a helpful task assistant. Provide concise, actionable task descriptions." },
                            { role: "user", content: prompt }
                        ],
                        max_tokens: 200,
                        temperature: 0.7
                    }),
                    signal: controller.signal
                });

                clearTimeout(timeoutId);

                if (!response.ok) {
                    const errBody = await response.text();
                    console.error("[AI] OpenAI provider error:", response.status, errBody);
                    return res.status(502).json({
                        message: `OpenAI provider error (${response.status}). Please verify your OPENAI_API_KEY.`,
                        code: "PROVIDER_ERROR"
                    });
                }

                const data = await response.json();
                const text = data?.choices?.[0]?.message?.content?.trim();

                if (!text) {
                    return res.status(502).json({
                        message: "OpenAI provider returned an empty response. Please write description manually.",
                        code: "EMPTY_AI_RESPONSE"
                    });
                }

                return res.status(200).json({
                    description: text,
                    disclaimer,
                    provider: "openai"
                });
            } catch (fetchErr) {
                clearTimeout(timeoutId);
                if (fetchErr.name === "AbortError") {
                    return res.status(504).json({
                        message: "AI generation request timed out after 10 seconds. Please try again or write description manually.",
                        code: "TIMEOUT"
                    });
                }
                throw fetchErr;
            }
        }
    } catch (error) {
        console.error("[AI] Unexpected error:", error.message);
        return res.status(500).json({
            message: "Failed to generate AI description due to network or server error. You can still write your description manually.",
            error: error.message
        });
    }
});

module.exports = router;
