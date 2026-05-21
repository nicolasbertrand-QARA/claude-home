#!/usr/bin/env python3
"""Unslop: rewrite AI-generated text to sound more human using the Unslopper model."""

import sys
from mlx_lm import load, generate
from mlx_lm.sample_utils import make_sampler, make_logits_processors

MODEL_ID = "N8Programs/Unslopper-30B-A3B-bf16"

def unslop(passage: str) -> str:
    model, tokenizer = load(MODEL_ID)
    prompt = f"Rewrite this AI passage to sound more humanlike:\n{passage}"
    messages = [{"role": "user", "content": prompt}]

    output = generate(
        model,
        tokenizer,
        tokenizer.apply_chat_template(messages, add_generation_prompt=True),
        max_tokens=4096,
        sampler=make_sampler(temp=0.8),
        logits_processors=make_logits_processors(repetition_penalty=1.1),
    )
    return output.strip()

if __name__ == "__main__":
    if len(sys.argv) > 1:
        input_file = sys.argv[1]
        with open(input_file, "r") as f:
            passage = f.read()
    else:
        passage = sys.stdin.read()

    if not passage.strip():
        print("Error: no input text provided.", file=sys.stderr)
        sys.exit(1)

    print(unslop(passage))
