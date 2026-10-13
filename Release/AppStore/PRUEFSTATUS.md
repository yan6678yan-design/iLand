# Technischer Stand des Einreichungspakets

Geprüft am 5. Oktober 2026.

## Erledigt

- Sieben echte Release-Screenshots, Deutsch, iPhone 16 Pro Max / iOS 18.6, 1320 × 2868, RGB-PNG ohne Alphakanal. Alle Ansichten visuell kontrolliert. Capture auf einem eigens angelegten Simulator, ohne persönliche Nutzerdaten.
- Name, Untertitel, Werbetext, Beschreibung und Suchbegriffe auf Apples Feldgrenzen geprüft. Suchbegriffe: 90 UTF-8-Bytes; Untertitel: 26 Zeichen; Werbetext: 161 Zeichen.
- 26 Release-Unit-Tests erfolgreich. Der zusätzliche Release-UI-Test für den kompletten Screenshot-Ablauf ebenfalls erfolgreich.
- Aktuelles Release-Archiv erfolgreich mit Apple-Development-Zertifikat und Team 7NAS48FD56 signiert. App und Widget mit `codesign --verify --strict` geprüft, Version 1.0.0 / Build 1, iPhone-only, iOS 17 minimum.
- Sprachmetadaten von App, Widget und Projekt auf Deutsch korrigiert. Keine Änderungen am App-Layout oder an den Funktionen.
- Finale archivierte Info.plists enthalten CFBundleDevelopmentRegion = de und CFBundleLocalizations = [de].
- Release enthält keine gebündelten Brand-Dateien. Schutz gegen Marktanfragen und Brand-Ressourcen durch den vorhandenen Distribution-Unit-Test geprüft.
- Support- und Datenschutzseiten erneut mit HTTP 200 erreichbar.

## Nachweise im lokalen Projekt

- Screenshot- und Unit-Test: `build/appstore-capture-final.log`
- XCTest-Ergebnis: `/tmp/iLand-AppStore-Capture/Logs/Test/Test-ILand-2026.10.05_23-25-33-+0200.xcresult`
- Finales Archiv-Log: `build/appstore-signed-archive-final.log`
- Lokales, entwicklersigniertes Beta-Archiv: `build/iLand-Development-Beta.xcarchive`
- Aufnahme-Test im Repository: `UITests/ILandUITests.swift`, `testAppStoreScreenshots`
- Paket-Prüfsummen: `SHA256SUMS.txt`

Die Erstellung erfolgte aus einer frischen privaten Repository-Kopie von 8d871b0 plus dem neuen Aufnahme-Test und der Sprachmetadatenkorrektur. Grund: NSFileCoordinator blockierte zeitweise das Öffnen des Projekts im Dokumente-Ordner. Es wurde keine ältere App-Version für die Bilder verwendet.

## Noch nicht erledigt / nicht als bestanden ausgeben

- Das Archiv verwendet Xcode 27.2 Beta (27B5028f) und eine Entwicklungssignatur. Es ist **kein fertig exportiertes App-Store-Distributionspaket**. Mit zulässigem Xcode neu archivieren und über Organizer für App Store Connect signieren/validieren/hochladen.
- Kein tatsächlicher Upload zu App Store Connect und keine Apple-Prüfung erfolgt.
- Kein TestFlight-/Geräteabnahmetest dieses Release-Builds auf einem physischen iPhone erfolgt. Ein angeschlossenes privates Gerät wurde nicht mit einer anderen App-Fassung überschrieben.
- Apple-Konto, aktive Mitgliedschaft, Verträge, verfügbarer App-Name, Review-Telefonnummer, Händlerstatus, Preis und Länder sind nicht serverseitig bestätigt.
- Keine pauschale Apple-Freigabe oder Rechtegarantie für beliebige vom Nutzer importierte Bilder.

Die konkreten Schritte für diese Punkte stehen in START_HIER.md. Das Einreichungsmaterial ist vorbereitet; die tatsächliche Einreichung erfolgt erst nach diesen Konto-, Geräte- und Upload-Schritten.

## Ergänzung vom 6. Oktober 2026

Zusätzlicher vollständiger Bildsatz mit 1206 × 2622 Pixeln für das mittlere Dynamic-Island-Display aufgenommen. Sieben echte Release-Aufnahmen visuell geprüft; PNG-Dimensionen und RGB ohne Alphakanal geprüft. Capture-UI-Test erfolgreich (`build/appstore-medium.log`). Keine Änderungen am App-Code. Anleitung auf die aktuellen Gerätekategorien korrigiert. Ein erfolgreicher Upload in das Konto des Nutzers ist noch nicht bestätigt.
