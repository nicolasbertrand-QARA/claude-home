---
name: Use Gemini Nano Banana 2 for image generation
description: When user asks to generate an image, use Gemini's Nano Banana 2 model (gemini-3.1-flash-image-preview) via API
type: feedback
originSessionId: 1a908eb9-8796-4d65-8795-48a90fd1e882
---
When the user asks to generate an image, use Gemini's **Nano Banana 2** model.

- **Model ID:** `gemini-3.1-flash-image-preview`
- **API endpoint:** `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-image-preview:generateContent`
- **API key env var:** `GEMINI_API_KEY` (set in `~/.zshrc`)
- **Required generationConfig:** `{"responseModalities": ["IMAGE", "TEXT"]}`
- Response contains base64-encoded image in `candidates[0].content.parts[].inlineData`

**Why:** User explicitly requested this model for all image generation tasks.

**How to apply:** On any image generation request, call the Gemini API with this model, decode the base64 image, save to a file, and display it to the user.
