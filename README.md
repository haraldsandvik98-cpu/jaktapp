# Jaktlogg

En enkel jakt-app (prototype) der du logger bilder av alt du har skutt i løpet av sesongen.

- **Land → kategori → art:** velg 🇳🇴 Norge eller 🇸🇪 Sverige øverst i «Arter» og i «Ny fangst», deretter Storvilt/Småvilt og art. Valget huskes, og artsoversikten følger landet. Eldre fangster uten land regnes som Norge.
- **Arter:** oversikt over Storvilt og Småvilt for valgt land, med antall fangster per art. Trykk på en art for å se fangstene og legge til ny: sted (valgfritt), posisjon på topografisk kart (trykk eller «Bruk min posisjon»), dato og tid, flere bilder, notater. Hver art har et ekte viltbilde (se Bildekreditter).
- **År:** velg år og land (Alle/Norge/Sverige), se totalt antall og fangstene per art, per måned eller på kart. Trykk på en fangst for bildegalleri (sveip) og sletting.

**Kjøre:** åpne `index.html` i en nettleser (ingen byggesteg), eller se live på https://haraldsandvik98-cpu.github.io/jaktapp/. Appen er privat: som standard lagres fangster og bilder kun på enheten (IndexedDB i nettleseren). Valgfritt kan du koble til ditt eget Supabase-prosjekt (se under).

Skjermbildene i `docs/screenshots/` bruker genererte eksempelfangster (illustrasjoner, ikke ekte bilder) som kun legges inn av skjermbilde-skriptet.

Flere krav kommer – appen bygges videre etter hvert.

## Land, kategorier og kilder

Artslistene er hentet fra offisielle kilder (lest november 2026). Appen viser **ingen jakttider** – sjekk alltid gjeldende forskrift («se gjeldende forskrift»).

