---
name: unslop
description: Rewrite AI-generated text to sound more human-like using the local Unslopper MLX model. Use when the user wants to "unslop" text, make AI writing sound more natural, or remove AI-typical patterns from prose.
user-invocable: true
disable-model-invocation: true
allowed-tools: Bash, Read, Write, Edit, Glob
argument-hint: "[file path or paste text]"
---

## Unslop — Remove AI writing patterns from text

This skill rewrites AI-generated text to sound more human using the **Unslopper-30B-A3B** model running locally via MLX (Apple Silicon).

### Prerequisites

The model requires `mlx-lm` and the model weights. If not already set up, install with:

```bash
pip3 install mlx-lm
```

The model (`N8Programs/Unslopper-30B-A3B-bf16`) will be downloaded automatically on first run.

### Workflow

1. **Get the input text.** The user provides either:
   - A file path as argument → read that file
   - Pasted text in the conversation
   - No argument → ask the user what text to unslop

2. **Write the input to a temp file** at `/tmp/unslop_input.txt`.

3. **Run the unslopper**:
   ```bash
   python3 ~/.claude/skills/unslop/unslop.py /tmp/unslop_input.txt
   ```

4. **Present the result** to the user. Show the rewritten text.

5. **Ask the user** if they want to:
   - Replace the original file with the unslopped version
   - Save to a new file
   - Copy to clipboard (`pbcopy`)
   - Make further adjustments

### Notes

- The model runs locally on Apple Silicon via MLX — no API calls, fully offline.
- First run will download ~15GB of model weights from Hugging Face.
- Recommended for prose/literary text. May be less effective on highly technical writing.
- Temperature 0.8, repetition penalty 1.1 are the recommended inference settings.
