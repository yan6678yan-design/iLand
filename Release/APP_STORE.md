# iLand – App-Store-Vorbereitung

Stand: 5. Oktober 2026. Technische Vorbereitung, keine Freigabe durch Apple.

Das vollständige Einreichungspaket mit Screenshots, Kopiertexten und Upload-Anleitung steht in [AppStore/START_HIER.md](AppStore/START_HIER.md). Die folgenden Prüfergebnisse dokumentieren den ursprünglichen Audit; aktuelle Nachweise stehen im Einreichungspaket.

## Minimale Korrekturen

- UserDefaults-Zugriff für die zuletzt gespeicherten Farben im Privacy Manifest deklariert (CA92.1).
- Öffentliche Datenschutz- und Supportlinks in den Einstellungen ergänzt.
- Nur Systemverschlüsselung: ITSAppUsesNonExemptEncryption = NO.
- Versionsnummern von App und Erweiterung werden aus denselben Build-Einstellungen übernommen.
- Tatsächliche Target-Einstellungen auf iPhone korrigiert; zuvor überschrieben sie die iPhone-Vorgabe mit iPad-Unterstützung.
- Fehler beim Löschen importierter Bilder oder eines lokalen API-Schlüssels werden nicht mehr verschwiegen.
- Kein Umbau der freigegebenen Dynamic-Island-Geometrie oder der Design-Oberfläche.

## Rechte und Release-Umfang

Die erste Release-Fassung bietet Custom, Timer und Reise, SF Symbols, System-Emoji und eigene Bilder. Die 100 gebündelten Firmenlogos und die bisherigen Kursintegrationen bleiben ausschließlich im privaten Entwicklungsprojekt (Debug). Release schließt den Logo-Assetkatalog und dessen Metadaten aus, bietet keine Logo-/Kursauswahl und blockiert Kursabfragen auch für alte Entwicklungsdaten. Keine Fernsteuerung, kein Review-Erkennungsmechanismus.

Grund: Simple Icons weist selbst darauf hin, dass die Bibliothekslizenz keine pauschale Freigabe der jeweiligen Markenrechte darstellt. Zusätzliche Nachweise liegen im Projekt nicht vor. Coinbase untersagt ohne Zusatzvereinbarung die Nutzung seiner Marktdaten in Anwendungen für andere Endnutzer. Finnhub beschränkt persönliche Pläne und Weiterverteilung ebenfalls. Ein persönlicher API-Schlüssel allein belegt keine Vertriebserlaubnis für die App.

Eine spätere Aktivierung erfordert dokumentierte passende Rechte, erneute Überprüfung der Datenschutzangaben und einen neuen App-Release. Die Quellen und bisherigen Implementierungen bleiben zur Weiterarbeit erhalten.

## Angaben für App Store Connect

- Name: iLand
- Untertitel: Deine Island. Dein Design.
- Kategorie: Dienstprogramme
- Datenschutz-URL: https://iland-app.pages.dev/datenschutz/
- Support-URL: https://iland-app.pages.dev/support/
- Kein Login, keine Käufe, keine Abos, keine Werbung, keine Handelsfunktion.
- App-Datenschutz für die beschriebene Release-Fassung: keine vom Entwickler oder eingebundenen SDKs erhobenen App-Daten. Designs, Fotos, Standort und Kalender werden nur lokal verarbeitet. Von Nutzern extern geöffnete Websites und freiwillige Support-E-Mails sind in der Datenschutzerklärung separat erläutert.
- Altersfreigabe anhand des aktuellen Fragebogens in App Store Connect beantworten; keine automatische Einstufung behaupten.

## Review-Hinweise (Englisch)

No account or sign-in is required. Open Designs, select Deep Focus, and start the Live Activity. A long press on Dynamic Island expands it on supported iPhones; other supported iPhones display Live Activities on the Lock Screen. Timer controls use ActivityKit and App Intents. Custom designs offer local text, symbol and photo customization. Imported photos are selected through Apple's system photo picker.

