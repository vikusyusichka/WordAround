const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const logger = require("firebase-functions/logger");
const {GoogleGenerativeAI} = require("@google/generative-ai");

setGlobalOptions({maxInstances: 10});

exports.generateQuiz = onRequest(async (req, res) => {
  try {
    if (req.method !== "POST") {
      return res.status(405).json({error: "Method not allowed"});
    }

    const apiKey = process.env.GEMINI_API_KEY;

    if (!apiKey) {
      logger.error("Missing GEMINI_API_KEY");
      return res.status(500).json({error: "Server API key is not configured"});
    }

    const {prompt} = req.body;

    if (!prompt) {
      return res.status(400).json({error: "Missing prompt"});
    }

    const genAI = new GoogleGenerativeAI(apiKey);

    const model = genAI.getGenerativeModel({
      model: "gemini-1.5-flash",
    });

    const result = await model.generateContent(prompt);

    return res.status(200).json({
      text: result.response.text(),
    });
  } catch (error) {
    logger.error("Gemini request failed", error);

    return res.status(500).json({
      error: "Gemini request failed",
    });
  }
});
