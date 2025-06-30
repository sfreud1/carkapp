import SwiftUI
import MultipeerConnectivity

/// Yakındaki cihazları listeleyen modal ekran
struct PairingView: View {
    @EnvironmentObject var peer: PeerManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if peer.foundPeers.isEmpty {
                    Text("Yakında cihaz bulunamadı…")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(peer.foundPeers, id: \.self) { p in
                        Button(p.displayName) {
                            peer.invite(p)      // eşleşme daveti gönder
                        }
                    }
                }
            }
            .navigationTitle("Cihaz Seç")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}
