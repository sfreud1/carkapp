import Foundation

struct MPMessage: Codable {
    enum Kind: String, Codable {
        case spinRequest   // çarkı döndür sinyali
        case spinResult    // sonucu ilet
    }
    let kind: Kind
    let payload: String?
}

extension Notification.Name {
    static let mpDidReceive = Notification.Name("mpDidReceive")
}
