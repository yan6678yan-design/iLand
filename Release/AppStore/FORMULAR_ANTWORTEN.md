# Antworten für App Store Connect

Gültig für die vorbereitete Release-Version 1.0.0 mit Custom, Timer und Reise. Nach neuen SDKs, Serverfunktionen oder Kursdiensten neu prüfen. Die folgenden Angaben sind vorbereitet, nicht bereits in App Store Connect gespeichert.

## App-Datenschutz

**„Erhebst du oder erheben deine Drittanbieterpartner Daten aus dieser App?“ → Nein, wir erheben keine Daten aus dieser App.**

Designs, Bilder, Orte, Kalenderabfragen und Einstellungen werden lokal verarbeitet. Die Release-App enthält keine Analyse-, Werbe- oder Tracking-SDKs und keine Marktdatenabfragen. Rein lokale Verarbeitung zählt laut Apple nicht als Datenerhebung für dieses Formular. Keine Datenarten oder Trackingzwecke ergänzen, die die Release-App nicht tatsächlich überträgt.

Datenschutz-URL: https://iland-app.pages.dev/datenschutz/

Extern aufgerufene Websites, deren technische Hostingprotokolle und freiwillige Support-E-Mails werden in der Datenschutzerklärung separat erläutert. Die App selbst versendet keine Supportdiagnostik automatisch. Wenn künftig Daten aus der App an dich oder einen Dienst gehen, diese Antwort neu bewerten.

## Altersfreigabe

Die aktuelle App bietet lokale Gestaltung ohne öffentlichen Feed und öffnet Webseiten außerhalb der App. Für den derzeitigen Funktionsumfang:

| Gruppe / Frage | Antwort |
|---|---|
| Kindersicherung / Parental controls | Nein |
| Altersprüfung / Age assurance | Nein |
| Unbeschränkter Webzugriff innerhalb der App | Nein – kein integrierter Browser |
| Breit verteilte nutzergenerierte Inhalte | Nein – private lokale Designs, kein öffentlicher Austausch |
| Soziale Medien | Nein |
| Nachrichten / Chat | Nein |
| Werbung | Nein |
| Anstößige Sprache, grober Humor, Horror, Alkohol/Tabak/Drogen | Keine |
| Medizinische Informationen, Gesundheits-/Wellness-Empfehlungen | Keine – Fokus-Timer ohne Gesundheitsberatung |
| Sexuelle/erwachsene Themen, Nacktheit | Keine |
| Gewalt, Waffen | Keine |
| Glücksspiel, simuliertes Glücksspiel, Wettbewerbe, Lootboxen | Keine |
| Kids-Kategorie / speziell für Kinder | Nicht auswählen |
| Abweichende höhere Mindestalter-Vorgabe | Keine eigene Vorgabe vorgesehen |

Apple berechnet die Altersfreigabe aus dem aktuellen Fragebogen und regionalen Regeln. Eine erwartete niedrige Einstufung ist keine manuell festzulegende Garantie. Zusätzliche neue Fragen nach dem tatsächlichen Verhalten beantworten. Der Begriff „User-Generated Content“ bezeichnet in Apples Definition die breite Verbreitung, nicht das private Gestalten eines lokalen Bildes.

## Verschlüsselung / Export

`ITSAppUsesNonExemptEncryption = NO` ist bereits in der App gesetzt. Die Release-App implementiert keine eigene Verschlüsselung; sie verwendet nur Betriebssystemfunktionen. Falls Apple nach nicht ausgenommener Verschlüsselung fragt: **Nein**. Falls nach der Art gefragt wird: ausschließlich von Apples Betriebssystem bereitgestellte Verschlüsselung. Nicht „keine Kryptografie überhaupt“ behaupten. Zusätzliche Exportdokumentation nur ausfüllen, falls Apple sie nach diesen Angaben tatsächlich verlangt.

## Inhalt, Geschäftsmodell und Zugänglichkeit

- Keine Drittanbieter-Markenbibliothek oder Finanzdaten in diesem Build. Private Nutzerbilder werden vom Nutzer ausgewählt; keine externen Medienkataloge. Die App bietet keinen Zugriff auf lizenzpflichtige Drittanbieter-Medieninhalte. Die einschlägige Rechtefrage entsprechend mit „Nein“ beantworten, nicht pauschal Rechte an jedem möglichen Nutzerfoto behaupten.
- Kein Login, Konto, Abo, In-App-Kauf oder Werbung. Kein Account-Löschformular erforderlich, weil kein Konto erstellt wird. Lokale Daten können in den Einstellungen gelöscht werden.
- Kein medizinisches Gerät, kein Glücksspiel, keine Krypto-Handelsplattform.
- Barrierefreiheitsangaben: Keine ungeprüften Unterstützungsmerkmale ankreuzen. Die Existenz von SwiftUI-Labels oder Dark Mode allein belegt nicht Apples vollständige Kriterien für VoiceOver, größere Schrift oder Kontrast. Ohne vollständigen Kriterien-Test zunächst keine entsprechenden Zusagen veröffentlichen.
- Händlerstatus, Adresse, Telefonnummer, Verträge und Steuerdaten sind persönliche Kontoangaben und bleiben von dir auszufüllen.

## Quellen

- [Apples Definition von Datenerhebung und Ausnahmen](https://developer.apple.com/app-store/app-privacy-details/)
- [Altersfreigaben und Begriffsdefinitionen](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/)
- [Exportverschlüsselung](https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
