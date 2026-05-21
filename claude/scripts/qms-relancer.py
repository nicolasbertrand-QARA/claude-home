#!/usr/bin/env python3
"""Daily reminder for QMS Notion documents in 'In verification' / 'In approval'.

Queries the Documents DB on Notion, finds rows in those statuses, and sends
one email per document to the assigned verifier (or approver) using the
template stored as TEMPLATE below.

Usage:
    qms-relancer.py            # send emails
    qms-relancer.py --dry-run  # show what would be sent, don't send
"""

import argparse
import base64
import json
import subprocess
import sys
from email.message import EmailMessage

NOTION_DB_ID = "2848f377-6f4f-802d-8a2c-db9cd436a0af"
SENDER = "nicolas.bertrand@theodo.com"

# Gender per person email — used to agree adjectives/role nouns in French.
# Values: "f" (féminin) or "m" (masculin). Unknown emails default to "m".
GENDER_BY_EMAIL: dict[str, str] = {
    "marine.accolas@theodo.com": "f",
    "noemie.parker@theodo.com": "f",
    "nicolas.bertrand@theodo.com": "m",
}

SUBJECT_TEMPLATE = "{first_name} tu as une tâche en attente sur le QMS"

BODY_TEMPLATE = """Hello {first_name},

Tu es {attendu} sur Notion pour {action} un document : {doc_url}

Rien de plus simple :
1. Tu relis le document
   a. Si c'est une vérification, tu proposes tes modifications en taggant l'auteur.
   b. Si c'est une approbation, tu t'assures que le document soit clean (pas de commentaire, pas de placeholders) et conforme.
2. Ensuite, tu fais passer son statut à l'étape suivante
   a. In verification → In approval si tu es {verificateur}
   b. In approval → Approved si tu es {approbateur}

☝️ Si tu es {verificateur} ET {approbateur}, il faut quand même faire les deux changements de statut, ne pas passer tout de suite à la fin.

Merci à toi,

Nico, via Claude.
"""

AGREEMENTS: dict[str, dict[str, str]] = {
    "f": {"attendu": "attendue", "verificateur": "vérificatrice", "approbateur": "approbatrice"},
    "m": {"attendu": "attendu", "verificateur": "vérificateur", "approbateur": "approbateur"},
}


def run(cmd: list[str]) -> str:
    result = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        sys.stderr.write(f"Command failed: {' '.join(cmd)}\nstderr: {result.stderr}\n")
        sys.exit(1)
    return result.stdout


def query_status(status: str) -> list[dict]:
    out = run([
        "notion", "db", "query", NOTION_DB_ID,
        "--filter", f"Status={status}",
        "--all",
        "--format", "json",
    ])
    return json.loads(out).get("results", [])


def extract_card(row: dict, people_property: str) -> dict | None:
    props = row["properties"]
    name_parts = props.get("Name", {}).get("title", [])
    doc_name = "".join(t["plain_text"] for t in name_parts).strip() or "(sans titre)"
    people = props.get(people_property, {}).get("people", [])
    if not people:
        return None
    return {
        "doc_name": doc_name,
        "doc_url": row["url"],
        "people": [
            {
                "name": p.get("name", ""),
                "email": p.get("person", {}).get("email", ""),
            }
            for p in people
            if p.get("person", {}).get("email")
        ],
    }


def first_name(full_name: str) -> str:
    return full_name.split(" ")[0] if full_name else ""


def build_message(to_email: str, to_name: str, doc_name: str, doc_url: str, action: str) -> EmailMessage:
    fn = first_name(to_name)
    gender = GENDER_BY_EMAIL.get(to_email.lower())
    if gender is None:
        sys.stderr.write(
            f"WARN: no gender mapping for {to_email}; defaulting to masculine. "
            f"Add it to GENDER_BY_EMAIL.\n"
        )
        gender = "m"
    agreement = AGREEMENTS[gender]
    msg = EmailMessage()
    msg["From"] = SENDER
    msg["To"] = to_email
    msg["Subject"] = SUBJECT_TEMPLATE.format(first_name=fn)
    msg.set_content(BODY_TEMPLATE.format(first_name=fn, action=action, doc_url=doc_url, **agreement))
    return msg


def send_via_gws(msg: EmailMessage) -> None:
    raw = base64.urlsafe_b64encode(msg.as_bytes()).decode("ascii")
    body = json.dumps({"raw": raw})
    run([
        "gws", "gmail", "users", "messages", "send",
        "--params", '{"userId": "me"}',
        "--json", body,
    ])


def collect_emails() -> list[dict]:
    """Returns list of {to_email, to_name, doc_name, doc_url, action}."""
    emails = []
    for row in query_status("In verification"):
        card = extract_card(row, "Assigned Verifier [Manual]")
        if not card:
            continue
        for p in card["people"]:
            emails.append({
                "to_email": p["email"],
                "to_name": p["name"],
                "doc_name": card["doc_name"],
                "doc_url": card["doc_url"],
                "action": "vérifier",
            })
    for row in query_status("In approval"):
        card = extract_card(row, "Assigned Approver [Manual]")
        if not card:
            continue
        for p in card["people"]:
            emails.append({
                "to_email": p["email"],
                "to_name": p["name"],
                "doc_name": card["doc_name"],
                "doc_url": card["doc_url"],
                "action": "approuver",
            })
    return emails


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true", help="Print emails without sending")
    args = ap.parse_args()

    emails = collect_emails()
    if not emails:
        print("Nothing to send today.")
        return 0

    for e in emails:
        msg = build_message(e["to_email"], e["to_name"], e["doc_name"], e["doc_url"], e["action"])
        if args.dry_run:
            print("=" * 70)
            print(f"To: {msg['To']}")
            print(f"Subject: {msg['Subject']}")
            print(f"Doc: {e['doc_name']}")
            print("-" * 70)
            print(msg.get_content())
        else:
            send_via_gws(msg)
            print(f"Sent → {e['to_email']} ({e['doc_name']})")

    return 0


if __name__ == "__main__":
    sys.exit(main())
