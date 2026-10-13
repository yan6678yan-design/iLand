# iLand

**Release-Vorbereitung:** [Audit und Einreichungshinweise](Release/APP_STORE.md). Release bietet Custom, Timer und Reise. Markenlogos und Kursintegrationen bleiben bis zur Klärung der Nutzungsrechte nur in Debug verfügbar; die späteren Abschnitte dokumentieren auch diese Entwicklungsfunktionen. Die Supportwebsite liegt unter `Website/public`.

Native iPhone-App für persönliche, zeitlich begrenzte Live Activities. SwiftUI, ActivityKit, WidgetKit, App Intents, Core Location, EventKit. Mindestversion: iOS 17.

## Starten

1. `ILand.xcodeproj` in Xcode öffnen und das Scheme **ILand** auswählen.
2. Einen iPhone-Simulator auswählen und mit ⌘R starten. Die App funktioniert auch ohne Dynamic Island; Live Activities erscheinen dann auf dem Sperrbildschirm.
3. Für ein echtes iPhone unter **Signing & Capabilities** in beiden Targets dasselbe eigene Development Team auswählen. Die Bundle IDs und die App Group `group.ch.yannis.ILand` müssen im gewählten Team verfügbar sein. Bei einer Änderung der Gruppe auch `SharedAssets.directory` und die Entitlements aktualisieren.

Das Projekt ist vollständig eingecheckbar und benötigt keine externen Swift-Pakete. `project.yml` dient als reproduzierbare XcodeGen-Quelle; das erzeugte Xcode-Projekt liegt bereits bei.

Die vorgefundene lokale `DEVELOPER_DIR`-Einstellung zeigt auf einen nicht vorhandenen Download-Pfad. Auf diesem Mac liegt Xcode unter `/Users/Yannis/Xcode-beta.app`. Build-Befehle können diesen Pfad pro Aufruf verwenden, ohne die globale Einstellung zu verändern:

```sh
DEVELOPER_DIR=/Users/Yannis/Xcode-beta.app/Contents/Developer xcodebuild \
  -project ILand.xcodeproj -scheme ILand \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO test
```

## Bedienung

- **Home:** aktive Aktivität, sieben Beispiel-Designs, zuletzt verwendete Designs und Favoriten.
- **Designs:** Suche, Favoritenfilter, neue Designs. Aktive Designs stehen zuerst und sind grün mit „Läuft gerade“ markiert. Über den großen Bearbeiten-Button bearbeiten/umbenennen, duplizieren und nach Bestätigung löschen.
- **Design-Studio:** System-Icons in sechs Kategorien, System-Emoji, eigenes Bild oder eines von 100 Markenlogos, Farben, Texte, Timer, Reisedaten, Vorschauanimationen und verknüpfte Aktionen. Erfolgreiches Speichern wird durch einen animierten Haken und haptisches Feedback bestätigt.
- **Regeln:** UND/ODER, Orte, Zeitfenster, gerade laufende Kalenderereignisse. Beispielregeln sind zunächst deaktiviert. Bedingungen lassen sich durch Wischen löschen.
- **Einstellungen:** System/Hell/Dunkel, optionale Berechtigungen, lokale Orte und vollständiges Zurücksetzen.
- **Timer:** echte System-Countdown-Darstellung, Pause/Fortsetzen/Reset über LiveActivityIntent, auch auf dem Sperrbildschirm.

## Architektur

- `ILand/Views`: UI, Design-Editor, Vorschau, Regel-Builder, Einstellungen.
- `ILand/Services/IslandStore.swift`: lokale atomare JSON-Speicherung, Designverwaltung und ActivityKit-Lifecycle.
- `ILand/RuleModels.swift`: reine Regelauswertung einschließlich Mitternachtsfenstern, Standortqualität und fehlenden Berechtigungen.
- `ILand/Services/Permissions.swift`: zustimmungsbasierter Standort-/Kalenderzugriff.
- `Shared`: gemeinsame Activity-Attribute, Icons, Bildspeicherung in der App Group und interaktive Intents.
- `ILandWidgets`: kompakte, minimale, erweiterte und Sperrbildschirm-Darstellung.
- `Tests`, `UITests`: Logik-, Persistenz- und End-to-End-Tests mit Screenshot-Anhängen.

