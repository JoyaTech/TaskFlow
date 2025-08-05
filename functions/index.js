
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");
const twilio = require("twilio");

admin.initializeApp();

const twilioAccountSid = functions.config().twilio.account_sid;
const twilioAuthToken = functions.config().twilio.auth_token;
const twilioPhoneNumber = functions.config().twilio.phone_number;
const googleApiKey = functions.config().google.api_key;

const twilioClient = twilio(twilioAccountSid, twilioAuthToken);

exports.whatsappBot = functions.https.onRequest(async (req, res) => {
  const incomingMsg = req.body.Body;
  const from = req.body.From;

  try {
    const response = await axios.post(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=${googleApiKey}`,
        {
          contents: [
            {
              parts: [
                {
                  text: incomingMsg,
                },
              ],
            },
          ],
        },
    );

    const botResponse = response.data.candidates[0].content.parts[0].text;

    await twilioClient.messages.create({
      body: botResponse,
      from: twilioPhoneNumber,
      to: from,
    });

    res.status(200).send("Message sent successfully!");
  } catch (error) {
    console.error("Error processing message:", error);
    res.status(500).send("Error processing message");
  }
});
