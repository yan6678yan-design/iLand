import XCTest
import CoreLocation
import UIKit
import SwiftUI
@testable import ILand

final class ILandTests: XCTestCase {
    func testDistributionHasNoBundledBrandsOrMarketRequests() async throws {
        #if DEBUG
        XCTAssertTrue(DistributionFeatures.thirdPartyCatalogs)
        #else
        XCTAssertEqual(DesignKind.available, [.custom, .timer, .travel])
        XCTAssertFalse(IconMode.available.contains(.brand))
        XCTAssertFalse(ElementAppearance.available.contains(.brand))
        XCTAssertTrue(BrandCatalog.all.isEmpty)
        XCTAssertNil(Bundle.main.url(forResource: "Brands", withExtension: "json"))
        XCTAssertNil(UIImage(named: "brand_porsche"))
        do {
            _ = try await MarketClient.shared.quote(for: .bitcoin)
            XCTFail("A distribution build must not request unlicensed data")
        } catch MarketError.distributionUnavailable { }
        #endif
    }

    func testMarketQuoteDecodingRejectsInvalidDataAndKeepsSourceTime() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let crypto = Data(#"{"price":"62000.125","time":"2026-10-04T22:20:55.216199622Z"}"#.utf8)
        let quote = try MarketClient.decode(crypto, for: .bitcoin, fetchedAt: now)
        XCTAssertEqual(quote.price, 62000.125)
        XCTAssertEqual(quote.source, "Coinbase")
        XCTAssertLessThan(quote.asOf, quote.fetchedAt)
        let stock = MarketAsset(kind: .stock, symbol: "AAPL", name: "Apple")
        let stockQuote = try MarketClient.decode(Data(#"{"c":220,"pc":200,"t":1791000000}"#.utf8), for: stock, fetchedAt: now)
        XCTAssertEqual(try XCTUnwrap(stockQuote.changePercent), 10, accuracy: 0.0001)
        XCTAssertThrowsError(try MarketClient.decode(Data(#"{"c":0,"pc":200,"t":0}"#.utf8), for: stock, fetchedAt: now))
        XCTAssertThrowsError(try MarketClient.decode(Data(#"{"price":"NaN","time":"2026-10-04T22:20:55Z"}"#.utf8), for: .bitcoin, fetchedAt: now))
        XCTAssertFalse(MarketAsset(kind: .crypto, symbol: "BTC/../../", name: "Bad").isValid)
    }
    func testMarketPersistenceAndActivityBudget() throws {
        var design = IslandDesign.blank; design.kind = .market; design.selectAsset(.bitcoin)
        XCTAssertNil(design.validationError)
        XCTAssertEqual(design, try JSONDecoder().decode(IslandDesign.self, from: JSONEncoder().encode(design)))
        var state = IslandAttributes.ContentState(title: design.title, subtitle: design.subtitle, status: "", endDate: Date(), remaining: 0)
        state.marketQuote = MarketQuote(price: 60000, asOf: Date(), fetchedAt: Date(), source: "Coinbase")
        XCTAssertLessThan(try JSONEncoder().encode(IslandAttributes(design: design, startedAt: Date())).count + JSONEncoder().encode(state).count, 3900)
    }
    @MainActor func testCanvasCenterIncludesLegacyCameraAreaAndSnaps() {
        var design = IslandDesign.blank; design.customLayout = .standard
        XCTAssertEqual(IslandCanvasMetrics.centerY(for: design), 62)
        design.customLayout?.cameraLayout = nil
        let y = IslandCanvasMetrics.centerY(for: design) * IslandCanvasMetrics.ratio + IslandCanvasMetrics.cameraClearance
        XCTAssertEqual(y, IslandCanvasMetrics.height(for: design) / 2, accuracy: 0.001)
        XCTAssertEqual(IslandCanvasMetrics.snapped(158, to: 160), 160)
        XCTAssertEqual(IslandCanvasMetrics.snapped(150, to: 160), 150)
        XCTAssertEqual(IslandCanvasMetrics.snapped(3, to: 0), 0)
        XCTAssertEqual(IslandCanvasMetrics.snapped(-3, to: 0), 0)
        XCTAssertEqual(IslandCanvasMetrics.snapped(8, to: 0), 8)
    }
    @MainActor func testHiddenWebsiteActionDoesNotAddEmptyCanvasHeight() {
        var design = IslandDesign.blank
        design.kind = .timer; design.actionKind = .website
        let visibleHeight = IslandCanvasMetrics.height(for: design)
        design.setStyle(ElementStyle(appearance: .hidden), for: .action)
        XCTAssertEqual(IslandCanvasMetrics.height(for: design), 124 * IslandCanvasMetrics.ratio)
        XCTAssertEqual(visibleHeight - IslandCanvasMetrics.height(for: design), 24 * IslandCanvasMetrics.ratio, accuracy: 0.001)
    }
    @MainActor func testLegacyMusicAndBrandNameMigration() throws {
        let design = IslandDesign.blank
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(design)) as? [String: Any])
        object["kind"] = "Musik"
        object["motion"] = "Musikvisualisierung"
        object["actionKind"] = "Design in ILand"
        let migrated = try JSONDecoder().decode(IslandDesign.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(migrated.id, design.id)
        XCTAssertEqual(migrated.kind, .custom)
        XCTAssertEqual(migrated.motion, .none)
        XCTAssertEqual(migrated.actionKind, .inApp)
        XCTAssertEqual(DesignKind.allCases, [.custom, .timer, .travel, .market])
        XCTAssertFalse(ConditionKind.allCases.contains(.music))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("state.json")
        let snapshot = IslandStore.Snapshot(designs: [migrated], rules: [IslandRule(enabled: true, matchAll: false, conditions: [RuleCondition(kind: .music), RuleCondition(kind: .appActive)], designID: migrated.id)], places: [], appearance: "Dunkel")
        try JSONEncoder().encode(snapshot).write(to: file)
        let store = IslandStore(fileURL: file)
        XCTAssertFalse(store.rules[0].enabled)
        XCTAssertEqual(store.rules[0].conditions.map(\.kind), [.appActive])
        XCTAssertEqual(store.appearance, "Dunkel")
        XCTAssertTrue(store.save(migrated))
    }
    @MainActor func testActiveDesignOrderingRestoresAfterStop() {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("state.json")
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        let store = IslandStore(fileURL: file)
        let original = store.designs.map(\.id)
        store.activeDesign = store.designs[3]
        XCTAssertEqual(store.orderedDesigns.first?.id, original[3])
        XCTAssertEqual(store.orderedDesigns.dropFirst().map(\.id), original.filter { $0 != original[3] })
        store.activeDesign = nil
        XCTAssertEqual(store.orderedDesigns.map(\.id), original)
    }
    func testRightSymbolOverridesRestoreHiddenCanvasAndReplaceCompactText() {
        var design = IslandDesign.blank
        design.customLayout = .standard
        let index = design.customLayout!.items.firstIndex { $0.kind == .badge }!
        design.customLayout!.items[index].hidden = true
        design.setStyle(ElementStyle(appearance: .emoji, value: "🌿"), for: .badge)
        XCTAssertFalse(design.customLayout!.items[index].hidden)
        design.personalization?.compactText = "Alter Text"
        design.setStyle(ElementStyle(appearance: .hidden), for: .compact)
        XCTAssertNil(design.customization.compactText)
        XCTAssertEqual(design.style(.compact).appearance, .hidden)
        design.setStyle(ElementStyle(appearance: .hidden), for: .action)
        XCTAssertNil(design.validationError)
    }
    func testCustomColorRoundTripAndRecentHistory() throws {
        var design = IslandDesign.blank
        design.tint = IslandTint(rawValue: "#23B4D8")
        let copy = try JSONDecoder().decode(IslandDesign.self, from: JSONEncoder().encode(design))
        XCTAssertEqual(copy.tint, design.tint)
        XCTAssertEqual(try JSONDecoder().decode(IslandTint.self, from: Data("\"Violett\"".utf8)), .violet)
        let suite = UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        for tint in [IslandTint.violet, .mint, .blue, .orange, .pink, .mint] { RecentIslandColors.record(tint, defaults: defaults) }
        XCTAssertEqual(defaults.stringArray(forKey: RecentIslandColors.key), ["Mint", "Pink", "Orange", "Blau"])
    }
    @MainActor func testEnteringDirectEditorPreservesTemplatePixels() throws {
        var design = IslandDesign.blank
        design.title = "Zuhause"
        design.subtitle = "Dein Lieblingsort"
        func pixels(_ value: IslandDesign) throws -> Data {
            let renderer = ImageRenderer(content: ExpandedIslandContent(design: value)
                .background(.black))
            renderer.scale = 2
            return try XCTUnwrap(renderer.uiImage?.pngData())
        }
        let before = try pixels(design)
        design.customLayout = .standard
        XCTAssertEqual(before, try pixels(design), "Opening the direct editor must not rearrange or shrink the template.")
        XCTAssertNil(design.validationError)
    }
    func testLegacyCanvasCoordinatesAndCameraProtection() throws {
        let oldJSON = "{\"items\":[]}"
        let legacy = try JSONDecoder().decode(IslandLayout.self, from: Data(oldJSON.utf8))
        XCTAssertNil(legacy.cameraLayout)
        var item = LayoutItem(kind: .text, x: 160, y: 15, width: 150, height: 24)
        item.constrain(avoidingCamera: true)
        XCTAssertGreaterThanOrEqual(item.y - item.height * item.scale / 2, 36)
        XCTAssertNil(IslandLayout(items: [item], cameraLayout: true).validationError)
    }
    func testLayoutBoundsRotationAndPersistence() throws {
        var design = IslandDesign.blank
        XCTAssertTrue(design.showsIconBackground)
        design.iconBackground = false
        design.customLayout = .standard
        XCTAssertNil(design.validationError)
        for index in design.customLayout!.items.indices {
            design.customLayout!.items[index].rotation = 45
            design.customLayout!.items[index].scale = 2.5
            design.customLayout!.items[index].x = -500
            design.customLayout!.items[index].y = 500
            design.customLayout!.items[index].constrain(avoidingCamera: true)
        }
        XCTAssertNil(design.validationError)
        let decoded = try JSONDecoder().decode(IslandDesign.self, from: JSONEncoder().encode(design))
        XCTAssertEqual(design, decoded)
        XCTAssertFalse(decoded.showsIconBackground)
        var invalid = LayoutItem(kind: .text, x: 0, y: 0, width: 100, height: 20)
        XCTAssertNotNil(IslandLayout(items: [invalid]).validationError)
        invalid.x = .infinity
        XCTAssertNotNil(IslandLayout(items: [invalid]).validationError)
    }
    func testLayoutBudgetAndRealBrandAssets() throws {
        var design = IslandDesign.blank
        design.customLayout = .standard
        if DistributionFeatures.thirdPartyCatalogs { design.iconMode = .brand; design.brandID = "porsche" }
        for _ in 0..<5 {
            design.customLayout?.items.append(LayoutItem(kind: .text, x: 160, y: 65, width: 150, height: 24, text: "Mein eigener Text"))
        }
        XCTAssertNil(design.validationError)
        let state = IslandAttributes.ContentState(title: design.title, subtitle: design.subtitle, status: design.status, endDate: Date(), remaining: 1500)
        XCTAssertLessThan(try JSONEncoder().encode(IslandAttributes(design: design, startedAt: Date())).count + JSONEncoder().encode(state).count, 3900)
        for id in DistributionFeatures.thirdPartyCatalogs ? ["porsche", "rolex", "bmw", "gucci"] : [] {
            XCTAssertNotNil(BrandCatalog.all.first { $0.id == id })
            XCTAssertNotNil(UIImage(named: "brand_" + id))
        }
    }
    func testPersonalizationMigrationAndRoundTrip() throws {
        var design = IslandDesign.blank
        let legacy = try JSONDecoder().decode(IslandDesign.self, from: JSONEncoder().encode(design))
        XCTAssertNil(legacy.personalization)
        XCTAssertEqual(legacy.style(.badge).appearance, .automatic)
        design.setStyle(ElementStyle(appearance: .emoji, value: "🪴"), for: .badge)
        design.personalization?.compactText = "Zuhause 🏠"
        design.personalization?.actionText = "Mein Zuhause"
        let decoded = try JSONDecoder().decode(IslandDesign.self, from: JSONEncoder().encode(design))
        XCTAssertEqual(decoded, design)
        XCTAssertEqual(decoded.actionCaption, "Mein Zuhause")
        XCTAssertEqual(decoded.style(.badge).value, "🪴")
        design.setStyle(ElementStyle(), for: .badge)
        XCTAssertNil(design.personalization?.elements["badge"])
    }
    func testPersonalizationValidationAndRelevantControls() {
        var design = IslandDesign.blank
        design.title = ""; design.subtitle = ""; design.status = ""
        XCTAssertNil(design.validationError)
        design.setStyle(ElementStyle(appearance: .symbol, value: "not.a.real.sf.symbol"), for: .badge)
        XCTAssertNotNil(design.validationError)
        design.setStyle(ElementStyle(appearance: .hidden), for: .badge)
        XCTAssertNil(design.validationError)
        design.setStyle(ElementStyle(appearance: .hidden), for: .action)
        XCTAssertNil(design.validationError)
        design.setStyle(ElementStyle(), for: .action)
        design.personalization?.compactText = String(repeating: "x", count: 13)
        XCTAssertNotNil(design.validationError)
        design.personalization?.compactText = ""
        XCTAssertNil(design.validationError)
        design.kind = .timer
        XCTAssertTrue(design.editableElements.contains(.reset))
        XCTAssertFalse(design.editableElements.contains(.previous))
        design.kind = .custom
        XCTAssertFalse(design.editableElements.contains(.previous))
        XCTAssertFalse(design.editableElements.contains(.reset))
    }
    func testCustomizedPayloadFitsBudget() throws {
        var design = IslandDesign.blank
        design.kind = .custom; design.actionKind = .website; design.actionURL = "https://example.com"
        for element in design.editableElements { design.setStyle(ElementStyle(appearance: .emoji, value: "❤️"), for: element) }
        design.personalization?.compactText = "Meine Musik"
        design.personalization?.actionText = "Meine Webseite"
        let state = IslandAttributes.ContentState(title: design.title, subtitle: design.subtitle, status: design.status, endDate: Date(), remaining: 1500)
        XCTAssertLessThan(try JSONEncoder().encode(state).count + JSONEncoder().encode(IslandAttributes(design: design, startedAt: Date())).count, 3900)
    }
    func testTimeWindowAcrossMidnightAndBoundaries() {
        XCTAssertTrue(RuleCondition.includes(minute: 23 * 60, start: 22 * 60, end: 6 * 60))
        XCTAssertTrue(RuleCondition.includes(minute: 3 * 60, start: 22 * 60, end: 6 * 60))
        XCTAssertFalse(RuleCondition.includes(minute: 6 * 60, start: 22 * 60, end: 6 * 60))
        XCTAssertFalse(RuleCondition.includes(minute: 12 * 60, start: 22 * 60, end: 6 * 60))
        XCTAssertTrue(RuleCondition.includes(minute: 800, start: 0, end: 0))
    }
    func testRuleCombinationAndMissingPermissionsFailClosed() {
        let context = RuleContext(now: Date(), appActive: true, location: nil, places: [], eventTitles: [])
        var rule = IslandRule(enabled: true, conditions: [RuleCondition(kind: .appActive), RuleCondition(kind: .location)], designID: UUID())
        XCTAssertFalse(RuleEngine.matches(rule, context: context))
        rule.matchAll = false
        XCTAssertTrue(RuleEngine.matches(rule, context: context))
        rule.enabled = false
        XCTAssertFalse(RuleEngine.matches(rule, context: context))
        rule.enabled = true; rule.conditions = []
        XCTAssertFalse(RuleEngine.matches(rule, context: context))
    }
    func testLocationRejectsStaleAndInaccurateFixes() {
        let place = SavedPlace(name: "Zürich", latitude: 47.37, longitude: 8.54, radius: 150)
        let coordinate = CLLocationCoordinate2D(latitude: 47.37, longitude: 8.54)
        XCTAssertTrue(place.contains(CLLocation(coordinate: coordinate, altitude: 0, horizontalAccuracy: 20, verticalAccuracy: 20, timestamp: Date())))
        XCTAssertFalse(place.contains(CLLocation(coordinate: coordinate, altitude: 0, horizontalAccuracy: 500, verticalAccuracy: 20, timestamp: Date())))
        XCTAssertFalse(place.contains(CLLocation(coordinate: coordinate, altitude: 0, horizontalAccuracy: 20, verticalAccuracy: 20, timestamp: Date().addingTimeInterval(-600))))
    }
    func testExternalURLValidation() {
        var design = IslandDesign.blank; design.actionKind = .website
        for url in ["javascript:alert(1)", "file:///private/test", "iland://design/test", "https://"] { design.actionURL = url; XCTAssertNil(design.validActionURL, url) }
        design.actionURL = "https://example.com/path"; XCTAssertNotNil(design.validActionURL)
        design.actionKind = .deepLink; design.actionURL = "shortcuts://run-shortcut?name=Home"; XCTAssertNotNil(design.validActionURL)
    }
    func testWebsiteDomainsAndUnsafeURLs() {
        XCTAssertEqual(WebsiteAddress.normalized(" example.com ")?.absoluteString, "https://example.com")
        XCTAssertEqual(WebsiteAddress.normalized("EXAMPLE.com/shop?q=watch#details")?.absoluteString, "https://example.com/shop?q=watch#details")
        XCTAssertEqual(WebsiteAddress.normalized("http://example.com:8080")?.absoluteString, "http://example.com:8080")
        for input in ["", "example", "example .com", "https://", "javascript:alert(1)", "ftp://example.com", "file:///example.com", "https://user:pass@example.com", "https://-bad.com", "https://example..com", "https://example.com:99999"] {
            XCTAssertNil(WebsiteAddress.normalized(input), input)
        }
    }
    func testWebsiteRouteCannotInjectAnotherDestination() {
        let id = UUID()
        XCTAssertEqual(IslandRoute(url: IslandRoute.website(id).url), .website(id))
        XCTAssertEqual(IslandRoute(url: IslandRoute.design(id).url), .design(id))
        XCTAssertNil(IslandRoute(url: URL(string: "iland://website/\(id)?url=https://other.example")!))
        XCTAssertNil(IslandRoute(url: URL(string: "iland://website/wrong/\(id)")!))
    }
    func testAllBundledLogosAndLegacyDesignDecoding() throws {
        XCTAssertEqual(BrandCatalog.all.count, DistributionFeatures.thirdPartyCatalogs ? 100 : 0)
        XCTAssertEqual(Set(BrandCatalog.all.map(\.id)).count, DistributionFeatures.thirdPartyCatalogs ? 100 : 0)
        for brand in BrandCatalog.all {
            let asset = try XCTUnwrap(UIImage(named: "brand_" + brand.id), brand.id)
            let format = UIGraphicsImageRendererFormat(); format.opaque = false; format.scale = 1
            let rendered = UIGraphicsImageRenderer(size: CGSize(width: 96, height: 96), format: format).image { _ in asset.draw(in: CGRect(x: 0, y: 0, width: 96, height: 96)) }
            let pixelData = try XCTUnwrap(rendered.cgImage?.dataProvider?.data)
            XCTAssertTrue((pixelData as Data).contains { $0 > 0 }, "Logo ist leer: " + brand.name)
            XCTAssertNotNil(URL(string: brand.source))
        }
        let original = IslandDesign.blank
        let encoded = try JSONEncoder().encode(original)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        json.removeValue(forKey: "brandID")
        let legacy = try JSONDecoder().decode(IslandDesign.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertEqual(legacy.id, original.id)
        XCTAssertNil(legacy.brandID)
    }
    func testActivityPayloadFitsBudget() throws {
        for design in IslandDesign.examples {
            let state = IslandAttributes.ContentState(title: design.title, subtitle: design.subtitle, status: design.status, endDate: Date(), remaining: 1500)
            let attributes = IslandAttributes(design: design, startedAt: Date())
            XCTAssertLessThan(try JSONEncoder().encode(state).count + JSONEncoder().encode(attributes).count, 4096)
        }
    }
    @MainActor func testPersistenceAndDuplicateIdentity() throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("state.json")
        defer { try? FileManager.default.removeItem(at: file.deletingLastPathComponent()) }
        let first = IslandStore(fileURL: file)
        var design = IslandDesign.blank; design.name = "Mein gespeichertes Design"
        XCTAssertTrue(first.save(design)); first.duplicate(design)
        let second = IslandStore(fileURL: file)
        XCTAssertTrue(second.designs.contains { $0.id == design.id && $0.name == design.name })
        XCTAssertEqual(Set(second.designs.map(\.id)).count, second.designs.count)
        XCTAssertTrue(second.designs.contains { $0.name == design.name + " Kopie" })
    }
    @MainActor func testCorruptStorageIsNotOverwritten() throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let original = Data("corrupt-existing-data".utf8)
        try original.write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }
        let store = IslandStore(fileURL: file)
        XCTAssertFalse(store.save(.blank))
        XCTAssertEqual(try Data(contentsOf: file), original)
    }
}
