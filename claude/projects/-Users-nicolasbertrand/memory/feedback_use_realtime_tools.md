---
name: feedback-use-realtime-tools
description: "When the user asks about current/real-world events, USE WebSearch/WebFetch first. Speculation lists are unacceptable."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: a0abe1d6-f7c9-48b1-ad25-57395662c713
---

When the user asks about a current real-world situation (trafic SNCF, météo, actualité, état d'un service, etc.), use WebSearch / WebFetch immediately to get real data. Do NOT produce a list of speculative hypotheses ("peut-être grève, peut-être incident, peut-être événement…").

**Why:** User explicitly flagged this pattern as unacceptable on 2026-06-09 ("tu as accès à internet, tu as toutes les infos en temps réel que tu veux, garde en mémoire que ce type de réponse est inacceptable"). Speculation when tools are available wastes their time and signals laziness.

**How to apply:** For any factual question about the live world, default order = (1) search the web, (2) report what's actually happening, (3) only then add interpretation. Hypothesis lists are acceptable only after a search returned nothing useful, and must be labeled as such.
