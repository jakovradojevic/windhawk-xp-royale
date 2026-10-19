# XP Royale za Windhawk

- `taskbar-royale.json`: podešavanja za **Windows 11 Taskbar Styler** (Royale plava traka, zeleno Start dugme, svetloplavi tray)
- `startmenu-royale.json`: podešavanja za **Windows 11 Start Menu Styler** (XP raspored sa dve kolone: plavi header/footer sa narandžastim linijama, bela kolona Pinned/Recommended, svetloplava kolona All Programs, XP plavi hover)
- `apply-theme.ps1`: upisuje JSON u Windhawk registry i reload-uje mod (pokrenuti kao admin)
- `backup\*.reg`: originalna podešavanja pre izmena

## Primena (PowerShell kao administrator)

```powershell
.\apply-theme.ps1 -Mod windows-11-taskbar-styler    -Json .\taskbar-royale.json
.\apply-theme.ps1 -Mod windows-11-start-menu-styler -Json .\startmenu-royale.json
.\apply-theme.ps1 -Watch     # primenjuje automatski svaki put kad se JSON promeni
```

Skript ne restartuje procese sam od sebe.

**Važno za pretragu:** svaka uživo primena `startmenu-royale.json` ostavi pretragu u Startu praznu
(bez rezultata) dok se Windows Search i SearchHost ne resetuju. Posle izmene napravi prazan fajl
`reset-search.flag` pored skripte. Watcher (radi kao admin) ga vidi i pokreće `reset-search.ps1`,
pa UAC prompt nije potreban. Posle restarta računara ovo nije potrebno.
Posle promene **layouta** (`disableNewStartMenuLayout`) Start ume da ostane prazan do sledećeg logovanja.

Narandžaste linije u Startu su poravnate sa desnom kolonom na ekranu visine 1080 px
(meni visok 866 px). Na drugoj rezoluciji podesi offsete u `MenuBrush`.

## Vraćanje na staro

Dupli klik na `backup\taskbar-styler-backup.reg` i `backup\start-menu-styler-backup.reg`,
pa u Windhawk-u disable/enable oba moda (ili restart explorer-a).

## Napomene

- Desna kolona izgleda kao XP "All Programs" kad je u Start meniju izabrano **View: List**.
- Taskbar ne učitava lokalne slike, samo URL-ove. Zato Start dugme ima XP zastavicu
  bez natpisa "start". Slika sa natpisom je u `%LOCALAPPDATA%\XPRoyale\start-button.png`;
  ako se postavi na neki javni URL, dovoljno je zameniti `ImageSource` u `taskbar-royale.json`.
- `xamlDiagnosticsHandling` je podešen na `block`, pa se više ne pojavljuje dijalog
  "module is trying to use XAML diagnostics" koji je blokirao taskbar.
- Iz Start Menu Stylera je uklonjen ručno dodati `explorer.exe` (Custom process inclusion),
  jer mod nije namenjen explorer-u i pravio je konflikt sa Taskbar Stylerom.
- **Open-Shell** je preuzimao Start dugme. Uklonjen mu je autostart (bekap: `backup\hklm-run-backup.reg`),
  `AutoStart=0` u njegovim podešavanjima, a zatim je deinstaliran.
- Polje "Run..." je identično na Startu i na rezultatima: zaobljeno, belo, XP ivica `#7F9DB9`, ista pozicija.
- Pretraga ima isti okvir kao Start (plavi header i footer, narandžaste linije). Footer na rezultatima
  je nacrtan unutar web stranice (`body::after`), a lista ima razmak na dnu. Okvir WebView-a se
  ne sme menjati (`Grid#WebViewGrid` margin, `height` na `html/body`), jer to kvari pretragu do reseta.
- Korisnik i power dugme ne mogu da budu na ekranu rezultata: oni su deo Start prozora, koji
  Windows sakriva dok je pretraga aktivna. Footer je zato samo vizuelno isti.
- Pretraga ima samo dva stanja, Start i rezultati (`webContentCustomJs`):
  - klik na "Run..." ne otvara prazan ekran; pretraga kreće kucanjem na Startu;
  - zeleno "Back" ili brisanje upita zatvaraju pretragu (`dismissApp`), a sledeće otvaranje Starta
    je uvek početna strana. Windows nema poziv koji vraća direktno na početnu stranu bez zatvaranja.
- Rezultati: Tahoma, tamnoplavi bold naslovi grupa, XP toolbar filteri, XP plava selekcija sa belim tekstom,
  svetloplavi preview kao kolona All Programs; icon fontovi su izuzeti.
- Power meni, meni korisnika i tooltipovi su u XP stilu (bela pozadina, tamnoplava ivica, XP plava selekcija,
  svetložuti tooltip).
- `restart-watcher.ps1` (kao admin) gasi stari watcher i pokreće novi, minimizovan,
  da ne krade fokus.