| Land | Storvilt | Småvilt | Kilde |
|---|---|---|---|
| Norge | 12 | 27 (+ Annet) | [Jakttidsforskriften FOR-2022-01-21-128](https://lovdata.no/dokument/SF/forskrift/2022-01-21-128) §§ 2–3 (endret 01.07.2026); bjørn, ulv, jerv (lisens) og gaupe (kvote) etter [rovviltforskriften FOR-2005-03-18-242](https://lovdata.no/dokument/SF/forskrift/2005-03-18-242) |
| Sverige | 12 | 25 (+ Annat) | [Jaktförordning (1987:905)](https://www.riksdagen.se/sv/dokument-och-lagar/dokument/svensk-forfattningssamling/jaktforordning-1987905_sfs-1987-905/) bilaga 1 (allmän jakttid), bilaga 4 och 23 c–f §§ (licensjakt/skyddsjakt) |

Merking: **Lisens**/**Kvote**/**Skyddsjakt** = kun når myndighetene har vedtatt jakt/felling (ingen ordinær jakttid). **Fremmed art** = fremmed/introdusert art. Svenske arter vises med svensk navn og norsk navn under. Arter uten eget bilde får et nøytralt emoji-kort.

Merknader: gråmåke/svartbak har ikke lenger jakttid i § 2 (endring 01.07.2026), så «Måker» er fjernet for Norge (gamle Måker-fangster vises under Annet). Svensk bilaga 1 får ny versjon fra 2027-07-01; listen må da sjekkes på nytt.

**Supabase:** kjør `supabase/schema.sql` på nytt (legger til kolonnen `country`). Uten kolonnen lagres fangster fortsatt, men uten land.

## Lagring på server (valgfritt, Supabase)

Uten oppsett lagres alt kun på enheten. Vil du ha fangstene privat på en server (og på flere enheter), kan du koble til ditt eget gratis Supabase-prosjekt:

1. Gå til [supabase.com](https://supabase.com), lag en gratis konto og trykk **New project**.
2. Åpne **SQL Editor**, lim inn hele [`supabase/schema.sql`](supabase/schema.sql) og trykk **Run**. Dette lager tabellen `entries` med radnivåsikkerhet (RLS) og en privat bildebøtte `photos` der hver bruker kun når sine egne filer.
3. **Authentication → URL Configuration:** sett **Site URL** til `https://haraldsandvik98-cpu.github.io/jaktapp/` og legg samme adresse til under **Redirect URLs** (brukes av bekreftelses-, innloggings- og «glemt passord»-lenker).
4. *Valgfritt, anbefalt for en personlig app:* **Authentication → Providers → Email** → slå av **Confirm email**. Da kan du opprette konto med passord og være innlogget med en gang, uten e-post.
5. **Project Settings → API** (eller **API Keys**): kopier **Project URL** (`https://xxxx.supabase.co`, appen fjerner selv `/rest/v1` o.l.) og **anon / publishable key**. Bruk aldri `service_role`/secret-nøkkelen. Appen avviser den.
6. Appen → **Innstillinger**: lim inn URL og nøkkel og trykk **Lagre**.
7. Innlogging:
   - **Ny bruker? Opprett konto:** e-post + passord (minst 6 tegn).
   - **Logg inn med passord:** standard. Gir ingen e-post, så du unngår Supabase sin grense «email rate limit exceeded».
   - **Glemt passord?:** sender en lenke, og du velger nytt passord i appen.
   - **Send innloggingslenke i stedet:** e-postlenke som reserve. Har du logget inn med lenke, kan du sette passord under **Innstillinger → Konto → Sett passord**.
8. Har du fangster lagret lokalt fra før, trykk **Flytt lokale fangster til server** under Innstillinger.

Supabase sin innebygde e-posttjeneste sender bare noen få e-poster i timen. Får du «For mange e-poster», vent en time eller bruk passord.

Anon-nøkkelen er offentlig etter design. Det er RLS-reglene i `schema.sql` som sørger for at bare du ser dine fangster og bilder.

## Bildekreditter

Bakgrunn (`assets/bg.jpg`): «River in the heart of Trollheimen mountains» av Jakub Fryš, [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:River_in_the_heart_of_Trollheimen_mountains.jpg), lisens [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). Nedskalert og komprimert.

### Artsbilder (`assets/species/`)

Alle fra Wikimedia Commons, beskåret til kvadrat og komprimert (endret).

| Art | Fil | Fotograf | Lisens |
|---|---|---|---|
| Elg | [European Elk (Europeisk Elg) (Alces alces alces) - Bodø, Norway 2023-07-16.jpg](https://commons.wikimedia.org/wiki/File:European_Elk_(Europeisk_Elg)_(Alces_alces_alces)_-_Bod%C3%B8,_Norway_2023-07-16.jpg) | Ryan Hodnett | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) |
| Hjort | [Red Deer Cervus Elaphus Richmond Park 2025 01.jpg](https://commons.wikimedia.org/wiki/File:Red_Deer_Cervus_Elaphus_Richmond_Park_2025_01.jpg) | Julian Herzog (Website) | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0) |
| Rådyr | [Roe deer (Capreolus capreolus) female Cumnor.jpg](https://commons.wikimedia.org/wiki/File:Roe_deer_(Capreolus_capreolus)_female_Cumnor.jpg) | Charles J. Sharp | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) |
| Rådyrbukk | [Capreolus capreolus Wien Zentralfriedhof 20221021 06.jpg](https://commons.wikimedia.org/wiki/File:Capreolus_capreolus_Wien_Zentralfriedhof_20221021_06.jpg) | Uoaei1 | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) |
| Villsvin | [Wild boar (Sus scrofa vittatus) juvenile.jpg](https://commons.wikimedia.org/wiki/File:Wild_boar_(Sus_scrofa_vittatus)_juvenile.jpg) | Charles J. Sharp | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) |
| Villrein | [Rangifer tarandus fennicus 245142390.jpg](https://commons.wikimedia.org/wiki/File:Rangifer_tarandus_fennicus_245142390.jpg) | Pentti Impiö | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0) |
| Rype | [Rock ptarmigan (Lagopus muta islandorum) female breeding Botnsvatn.jpg](https://commons.wikimedia.org/wiki/File:Rock_ptarmigan_(Lagopus_muta_islandorum)_female_breeding_Botnsvatn.jpg) | Charles J. Sharp | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) |
| Hare | [Mountain hare (Lepus timidus) Oppdal.jpg](https://commons.wikimedia.org/wiki/File:Mountain_hare_(Lepus_timidus)_Oppdal.jpg) | Charles J. Sharp | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) |
| Storfugl | [Tetrao urogallus Richard Bartz.jpg](https://commons.wikimedia.org/wiki/File:Tetrao_urogallus_Richard_Bartz.jpg) | Richard Bartz, Munich aka Makro Freak | [CC BY-SA 2.5](https://creativecommons.org/licenses/by-sa/2.5) |
| Orrfugl | [Orrtuppen.jpg](https://commons.wikimedia.org/wiki/File:Orrtuppen.jpg) | Spjutkastare | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) |
| Jerpe | [Hazel Grouse.jpg](https://commons.wikimedia.org/wiki/File:Hazel_Grouse.jpg) | Chinmay Rahane | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) |
| Rev | [Vulpes vulpes Mallnitz 01.jpg](https://commons.wikimedia.org/wiki/File:Vulpes_vulpes_Mallnitz_01.jpg) | Uoaei1 | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) |
| Grevling | [European badger (Meles meles taxus) Drenthe 2.jpg](https://commons.wikimedia.org/wiki/File:European_badger_(Meles_meles_taxus)_Drenthe_2.jpg) | Charles J. Sharp | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) |
| Mår | [European pine marten (Martes martes) Drenthe 2.jpg](https://commons.wikimedia.org/wiki/File:European_pine_marten_(Martes_martes)_Drenthe_2.jpg) | Charles J. Sharp | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) |
| Mink | [Mink (Neovison vison).jpg](https://commons.wikimedia.org/wiki/File:Mink_(Neovison_vison).jpg) | Marton Berntsen | [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0) |
| Røyskatt | [035 Stoat in winter coat in Parc naturel régional Jura vaudois Photo by Giles Laurent.jpg](https://commons.wikimedia.org/wiki/File:035_Stoat_in_winter_coat_in_Parc_naturel_r%C3%A9gional_Jura_vaudois_Photo_by_Giles_Laurent.jpg) | Giles Laurent | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) |
| Bever | [Річковий бобер (Castor fiber).jpg](https://commons.wikimedia.org/wiki/File:%D0%A0%D1%96%D1%87%D0%BA%D0%BE%D0%B2%D0%B8%D0%B9_%D0%B1%D0%BE%D0%B1%D0%B5%D1%80_(Castor_fiber).jpg) | Ryzhkov Sergey | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) |
| Ekorn | [Red squirrel (21808).jpg](https://commons.wikimedia.org/wiki/File:Red_squirrel_(21808).jpg) | Rhododendrites | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) |
| Ender | [Anas platyrhynchos male female.jpg](https://commons.wikimedia.org/wiki/File:Anas_platyrhynchos_male_female.jpg) | This picture was realized by Richard Bartz by using a Canon EF 70-300mm f/4-5.6 IS USM Lens | [CC BY-SA 2.5](https://creativecommons.org/licenses/by-sa/2.5) |
| Gjess | [Graugans Anser Anser.jpg](https://commons.wikimedia.org/wiki/File:Graugans_Anser_Anser.jpg) | H005, denoised by Pro2 | [Public domain]() |
| Ærfugl | [Portrait einer männlichen Eiderente (Somateria mollissima) auf Norderney.jpg](https://commons.wikimedia.org/wiki/File:Portrait_einer_m%C3%A4nnlichen_Eiderente_(Somateria_mollissima)_auf_Norderney.jpg) | Stephan Sprinz | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0) |
| Skarv | [Phalacrocorax carbo, Hérault River cf01.jpg](https://commons.wikimedia.org/wiki/File:Phalacrocorax_carbo,_H%C3%A9rault_River_cf01.jpg) | Christian Ferrer | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) |
| Ringdue | [Common Wood Pigeon facing left.jpg](https://commons.wikimedia.org/wiki/File:Common_Wood_Pigeon_facing_left.jpg) | Alexis LOURS | [CC BY 2.0](https://creativecommons.org/licenses/by/2.0) |
| Rugde | [Waldschnepfe (scolopax rusticola) - Spiekeroog, Nationalpark Niedersächsisches Wattenmeer.jpg](https://commons.wikimedia.org/wiki/File:Waldschnepfe_(scolopax_rusticola)_-_Spiekeroog,_Nationalpark_Nieders%C3%A4chsisches_Wattenmeer.jpg) | Stephan Sprinz | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) |
| Enkeltbekkasin | [Common snipe (Gallinago gallinago faeroeensis) Botnsvatn.jpg](https://commons.wikimedia.org/wiki/File:Common_snipe_(Gallinago_gallinago_faeroeensis)_Botnsvatn.jpg) | Charles J. Sharp | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) |
| Kråkefugler | [Hooded crow (Corvus cornix) at Gulf of Trieste.jpg](https://commons.wikimedia.org/wiki/File:Hooded_crow_(Corvus_cornix)_at_Gulf_of_Trieste.jpg) | Petar Milošević | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) |
| Måker | [Head of European herring gull (Larus argentatus). Saint-Malo, France.jpg](https://commons.wikimedia.org/wiki/File:Head_of_European_herring_gull_(Larus_argentatus)._Saint-Malo,_France.jpg) | Ввласенко | [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0) |
| Gråtrost | [Turdus pilaris on Crataegus in winter.jpg](https://commons.wikimedia.org/wiki/File:Turdus_pilaris_on_Crataegus_in_winter.jpg) | Anaxibia (Andrey Polstianoi) | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) |
| Fasan | [Common pheasant (Phasianus colchicus) male 3.jpg](https://commons.wikimedia.org/wiki/File:Common_pheasant_(Phasianus_colchicus)_male_3.jpg) | Charles J. Sharp | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) |
| Bjørn / Björn | [Eurasian brown bear (Ursus arctos arctos) female 1.jpg](https://commons.wikimedia.org/wiki/File:Eurasian_brown_bear_(Ursus_arctos_arctos)_female_1.jpg) | Charles J. Sharp | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) |
| Ulv / Varg | [Loup gris (Canis lupus ).jpg](https://commons.wikimedia.org/wiki/File:Loup_gris_(Canis_lupus_).jpg) | Clément Bardot | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) |
| Gaupe / Lo | [Lynx lynx - 05.jpg](https://commons.wikimedia.org/wiki/File:Lynx_lynx_-_05.jpg) | Carlos Delgado | [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0) |
| Jerv / Järv | [Glouton DSCF6836.jpg](https://commons.wikimedia.org/wiki/File:Glouton_DSCF6836.jpg) | Musicaline | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) |
| Dåhjort / Dovhjort | [Fallow Deer Dama Dama in Richmond Park 2023 03.jpg](https://commons.wikimedia.org/wiki/File:Fallow_Deer_Dama_Dama_in_Richmond_Park_2023_03.jpg) | Julian Herzog (Website) | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0) |
| Muflon / Mufflonfår | [Mouflon Corse.jpg](https://commons.wikimedia.org/wiki/File:Mouflon_Corse.jpg) | Clément Bardot | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) |
| Mårhund / Mårdhund | [Єнотовидний собака (Nyctereutes procyonoides).jpg](https://commons.wikimedia.org/wiki/File:%D0%84%D0%BD%D0%BE%D1%82%D0%BE%D0%B2%D0%B8%D0%B4%D0%BD%D0%B8%D0%B9_%D1%81%D0%BE%D0%B1%D0%B0%D0%BA%D0%B0_(Nyctereutes_procyonoides).jpg) | Ryzhkov Sergey | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) |
| Vaskebjørn / Tvättbjörn | [Raccoon (Procyon lotor) 3.jpg](https://commons.wikimedia.org/wiki/File:Raccoon_(Procyon_lotor)_3.jpg) | Darkone | [CC BY-SA 2.5](https://creativecommons.org/licenses/by-sa/2.5) |
| Bisam | [Ondatra zibethicus CT.jpg](https://commons.wikimedia.org/wiki/File:Ondatra_zibethicus_CT.jpg) | Cephas | [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0) |
| Kanin / Vildkanin | [Oryctolagus cuniculus Rcdo.jpg](https://commons.wikimedia.org/wiki/File:Oryctolagus_cuniculus_Rcdo.jpg) | JM Ligero Loarte | [CC BY 3.0](https://creativecommons.org/licenses/by/3.0) |
| Sørhare / Fälthare | [European hare (Lepus europaeus) Marken 2.jpg](https://commons.wikimedia.org/wiki/File:European_hare_(Lepus_europaeus)_Marken_2.jpg) | Charles J. Sharp | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) |
| Iller | [Тхір лісовий.jpg](https://commons.wikimedia.org/wiki/File:%D0%A2%D1%85%D1%96%D1%80_%D0%BB%D1%96%D1%81%D0%BE%D0%B2%D0%B8%D0%B9.jpg) | Byrdyak | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) |
| Rapphöna (rapphøne) | [Perdix perdix hispaniensis MHNT PHAS 1996 18.jpg](https://commons.wikimedia.org/wiki/File:Perdix_perdix_hispaniensis_MHNT_PHAS_1996_18.jpg) | Roger Culos | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) |
| Säl (sel) | [Focas grises (Halichoerus grypus), playa de Horsey, Norfolk, Inglaterra, 2022-11-20, DD 11.jpg](https://commons.wikimedia.org/wiki/File:Focas_grises_(Halichoerus_grypus),_playa_de_Horsey,_Norfolk,_Inglaterra,_2022-11-20,_DD_11.jpg) | Diego Delso | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) |
| Nötskrika (nøtteskrike) | [Alakarga - Eurasian Jay - Garrulus glandarius 03.jpg](https://commons.wikimedia.org/wiki/File:Alakarga_-_Eurasian_Jay_-_Garrulus_glandarius_03.jpg) | Zeynel Cebeci | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) |