# iLand im App Store einreichen

Stand: 5. Oktober 2026 · Version 1.0.0 · Build 1 · Sprache Deutsch

Dieses Paket enthält die Texte und Screenshots für die erste Einreichung. Es ist keine bereits erfolgte Veröffentlichung. Das App-Layout und der Release-Funktionsumfang bleiben unverändert.

## 1. Vor dem Upload: dein Apple-Konto

Öffne [App Store Connect](https://appstoreconnect.apple.com/). Du brauchst eine aktive Apple-Developer-Program-Mitgliedschaft und Zugriff auf das Team **7NAS48FD56**. Offene Vereinbarungen muss der Account Holder selbst lesen und annehmen.

Die folgenden persönlichen Angaben kann ich nicht wahrheitsgemäß für dich erfinden:

- App-Review-Kontakt: Yannis Ress Lasser, eine erreichbare Telefonnummer mit Landesvorwahl und deine Kontakt-E-Mail. Als vorhandenes Supportpostfach wird **yannis.66678@gmail.com** verwendet.
- Bei EU-Vertrieb: deinen tatsächlichen Händlerstatus angeben. Als Händler verlangt Apple eine verifizierbare Anschrift, Telefonnummer und E-Mail. Nicht allein wegen einer kostenlosen App „Nicht-Händler“ auswählen. Die Einstufung hängt von deiner tatsächlichen Tätigkeit ab.
- Preis und Länder auswählen. Diese Anleitung verwendet als Vorschlag **kostenlos, ohne In-App-Käufe**, zunächst die gewünschten deutschsprachigen Länder. Es wurden keine Preis- oder Vertriebsänderungen in deinem Apple-Konto vorgenommen.

## 2. App in App Store Connect anlegen

Unter **Meine Apps → + → Neue App**:

| Feld | Wert |
|---|---|
| Plattform | iOS |
| Name | iLand |
| Primäre Sprache | Deutsch |
| Bundle-ID | ch.yannis.ILand |
| SKU | iland-ios-001 (interne Kennung, falls noch frei) |
| Benutzerzugriff | Nach deinem Bedarf |

Falls die Bundle-ID fehlt: im richtigen Team unter Certificates, Identifiers & Profiles prüfen. Nicht eine zweite zufällige Bundle-ID verwenden. App und Widget benötigen dieselbe App Group **group.ch.yannis.ILand**. Die Widget-ID ist **ch.yannis.ILand.widgets**.

Falls der Name bereits belegt ist, verlangt Apple einen verfügbaren Namen; der reservierte Status ist hier nicht geprüft. Die sichtbare App bleibt im Projekt iLand.

## 3. Produktseite ausfüllen

Im Ordner **Texte/de-DE** ist jedes Kopierfeld eine eigene UTF-8-Datei:

| App-Store-Feld | Datei / Wert |
|---|---|
| Name | name.txt |
| Untertitel | subtitle.txt |
| Werbetext | promotional_text.txt |
| Beschreibung | description.txt |
| Schlüsselwörter | keywords.txt |
| Primäre Kategorie | Dienstprogramme / Utilities |
| Sekundäre Kategorie | Optional leer lassen |
| Support-URL | https://iland-app.pages.dev/support/ |
| Marketing-URL | https://iland-app.pages.dev/ |
| Datenschutz-URL | https://iland-app.pages.dev/datenschutz/ |
| Copyright | 2026 Yannis Ress Lasser |
| Version | 1.0.0 |
| Lizenzvereinbarung | Apples Standard-EULA, sofern du keine eigene benötigst |
| Versionsfreigabe | Diese Version manuell veröffentlichen |

Für die erste Version ist kein „Was ist neu“-Text nötig. Es gibt keine In-App-Käufe, Abonnements oder Game-Center-Konfiguration.

### Screenshots hochladen

Die PNG-Dateien liegen in zwei getrennten Ordnern:

- **Screenshots/de-DE/dynamic-island-medium-1206x2622**: für „iPhone mit Dynamic Island – mittleres Display“ (iPhone 16 Pro, 1206 × 2622 Pixel). Diesen Satz für das entsprechende Pflichtfeld verwenden.
- **Screenshots/de-DE/6.9-inch**: für „iPhone mit Dynamic Island – großes Display“ (iPhone 16 Pro Max, 1320 × 2868 Pixel).

Unter „Alle Größen im Medienmanager anzeigen“ das passende Gerät auswählen. Nur die sieben nummerierten PNG-Dateien des jeweiligen Ordners hineinziehen; nicht die ZIP-Datei oder README/Manifest. Bei „Dateiabmessungen sind ungültig“ zuerst die unter dem Upload-Feld angegebenen Pixelmaße mit dem gewählten Satz vergleichen. Die Originaldateien über GitHub „Download raw file“ oder durch Entpacken des Pakets herunterladen; keine Browser-Vorschaubilder speichern.

Apples am 6. Oktober 2026 geprüfte Übersicht nennt mindestens einen Screenshot für das mittlere Dynamic-Island-Display als iPhone-Anforderung. Die bisherige Anleitung nur mit dem großen 6,9-Zoll-Satz ist damit korrigiert. Beide Sätze sind echte Release-Aufnahmen ohne nachträgliche Skalierung. Die App ist iPhone-only; keine iPad-Bilder erforderlich. Ein Vorschauvideo ist optional. Das App-Symbol kommt aus dem hochgeladenen Build.

## 4. Datenschutz, Alter und Review

Übertrage die Angaben aus **FORMULAR_ANTWORTEN.md**. Unter „App Review“:

- Anmeldung erforderlich: **Nein**; keine Demo-Zugangsdaten eintragen.
- Kontakt: deine echten, erreichbaren Kontaktdaten eintragen.
- Hinweise: **Texte/de-DE/review_notes_en.txt** vollständig kopieren.
- Anhang: nicht erforderlich, da die Funktionen ohne Konto testbar sind.

Unter „Preise und Verfügbarkeit“ den gewünschten Preis und die gewünschten Länder setzen. Die automatische Verfügbarkeit als iPhone-App auf Mac und Apple Vision Pro für diese auf iPhone getestete Erstversion deaktivieren, solange diese Plattformen nicht gesondert geprüft wurden.

## 5. App mit zulässigem Xcode archivieren

Auf diesem Mac liegt Xcode **27.2 Beta, Build 27B5028f**. Eine Beta ist kein nachgewiesen zulässiges Werkzeug für die App-Store-Freigabe. Installiere eine von Apple aktuell für Einreichungen akzeptierte stabile Xcode-Version oder ausdrücklich freigegebene RC. Ein erfolgreiches lokales Archiv allein bestätigt die Upload-Zulassung nicht.

1. `ILand.xcodeproj` mit diesem Xcode öffnen.
2. In **Xcode → Settings → Accounts** mit deinem Apple-Developer-Konto anmelden.
3. Bei **ILand** und **ILandWidgets → Signing & Capabilities** das Team **7NAS48FD56** wählen und **Automatically manage signing** aktiv lassen. Beide Targets müssen dieselbe App Group verwenden.
4. Scheme **ILand**, Ziel **Any iOS Device (arm64)** bzw. ein echtes iPhone wählen, keinen Simulator.
5. Version **1.0.0**, Build **1** prüfen. Falls Build 1 bereits hochgeladen wurde, die Buildnummer in App UND Widget gemeinsam erhöhen, z. B. auf 2.
6. **Product → Archive**. Die Archive-Aktion des Schemes verwendet Release; deshalb sind Entwicklungslogos und Kursintegrationen ausgeschlossen.
7. Im **Organizer → Archives** das gerade erstellte Archiv auswählen. **Validate App** ausführen, falls angeboten. Danach **Distribute App → App Store Connect → Upload**. Automatische Signierung wählen. Xcode kann mit den nötigen Kontorechten die Distributionssignierung verwalten.
8. Bei Zertifikats-, Profil- oder Vertragsfehlern die konkrete Xcode-Meldung im angegebenen Team beheben. Keine fremden Team-IDs einsetzen, keine privaten Schlüssel ins Repository kopieren und keine SDK-Versionsangaben manipulieren.
9. Nach erfolgreichem Upload die Verarbeitung in App Store Connect abwarten. Den verarbeiteten Build bei Version 1.0.0 auswählen. Erst der akzeptierte Upload bestätigt die serverseitige Prüfung des Werkzeugs und der Signierung.

## 6. Kurzer Test mit dem hochgeladenen Build

Nutze den Build zuerst intern in TestFlight auf einem echten iPhone mit Dynamic Island:

- Frisch starten, Vorlage auswählen, bearbeiten, speichern und App neu öffnen: Änderungen bleiben erhalten.
- Eigene Live Activity starten, kompakte/erweiterte Darstellung und Sperrbildschirm vergleichen. Eigenes Foto muss auch außerhalb der App erscheinen.
- Timer pausieren/fortsetzen/zurücksetzen; App schließen und Intents erneut prüfen.
- Webseite hinterlegen und prüfen, dass das konfigurierte Ziel im Standardbrowser geöffnet wird.
- Standort/Kalender erst ablehnen, dann optional zulassen und widerrufen: Designer und Timer funktionieren weiterhin, passende Regelhinweise bleiben verständlich.
- Live Activity beenden und lokale Daten löschen: kein Absturz; keine alte Aktivität bleibt versehentlich aktiv.

Diese Geräteprüfung ist nicht durch Simulator-Screenshots ersetzt. Verwende zum Datenlöschen Testdaten, nicht deine persönlichen Designs.

## 7. An Apple schicken

1. In App Store Connect: Version 1.0.0 öffnen und den hochgeladenen, verarbeiteten Build auswählen.
2. Prüfen: Screenshots, Texte, Support, Datenschutz, Altersfreigabe, Verschlüsselungsantworten, Preis/Länder und Review-Kontakt vollständig.
3. **Zur Prüfung hinzufügen / Add for Review**.
4. Auf der Einreichungsseite **An App Review senden / Submit to App Review** bestätigen. Erst dieser Schritt schickt die Version wirklich an Apple.
5. Rückfragen erscheinen in App Store Connect. Nach Freigabe bei manueller Veröffentlichung **Diese Version veröffentlichen** wählen.

Apple entscheidet über die Zulassung; dieses Paket enthält keine Freigabezusage. Es wurde in dieser Vorbereitung kein Build an Apple geschickt und kein Vertrag für dich angenommen.

## Quellen

- [Screenshots: Größen und Anforderungen](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
- [Metadaten und Feldgrenzen](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)
- [Builds hochladen](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds)
- [Xcode-Distribution](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases)
- [Beta-Software und Einreichung](https://developer.apple.com/support/install-beta/)
- [EU-Händlerangaben](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/)
