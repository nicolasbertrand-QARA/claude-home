---
name: Theodo Academy Standards (the Theodo Way)
description: Comprehensive reference to ~38 Theodo Academy Standards across Tech, Product, Sprint, Recruitment — the Lean/Toyota-rooted craft system. Cite the relevant standard by name when advising on a topic it covers; fetch from Notion for the full living version.
type: reference
originSessionId: c49bb997-7a09-4140-bab8-a666604a2328
---
# Source of truth (always fetch fresh when going deep)
- DB: https://www.notion.so/m33/19c6a9acc30244e996d3a06a0a5fa913 — 🎓 Theodo Academy Standards
- Data source: `collection://65a40b3f-9abe-4f27-b565-af8674230b50`
- Parent page "Theodo Academy": https://www.notion.so/d11c5f299420496ca548614dcd42cf29
- Programs DB: `collection://ad6a4e26-29eb-4f6e-a748-71282e0e8af7`
- Programs: **Tech · Product Delivery · Sprint · Product Engineering · Recruitment**
- Status field: Nurturing / In progress / Live / Archived

# What a Theodo standard IS (meta-standard "Academy standard")
Structure: **Intent → Key Points (visual) → Put into practice**.
- Extracts the *expertise behind a gesture* — the mental models, not micro-instructions.
- Built from the **gemba**: OK/KO pieces from the field + verbatims from beginners and experts to surface misconceptions.
- Living document, refined via **andon** (peer challenges with Academy experts) and **dojo** sessions where participants bring real *pieces* of their own work.
- Each standard has a Reference Piece, a "Put into practice" guide, and an expert page documenting common mistakes / misconceptions / mental models.

# Core vocabulary (use natively)
- **Gemba** — the real workplace; where the gesture is performed.
- **Andon** — call for help / pull the cord / escalate when stuck.
- **Dojo** — peer-learning session led by an expert, on participants' real pieces.
- **Piece** — real work artifact (code, ticket, email, diagram, screenshot, interview note).
- **Reframe** — replacing a misconception with the right mental model.
- **Taktak** — sharp, concise synthesis.
- **Dantotsu** — defect-by-defect deep root-cause practice (occurrence vs detection failure; countermeasure + eradication).
- **RDP (Résolution de Problème)** — A3-style problem-solving for multi-week, multi-people problems.
- **Weak Point Management** — recurring defect detection; repeated "why?" until pattern stops.
- **Go & See** — wildlife-photographer observation of users in real situations; no questions, no demo.
- **Client Value Model** — explicit per-project model of client preferences, evolving with each questionnaire.
- **Pieces OK / KO** — well-done / poorly-done examples; raw material from which standards are built.
- **CST** — Client Service Team (sales / delivery / tech).
- **DPS** — Daily Problem Solving.
- **SDR** — Staffing Decision Record.
- **LPM / TL / PM / AM** — Lead PM / Tech Lead / PM / Account Manager.
- **Scorecard** — role-specific evaluation dimensions for hiring.

# Cross-cutting principles (the DNA across all programs)
1. **Field over theory.** Gemba + Go & See + real pieces beat opinions and roadmaps.
2. **Mental models > framework trivia.** "Mastery is the quality of mental models on business modeling, system structure, and failure modes." (Dantotsu)
3. **Reframe, don't teach.** Surface the misconception ("you thought X, but actually Y") before giving the right approach.
4. **Defects are gold.** Every defect → Dantotsu → countermeasure → eradication of the class.
5. **Show, don't tell.** Visuals, one key message per slide, taktak synthesis.
6. **Collaborative artifacts.** BPMN workshop > BPMN diagram; spec is shared discovery, not PM handoff.
7. **Anticipation over reaction.** Project launch review, SDR, calibration meeting, BPMN — surface failure modes before they bite.
8. **No surprises to the client.** Daily mail, weekly questionnaire reply <24h, sprint review storytelling, ahead-of-time roadmap calls.
9. **Ingenuity over playbook.** Iconic case studies and storylines pivot on a creative reframe, not standard methodology.
10. **Living standards.** When the standard has a gap, that's andon-worthy.

---

