# Meeting Scribe — Custom Build Plan

## Context

You want a privacy-preserving way to capture and structure both Google Meet and in-person meetings, given that off-the-shelf services (Granola/Fireflies) would process confidential client/MDSW conversations on third-party servers without a DPIA.

The custom approach keeps audio + transcripts local on your Apple Silicon Mac, sends only de-identified text to Claude for structured extraction (decisions, action items, QARA flags, open questions), and lands the result in a new Notion *Meetings* database with an email recap to yourself via `gws`. Trigger is a microphone icon in the macOS menu bar, alongside your existing Notion/battery/Übersicht icons.

## Architecture

```
                    Menu bar (rumps Python app, LaunchAgent)
                    [🎤 idle | 🔴 recording | ⏳ processing | ✅ done]
                          │
                Click  →  "Start (Meet)" │ "Start (IRL)" │ "Stop" │ "Open last"
                          │
              ┌───────────┴───────────┐
              │                       │
       AudioCapture                Session state
       (ffmpeg + caffeinate)       ~/MeetingScribe/sessions/<ts>/meta.json
              │
              │  (second click → SIGINT)
              ▼
       Pipeline worker (subprocess)
         1. ffmpeg amix      → mixed.wav
         2. mlx-whisper FR   → transcript.json (turbo + QARA prompt)
         3. PII regex strip  → transcript_clean.txt
         4. Claude API       → summary.json (decisions/actions/qara/questions)
         5. Notion REST API  → meeting page (idempotent by session_id)
         6. gws gmail send   → recap email to self
              │
              ▼
       meta.json="done"  →  ✅ in menu bar 5s, then back to 🎤
```

## Critical decisions (resolved, not optional)

1. **Menu bar app:** `rumps` (Python). 30 lines, you're Python-fluent, no Swift toolchain. Runs in a venv via LaunchAgent so it survives logout/sleep.
2. **Audio:** BlackHole 2ch + Aggregate Device `Scribe-Meet` (mic + BlackHole) created once in Audio MIDI Setup. `SwitchAudioSource` (brew) flips system output to BlackHole only while in Meet mode, restored in a `try/finally` on stop. ScreenCaptureKit would be cleaner but is a multi-day Swift detour.
3. **Whisper model:** `mlx-community/whisper-large-v3-turbo` — ~8× faster than large-v3, ~1–2 WER pts cost on French. Mitigate accuracy on QARA terms via `initial_prompt` listing your vocabulary (MDR, IEC 62304, ISO 14971, CAPA, dispositif médical, classe IIa, dossier technique, exigences essentielles, gestion des risques…).
4. **No diarization in v1.** Instead, prompt Claude to attribute action items by name inferred from the transcript ("Nicolas dit qu'il fera…"). Add pyannote later only if attribution is poor over 5 real sessions.
5. **Mode = explicit menu, not auto-detect.** "Start (Meet)" vs "Start (IRL)" — auto-detection via active-app is fragile across Safari/Chrome/Arc and during screen-share.
6. **Confidentiality gate:** Menu item "Cloud summary: on/off". When off, skip Claude and email a transcript-only recap. Default *off* for IRL, *on* for Meet (configurable).
7. **Sleep prevention:** `caffeinate -dimsu` spawned as a sibling process for the recording duration; killed on stop. Without it, lid-close silently truncates the WAV.

## Components & file paths

```
~/MeetingScribe/
  .venv/                                       # python 3.13 venv
  bin/
    scribe                                     # entrypoint (LaunchAgent target)
    scribe-pipeline                            # one-shot post-processing
  src/scribe/
    menubar.py                                 # rumps app, icon states
    controller.py                              # state machine, subprocess mgmt, recovery
    audio.py                                   # ffmpeg cmds, SwitchAudioSource wrapper
    transcribe.py                              # mlx-whisper w/ FR + QARA prompt
    extract.py                                 # Claude API, prompt-cached system prompt
    pii.py                                     # regex strip emails/phones pre-Claude
    notion_sink.py                             # Notion REST, idempotent via session_id
    email_sink.py                              # gws gmail send wrapper
    config.py                                  # paths, env var loading
  prompts/
    extract_qara.md                            # cached system prompt w/ JSON schema
  sessions/<YYYYMMDD-HHMMSS>/
    meta.json                                  # status state machine
    raw-mic.wav   raw-sys.wav   mixed.wav   mixed.m4a
    transcript.json   transcript_clean.txt
    summary.json   notion_page_id   email_message_id
  retry-queue/                                 # pending Notion/email uploads
  logs/scribe.log

~/Library/LaunchAgents/com.nicolasbertrand.meetingscribe.plist  # RunAtLoad, KeepAlive
```

## Notion *Meetings* DB schema

