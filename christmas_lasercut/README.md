# Laser-Cut Weihnachtsornament – FF-Vorderthiersee

**Datei zum Schneiden:** `Weihnachten_FF-Vorderthiersee_lasercut.svg`
**Vorschau:** `preview.png`

## Design
- Christbaumkugel-Form mit Aufhängeöse, Spitzen-/Perlenrand
- Tannengirlande in zwei Bögen, Schleife, hängender facettierter Stern, 6 Kugeln
- „Frohe Weihnachten“ in Script, „wünscht“ mit Zierlinien
- Tiroler Bergpanorama mit Schneekappen, Tannen und Feuerwehrhaus mit Schlauchturm
- „FF-Vorderthiersee“ im Bogen-Banner (Cinzel Bold)

## Technische Daten
- Maße: 204 × 217 mm (Ø 200 mm + Öse), Einheit mm
- **Ein einziges zusammenhängendes Teil** – keine herausfallenden Inseln
- Schnittlinie: rot `#FF0000`, 0,1 mm Haarlinie (LightBurn, Glowforge, xTool, RDWorks)
- Alle Texte sind Pfade, es werden keine Schriften benötigt
- Mindeststegbreite ≈ 0,6 mm, Mindestspalt ≈ 0,7 mm
- Empfohlen: 3 mm Pappel-/Birkensperrholz, 2–3 mm MDF oder 3 mm Acryl, Größe ≥ 180 mm.
  Für kleinere Formate in `generate.py` die Werte von `KERF_CLEAN` und `EMB` erhöhen.

## Neu erzeugen
```
pip install fonttools uharfbuzz shapely cairosvg
./render.sh
```
Schriften: Great Vibes & Cinzel (SIL Open Font License 1.1).
