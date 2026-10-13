import Foundation
import Security
import SwiftUI
import AppIntents

struct MarketAsset: Codable, Hashable, Identifiable {
    enum Kind: String, Codable, CaseIterable { case crypto = "Krypto", stock = "Aktien" }
    var kind: Kind
    var symbol: String
    var name: String
    var id: String { kind.rawValue + symbol }
    var isValid: Bool {
        !symbol.isEmpty && symbol.count <= 16 && symbol.range(of: "^[A-Z0-9.-]+$", options: .regularExpression) != nil && !name.isEmpty && name.count <= 60
    }
    static let bitcoin = MarketAsset(kind: .crypto, symbol: "BTC", name: "Bitcoin")
    static let examples: [MarketAsset] = [bitcoin,
        .init(kind: .crypto, symbol: "ETH", name: "Ethereum"), .init(kind: .crypto, symbol: "SOL", name: "Solana"),
        .init(kind: .crypto, symbol: "DOGE", name: "Dogecoin"), .init(kind: .crypto, symbol: "XRP", name: "XRP"),
        .init(kind: .stock, symbol: "AAPL", name: "Apple"), .init(kind: .stock, symbol: "MSFT", name: "Microsoft"),
        .init(kind: .stock, symbol: "NVDA", name: "NVIDIA"), .init(kind: .stock, symbol: "GOOGL", name: "Alphabet"),
        .init(kind: .stock, symbol: "AMZN", name: "Amazon"), .init(kind: .stock, symbol: "TSLA", name: "Tesla")]
}
struct MarketQuote: Codable, Hashable {
    var price: Double
    var asOf: Date
    var fetchedAt: Date
    var source: String
    var changePercent: Double?
    var priceText: String { price.formatted(.currency(code: "USD").precision(.fractionLength(price < 1 ? 4 : 2))) }
    var timeText: String { asOf.formatted(date: Calendar.current.isDateInToday(asOf) ? .omitted : .abbreviated, time: .standard) }
}
extension IslandDesign {
    var selectedAsset: MarketAsset { marketAsset ?? .bitcoin }
    mutating func selectAsset(_ asset: MarketAsset) {
        marketAsset = asset; title = asset.name; subtitle = asset.symbol + " · USD"
        iconMode = .symbol; symbol = asset.symbol == "BTC" ? "bitcoinsign.circle.fill" : "chart.line.uptrend.xyaxis"
        let brands = ["AAPL": "apple", "MSFT": "microsoft", "NVDA": "nvidia", "GOOGL": "google", "AMZN": "amazon", "TSLA": "tesla"]
        if let id = brands[asset.symbol], BrandCatalog.all.contains(where: { $0.id == id }) { iconMode = .brand; brandID = id }
        if asset.symbol == "ETH" { symbol = "diamond.fill" }
        if name == "Mein Design" { name = asset.name }
    }
}

