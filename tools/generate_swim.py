#!/usr/bin/env python3
"""
generate_swim.py — probeer met de Google Gemini API een zwem-sprite van Flint te
maken in exact zijn eigen stijl (image-to-image).

Dit script draai je op je EIGEN Mac (bijv. via Claude Code in de terminal), NIET
in de Cowork-omgeving. Reden: het heeft internet naar Google en jouw persoonlijke
API-sleutel nodig, en die sleutel hoort niet in een gedeelde omgeving.

------------------------------------------------------------------------------
EENMALIG INSTELLEN
------------------------------------------------------------------------------
1. Gratis API-sleutel halen op https://aistudio.google.com/apikey
2. In de terminal, in de projectmap:
       pip3 install --upgrade google-genai pillow
       export GEMINI_API_KEY="jouw_sleutel_hier"
3. Script draaien:
       python3 tools/generate_swim.py

De uitvoer komt in: assets/sprites/player/SwimFlint_ai.png
Bevalt het? Hernoem het naar SwimFlint.png (overschrijf de placeholder) en Godot
gebruikt het meteen — de afmetingen blijven gelijk, dus verder hoeft niets.

------------------------------------------------------------------------------
LET OP (eerlijk)
------------------------------------------------------------------------------
- Beeld-naar-beeld op een piepklein pixel-figuurtje is wisselvallig: soms komt er
  een mooier resultaat uit, soms iets dat te glad is of niet meer bij de stijl
  past. Draai desnoods een paar keer of pas de PROMPT hieronder aan.
- De modelnaam voor beeldgeneratie bij Google verandert regelmatig. Werkt het
  niet, pas dan MODEL hieronder aan (zie de foutmelding, die noemt vaak een
  geldige naam) of kijk op https://ai.google.dev/gemini-api/docs/image-generation
"""

import os
import sys

# Bronframe: een enkele loop-pose van Flint als vertrekpunt (128x128).
INPUT_IMAGE = "assets/sprites/player/Run.png"
OUTPUT_IMAGE = "assets/sprites/player/SwimFlint_ai.png"

# Pas deze aan als de API klaagt over een onbekend model.
MODEL = "gemini-2.5-flash-image-preview"

PROMPT = (
    "This is a small 2D game character in a hand-drawn pixel/cartoon style "
    "(a blond boy with a dark blue shirt and brown pants). Keep his EXACT art "
    "style, proportions, colors and outline. Draw him in a SWIMMING pose seen "
    "from the side, facing right: body roughly horizontal and leaning forward, "
    "arms reaching forward, legs kicking behind him, as if swimming through "
    "water. Single character, centered, on a fully transparent background, "
    "same small sprite size as the source. No water, no bubbles, no text."
)


def main() -> int:
    try:
        from google import genai
        from google.genai import types
        from PIL import Image
    except ImportError:
        print("Ontbrekende pakketten. Draai eerst:  pip3 install --upgrade google-genai pillow")
        return 1

    key = os.environ.get("GEMINI_API_KEY")
    if not key:
        print("Zet eerst je sleutel:  export GEMINI_API_KEY=\"...\"  (zie kop van dit bestand)")
        return 1

    if not os.path.exists(INPUT_IMAGE):
        print(f"Bronafbeelding niet gevonden: {INPUT_IMAGE} (draai dit vanuit de projectmap)")
        return 1

    # Neem het eerste 128x128-frame als referentie.
    src = Image.open(INPUT_IMAGE).convert("RGBA")
    frame = src.crop((0, 0, 128, 128))
    tmp = "_flint_frame_tmp.png"
    frame.save(tmp)

    client = genai.Client(api_key=key)
    print(f"Verstuur naar {MODEL} ...")
    try:
        resp = client.models.generate_content(
            model=MODEL,
            contents=[PROMPT, Image.open(tmp)],
            config=types.GenerateContentConfig(response_modalities=["IMAGE", "TEXT"]),
        )
    except Exception as e:
        print("API-fout:", e)
        print("Tip: pas MODEL bovenin dit bestand aan naar een naam uit de foutmelding.")
        os.remove(tmp)
        return 1

    saved = False
    for part in resp.candidates[0].content.parts:
        if getattr(part, "inline_data", None) and part.inline_data.data:
            with open(OUTPUT_IMAGE, "wb") as f:
                f.write(part.inline_data.data)
            saved = True
            print(f"Klaar: {OUTPUT_IMAGE}")
    os.remove(tmp)

    if not saved:
        print("Geen afbeelding terug gekregen. Probeer opnieuw of pas de PROMPT aan.")
        return 1
    print("Bevalt het? Hernoem naar SwimFlint.png om de placeholder te vervangen.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
