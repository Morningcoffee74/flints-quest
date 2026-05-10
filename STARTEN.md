# Flint's Quest starten

## Eerste keer (eenmalig)

1. **Download Godot 4** (als je dat nog niet hebt)
   - Ga naar https://godotengine.org/download/
   - Download **Godot Engine – Standard** voor macOS
   - Sleep de app naar je Applications map

2. **Download het project van GitHub**
   - Ga naar https://github.com/Morningcoffee74/flints-quest
   - Klik op de groene knop **"Code"** → **"Download ZIP"**
   - Pak het ZIP-bestand uit (dubbelklik)
   - Of, als je Git hebt: open Terminal en typ:
     ```
     git clone https://github.com/Morningcoffee74/flints-quest.git
     ```

## Het spel openen in Godot

1. Start **Godot 4**
2. Klik op **"Import"** (of "Importeren")
3. Navigeer naar de map **`flints-quest`** (of `Flint Game`)
4. Klik op **`project.godot`** → **"Open"**
5. Het project laadt nu in de Godot editor

## Het spel spelen

- Druk op **F5** (of klik het ▶ Play-knopje rechtsboven)
- Het hoofdmenu verschijnt
- Klik **"Nieuw Spel"** → voer een naam in → **"Aanmaken"**
- Klik op **level 1** op de wereldkaart → spelen!

## Bijwerken (als er een nieuwe versie is)

Als je **ZIP** hebt gedownload:
- Download opnieuw via GitHub → "Download ZIP" → pak uit en vervang de oude map

Als je **Git** hebt:
1. Open Terminal in de projectmap
2. Typ: `git pull`
3. Heropen het project in Godot (of klik op het Godot venster, het laadt automatisch bij)

## Besturing

| Actie                              | Toetsen        |
|------------------------------------|----------------|
| Lopen                              | A / D of ← / → |
| Springen                           | Spatie of Z    |
| Boksen                             | X of Enter     |
| Bukken *(op de grond)*             | S of ↓         |
| Ladder op                          | W of ↑         |
| Ladder af *(als je op een ladder staat)* | S of ↓   |
| Pauzeren                           | Escape         |

> **S / ↓** doet twee dingen afhankelijk van de situatie:  
> op de grond = bukken (vogels ontwijken), aan een ladder = omlaag klimmen.
