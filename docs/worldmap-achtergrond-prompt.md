# Tekenprompt: wereldkaart-achtergronden

Prompts voor een beeld-LLM (Gemini, DALL·E, Midjourney, …) om per wereld een
achtergrond te maken voor het levelkeuze-scherm (de wereldkaart).

## Zo gebruik je het

1. Kopieer de **basisprompt** hieronder en plak daarachter de **themaregel** van de wereld.
2. Laat het beeld genereren op (of schaal het daarna naar) **1280×720**.
3. Sla het op als `assets/sprites/backgrounds/worldmap/world<N>.png`
   (bijv. `world1.png`). Het spel laadt het automatisch als achtergrond
   van de wereldkaart; de levelknoppen en het pad worden eroverheen getekend.

## Basisprompt (Engels werkt meestal het best)

> A colorful cartoon world map background for a modern 2D platformer video
> game, smooth vector-style illustration, bright and friendly, landscape
> orientation 1280×720. A winding dirt path runs from the bottom-left corner
> up to the upper-right corner of the image, with 10 small open clearings
> evenly spaced along the path where level markers will be placed. The path
> curves gently: it starts bottom-left, rises slowly to the middle of the
> image, peaks around two-thirds to the right, and ends slightly lower at the
> right edge. Keep the area along the path uncluttered; put scenery details
> (trees, rocks, water, clouds) around and behind the path. No text, no
> letters, no numbers, no UI elements, no characters. Soft daylight,
> cheerful colors suitable for children.

Belangrijk: de 10 open plekken volgen ongeveer deze posities (x, y in pixels
op 1280×720): (120, 560), (250, 530), (380, 490), (490, 430), (570, 350),
(650, 270), (760, 220), (890, 240), (1020, 290), (1140, 330). Je kunt deze
zin toevoegen voor extra precisie:

> The 10 clearings are located approximately at these pixel coordinates on
> the 1280×720 canvas: (120, 560), (250, 530), (380, 490), (490, 430),
> (570, 350), (650, 270), (760, 220), (890, 240), (1020, 290), (1140, 330).

## Themaregel per wereld

| Wereld | Bestand | Themaregel (achter de basisprompt plakken) |
|---|---|---|
| 1 Bos | world1.png | Theme: a lush green forest with tall trees, mushrooms, ferns and wooden signposts; the path is a forest trail. |
| 2 Water | world2.png | Theme: a bright coastal water world with lagoons, lily pads, waterfalls and stepping stones; the path hops across small islands. |
| 3 Grot | world3.png | Theme: a mysterious cave world with glowing crystals, stalactites and torch-lit rock; the path is a rocky tunnel route, dimly but warmly lit. |
| 4 Jungle | world4.png | Theme: a dense tropical jungle with vines, giant leaves, ancient stone ruins and parrots; the path is an overgrown jungle track. |
| 5 Lucht | world5.png | Theme: a sky world high above the clouds with floating islands, rainbows and hot-air balloons; the path jumps from cloud to cloud. |
| 6 Strand | world6.png | Theme: a sunny palm beach with sand castles, seashells, beach umbrellas and a calm blue sea; the path is a trail in the sand. |
| 7 IJsberg | world7.png | Theme: an icy arctic world with icebergs, snow drifts, frozen lakes and northern lights; the path is a snowy trail with footprints. |
| 8 Woestijn | world8.png | Theme: a golden desert with dunes, cacti, pyramids and an oasis; the path is a sandy caravan route. |
| 9 Snoep | world9.png | Theme: a candy land with lollipop trees, chocolate rivers, candy canes and frosting hills; the path is a licorice road. |
| 10 Vulkaan | world10.png | Theme: a dramatic volcano world with lava rivers, dark rock, glowing embers and smoke plumes, still cartoon-friendly and not scary; the path is a cooled lava trail. |
