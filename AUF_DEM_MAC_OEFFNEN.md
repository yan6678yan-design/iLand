# iLand auf einem anderen Mac öffnen und einreichen

Das private Repository enthält den vollständigen App-Code, die Widget-Erweiterung, Tests, die Website und alle vorbereiteten App-Store-Materialien. Ein Beta-Xcode ist zum Öffnen des Projekts nicht vorgeschrieben. Verwende auf dem anderen Mac eine aktuell von Apple für App-Store-Einreichungen zugelassene stabile Xcode-Version.

## Projekt herunterladen

1. Auf dem anderen Mac bei GitHub mit **TheSocialNetwork35** oder einem berechtigten Konto anmelden.
2. [Das private Repository öffnen](https://github.com/TheSocialNetwork35/iLand).
3. **Code → Download ZIP** wählen und die ZIP-Datei entpacken. Alternativ das Repository mit GitHub Desktop klonen.
4. Im entpackten Ordner **ILand.xcodeproj** doppelklicken. Den gesamten Projektordner zusammenlassen; App und Widget verwenden gemeinsam den Ordner Shared.
5. Das fertige Xcode-Projekt verwenden. XcodeGen, zusätzliche Pakete oder das erneute Erzeugen des Projekts sind nicht nötig.

## In Xcode vorbereiten

1. Unter **Xcode → Settings → Accounts** mit deinem Apple-Developer-Konto anmelden.
2. Bei den Targets **ILand** und **ILandWidgets** unter **Signing & Capabilities** dein Team **7NAS48FD56** wählen und automatische Signierung verwenden.
3. Die bestehenden Kennungen beibehalten: App **ch.yannis.ILand**, Widget **ch.yannis.ILand.widgets**, App Group **group.ch.yannis.ILand**.
4. Scheme **ILand** wählen. Erst auf deinem iPhone testen. Zum Archivieren als Ziel **Any iOS Device (arm64)** oder ein echtes iPhone verwenden, keinen Simulator.
5. **Product → Archive**, danach im Organizer **Distribute App → App Store Connect → Upload**. Die Archive-Aktion verwendet Release.
6. Version ist **1.0.0**, Build **1**. Wenn dieser Build bereits bei Apple hochgeladen wurde, die Buildnummer für App und Widget gemeinsam erhöhen.

Zertifikate und private Schlüssel gehören nicht ins Repository. Xcode richtet die Signierung auf dem anderen Mac über dein Apple-Konto und dessen Rechte ein. Ein auf dem bisherigen Mac erzeugtes Beta-Archiv wird nicht benötigt: Auf dem anderen Mac neu archivieren.

## Hier liegen die Materialien

| Inhalt | Pfad |
|---|---|
| Xcode-Projekt | [ILand.xcodeproj](ILand.xcodeproj) |
| App-Code | [ILand](ILand) |
| Gemeinsame Modelle und Live-Activity-Ansichten | [Shared](Shared) |
| Widget-Erweiterung | [ILandWidgets](ILandWidgets) |
| Vollständige Einreichungsanleitung | [Release/AppStore/START_HIER.md](Release/AppStore/START_HIER.md) |
| Beschreibung, Untertitel, Suchbegriffe und Review-Text | [Release/AppStore/Texte/de-DE](Release/AppStore/Texte/de-DE) |
| App-Store-Screenshots, mittleres und großes Display | [Release/AppStore/Screenshots/de-DE](Release/AppStore/Screenshots/de-DE) |
| Datenschutz- und Altersfreigabe-Antworten | [Release/AppStore/FORMULAR_ANTWORTEN.md](Release/AppStore/FORMULAR_ANTWORTEN.md) |
| Alle Einreichungsmaterialien zusätzlich als ZIP | [Release/iLand-AppStore-Paket.zip](Release/iLand-AppStore-Paket.zip) |
| Website-Code | [Website/public](Website/public) |

Beim Öffnen einer einzelnen PNG- oder ZIP-Datei auf GitHub lässt sie sich über **Download raw file** herunterladen. Zum Übertragen des gesamten Projekts ist **Code → Download ZIP** am einfachsten.

Die Release-Version enthält Custom, Timer und Reise. Markenlogos und Kursintegrationen bleiben im privaten Debug-Entwicklungsstand. Ein normaler Debug-Start in Xcode zeigt deshalb mehr Funktionen als das Release-Archiv; die Screenshots im AppStore-Ordner zeigen die tatsächlich vorbereitete Release-Version.

Die Einreichung selbst ist noch nicht erfolgt. Persönliche Apple-Kontoangaben, Geräteprüfung und der tatsächliche Upload bleiben erforderlich. Die genaue Reihenfolge steht in START_HIER.md.
