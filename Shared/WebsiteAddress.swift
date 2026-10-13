import Foundation

/// Accept a domain or HTTP(S) URL, never an arbitrary executable URL scheme.
enum WebsiteAddress {
    static func normalized(_ input: String) -> URL? {
        let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, value.utf8.count <= 2048,
              value.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else { return nil }
        let candidate = value.contains("://") ? value : "https://" + value
        guard var components = URLComponents(string: candidate),
              let scheme = components.scheme?.lowercased(), ["https", "http"].contains(scheme),
              let host = components.host, host.contains("."), host.count <= 253,
              components.user == nil, components.password == nil else { return nil }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        guard host.split(separator: ".", omittingEmptySubsequences: false).allSatisfy({
            !$0.isEmpty && $0.count <= 63 && !$0.hasPrefix("-") && !$0.hasSuffix("-") && $0.unicodeScalars.allSatisfy(allowed.contains)
        }) else { return nil }
        if let port = components.port, !(1...65535).contains(port) { return nil }
        components.scheme = scheme
        components.host = host.lowercased()
        return components.url
    }
}

enum IslandRoute: Equatable {
    case design(UUID)
    case website(UUID)

    init?(url: URL) {
        guard url.scheme == "iland", url.query == nil, url.fragment == nil,
              url.pathComponents.count == 2, let id = UUID(uuidString: url.lastPathComponent) else { return nil }
        switch url.host {
        case "design": self = .design(id)
        case "website": self = .website(id)
        default: return nil
        }
    }
    var url: URL {
        switch self {
        case .design(let id): URL(string: "iland://design/\(id.uuidString)")!
        case .website(let id): URL(string: "iland://website/\(id.uuidString)")!
        }
    }
}
