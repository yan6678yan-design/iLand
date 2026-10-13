import XCTest

final class ILandUITests: XCTestCase {
    /// Run only on a fresh, dedicated simulator with the Release configuration.
    @MainActor func testAppStoreScreenshots() throws {
        #if DEBUG
        throw XCTSkip("App Store screenshots require Release")
        #else
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(de)", "-AppleLocale", "de_CH"]
        app.launch()
        XCTAssertTrue(app.buttons["createDesign"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Einstellungen"].tap()
        app.buttons["appearance-Hell"].tap()
        app.tabBars.buttons["Home"].tap()
        capture("Store-01-Home")
        app.tabBars.buttons["Designs"].tap()
        XCTAssertTrue(app.navigationBars["Meine Designs"].waitForExistence(timeout: 5))
        capture("Store-02-Designs")
        app.staticTexts["Zuhause"].firstMatch.tap()
        app.segmentedControls.buttons["Erweitert"].tap()
        capture("Store-03-Deine-Island")
        app.buttons["Bearbeiten"].tap()
        XCTAssertTrue(app.navigationBars["Design-Studio"].waitForExistence(timeout: 5))
        capture("Store-04-Design-Studio")
        app.buttons["Abbrechen"].tap()
        app.buttons["Fertig"].tap()
        app.staticTexts["Deep Focus"].firstMatch.tap()
        app.segmentedControls.buttons["Erweitert"].tap()
        app.buttons["Als Live Activity aktivieren"].tap()
        XCTAssertTrue(app.buttons["Live Activity beenden"].waitForExistence(timeout: 10))
        capture("Store-05-Fokus-Timer")
        app.buttons["Live Activity beenden"].tap()
        app.buttons["Fertig"].tap()
        app.tabBars.buttons["Regeln"].tap()
        capture("Store-06-Regeln")
        app.tabBars.buttons["Einstellungen"].tap()
        app.buttons["appearance-Dunkel"].tap()
        app.tabBars.buttons["Home"].tap()
        capture("Store-07-Dark-Mode")
        #endif
    }

    @MainActor func testReleasePrivacyAndAvailableDesigns() throws {
        #if DEBUG
        throw XCTSkip("Run this smoke test with the Release configuration")
        #else
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(de)", "-AppleLocale", "de_CH"]
        app.launch()
        app.buttons["createDesign"].tap()
        let activity = app.buttons["designKind"]
        for _ in 0..<4 { if activity.isHittable { break }; app.swipeUp() }
        activity.tap()
        XCTAssertTrue(app.buttons["Timer"].exists)
        XCTAssertTrue(app.buttons["Reise"].exists)
        XCTAssertFalse(app.buttons["Aktien"].exists)
        app.buttons["Custom"].tap()
        app.buttons["Abbrechen"].tap()
        app.tabBars.buttons["Einstellungen"].tap()
        app.swipeUp()
        XCTAssertFalse(app.staticTexts["Kursdaten"].exists)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Support & Kontakt")).firstMatch.exists)
        app.buttons["Datenschutz & Daten"].tap()
        XCTAssertTrue(app.buttons["Datenschutzerklärung"].waitForExistence(timeout: 5))
        capture("29-Release-Datenschutz")
        #endif
    }

    @MainActor func testDesignRuleAndLiveActivityWorkflow() throws {
        let app = XCUIApplication()
        app.launchEnvironment["ILAND_UI_TEST_STORE"] = UUID().uuidString
        app.launchArguments = ["-AppleLanguages", "(de)", "-AppleLocale", "de_CH"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Kleine Island.\nGroße Möglichkeiten."].waitForExistence(timeout: 10))
        capture("01-Home")
        app.buttons["createDesign"].tap()
        XCTAssertTrue(app.navigationBars["Design-Studio"].waitForExistence(timeout: 5))
        capture("02-Designer")
        let name = app.textFields["Name"]
        name.tap()
        name.press(forDuration: 1.1)
        if app.menuItems["Select All"].exists { app.menuItems["Select All"].tap() }
        // Clear predictably regardless of the simulator's keyboard locale.
        if let value = name.value as? String { name.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count)) }
        name.typeText("UI Test Island")
        app.buttons["Sichern"].tap()
        XCTAssertTrue(app.navigationBars["Design-Studio"].waitForNonExistence(timeout: 6))
        XCTAssertTrue(app.tabBars.buttons["Designs"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Designs"].tap()
        app.swipeUp()
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["UI Test Island"].waitForExistence(timeout: 5))
        app.staticTexts["UI Test Island"].tap()
        XCTAssertTrue(app.buttons["Als Live Activity aktivieren"].waitForExistence(timeout: 5))
        app.buttons["Als Live Activity aktivieren"].tap()
        XCTAssertTrue(app.buttons["Live Activity beenden"].waitForExistence(timeout: 10))
        capture("03-Aktive-Island")
        app.buttons["Live Activity beenden"].tap()
        XCTAssertTrue(app.buttons["Als Live Activity aktivieren"].waitForExistence(timeout: 5))
        app.buttons["Fertig"].tap()
        app.tabBars.buttons["Regeln"].tap()
        capture("04-Regeln")
        app.swipeUp()
        app.buttons["Neue Regel erstellen"].tap()
        XCTAssertTrue(app.navigationBars["Regel-Builder"].waitForExistence(timeout: 5))
        capture("05-Regel-Builder")
        app.buttons["Sichern"].tap()
        XCTAssertTrue(app.buttons["Meine Regel"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Einstellungen"].tap()
        capture("06-Einstellungen")
        app.terminate()
        app.launch()
        app.tabBars.buttons["Regeln"].tap()
        app.swipeUp()
        XCTAssertTrue(app.buttons["Meine Regel"].waitForExistence(timeout: 5))
    }
    @MainActor func testValidationDarkModeAndTimer() throws {
        let app = XCUIApplication()
        app.launchEnvironment["ILAND_UI_TEST_STORE"] = UUID().uuidString
        app.launchArguments = ["-AppleLanguages", "(de)", "-AppleLocale", "de_CH"]
        app.launch()
        app.buttons["createDesign"].tap()
        let name = app.textFields["Name"]
        name.tap()
        name.press(forDuration: 1.1)
        let selectAll = app.descendants(matching: .any).matching(NSPredicate(format: "label IN %@", ["Select All", "Alles auswählen", "Alles Auswählen"])).firstMatch
        if selectAll.waitForExistence(timeout: 2) { selectAll.tap() }
        name.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: (name.value as? String)?.count ?? 11))
        XCTAssertTrue((name.value as? String) == "" || (name.value as? String) == "Name")
        app.buttons["Sichern"].tap()
        XCTAssertTrue(app.alerts["iLand"].waitForExistence(timeout: 4))
        app.alerts.buttons["OK"].tap()
        app.buttons["Abbrechen"].tap()
        app.tabBars.buttons["Einstellungen"].tap()
        capture("17-Einstellungen-Hell")
        app.buttons["appearance-Dunkel"].tap()
        capture("18-Einstellungen-Dunkel")
        app.tabBars.buttons["Home"].tap()
        capture("07-Home-Dark")
        app.tabBars.buttons["Designs"].tap()
        app.staticTexts["Deep Focus"].tap()
        app.buttons["Als Live Activity aktivieren"].tap()
        XCTAssertTrue(app.buttons["Live Activity beenden"].waitForExistence(timeout: 5))
        app.buttons["Pause / Fortsetzen"].tap()
        XCTAssertTrue(app.staticTexts["Pausiert"].waitForExistence(timeout: 5))
        app.buttons["Zurücksetzen"].tap()
        XCTAssertTrue(app.staticTexts["Timer läuft"].waitForExistence(timeout: 5))
        XCUIDevice.shared.press(.home)
        XCTAssertTrue(app.wait(for: .runningBackground, timeout: 5))
        sleep(2) // Let SpringBoard's home transition finish before capturing the island.
        capture("08-Dynamic-Island")
        app.activate()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        sleep(1)
        app.buttons["Live Activity beenden"].tap()
        XCTAssertTrue(app.buttons["Als Live Activity aktivieren"].waitForExistence(timeout: 5))
    }
    @MainActor func testBrandWebsiteAndExpandedIsland() throws {
        let app = XCUIApplication()
        app.launchEnvironment["ILAND_UI_TEST_STORE"] = UUID().uuidString
        app.launchArguments = ["-AppleLanguages", "(de)", "-AppleLocale", "de_CH"]
        app.launch()
        app.tabBars.buttons["Designs"].tap()
        app.buttons["Neues Design"].tap()
        app.swipeUp()
        app.buttons["editLeftSymbol"].tap()
        app.segmentedControls.buttons["Logos"].tap()
        app.buttons["chooseBrand"].tap()
        XCTAssertTrue(app.navigationBars["Logos"].waitForExistence(timeout: 5))
        capture("09-Logoauswahl")
        app.searchFields.firstMatch.tap()
        app.searchFields.firstMatch.typeText("BMW")
        app.buttons["brand-bmw"].tap()
        let actionPicker = app.buttons["actionKind"]
        for _ in 0..<6 { if actionPicker.isHittable { break }; app.swipeUp() }
        actionPicker.tap()
        app.buttons["Webseite"].tap()
        let address = app.textFields["Domain oder Webseite"]
        address.tap(); address.typeText("example.org")
        app.buttons["Sichern"].tap()
        let confirmation = app.descendants(matching: .any)["saveConfirmation"].firstMatch
        XCTAssertTrue(confirmation.waitForExistence(timeout: 2))
        capture("10-Gespeichert")
        XCTAssertTrue(app.navigationBars["Design-Studio"].waitForNonExistence(timeout: 5))
        app.swipeUp(); app.swipeUp()
        app.staticTexts["Mein Design"].tap()
        app.buttons["Als Live Activity aktivieren"].tap()
        XCTAssertTrue(app.buttons["Live Activity beenden"].waitForExistence(timeout: 5))
        XCUIDevice.shared.press(.home)
        XCTAssertTrue(app.wait(for: .runningBackground, timeout: 5))
        sleep(2)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.035)).press(forDuration: 1.2)
        sleep(1)
        capture("11-Expanded-Webseite")
        XCTAssertTrue(springboard.staticTexts["Zeit für dich"].exists)
        let website = springboard.buttons["Webseite öffnen"]
        XCTAssertTrue(website.waitForExistence(timeout: 5))
        website.tap()
        let browser = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        XCTAssertTrue(browser.wait(for: .runningForeground, timeout: 10))
        sleep(2) // Allow the app-to-browser transition to finish before taking evidence.
        capture("12-Webseite-im-Browser")
        app.activate()
        sleep(1)
        app.buttons["Live Activity beenden"].tap()
    }
    @MainActor func testPersonalizedElementsAndCompactText() throws {
        let app = XCUIApplication()
        app.launchEnvironment["ILAND_UI_TEST_STORE"] = UUID().uuidString
        app.launchArguments = ["-AppleLanguages", "(de)", "-AppleLocale", "de_CH"]
        app.launch()
        app.buttons["createDesign"].tap()
        let details = app.buttons["personalizeDetails"]
        if !details.isHittable { app.swipeUp() }
        details.tap()
        let badge = app.buttons["element-badge"]
        for _ in 0..<5 { if badge.isHittable { break }; app.swipeUp() }
        badge.tap()
        app.buttons["elementAppearance"].tap()
        app.buttons["Emoji"].tap()
        let emoji = app.textFields["elementEmoji"]
        emoji.tap()
        emoji.typeText(XCUIKeyboardKey.delete.rawValue + "🌿")
        app.buttons["Übernehmen"].tap()
        let toggle = app.switches["customCompactText"]
        app.swipeUp()
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.88, dy: 0.5)).tap()
        let compact = app.textFields["Kompakttext"]
        XCTAssertTrue(compact.waitForExistence(timeout: 3))
        compact.tap()
        if let value = compact.value as? String { compact.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count)) }
        compact.typeText("MEINS")
        app.navigationBars.buttons["Design-Studio"].tap()
        app.buttons["Sichern"].tap()
        XCTAssertTrue(app.navigationBars["Design-Studio"].waitForNonExistence(timeout: 6))
        app.terminate(); app.launch()
        app.tabBars.buttons["Designs"].tap()
        app.swipeUp(); app.swipeUp()
        app.staticTexts["Mein Design"].tap()
        XCTAssertTrue(app.staticTexts["MEINS"].waitForExistence(timeout: 5))
        capture("13-Personalisierte-Kompaktansicht")
        app.segmentedControls.buttons["Erweitert"].tap()
        XCTAssertTrue(app.staticTexts["🌿"].waitForExistence(timeout: 3))
        capture("14-Personalisierte-Details")
    }
    @MainActor func testVisualLayoutAndLogoCatalog() throws {
        let app = XCUIApplication()
        app.launchEnvironment["ILAND_UI_TEST_STORE"] = UUID().uuidString
        app.launchArguments = ["-AppleLanguages", "(de)", "-AppleLocale", "de_CH"]
        app.launch()
        app.buttons["createDesign"].tap()
        app.buttons["editCanvas"].tap()
        XCTAssertTrue(app.navigationBars["Layout bearbeiten"].waitForExistence(timeout: 5))
        app.descendants(matching: .any)["canvas-title"].firstMatch.doubleTap()
        let title = app.descendants(matching: .any)["canvasInlineText"].firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 3))
        title.tap()
        title.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 11) + "Mein Layout")
        app.buttons["Fertig"].tap()
        let badge = app.descendants(matching: .any)["canvas-badge"].firstMatch
        badge.tap()
        badge.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 0.2, thenDragTo: badge.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).withOffset(CGVector(dx: -28, dy: 30)))
        app.sliders["layout-Größe"].adjust(toNormalizedSliderPosition: 0.5)
        app.sliders["layout-Drehung"].adjust(toNormalizedSliderPosition: 0.6)
        app.buttons["select-layout-mainIcon"].tap()
        let background = app.switches["layoutIconBackground"]
        for _ in 0..<3 { if background.isHittable { break }; app.swipeUp() }
        background.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        let add = app.buttons["addCanvasText"]
        for _ in 0..<4 { if add.isHittable { break }; app.swipeUp() }
        add.tap()
        let inline = app.descendants(matching: .any)["canvasInlineText"].firstMatch
        XCTAssertTrue(inline.waitForExistence(timeout: 3))
        inline.tap()
        inline.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 9) + "Mein Platz")
        app.buttons["Fertig"].tap()
        capture("15-Visueller-Editor")
        app.buttons["Übernehmen"].tap()
        app.buttons["Sichern"].tap()
        XCTAssertTrue(app.navigationBars["Design-Studio"].waitForNonExistence(timeout: 6))
        app.terminate(); app.launch()
        app.tabBars.buttons["Designs"].tap()
        app.swipeUp(); app.swipeUp()
        app.staticTexts["Mein Design"].tap()
        app.segmentedControls.buttons["Erweitert"].tap()
        XCTAssertTrue(app.staticTexts["Mein Platz"].waitForExistence(timeout: 5))
        capture("19-Erweiterte-Vorschau")
        app.buttons["Als Live Activity aktivieren"].tap()
        XCTAssertTrue(app.buttons["Live Activity beenden"].waitForExistence(timeout: 5))
        XCUIDevice.shared.press(.home)
        sleep(2)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.035)).press(forDuration: 1.2)
        sleep(1)
        XCTAssertTrue(springboard.staticTexts["Mein Platz"].waitForExistence(timeout: 5))
        capture("16-Freies-Layout-Live-Activity")
        app.activate(); sleep(1)
        app.buttons["Live Activity beenden"].tap()
    }
    @MainActor func testSettingsNavigationAndPersistence() throws {
        let app = XCUIApplication()
        app.launchEnvironment["ILAND_UI_TEST_STORE"] = UUID().uuidString
        app.launchArguments = ["-AppleLanguages", "(de)", "-AppleLocale", "de_CH"]
        app.launch()
        app.tabBars.buttons["Einstellungen"].tap()
        capture("17-Einstellungen-Hell")
        app.buttons["appearance-Dunkel"].tap()
        capture("18-Einstellungen-Dunkel")
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Meine Orte")).firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Meine Orte"].waitForExistence(timeout: 5))
        app.buttons["Ort hinzufügen"].tap()
        XCTAssertTrue(app.navigationBars["Ort hinzufügen"].waitForExistence(timeout: 5))
        app.buttons["Abbrechen"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Berechtigungen")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Standort"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Kalender"].exists)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.swipeUp()
        app.buttons["Datenschutz & Daten"].tap()
        app.buttons["Alle lokalen Daten löschen"].tap()
        XCTAssertTrue(app.buttons["Alles löschen"].waitForExistence(timeout: 5))
        app.buttons["Abbrechen"].tap()
        app.terminate(); app.launch()
        app.tabBars.buttons["Einstellungen"].tap()
        XCTAssertTrue(app.buttons["appearance-Dunkel"].isSelected)
        app.buttons["appearance-Hell"].tap()
        XCTAssertTrue(app.buttons["appearance-Hell"].isSelected)
    }
    @MainActor func testActiveDesignEditingAndRightSymbols() throws {
        let app = XCUIApplication()
        app.launchEnvironment["ILAND_UI_TEST_STORE"] = UUID().uuidString
        app.launchArguments = ["-AppleLanguages", "(de)", "-AppleLocale", "de_CH"]
        func tapVisible(_ identifier: String) throws {
            let ready = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                app.buttons.matching(identifier: identifier).allElementsBoundByIndex.contains { $0.isHittable }
            }, object: nil)
            XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 5), .completed)
            let buttons = app.buttons.matching(identifier: identifier).allElementsBoundByIndex
            try XCTUnwrap(buttons.first(where: { $0.isHittable }), "Visible button: \(identifier)").tap()
        }
        func reveal(_ identifier: String, down: Bool = false) {
            for _ in 0..<6 {
                if app.buttons.matching(identifier: identifier).allElementsBoundByIndex.contains(where: { $0.isHittable }) { return }
                if down { app.swipeDown() } else { app.swipeUp() }
            }
        }
        app.launch()
        XCTAssertTrue(app.staticTexts["iLand"].firstMatch.waitForExistence(timeout: 5))
        app.tabBars.buttons["Designs"].tap()
        XCTAssertFalse(app.staticTexts["On Repeat"].exists)
        app.staticTexts["Zuhause"].tap()
        try tapVisible("editDesign")
        XCTAssertTrue(app.navigationBars["Design-Studio"].waitForExistence(timeout: 5))
        reveal("editRightSymbol")
        try tapVisible("editRightSymbol")
        try tapVisible("Emoji")
        let emoji = app.textFields["Emoji"]
        emoji.tap(); emoji.typeText(XCUIKeyboardKey.delete.rawValue + "🌿" + "\n")
        reveal("Kompakt", down: true)
        try tapVisible("Kompakt")
        reveal("editRightSymbol")
        try tapVisible("editRightSymbol")
        reveal("Löschen")
        try tapVisible("Löschen")
        reveal("Erweitert", down: true)
        try tapVisible("Erweitert")
        reveal("personalizeDetails", down: true)
        try tapVisible("personalizeDetails")
        reveal("element-action")
        try tapVisible("element-action")
        try tapVisible("elementAppearance")
        try tapVisible("Ausblenden")
        try tapVisible("Übernehmen")
        app.navigationBars.buttons["Design-Studio"].tap()
        capture("20-Symbole-personalisieren")
        try tapVisible("Sichern")
        XCTAssertTrue(app.navigationBars["Design-Studio"].waitForNonExistence(timeout: 6))
        reveal("Erweitert", down: true)
        try tapVisible("Erweitert")
        XCTAssertTrue(app.staticTexts["🌿"].waitForExistence(timeout: 5))
        try tapVisible("Als Live Activity aktivieren")
        XCTAssertTrue(app.buttons["Live Activity beenden"].waitForExistence(timeout: 5))
        try tapVisible("Fertig")
        XCTAssertTrue(app.staticTexts["Läuft gerade"].waitForExistence(timeout: 5))
        XCTAssertLessThan(app.staticTexts["Zuhause"].frame.minX, app.staticTexts["Deep Focus"].frame.minX)
        capture("21-Aktives-Design")
        app.staticTexts["Zuhause"].tap()
        try tapVisible("Live Activity beenden")
        try tapVisible("Fertig")
        XCTAssertFalse(app.staticTexts["Läuft gerade"].exists)
    }
    @MainActor func testTemplateExpandedAndColorPalette() throws {
        let app = XCUIApplication()
        app.launchEnvironment["ILAND_UI_TEST_STORE"] = UUID().uuidString
        app.launchArguments = ["-AppleLanguages", "(de)", "-AppleLocale", "de_CH"]
        app.launch()
        app.tabBars.buttons["Designs"].tap()
        app.staticTexts["Zuhause"].tap()
        app.segmentedControls.buttons["Erweitert"].tap()
        capture("22-Vorlage-Vorschau")
        app.buttons["Als Live Activity aktivieren"].tap()
        XCTAssertTrue(app.buttons["Live Activity beenden"].waitForExistence(timeout: 5))
        XCUIDevice.shared.press(.home)
        sleep(2)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.035)).press(forDuration: 1.2)
        XCTAssertTrue(springboard.staticTexts["Endlich angekommen"].waitForExistence(timeout: 5))
        capture("23-Vorlage-Live")
        app.activate()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        sleep(1)
        app.buttons["Live Activity beenden"].tap()
        XCTAssertTrue(app.buttons["Als Live Activity aktivieren"].waitForExistence(timeout: 5))
        app.buttons["editDesign"].tap()
        XCTAssertTrue(app.navigationBars["Design-Studio"].waitForExistence(timeout: 5))
        let left = app.buttons["editLeftSymbol"]
        for _ in 0..<5 { if left.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(left.isHittable)
        XCTAssertTrue(app.buttons["editRightSymbol"].isHittable)
        capture("24-Symbole-und-Farben")
        let palette = app.descendants(matching: .any)["moreColors"].firstMatch
        if !palette.isHittable { app.swipeUp() }
        palette.tap()
        XCTAssertTrue(app.buttons["Spektrum"].waitForExistence(timeout: 5) || app.staticTexts["Spektrum"].exists)
        capture("25-Farbpalette")
    }
    @MainActor func testCanvasDeleteAndCenter() throws {
        let app = XCUIApplication()
        app.launchEnvironment["ILAND_UI_TEST_STORE"] = UUID().uuidString
        app.launchArguments = ["-AppleLanguages", "(de)", "-AppleLocale", "de_CH"]
        app.launch(); app.buttons["createDesign"].tap(); app.buttons["editCanvas"].tap()
        app.buttons["select-layout-mainIcon"].tap()
        app.buttons["Position & Reihenfolge"].tap()
        for identifier in ["layout-Horizontal", "layout-Vertikal", "layout-Drehung"] {
            let slider = app.sliders[identifier]
            for _ in 0..<4 { if slider.isHittable { break }; app.swipeUp() }
            slider.adjust(toNormalizedSliderPosition: 0.5)
        }
        XCTAssertTrue(app.staticTexts["0°"].exists)
        XCTAssertFalse(app.buttons["center-Horizontal"].exists)
        XCTAssertFalse(app.buttons["center-Vertikal"].exists)
        capture("28-Layout-Zentrieren")
        let delete = app.buttons["deleteCanvasElement"]
        for _ in 0..<4 { if delete.isHittable { break }; app.swipeUp() }
        delete.tap()
        XCTAssertFalse(app.buttons["select-layout-mainIcon"].exists)
        app.buttons["Rückgängig"].tap()
        XCTAssertTrue(app.buttons["select-layout-mainIcon"].exists)
        app.buttons["Übernehmen"].tap()
        app.buttons["Sichern"].tap()
        XCTAssertTrue(app.navigationBars["Design-Studio"].waitForNonExistence(timeout: 6))
        app.tabBars.buttons["Designs"].tap(); app.swipeUp(); app.swipeUp()
        app.staticTexts["Mein Design"].firstMatch.tap()
        app.segmentedControls.buttons["Erweitert"].tap()
        capture("30-Zentriert-Vorschau")
        app.buttons["Als Live Activity aktivieren"].tap()
        XCTAssertTrue(app.buttons["Live Activity beenden"].waitForExistence(timeout: 10))
        XCUIDevice.shared.press(.home); sleep(2)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.035)).press(forDuration: 1.2)
        sleep(1); capture("31-Zentriert-Island")
        XCUIDevice.shared.press(.home)
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.001))
            .press(forDuration: 0.1, thenDragTo: springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.9)))
        sleep(1)
        if springboard.buttons["Erlauben"].exists { springboard.buttons["Erlauben"].tap(); sleep(1) }
        capture("32-Zentriert-Sperrbildschirm")
        app.activate(); sleep(1)
        app.buttons["Live Activity beenden"].tap()
    }
    @MainActor func testBitcoinLiveQuote() throws {
        let app = XCUIApplication()
        app.launchEnvironment["ILAND_UI_TEST_STORE"] = UUID().uuidString
        app.launchArguments = ["-AppleLanguages", "(de)", "-AppleLocale", "de_CH"]
        app.launch(); app.buttons["createDesign"].tap()
        let activity = app.buttons["designKind"]
        for _ in 0..<4 { if activity.isHittable { break }; app.swipeUp() }
        activity.tap(); app.buttons["Aktien"].tap()
        let bitcoin = app.buttons["asset-BTC"]
        for _ in 0..<4 { if bitcoin.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(bitcoin.waitForExistence(timeout: 5))
        bitcoin.tap()
        app.buttons["Sichern"].tap()
        XCTAssertTrue(app.navigationBars["Design-Studio"].waitForNonExistence(timeout: 6))
        app.tabBars.buttons["Designs"].tap(); app.swipeUp(); app.swipeUp()
        app.staticTexts["Bitcoin"].firstMatch.tap()
        app.segmentedControls.buttons["Erweitert"].tap()
        app.buttons["Als Live Activity aktivieren"].tap()
        XCTAssertTrue(app.buttons["Live Activity beenden"].waitForExistence(timeout: 20))
        capture("26-Bitcoin-Vorschau")
        XCUIDevice.shared.press(.home); sleep(2)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.035)).press(forDuration: 1.2)
        XCTAssertTrue(springboard.buttons["Kurs aktualisieren"].firstMatch.waitForExistence(timeout: 5))
        let timestamp = springboard.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Stand ")).firstMatch
        let before = timestamp.label
        sleep(3)
        springboard.buttons["Kurs aktualisieren"].firstMatch.tap()
        let updated = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in timestamp.exists && timestamp.label != before }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [updated], timeout: 15), .completed)
        capture("27-Bitcoin-Live")
        app.activate(); XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5)); sleep(1)
        app.buttons["Live Activity beenden"].tap()
    }
    @MainActor private func capture(_ name: String) {
        // Let the rendered tab/sheet transition settle before store photography.
        if name.hasPrefix("Store-") { sleep(1) }
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