# Standards by program

## Foundation / Method
| Standard | Intent (1-line) | Notion ID |
|---|---|---|
| **Academy standard** (meta) | Extract expertise behind the gesture without micro-guidance. | `16d8f3776f4f806a9ea0d45415826c2f` |
| **Dantotsu** | Inspire devs to care about quality through defect-by-defect deep RCA. 8 steps: defect → user impact → causal chain → root cause of occurrence → detection failure → countermeasure → eradication → go further. Reframe: "I forgot" / "no test" are not root causes. | `1ad8f3776f4f8041a3a6c1d6fa2cd0d1` |
| **STANDARD RDP** | Turn a multi-week, multi-people problem into shareable insights. Frame as quality/cost/on-time gap; reconstruct timeline with 5W1H; attach real artifacts; separate occurrence vs recurrence causes; use VUCA; taktak synthesis. | `1578f3776f4f80bd8ed2e866a8288d01` |
| **Weak Point Management** | Detect recurring defect categories despite countermeasures via repeated "why?" until pattern stops. | `33e8f3776f4f806ab67ef3106175db72` |

## Tech (engineering craft)
| Standard | Intent + key reframe | Notion ID |
|---|---|---|
| **Good debugging method** | Frame: **S.U.E.D** (Solved · Understood · Efficient · Dantotsu-ed). 6 steps: Zen → See it fail (reproduce) → Quit thinking and look → Divide & conquer → Audit trail → Dantotsu. Reframe: trial-and-error is not "fast"; software isn't a jungle, think first. | `53a1cf22df6e49aaa455d221c02ef18f` |
| **Good local debugging technique** | Master debuggers (not console.log). 50% of dev time is debugging. Use `debugger;`/`breakpoint()`, n/s/r/c commands, capture fixtures. Framework code is *not* a black box (read node_modules). | `d3ef6813c0cf4505a1413e22976754ae` |
| **Good remote/network debugging** | Debug remote/prod safely: check version-in-prod first, secure debug mode, conditional breakpoints (don't block all users), `ssh -L` port-forward, sync source code. | `a0a1b82b63784ba5b58e12b488615f59` |
| **Refactoring code** | Long methods (20+ lines) breed bugs. Apply Fowler's Extract Function. **Never mix refactor + behavioral change** in one commit. Refactoring without tests is gambling. | `209c6074e1b74911b3ff32440a287805` |
| **Naming variables and functions** | Read:write ratio is 10:1. Names = primary communication. Specificity matches scope. Use team vocabulary (one term per concept). Avoid `data`/`tmp`/`foo`, gratuitous context, abbreviations, language-mixing. Singular for items, plural for collections. | `ba767c2b23ff43539ad5ea5cab222f58` |
| **Clean Conditionals** | Each branch = potential bug trap. Return early > nested else > stateful flags. Polymorphism > switch > if. Name your predicates. One path = one result. | `fb10629c5b7648fc819e46bb1dc0f28b` |
| **Guiding AI code completion** | Context determines suggestion quality. 1 minute of preparation (open sample files, load types, organize workspace) dramatically improves Copilot output. Start in new files (tests) for low-risk muscle memory. | `20d8f3776f4f80f0a300e946b7e8b1d7` |

## Product / Discovery / Engineering
| Standard | Intent + key reframe | Notion ID |
|---|---|---|
| **The product concept** | Align team and stakeholders by stating the core challenge in **one sentence**. Concept describes the problem, not the solution. | `2d084063-1921-4e53-95a9-e58a536ac826` |
| **Product architecture** | PM-owned visual mapping user *key preferences* + *critical performances* per segment to product components. Used to negotiate where to spend team energy and to prove fit in sales. Don't reverse-engineer from the backlog. | `cda3406e-2b53-4799-89ed-b97d5f6ebb47` |
| **Functional architecture diagram** | Show product structure + 3S risks (speed, scalability, security) + delivery risks. Tell **1-2 key messages**, not every detail. Each box must connect to a preference. Avoid crossing arrows. | `2d41d6f1-8c08-4517-96d0-9120c6775aab` |
| **BPMN** | Workshop (PM + TL + Dev owner + Designer) on Epic flow with success/error per step. **The value is the discussion, not the diagram.** Inputs: scope, finalized mockups, tech investigation done, edge cases pre-spotted, attendees prepped. | `2408f377-6f4f-80d3-a193-c50565f4530b` |
| **Interviewing users** | Listen, don't pitch. Track interviewee speaking time. Gather raw quotes/observations only — no interpretation in-session. **Past experiences** ("Tell me about the last time…"), not hypotheticals. Never demo product. Unfold emotions. | `cf02ab13-6e2a-49b1-972e-466ca6ebe291` |
| **Jobs to be done (JTBD)** | The "desired self" the user wants to become — not actions. Three dimensions: functional + emotional + social. Distinct segments have distinct JTBDs. Ground in voice-of-customer; never assume. | `f2dd2698-85a3-4c1b-a182-15ab39c5dd5a` |
| **UX Basics for PMs** | Foundation training for PMs to master core UX principles for adoption. (Module gateway, structured training program.) | `2188f377-6f4f-802d-96d6-f706b3436ecf` |
| **Concept Paper - Ondo** | Example: 5 distinct JTBDs across PM-submit, PM-analyze, group-PM-track, team-request-support, AM-monitor. Multi-stakeholder JTBD mapping. | `a06bf1b3-fa46-45c6-8c0e-04ba751f70b9` |
| **Power map** | Map decision-maker, influencers, and **champion** in a sales process. Address both left-brain (rational) and right-brain (emotional) drivers. Stated objectives ≠ real objectives — dig for personal stakes. | `2248f377-6f4f-807a-8738-e049b1bbca6f` |
| **Go & See** | Observe users in real situation like a wildlife photographer. **No questions, no interruption, no demo.** Capture lead times, gestures, emotions, quotes, tools, documents, workplace organization. ≠ interview, ≠ user test. | `abaf8116ac5c44b59c27fec9a28fcc42` |
| **The Client Value Model** | Per-project, evolving model of client preferences. Built with sales + team who know client; validate against questionnaires; revisit before milestones. Drives which Theodo standards to adapt. | `78ba6e28333d400a8f6e06824fd588e8` |

## Sprint / Delivery
| Standard | Intent + key reframe | Notion ID |
|---|---|---|
| **The feature kanban** | Make team flow problems visible. Columns reflect real workflow stages; explicit WIP limits; discuss what the board reveals weekly. | `99ab4dd2-5762-49ad-a439-0580d9060429` |
| **Sprint review slide deck** | Give client *control* via transparent narrative on progress, risks, and team actions — without alarming. Storytelling first, slides second. Start prep right after previous sprint. Second pair of eyes before meeting. | `3c9e0732-8efd-4109-913d-aa17bfd3cfa6` |
| **Specification** | 13-step operating mode from problem validation through prod monitoring. Backwards from Gemba observation. Map all use cases (happy + edge + error). Spec is **shared discovery, not PM handoff**. | `2b78f377-6f4f-800f-b6d2-db39ddb6c7c1` |
| **User Story** | Four-part: **Who** (persona) + **Where** (specific UI/page) + **Trigger** (action) + **Visible Result** (what changes). End-to-end validation, not API 200. "Dev" is not a persona; vague "where" hides team un-clarity. | `2268f377-6f4f-80c2-a9d8-c937057718d6` |
| **Standard UJ v3** (User Journey) | Map current user situation with emotions, frictions, touchpoints — to surface opportunities as **"How Might We"** (not solutions). Build on Go & See, not assumptions. Compact enough that emotions visibly link to steps. | `c75faaf7-229b-4537-aa09-214095d3d697` |
| **Storyline** | Five-part narrative: Essential point + Context + Complication + **Turning point (reframe)** + Resolution. Co-build with client. Time spent on storyline upfront saves deck-building time. | `2248f377-6f4f-800a-b639-c43bdbae69db` |
| **Daily Mail** | Build trust by showing fast value or proactive blocker handling. **No surprises** — call ahead of any roadmap impact. Run DPS same-day if a ticket isn't done so learnings are mail-ready. | `eea51d70-f20f-4ccd-99a6-24461c45d6e5` |
| **Project Launch review** | Pre-launch CST consensus on most probable failure modes. Strengthens team autonomy by neutralizing scenarios before they bite. | `1538f377-6f4f-8090-be6e-ca2e87b0c2ff` |
| **SDR (Staffing Decision Record)** | Document team composition + skill gaps + counter-measures across 3 pillars: technical, delivery, product. TL ≥ 2 yrs; LPM Académie L3 for fixed-price. Don't isolate a Theodoer; don't pair two first-time managers. Validate with LPM + TL before announcing staffing. | `2888f377-6f4f-80f4-9455-eddbfc596661` |
| **Standard analyse de questionnaire client** | Reply <24h. Precise root-cause per problem (not Pareto groupings). Two outputs: problems + new client preferences. Frame from *client* perspective, not company. Visible plan progress. | `0121ea33-612b-40aa-a292-445cc471f470` |

## Recruitment
| Standard | Intent + key reframe | Notion ID |
|---|---|---|
| **Mener un E1** | Evaluate fit on group values + role aptitudes via STAR (Situation/Task/Actions/Results/Recul). Test smartness, drive, team spirit. Create desire authentically. Live debrief with positive-first then factual gap. Don't repeat qualification call; don't drift into café-du-commerce. | `6d4573c6-7aad-4f9b-915f-1c3f9534d0ba` |
| **Préparer brief & debrief d'entretien** | 24h pre-brief: CV + drivers + warning flags + role context. Debrief is **factual review of scorecard**, not impressions. Probe vague statements until concrete behavior emerges. Log in ATS (Lever). Never share prior interview score before fresh evaluation. | `24d8f3776f4f80a99546e2619513de19` |
| **Skill card (contacting candidates)** | Personal interest > template. Reference specific profile detail + one inspiring fact tied to *their* drivers. End with one sincere open question. Match channel to seniority. Avoid: comp/ben pitch, jargon (A3, Kaizen), war/seductive vocab, intrusive questions. | `85859ce9-895b-4c41-b797-f347b3183c3e` |
| **Calibration meeting** | Sync hiring stakeholders on persona, mandatory vs nice-to-have skills, problems-to-solve. Hold *after* JD finalized. Output: written report shared with all interviewers. | `bbf8c1c0-b286-4171-bb0a-98e001a7d3b1` |
| **Pitch an iconic case study** | Iconic = high-brand (TF1) OR innovative (BPI). Story arc: how-we-met + urgency → client's market/biz/regulatory/org constraints → ingenious solution → quantified results in audience's terms → dialogue (not monologue). Connect to *listener's* world. | `f1e5445e-aa52-4de0-9f00-e1b20de77074` |

---

# How to use this memory
- **Default mode (everyday):** keep these standards in the back of mind. When advising on a topic that maps to a standard, frame in the standard's vocabulary and cite it by name. Don't lecture.
- **Strict mode (`/LeanTech` skill):** enforce rigorously — fetch the canonical standard from Notion, demand the user's piece, reframe misconceptions, apply the standard's "Put into practice" steps, push for eradication.
- **Topic mapping shortcut:**
  - Bug / defect → Dantotsu
  - Multi-week problem → RDP
  - Recurring defect class → Weak Point Management
  - User research → Go & See, Interviewing users, JTBD
  - Spec / Epic → Specification, BPMN, User Story
  - Architecture / system design → Product architecture, Functional architecture diagram
  - Sprint comm → Daily Mail, Sprint review slide deck, Questionnaire analysis
  - Hiring → Calibration meeting, Skill card, Mener un E1, Brief/debrief, Pitch iconic case
  - Sales / proposal → Power map, Storyline, Pitch iconic case, Concept paper
  - Code quality → Naming, Clean Conditionals, Refactoring, Debugging method (S.U.E.D)
  - Team staffing → SDR
  - Project kick → Project Launch review, Client Value Model
- **When the user references a standard not yet in this memory:** fetch from Notion via `mcp__claude_ai_Notion__notion-fetch` (data source `collection://65a40b3f-9abe-4f27-b565-af8674230b50`) and update this file.