| Property        | Type          | Notes |
|-----------------|---------------|-------|
| Title           | title         | `<YYYY-MM-DD> — <auto first 6 words of summary>` |
| Date            | date          | recording start timestamp |
| Source          | select        | `Meet` / `IRL` |
| Duration (min)  | number        | computed from WAV |
| Language        | select        | `FR` / `EN` / `Mixed` |
| Status          | select        | `Draft` / `Reviewed` / `Filed` |
| Decisions       | rich_text     | bullets |
| Action items    | rich_text     | `- [ ] {action} — @{owner} (due: {date or "?"})` |
| QARA flags      | multi_select  | `MDR`, `IEC 62304`, `ISO 14971`, `IEC 62366`, `Audit`, `CAPA`, `DHF`, `PMS` |
| Open questions  | rich_text     | bullets |
| Transcript      | files         | `transcript_clean.txt` |
| Audio           | files         | `mixed.m4a` — **only attached when Source=Meet**; IRL stays local |
| Session ID      | rich_text     | hidden idempotency key |
| Client          | relation      | optional, deferred (no Clients DB exists yet) |

## Build order (8 steps)

1. **Prereqs (manual, one-time):**
   - `brew install ffmpeg blackhole-2ch switchaudio-osx`
   - Open Audio MIDI Setup → create Aggregate Device named `Scribe-Meet` (Built-in Mic + BlackHole 2ch)
   - Set env vars in `~/.zshrc`: `ANTHROPIC_API_KEY`, `NOTION_TOKEN`, `NOTION_MEETINGS_DB_ID`
   - In Notion: create internal integration, create *Meetings* DB with schema above, share DB with the integration
2. **Bootstrap:** `python3.13 -m venv ~/MeetingScribe/.venv && pip install mlx-whisper anthropic rumps requests`
3. **`audio.py` + smoke test:** record 30s mic-only and 30s Meet-mode; verify `mixed.wav` has both channels populated (`ffprobe -show_streams`)
4. **`transcribe.py`:** wire mlx-whisper turbo + the QARA `initial_prompt`; benchmark on a 10-min French sample (target <90s on M-series)
5. **`extract.py`:** Claude Sonnet 4.6 with prompt caching on system prompt; strict JSON output schema (`decisions[]`, `actions[{text,owner,due}]`, `qara_flags[]`, `questions[]`)
6. **`notion_sink.py` + `email_sink.py`:** Notion REST upsert keyed on session_id (hidden property); gws send via `gws gmail send --to nicolas.bertrand@theodo.com`
7. **`menubar.py` + `controller.py`:** rumps app with 4-state icon; menu items "Start (Meet) / Start (IRL) / Stop / Open last session / Cloud summary toggle / Quit"; state machine writes `meta.json` after each step
8. **`resilience.py` + LaunchAgent:** on startup, scan `sessions/` for `status != done` and resume from last completed step; reset audio output to built-in speakers if previous session crashed mid-route; install LaunchAgent plist

## Top risks & mitigations

1. **System output stuck on BlackHole after crash → silent Mac.** Mitigation: `try/finally` in controller restores output; startup check resets if `meta.json` shows incomplete. Test by `kill -9` mid-record.
2. **Confidentiality leak via Claude.** Mitigation: PII regex pre-strip (emails, phone numbers, IBANs); cloud-summary toggle defaults off for IRL; raw audio never leaves disk for IRL sessions; verify Anthropic workspace has training disabled.
3. **macOS sleep kills ffmpeg silently.** Mitigation: `caffeinate -dimsu` sibling process for recording duration.
4. **QARA-vocabulary transcription errors.** Mitigation: `initial_prompt` injection of standards/terms; review v1 outputs on 5 real meetings before trusting unattended.

## Verification (end-to-end)

After build complete:
1. **Mic-only path (IRL sim):** click "Start (IRL)", read aloud a 2-min French snippet mentioning a CAPA decision and an action item. Click "Stop". Within 3 min: Notion page exists with decision + action item correctly extracted, recap email received, audio NOT attached to Notion, raw WAV present locally.
2. **Meet path:** join a real Meet with a colleague (or play a French podcast through speakers in a test room). Click "Start (Meet)". Verify `Scribe-Meet` aggregate is selected as system output (visible via menu bar audio icon). Talk 5 min. Click "Stop". Verify both sides of conversation appear in transcript, system output restored to built-in speakers automatically.
3. **Crash recovery:** start a recording, `kill -9` the menubar process. Restart it. Verify session resumes from last completed step (or marks failed and surfaces in retry queue).
4. **Sleep resilience:** start recording, close lid for 30s, reopen. Verify recording continues (caffeinate held it awake) and final WAV is contiguous.
5. **Quality check on 5 real meetings:** review attribution accuracy (action item owners), QARA flag precision/recall, French transcription WER on technical terms. Decide whether to add diarization in v2.

## What's explicitly out of scope for v1

- Speaker diarization (deferred to v2 if attribution is poor)
- Live/real-time transcription (post-meeting only)
- Multi-language code-switching optimization
- Notion *Clients* DB relation (no such DB exists yet)
- Auto-detect mode (explicit menu choice instead)
- iOS/iPhone mic capture (use the built-in Mac mic; iPhone-as-mic adds a Continuity step)
