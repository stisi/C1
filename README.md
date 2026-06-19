# Schützenmadln – Salve & Schnaps

Ein humorvolles 2D-Android-Spiel: eine satirische Rollentausch-Persiflage
auf das Tiroler Schützenwesen. Die Schützenkompanie besteht ausschließlich
aus **Frauen in Schützentracht** (Hut mit Spielhahnfeder, Lodenjanker,
Bandelier) – die **Männer bedienen als Marketenderinnen verkleidet**
(Dirndl, Schürze, Schnapsfassl) im Bierzelt.

> **16+** · Enthält satirischen Alkohol-Humor.
> *Trink verantwortungsvoll – im echten Leben schießt man nüchtern.*

## Spielmodi

### Modus 1 – „Die Ehrensalve" (Schützinnen)
- Der Hauptmann zählt ein: *„Oans… zwoa… drei… FEUER!"*
- **Genau auf den vierten Schlag tippen** – je genauer, desto synchroner
  kracht die Salve. Das Toleranzfenster schrumpft pro Level (350 ms → 80 ms).
- Direkt danach: **Bier-Exen.** Handy kippen (Gyroskop/Beschleunigungssensor),
  um die Maß zu leeren – zu ruckartig gekippt = Bier schwappt über =
  Punktabzug und Spott vom Hauptmann (*„Madl, des war nix!"*).

### Modus 2 – „Der Marketender" (Mander im Dirndl)
- Finger halten = Schnaps einschenken. Stamperl **exakt bis zur roten
  Marke** füllen, nicht überlaufen lassen.
- **Die Regel:** Nach jedem Ausschank trinkt der Marketender selbst eins mit.
- Steigender Pegel als Kernmechanik:
  - der Bildschirm **wackelt und verschwimmt**,
  - die Hand **zittert**, die Flasche **schwankt**,
  - Touch-Eingaben kommen **verzögert** an (bis ~0,5 s),
  - die **Spielhahnfeder** am Hut hängt als Promille-Anzeige immer schiefer.
- Bei 3,0 ‰ fällt der Marketender um – aus is'.

### Frau gegen Marketender (lokaler 2-Spieler-Wechselmodus)
Erst spielt die Schützin alle Level, dann wird das Handy weitergegeben
und der Marketender schenkt aus. Endabrechnung auf der Ergebnistafel.

## Features
- Tiroler Dialekt in Comic-Sprechblasen (*„Oanschenkn, net daneben, Bua!"*)
- **Prozeduraler Blasmusik-Soundtrack** (Humbta-Humbta-Synthesizer), der mit
  steigendem Pegel immer schräger und verstimmter klingt
- Handgezeichnete Vektor-Illustrationen (SVG in `art/`) für die Figuren und
  das Bierzelt; Feder und Gewehr als eigene, animierbare Teil-Sprites.
  Effekte (Schuss, Bierfüllung, Wackeln) prozedural
- Highscores: **„Ehrenschützin"** und **„Marketender des Jahres"**
  (lokal gespeichert)
- 6 Level mit steigendem Schwierigkeitsgrad
- Disclaimer-Screen (16+)

## Technik
- **Engine:** Godot 4.2+ (2D, Mobile-Renderer)
- **Plattform:** Android, Hochformat (720×1280, skaliert)
- **Eingabe:** Touch + Gyroskop/Beschleunigungssensor
  (Desktop-Fallback: Maus; Kippen = Ziehen bei gehaltener Taste)
- **Grafik:** SVG-Illustrationen in `art/` (von Godot als Texturen importiert),
  Effekte über `_draw()`. **Musik** prozedural via `AudioStreamGenerator` –
  keine Binär-Assets im Repo

## Projektstruktur
```
project.godot          – Engine-Konfiguration (Hochformat, Sensoren)
autoload/GameState.gd  – Punkte, Level, Promille, Versus-Modus, Highscores
autoload/Dialekt.gd    – Tiroler Sprüche-Pools
autoload/AudioDirigent.gd – prozedurale Blasmusik + Schuss-/Plopp-Sounds
art/*.svg              – Illustrationen: Schützin, Marketender, Bierzelt, Feder, Gewehr
ui/Figur.gd            – setzt die Figuren aus SVG-Sprites zusammen (drehbare Feder/Gewehr)
ui/SpeechBubble.gd     – Sprechblasen
scenes/Disclaimer.*    – 16+-Hinweis
scenes/MainMenu.*      – Hauptmenü
scenes/Salve.*         – Modus 1: Timing-Minigame
scenes/BierExen.*      – Modus 1b: Gyroskop-Maß
scenes/Marketender.*   – Modus 2: Einschenken mit Pegel
scenes/Ergebnis.*      – Auswertung & Versus-Übergabe
scenes/Ehrentafel.*    – Highscores
```

## Bauen & Ausprobieren
1. [Godot 4.2+](https://godotengine.org/download) installieren und das
   Projektverzeichnis öffnen – F5 startet das Spiel (Maus simuliert Touch).
2. **Android-Export:** In Godot unter *Editor → Export-Vorlagen verwalten*
   die Vorlagen laden, Android SDK + Debug-Keystore in den Editor-Einstellungen
   hinterlegen, dann *Projekt → Exportieren → Android*. Ein Basis-Preset
   liegt in `export_presets.cfg` bei.
3. Aufs Handy spielen – das Bier-Exen braucht echte Sensoren, der Rest
   geht auch am Schreibtisch.
