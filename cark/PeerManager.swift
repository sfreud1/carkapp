import Foundation
import MultipeerConnectivity
import SwiftUI          // binding kolaylığı için

final class PeerManager: NSObject, ObservableObject {
    /// Paylaşılan tekil örnek (singleton)
    static let shared = PeerManager()
    // MARK: - Yayınlanan durumlar
    @Published var foundPeers: [MCPeerID] = []
    @Published var connectedPeer: MCPeerID?
    @Published var lastReceived: String = ""
    private var autoTargetName: String?
    
    // MARK: - Multipeer bileşenleri
    private let serviceType = "wifireq-spin"           // max 15 karakter
    private let myPeerID    = MCPeerID(displayName: UIDevice.current.name)
    private lazy var session: MCSession = {
        let s = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        s.delegate = self
        return s
    }()
    
    private lazy var advertiser = MCNearbyServiceAdvertiser(
        peer: myPeerID,
        discoveryInfo: nil,
        serviceType: serviceType
    )
    
    private lazy var browser = MCNearbyServiceBrowser(
        peer: myPeerID,
        serviceType: serviceType
    )
    
    // MARK: - Public API
    func start() {
        advertiser.delegate = self
        browser.delegate    = self
        // Otomatik yeniden davet için kaydedilmiş eş adı varsa yükle
        if let saved = PairStore.load() {
            self.autoTargetName = saved.displayName
        }
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }
    
    func stop() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        session.disconnect()
    }
    
    func invite(_ peer: MCPeerID) {
        browser.invitePeer(peer, to: session, withContext: nil, timeout: 10)
    }
    
    // MARK: - Mesaj gönderme yardımcıları
    func sendSpinRequest() {
        send(kind: .spinRequest, value: nil)
    }

    func sendSpinResult(_ result: String) {
        send(kind: .spinResult, value: result)
    }

    // JSON-encode edip gönder
    private func send(kind: MPMessage.Kind, value: String?) {
        guard !session.connectedPeers.isEmpty else { return }
        let msg = MPMessage(kind: kind, payload: value)
        guard let data = try? JSONEncoder().encode(msg) else { return }
        try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
    }
}

// MARK: - Delegeler
extension PeerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID,
                 didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                // Bağlandık — taramayı durdur, güç tasarrufu
                self.browser.stopBrowsingForPeers()
                self.connectedPeer = peerID

                // İlk bağlantıda kalıcı olarak sakla
                if PairStore.load() == nil {
                    PairStore.save(.init(displayName: peerID.displayName,
                                         serviceType: self.serviceType))
                }
            case .notConnected:
                if peerID == self.connectedPeer {
                    self.connectedPeer = nil
                }
                // Tekrar bağlantı aramak için taramayı başlat
                self.browser.startBrowsingForPeers()
                self.advertiser.startAdvertisingPeer()
            default:
                break
            }
        }
    }
    func session(_ session: MCSession, didReceive data: Data,
                 fromPeer peerID: MCPeerID) {

        if let msg = try? JSONDecoder().decode(MPMessage.self, from: data) {
            // Yapısal mesaj: NotificationCenter ile yay
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .mpDidReceive, object: msg)
            }
        } else if let str = String(data: data, encoding: .utf8) {
            // Geriye uyumluluk: düz string
            DispatchQueue.main.async { self.lastReceived = str }
        }
    }
    // Gerekmeyen diğer delegeleri boş bırakıyoruz
    func session(_ s: MCSession, didReceive stream: InputStream, withName: String, fromPeer: MCPeerID) {}
    func session(_ s: MCSession, didStartReceivingResourceWithName: String, fromPeer: MCPeerID, with: Progress) {}
    func session(_ s: MCSession, didFinishReceivingResourceWithName: String, fromPeer: MCPeerID, at: URL?, withError: Error?) {}
}

extension PeerManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)   // otomatik kabul – test için yeterli
    }
}

extension PeerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String: String]?) {
        // Aynı cihazı listede tekrar tekrar göstermeyelim
        if !self.foundPeers.contains(peerID) {
            DispatchQueue.main.async { self.foundPeers.append(peerID) }
        }
        // Daha önce eşleştirilmiş cihazı görür görmez davet et
        if let target = autoTargetName, peerID.displayName == target {
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
        }
    }
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async { self.foundPeers.removeAll { $0 == peerID } }
    }
}
