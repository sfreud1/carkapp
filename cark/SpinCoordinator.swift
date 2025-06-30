import Foundation
import Combine

final class SpinCoordinator: ObservableObject {
    @Published var incomingRequest = false      // Karşı taraftan spin isteği geldi
    @Published var awaitingAccept  = false      // Biz istek gönderdik, onay bekliyoruz
    @Published var lastResult: String?          // "work" veya "watch movie"

    private var bag: AnyCancellable?

    init() {
        bag = NotificationCenter.default.publisher(for: .mpDidReceive)
            .compactMap { $0.object as? MPMessage }
            .sink { [weak self] msg in
                switch msg.kind {
                case .spinRequest:
                    self?.incomingRequest = true
                case .spinResult:
                    self?.awaitingAccept  = false   // onay geldi, bekleme bitti
                    self?.lastResult      = msg.payload
                }
            }
    }

    // PeerManager’a çağrı sarmalları (isteğe bağlı)
    func sendRequest() {
        awaitingAccept = true              // karşı taraftan onay bekleniyor
        PeerManager.shared.sendSpinRequest()
    }
    func sendResult(_ res: String){ PeerManager.shared.sendSpinResult(res) }
}