Die lokale Datendatei liegt im App-Container unter `Application Support/ILand/state.json`. Unlesbare Daten werden nicht automatisch überschrieben. Verkleinerte Benutzerbilder liegen in der App Group. Es gibt keinen Server, keine Analyse-SDKs und kein Konto.

## Bewusste Plattformgrenzen

- iLand verwendet ausschließlich öffentliche APIs und ersetzt keine systemweite Dynamic Island. Das System entscheidet über Sichtbarkeit, Priorität und Darstellung; Live Activities enden spätestens nach acht Stunden.
- Regeln werden im Vordergrund beim Öffnen, bei Standortänderungen und ungefähr alle 30 Sekunden ausgewertet. Ortsermittlung wird gedrosselt und nur bei Freigabe angefragt. Es gibt kein permanentes Hintergrund-Geofencing, kein Push-Backend und keine Zusage einer exakten zeitgesteuerten Hintergrundausführung.
- Die erste passende Regel gewinnt. Eine Regel startet nur beim Wechsel in einen Treffer neu; manuelles Beenden führt nicht sofort zum Neustart durch dieselbe Bedingung. Ein manuell gewähltes Design kann beim Eintritt in eine neue passende Regel ersetzt werden.
- Kalenderereignisse werden nur gelesen und lokal ausgewertet. Reise-/Flugdaten werden manuell gepflegt. Es gibt keine Airline-API und keine Musikabfrage fremder Apps.
- Live-Activity-Taps öffnen über `iland://design/<UUID>` das Design in iLand. Nach langem Drücken erscheint bei Designs mit Webseiten-Aktion der Button **Webseite**. Er öffnet über `iland://website/<UUID>` die gespeicherte Adresse im Standardbrowser, ohne zusätzlichen Bestätigungsschritt in iLand. Domains wie `example.org` erhalten automatisch HTTPS. iOS kann für verknüpfte Universal Links die zugehörige App bevorzugen. App-Deep-Links werden weiterhin aus der Detailansicht geöffnet.
- Vorschauanimationen zeigen Stilideen. Widgets unterstützen keine frei laufenden Daueranimationen. Echte Timer/Fortschrittsanzeigen nutzen Systemansichten. „Bewegung reduzieren“ wird in der Vorschau respektiert.
- Standortfreigabe ist „Bei Verwendung“, nicht „Immer“. Ein Standort älter als fünf Minuten oder ungenauer als der gewählte Radius zählt nicht als Treffer. Keine Positionsverläufe.
- Zurücksetzen löscht App-Daten, widerruft jedoch keine iOS-Berechtigungen. Diese lassen sich über den Einstellungslink ändern.

## Noch auf einem echten Gerät zu prüfen

Provisionierung der App Group, Bilddarstellung in der Live Activity, Dynamic-Island-Langdruck, Widget-Intents nach Prozessbeendigung, reale Standort-/Kalenderfreigaben, Verhalten bei der systemseitigen Beendigung von Live Activities. Ein erfolgreicher Simulator-Test ersetzt diese Geräteprüfung nicht.