enum MarketError: LocalizedError {
    case missingKey, unavailable, invalidQuote, keychain, distributionUnavailable
    var errorDescription: String? {
        switch self {
        case .distributionUnavailable: "Kursdesigns sind in dieser Version nicht verfügbar. Du kannst das Design als Custom, Timer oder Reise weiterverwenden."
        case .missingKey: "Für Aktien bitte unter Einstellungen → Kursdaten deinen Finnhub-API-Schlüssel hinterlegen. Krypto funktioniert ohne Schlüssel."
        case .unavailable: "Kurs nicht verfügbar. Prüfe das Symbol, deine Verbindung und gegebenenfalls den API-Schlüssel."
        case .invalidQuote: "Die Kursquelle hat keinen gültigen Kurs geliefert."
        case .keychain: "Der API-Schlüssel konnte nicht sicher gespeichert werden."
        }
    }
}
enum MarketCredentials {
    private static var query: [String: Any] { [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "ch.yannis.iLand.market", kSecAttrAccount as String: "finnhub"] }
    static func read() -> String? {
        var request = query; request[kSecReturnData as String] = true
        var result: CFTypeRef?
        guard SecItemCopyMatching(request as CFDictionary, &result) == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    static func save(_ value: String) throws {
        let key = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if key.isEmpty {
            let status = SecItemDelete(query as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else { throw MarketError.keychain }
            return
        }
        let attributes: [String: Any] = [kSecValueData as String: Data(key.utf8), kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            guard SecItemAdd(query.merging(attributes) { _, new in new } as CFDictionary, nil) == errSecSuccess else { throw MarketError.keychain }
        } else if status != errSecSuccess { throw MarketError.keychain }
    }
}
actor MarketClient {
    static let shared = MarketClient()
    private var cache: [MarketAsset: MarketQuote] = [:]
    func quote(for asset: MarketAsset, force: Bool = false) async throws -> MarketQuote {
        guard DistributionFeatures.thirdPartyCatalogs else { throw MarketError.distributionUnavailable }
        guard asset.isValid else { throw MarketError.invalidQuote }
        if let cached = cache[asset], Date().timeIntervalSince(cached.fetchedAt) < (force ? 2 : 15) { return cached }
        var request: URLRequest
        if asset.kind == .crypto {
            request = URLRequest(url: URL(string: "https://api.exchange.coinbase.com/products/\(asset.symbol)-USD/ticker")!)
        } else {
            guard let key = MarketCredentials.read(), !key.isEmpty else { throw MarketError.missingKey }
            var components = URLComponents(string: "https://finnhub.io/api/v1/quote")!
            components.queryItems = [URLQueryItem(name: "symbol", value: asset.symbol)]
            request = URLRequest(url: components.url!)
            request.setValue(key, forHTTPHeaderField: "X-Finnhub-Token")
        }
        request.timeoutInterval = 12; request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw MarketError.unavailable }
        let result = try Self.decode(data, for: asset, fetchedAt: Date())
        cache[asset] = result
        return result
    }
    static func decode(_ data: Data, for asset: MarketAsset, fetchedAt: Date) throws -> MarketQuote {
        let result: MarketQuote
        if asset.kind == .crypto {
            struct Tick: Decodable { var price: String; var time: String }
            let tick = try JSONDecoder().decode(Tick.self, from: data)
            let formatter = ISO8601DateFormatter(); formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            guard let price = Double(tick.price), let date = formatter.date(from: tick.time) ?? ISO8601DateFormatter().date(from: tick.time) else { throw MarketError.invalidQuote }
            result = MarketQuote(price: price, asOf: date, fetchedAt: fetchedAt, source: "Coinbase")
        } else {
            struct Tick: Decodable { var c: Double; var pc: Double; var t: Double }
            let tick = try JSONDecoder().decode(Tick.self, from: data)
            guard tick.t > 0 else { throw MarketError.invalidQuote }
            result = MarketQuote(price: tick.c, asOf: Date(timeIntervalSince1970: tick.t), fetchedAt: fetchedAt, source: "Finnhub", changePercent: tick.pc > 0 ? (tick.c / tick.pc - 1) * 100 : nil)
        }
        guard result.price.isFinite, result.price > 0, result.changePercent?.isFinite ?? true, result.asOf <= fetchedAt.addingTimeInterval(60) else { throw MarketError.invalidQuote }
        return result
    }
}

struct MarketIslandContent: View {
    var design: IslandDesign
    var state: IslandAttributes.ContentState?
    var activityID: String?
    var refreshAccessible = true
    var body: some View {
        let ratio = IslandCanvasMetrics.ratio
        ZStack(alignment: .topLeading) {
            DesignIcon(design: design, size: 32).position(x: 36, y: 32)
            Group {
                if design.style(.badge).appearance != .hidden {
                    if let activityID {
                        Button(intent: MarketRefreshIntent(activityID: activityID)) { refreshSymbol }
                            .buttonStyle(.plain).accessibilityLabel("Kurs aktualisieren").accessibilityHidden(!refreshAccessible)
                    } else { refreshSymbol }
                }
            }.font(.system(size: 20, weight: .semibold)).foregroundStyle(design.tint.color).position(x: 287, y: 32)
            Text(state?.marketQuote?.priceText ?? "— USD")
                .font(.system(size: 23, weight: .semibold, design: .rounded)).monospacedDigit()
                .contentTransition(.numericText()).animation(.easeInOut(duration: 0.25), value: state?.marketQuote?.price).lineLimit(1).minimumScaleFactor(0.65)
                .frame(width: 172, height: 30).position(x: 160, y: 50)
            Text(design.title + " · " + design.selectedAsset.symbol)
                .font(.system(size: 11)).foregroundStyle(.white.opacity(0.6)).lineLimit(1).frame(width: 190).position(x: 160, y: 72)
            VStack(alignment: .leading, spacing: 3) {
                if let quote = state?.marketQuote {
                    Text((state?.marketError == nil ? "Stand " : "Abruf fehlgeschlagen · Stand ") + quote.timeText)
                        .foregroundStyle(state?.marketError == nil ? Color.white.opacity(0.75) : .orange)
                    Text(quote.source + (quote.changePercent.map { " · " + $0.formatted(.number.precision(.fractionLength(2)).sign(strategy: .always())) + " % zum Vortag" } ?? " · USD"))
                        .foregroundStyle(.white.opacity(0.5))
                } else { Text(state?.marketError == nil ? "Kurs laden, um zu starten" : "Kurs nicht verfügbar").foregroundStyle(.white.opacity(0.65)) }
            }.font(.system(size: 9)).lineLimit(1).minimumScaleFactor(0.8)
                .frame(width: 240, alignment: .leading).position(x: 160, y: 98)
        }.frame(width: 320, height: 124).foregroundStyle(.white)
            .scaleEffect(ratio, anchor: .topLeading)
            .frame(width: IslandCanvasMetrics.deviceWidth, height: 124 * ratio, alignment: .topLeading)
            .environment(\.colorScheme, .dark).dynamicTypeSize(.medium)
    }
    @ViewBuilder private var refreshSymbol: some View {
        if design.style(.badge).appearance == .automatic { Image(systemName: "arrow.clockwise") }
        else { IslandElementIcon(design: design, element: .badge, size: 20) }
    }

}
