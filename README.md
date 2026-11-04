# jakt-app (prototype)

Klikkbar prototype av en norsk jakt-app, mobilformat, én fil (`index.html`, Leaflet via CDN).

## Kjør
Åpne `index.html` i nettleseren, eller: `python3 -m http.server` og gå til http://localhost:8000.

## Klikksti
1. **Kart** – kart over Norge med 5 eksempelområder (Trollheimen, Romsdal, Hardangervidda, Finnskogen, Saltfjellet). Trykk et område → kort med vilt og jakttider.
2. **Jakttider** – Gantt-kalender aug–mars for elg, hjort, rådyr, rype, hare, med linje for i dag, notater om kommunale jakttider og jaktforbud 24.–31. desember. Elgdatoen er merket ubekreftet.
3. **Varsler** – av/på per art, varsel 1/3/7/14 dager før, test-knapp viser «Elgjakta starter om 3 dager i Molde».

## Data
Illustrativt. Områdene er eksempeldata. Jakttider fra Miljødirektoratets forskrift om jakt- og fangsttider 2022–2028 (FOR-2022-01-21-128). **Elg 25.09.–23.12. er ikke bekreftet i selve forskriften – sjekk på Lovdata før den vises som offisiell.** Varsler er simulert (ingen ekte push).

Skjermbilder: `docs/screenshots/` · Video: `docs/demo.mp4`
