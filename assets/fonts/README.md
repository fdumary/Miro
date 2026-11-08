# Fonts

| File | Use | Licence |
|---|---|---|
| `UnifrakturMaguntia-Book.ttf` | Titles: start, end and credits screens, cutscene title cards | SIL Open Font License 1.1 (`UnifrakturMaguntia_OFL.txt`) |
| `PirataOne-Regular.ttf` | Every other line of game text (UI theme, bubbles, subtitles) | SIL Open Font License 1.1 (`PirataOne_OFL.txt`) |

Both come from Google Fonts. `scripts/typeface.gd` (autoload `Typeface`) makes Pirata One the default font for every
`draw_string` and Control; `scripts/cinema.gd` uses Unifraktur for titles. To try another face, replace the path in
`scripts/typeface.gd`.
