import Foundation

struct PairInfo: Codable {
    let displayName: String      // "iPhone de Ahmet"
    let serviceType: String      // "_wifireq-spin._tcp"
}

enum PairStore {
    private static let key = "savedPair"

    static func save(_ info: PairInfo) {
        if let data = try? JSONEncoder().encode(info) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func load() -> PairInfo? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(PairInfo.self, from: data)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