Apple-Dokumentation: [ActivityKit](https://developer.apple.com/documentation/activitykit), [Live Activities](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities).

## Verifiziert am 4. Oktober 2026

Build von App und Widget erfolgreich mit Xcode 27.2. Auf dem iPhone-16-Pro-Simulator mit iOS 18.6 sind **15 Unit-Tests und 5 UI-Tests bestanden** (einschließlich gezielter Wiederholung der angepassten UI-Abläufe). Geprüft: Persistenz/defekte Datendateien, Regelverknüpfung und Mitternachtsfenster, Standortqualität, Linkvalidierung, Activity-Payload-Größe, Design-/Regelerstellung mit Neustart, Fehlermeldungen ohne Verlust des Editors, Dark Mode sowie Start, Pause, Reset und Ende von Live Activities einschließlich Rückkehr aus dem Hintergrund. Zusätzlich geprüft: alle 100 gebündelten Logos, bisher gespeicherte Designs, Domain-Normalisierung, sichere interne Webseiten-Routen, Logoauswahl, Speicherbestätigung und Öffnen des Browsers über den Webseiten-Button der echten erweiterten Dynamic Island.

Screenshots liegen unter `Screenshots/`. Die aktuellen Testprotokolle liegen unter `build/personalization-tests.log` und `build/personalization-recheck.log` (einschließlich Pfaden zu den xcresult-Berichten). Zwei UI-Testabläufe wurden nach Korrektur ihrer Warte- bzw. Tap-Schritte erfolgreich wiederholt. UI-Tests verwenden einen getrennten Datenspeicher. Geräteberechtigungen, importierte Medien und App-Group-Bilder sind weiterhin auf einem echten Gerät zu prüfen.

## Logo-Sammlung und Webseiten

Die 100 lokal gebündelten Logos umfassen 40 Automarken, 19 Mode-/Sportmarken, 8 Uhrenmarken, 20 Techmarken und 13 Lifestylemarken. Im Editor **Logos → Logo auswählen** öffnen; die Galerie ist durchsuchbar und nach Kategorien filterbar. Die Auswahl funktioniert ohne Netzwerk und ohne In-App-Kauf.

Quellen: Simple Icons **16.34.0** und als „Public domain“ gekennzeichnete SVG-Dateien von Wikimedia Commons. Originalgeometrie und Farben bleiben erhalten. Einige Marken werden als Wortmarke dargestellt, etwa Rolex. Bibliothekslizenz, Disclaimer, einzelne Quellen, Metadaten und SHA-256-Prüfsummen liegen unter `Shared/BrandLicenses/`. Eine kostenlose Grafikdatei gewährt nicht automatisch Markenrechte; die Marken gehören ihren jeweiligen Inhabern. In der Galerie sind die Quellen ebenfalls zugänglich.

`Scripts/import_brand_assets.py` baut den Katalog aus den festgelegten Quellen nach. Es verwendet lokale Download-Caches und respektiert HTTP-429-Retry-After-Antworten. Zur Laufzeit lädt iLand keine Logos aus dem Internet nach.

Die Webseiten-Adresse bleibt im lokalen Design-Datensatz und wird nicht in den beschränkten ActivityKit-Payload kopiert. Die Live Activity enthält nur einen internen Link zur Design-ID. Die App akzeptiert auf diesem Pfad nur die gespeicherte HTTP(S)-Adresse; aus einem aufrufenden Link können keine fremden Zieladressen eingeschleust werden. Fehlt ein Design oder wurde die Verknüpfung entfernt, erscheint eine verständliche Meldung.

Die untere Zeile der erweiterten Island hat zusätzliche seitliche und untere Abstände für die gerundeten Ecken. Längere Statusmeldungen können zweizeilig erscheinen, Aktionen haben eine eigene abgesetzte Fläche.

## Individuelle Elemente

Im Design-Studio öffnet **Details personalisieren** eine eigene, übersichtliche Seite mit Vorschau. Sie zeigt nur die Elemente, die zur gewählten Aktivität passen: rechtes Kopfsymbol, kompakte Darstellung, Statussymbol, Link-Symbol sowie gegebenenfalls Pause/Fortsetzen und Timer-Reset. Jedes Element lässt sich einzeln als System-Icon, Emoji, Logo oder eigenes Bild gestalten. Dekorative Elemente können ausgeblendet werden; Bedientasten behalten ihre Funktion und zugängliche Funktionsbezeichnung. Die Symbolauswahl unterstützt zusätzlich manuell eingegebene, auf dem Gerät verfügbare SF-Symbol-Namen.

Titel, Untertitel und Status dürfen leer sein. Eigener Kompakttext (12 Zeichen), Link-Beschriftung und Gate-Beschriftung (je 20 Zeichen) können auch Emojis enthalten. Zeichenzähler zeigen die Grenzen vor dem Speichern. Bei Timern ersetzt ein eigener Kompakttext ausschließlich die kleine Anzeige; der erweiterte Countdown bleibt funktional.

Einzelne Symbole lassen sich über „Standard“ zurücksetzen, zusätzliche Details gesammelt über einen bestätigten Reset. Die Haupttexte und das Hauptsymbol bleiben beim Details-Reset erhalten. Änderungen werden erst mit „Sichern“ im Haupteditor gespeichert. Die Darstellung wird gemeinsam von Vorschau und Widget genutzt; bestehende Designs ohne neue Felder behalten ihre Standardwerte. Vor dem Start wird die Gesamtgröße des ActivityKit-Payloads geprüft, damit zu große Inhalte bestehende Aktivitäten nicht ersetzen.

Zusätzlich verifiziert: optionale Personalisierungsfelder in alten Designs, Rücksetzen auf Standard, gültige/ungültige Symbole, ausgeblendete Dekoration, Payload mit individuellen Elementen sowie Emoji und Kompakttext nach Speichern und App-Neustart. Screenshots `13-Personalisierte-Kompaktansicht.png` und `14-Personalisierte-Details.png` zeigen das gespeicherte Ergebnis.


## Freies Custom-Layout und Projektzuordnung

**Custom → Erweitert → Layout direkt bearbeiten** öffnet den visuellen Editor. Elemente antippen und ziehen; Größe und Winkel im Inspector einstellen. Texte doppelt antippen, um sie direkt auf der Fläche zu ändern. Neue Texte und Emoji/Icon-Elemente können hinzugefügt, verschoben, gedreht, ausgeblendet oder entfernt werden. Die Ebenenreihenfolge ist unter „Position & Reihenfolge“ einstellbar. Rückgängig/Wiederholen und ein bestätigtes Zurücksetzen sind vorhanden. „Übernehmen“ kehrt zum Entwurf zurück; erst „Sichern“ speichert das Design. Der freie Modus gilt nur für die erweiterte Custom-Island und deren Sperrbildschirmdarstellung. Kompaktanzeige, Timer und Reise behalten ihre eigenen Ansichten.

Die logische Zeichenfläche beträgt 320 × 124 Punkte. Rotierte Begrenzungen werden in den sicheren Innenbereich geklemmt. Bis zu 12 Elemente sind möglich; die vollständige ActivityKit-Nachricht bleibt zusätzlich durch die bestehende Payload-Prüfung geschützt. Die gleiche Zeichenfläche rendert im Editor, in der Vorschau und im Widget. Ein freies Layout enthält keine frei ausführbaren Aktionen: Die Link-Schaltfläche verwendet weiterhin die konfigurierten internen/Website-Routen.

„Symbolhintergrund“ schaltet den Hintergrund des Hauptsymbols ein und aus, auch im Standardlayout und der Kompaktansicht. Bei Logos ohne Hintergrund wird eine getönte, transparente Silhouette verwendet, damit schwarze Markenformen auf der schwarzen Island erkennbar bleiben. Der Katalog wird mit Porsche und Rolex an erster Stelle angezeigt und enthält weiterhin 100 lokale Firmenlogos; Wortmarken sind als solche enthalten. Artwork-Quellen und Markenhinweise bleiben im Katalog verlinkt.

Die gemeldeten Scope-Fehler und die leere Logo-Galerie hatten dieselbe Ursache: fehlende Source-/Resource-Mitgliedschaften in der zuletzt gespeicherten Projektdatei. App, Widget, Shared und Tests verwenden jetzt **PBXFileSystemSynchronizedRootGroup** (Xcode 16+), sodass neue Swift-Dateien und der JSON-Katalog automatisch dazugehören. Signing-Einstellungen wurden erhalten. Nach einer absichtlichen Neugenerierung durch XcodeGen erneut `python3 Scripts/repair_project_membership.py` ausführen. Das Prüfprotokoll muss einen Build des tatsächlichen `ILand.xcodeproj` enthalten, nicht einer temporären Projektkopie.

Bei Gucci wurden redundante rechteckige SVG-Maskierungen entfernt, die Xcode als leeren Inhalt renderte. Originalpfade, Transformationen und Farben sind unverändert. Quell- und generierter Asset-Hash sind getrennt dokumentiert. Der Asset-Test rendert jedes der 100 Logos und prüft auf sichtbaren Pixelinhalt, statt nur die Existenz eines UIImage-Objekts zu prüfen.


Abschlussprüfung des tatsächlichen Projekts: App und Widget bauen erfolgreich. 15 Logiktests und fünf UI-Abläufe sind bestanden, mit gezielten Wiederholungen nach Korrektur der UI-Testabfragen. Die neue Canvas-Prüfung umfasst Doppeltipp-Texteingabe, Verschieben, Skalierung, Drehung, Hintergrundschalter, zusätzlichen Text, Persistenz nach Neustart und dessen Darstellung in der echten erweiterten Live Activity auf iPhone 16 Pro / iOS 18.6. Protokolle: `build/layout-tests.log`, `build/logo-render-tests.log`, `build/logo-ui-tests.log`, `build/layout-ui-tests.log`. Bilder: `Screenshots/09-Logoauswahl.png`, `Screenshots/15-Visueller-Editor.png`, `Screenshots/16-Freies-Layout-Live-Activity.png`. Die lokale Xcode-Umgebung kann nach Testabschluss einen Fehler beim Sammeln zusätzlicher simctl-Diagnosen melden; die im Bericht bestätigten Testergebnisse bleiben davon getrennt.


## Aktuelle Anpassungen

Der angezeigte App-Name lautet überall **iLand**. Technische Bundle-IDs, App Group und Speicherpfade bleiben für bestehende Installationen stabil. Musik ist entfernt; gespeicherte Musik-Designs werden als Custom geladen, Musik-Regeln deaktiviert. Unter „Symbol & Farbe“ öffnen „Symbol links“ und „Symbol rechts“ die jeweilige Bearbeitung. Die Link-Schaltfläche bleibt unter „Details personalisieren“ erreichbar. Die Auswahl eines kompakten Symbols ersetzt einen zuvor eingestellten Kompakttext.


Erweiterte Vorlage und freies Layout verwenden in Vorschau und Widget dieselbe `ExpandedIslandContent`-Komponente. Normale Vorlagen nutzen wieder Symbole oben an den Seiten, mittige Titel und eine untere Statuszeile. Die gemeinsame Zeichenfläche wird proportional skaliert und für WidgetKit in kamera-sichere Bereiche aufgeteilt. Der Direkteditor übernimmt exakt die Vorlagenkoordinaten; bestehende freie Layouts ohne `cameraLayout` behalten ihre bisherigen Koordinaten unterhalb der Kamera. Schrift und Symbole werden nicht mehr durch eine separate Höhenkompression verkleinert. Die Farbauswahl zeigt bis zu drei zuletzt gespeicherte Farben und direkt daneben den Farbkreis für die native iOS-Palette, ohne zusätzliche Überschriften. Beliebige RGB-Farben werden als kompakte Hex-Werte gespeichert; ältere benannte Farben bleiben lesbar.


## Aktien & Krypto

Designart **Aktien** bietet Krypto (Coinbase Exchange, öffentliche USD-Handelspaare) und Aktien (Finnhub, persönlicher API-Schlüssel unter Einstellungen → Kursdaten). Bitcoin ist ohne Schlüssel nutzbar; Unternehmensaktien benötigen einen gültigen Finnhub-Datenzugang. Eigene Symbole können eingegeben werden. Netzwerkfehler oder nicht unterstützte Symbole werden angezeigt, niemals durch erfundene Kurse ersetzt.

Bei aktiver App wird die laufende Kurs-Island alle 30 Sekunden aktualisiert. Die Taste ↻ ruft über einen LiveActivityIntent auch aus der erweiterten Island neue Daten ab. Ohne APNs-Backend gibt es keine dauernde automatische Hintergrundaktualisierung. Der letzte Handel wird mit Quellenname und Zeitstempel angezeigt; ein fehlgeschlagener Abruf lässt den letzten Kurs stehen und kennzeichnet den Fehler. Aktien zeigen, falls verfügbar, die Veränderung zum vorherigen Schlusskurs. Es gibt keine Handelsfunktion.

Der Finnhub-Schlüssel liegt ausschließlich im lokalen Schlüsselbund (ThisDeviceOnly), nicht in Designs, Live-Activity-Payloads oder Logs. An Kursanbieter gehen Symbol, IP-Adresse und gegebenenfalls der Finnhub-Schlüssel. Die Auswahl sendet keine Standort- oder Kalenderdaten. HTTP-Status, Preise und Zeitstempel werden geprüft; Wiederholungen werden kurz zwischengespeichert.

Quellen: [Coinbase Ticker](https://docs.cdp.coinbase.com/api-reference/exchange-api/rest-api/products/get-product-ticker), [Finnhub Quote](https://finnhub.io/docs/api/quote), [ActivityKit](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities).

Die Symbolauswahl für links und rechts verwendet jetzt dieselbe Inline-Auswahl. Im Direkteditor entfernt „Löschen“ das gewählte Element; Rückgängig stellt es wieder her. Horizontale und vertikale Positionsregler rasten innerhalb von vier logischen Punkten an der tatsächlichen Mitte ein. Bei älteren Layouts wird der Kamerabereich in die Berechnung der vertikalen Mitte einbezogen.

## Einheitliche Zentrierung

Horizontal, Vertikal und Drehung besitzen eine mittlere Einrastmarkierung; die Drehung rastet bei 0° ein. Die zusätzlichen „Zur Mitte“-Buttons entfallen. Die mittlere WidgetKit-Region richtet ihren Ausschnitt an der tatsächlich verfügbaren Höhe unter der Kamera aus, statt einen festen Kameraabstand anzunehmen. Sperrbildschirm und Vorschau verwenden dieselbe `ExpandedIslandContent`-Zeichenfläche und dasselbe Seitenverhältnis, ohne separate Canvas-Paddings. Die äußere Systemform und die erste iOS-Freigabeaufforderung bleiben von iOS vorgegeben.

Verifiziert am 5. Oktober 2026 mit dem tatsächlichen Xcode-Projekt: 26 Unit-Tests bestanden; Zentrierung/0°/Löschen/Rückgängig/Speichern und echte Simulator-Island sowie Timer-Pause/Reset/Ende als UI-Abläufe geprüft. Beim ersten Timer-Durchlauf zeigte sich eine veraltete Statusanzeige; nach Auswahl der tatsächlich aktiven Timer-Activity und Beobachtung ihrer Inhaltsupdates besteht der wiederholte Ablauf. Screenshots 30–32 zeigen Vorschau, Dynamic Island und Sperrbildschirm (iPhone 16 Pro, iOS 18.6). Logs: `build/centering-final.log`, `build/centering-recheck.log`, `build/centering-release.log`. Ein Vergleich auf einem physischen iPhone ist hier nicht erfolgt.