Location and calendar permissions are optional and only used to evaluate user-created rules while the app is open. There is no continuous background location monitoring, advertising, analytics or tracking. The app does not replace or override system Dynamic Island content. iOS controls Live Activity visibility and duration. Data can be removed under Settings → Datenschutz & Daten → Alle lokalen Daten löschen.

## Noch außerhalb des Codes erforderlich

1. Auf einem echten iPhone prüfen: App-Group-Bilder, langes Drücken, Timer-Intents nach Prozessende, Standort-/Kalenderfreigaben und Berechtigungswiderruf.
2. Signiertes Distribution-Archiv mit dem eigenen Apple-Developer-Team erstellen und in Organizer validieren. Ein unsignierter Geräte-Build ersetzt diese Prüfung nicht.
3. Für den Upload eine von Apple für App-Store-Veröffentlichungen zugelassene Xcode-Version verwenden. Lokal installiert: Xcode 27.2, Build 27B5028f, unter Xcode-beta.app. Die Upload-Zulassung dieser Beta ist nicht nachgewiesen. Apples Mindestanforderung seit 28. April 2026 ist Xcode/iOS SDK 26 oder neuer.
4. App Store Connect: Screenshots der tatsächlichen Release-Fassung (ohne Debug-Logos/Kurse), Datenschutzantworten, Altersfreigabe, Kontakt und gegebenenfalls Händlerangaben vervollständigen.
5. App Review entscheidet über Eignung und Mindestfunktionalität. Ein lokaler Audit garantiert keine Zulassung.

## Quellen

- [Apple App Review Guidelines, insbesondere 2.1, 4.2, 5.1.1 und 5.2](https://developer.apple.com/app-store/review/guidelines/)
- [Apple – App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)
- [Apple – Required Reason APIs](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype)
- [Apple – Exportverschlüsselung](https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations)
- [Simple Icons Disclaimer](https://github.com/simple-icons/simple-icons/blob/develop/DISCLAIMER.md)
- [Coinbase Market Data Terms](https://www.coinbase.com/legal/market_data)
- [Finnhub Terms](https://finnhub.io/terms-of-service)

## Veröffentlichung und technische Nachweise

- Privates Repository: https://github.com/TheSocialNetwork35/iLand
- Website: https://iland-app.pages.dev (Cloudflare Pages, GitHub-Integration, nur Website/public öffentlich).
- Öffentlicher Kontakt: yannis.66678@gmail.com, übernommen aus dem öffentlichen GitHub-Profil. Bei einem anderen gewünschten Supportpostfach beide Website-Seiten ändern.
- Geräte-Release-Archiv ohne Signierung erfolgreich: `/tmp/iLand-AppStore-Verified.xcarchive`; Log `build/appstore-verified-archive.log`. App und Widget enthalten keine Brand-Dateien oder Brand-Asset-Renditions; beide UIDeviceFamily = [1], Version 1.0.0/1.
- Debug: 24 bestehende Unit-Tests und 3 UI-Abläufe erfolgreich (`build/appstore-tests.log`, `build/appstore-ui-tests.log`).
- Release: alle 25 Unit-Tests bestanden (`build/appstore-release-unit-tests.log`), einschließlich Schutz gegen Kursabfragen/Brand-Ressourcen; zusätzlich zwei UI-Abläufe bestanden (`build/appstore-release-tests.log`). Geprüft: tatsächlich verfügbare Designarten, Datenschutz-/Supportlinks, Design speichern, Activity starten/beenden, Regel speichern und Persistenz.
- Website im Browser auf Desktop/Dark Mode und 390px/Light Mode geprüft; keine horizontale Überbreite. Support und Datenschutz antworten mit HTTP 200. Eine probeweise abgefragte Swift-Quelldatei antwortet mit HTTP 404.

Die Archive sind bewusst nicht im Git-Repository. Sie sind nicht signiert und wurden nicht in App Store Connect hochgeladen. Die Geräteprüfung und formale Einreichung bleiben erforderlich.
