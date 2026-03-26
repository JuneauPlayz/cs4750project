"use strict";

const admin = require("firebase-admin");
const { GoogleGenAI } = require("@google/genai");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { setGlobalOptions } = require("firebase-functions/v2");

setGlobalOptions({ region: "us-central1", maxInstances: 10 });

admin.initializeApp();
const db = admin.firestore();

const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");

const AI_REQUEST_LIMIT = 50;

function parseJsonResponse(text) {
  if (!text || typeof text !== "string") {
    throw new HttpsError("internal", "Empty response from AI service.");
  }
  try {
    return JSON.parse(text);
  } catch (_) {
    throw new HttpsError("internal", "AI service returned invalid JSON.");
  }
}

function requireString(value, fieldName) {
  if (typeof value !== "string" || !value.trim()) {
    throw new HttpsError("invalid-argument", `${fieldName} is required.`);
  }
  return value.trim();
}

function currentPeriodKey() {
  // Reset monthly (e.g., 2026-03).
  const d = new Date();
  const year = d.getUTCFullYear();
  const month = String(d.getUTCMonth() + 1).padStart(2, "0");
  return `${year}-${month}`;
}

async function enforceAiRateLimit(uid) {
  const periodKey = currentPeriodKey();
  const docId = `${uid}_${periodKey}`;
  const docRef = db.collection("ai_rate_limits").doc(docId);

  await db.runTransaction(async (txn) => {
    const snap = await txn.get(docRef);
    const currentCount = snap.exists ? snap.data().count || 0 : 0;

    if (currentCount >= AI_REQUEST_LIMIT) {
      throw new HttpsError(
        "resource-exhausted",
        "AI request limit reached. Try again next month."
      );
    }

    txn.set(
      docRef,
      {
        uid,
        periodKey,
        count: currentCount + 1,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });
}

async function generateJson({ prompt }) {
  const client = new GoogleGenAI({
    apiKey: GEMINI_API_KEY.value(),
  });

  const response = await client.models.generateContent({
    model: "gemini-2.5-flash",
    contents: prompt,
    config: {
      responseMimeType: "application/json",
    },
  });

  const text = response.text || "";
  return parseJsonResponse(text);
}

exports.suggestReferenceGames = onCall(
  { secrets: [GEMINI_API_KEY] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    await enforceAiRateLimit(request.auth.uid);

    const conceptDescription = requireString(
      request.data?.conceptDescription,
      "conceptDescription",
    );

    const prompt = `
You help game developers find modern reference games.

Given a short concept description, return JSON with a "games" array of 5 to 7 recognizable video game titles that are:
- stylistically or mechanically similar
- mostly modern (prefer 2016 and later)
- not obscure unless the description clearly asks for retro or niche inspirations
- useful references for a developer researching current market expectations

Concept:
${conceptDescription}

Return JSON only:
{
  "games": ["Title 1", "Title 2", "Title 3"]
}
`;

    const output = await generateJson({ prompt });
    const games = Array.isArray(output.games)
      ? output.games
          .map((title) => String(title || "").trim())
          .filter(Boolean)
          .slice(0, 7)
      : [];

    return { games };
  },
);

exports.analyzeGodotResource = onCall(
  { secrets: [GEMINI_API_KEY] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    await enforceAiRateLimit(request.auth.uid);

    const resource = request.data?.resource || {};
    const entryTypeInstructions = requireString(
      request.data?.entryTypeInstructions,
      "entryTypeInstructions",
    );

    const prompt = `
You are a game design analyst. You are given a structured game resource from the Godot Engine.
Your job is to explain the EXACT MECHANICAL behavior of this resource.

ANALYSIS RULES:
1. Verbatim Priority: If the 'Tooltip' or any field in 'Properties' that is a synonym for 'tooltip' or 'description' contains a designer-written explanation, copy that text exactly as 'description'.
2. Strict Mechanical Falling Back: Only if no clear tooltip/description exists should you decipher variables to explain behavior.
3. No Fluff: If you decipher variables, do not include lore or flavor text.
4. Name Preservation: If 'Name' is not 'Unknown', return it exactly.

ANALYSIS STRATEGY:
1. Check 'Name', 'Tooltip', and 'Properties' for existing mechanic descriptions.
2. If missing, decipher variables (triggers, effects, values) to build the mechanical sentence.
3. Classify the resource into one of the user-defined entry types below. If no clear match exists, mark it as "UNMATCHED".
4. If classified, extract best-effort values for that entry type's variables.

USER-DEFINED ENTRY TYPES:
${entryTypeInstructions}

Resource Data:
Type: ${resource.resourceType || "Unknown"}
Name: ${resource.name || "Unknown"}
Tooltip: ${resource.tooltip || "None"}
Properties: ${JSON.stringify(resource.properties || {})}
Sub-Resources: ${JSON.stringify(resource.subResources || [])}

Return JSON:
{
  "name": "RESOURCE_NAME_HERE",
  "resourceType": "RESOURCE_TYPE_HERE",
  "description": "MECHANICAL_BEHAVIOR_DESCRIPTION_ONLY",
  "detectedEntryType": "EXACT_ENTRY_TYPE_NAME_OR_UNMATCHED",
  "variables": {
    "Variable Name": "Value extracted from resource, otherwise Unknown"
  }
}
`;

    const output = await generateJson({ prompt });

    return {
      name: String(output.name || "Unknown Resource"),
      resourceType: String(output.resourceType || resource.resourceType || "Unknown"),
      description: String(output.description || "No description generated."),
      detectedEntryType: output.detectedEntryType
        ? String(output.detectedEntryType)
        : "UNMATCHED",
      variables:
        output.variables && typeof output.variables === "object"
          ? output.variables
          : {},
    };
  },
);
