import SwiftUI
import FirebaseAuth
import FirebaseFirestore
#if canImport(UIKit)
import UIKit
#endif
import MultipeerConnectivity

/// Ana ekran – SparkleBackground üzerinde çark + bağlantı durumları
struct WheelSpinView: View {
    // MARK: - Giriş parametreleri
    let userName: String
    let profileImageURL: URL?

    // MARK: - Environment / State
    @EnvironmentObject var peer: PeerManager         // bağlantı durumu
    @EnvironmentObject var spin: SpinCoordinator     // multipeer köprüsü
    @Environment(\.dismiss) private var dismiss

    @State private var db = Firestore.firestore()
    @State private var isSpinning = false
    @State private var rotationAngle: Double = 0
    @State private var headerText: String = "Ne Yapmalıyım?"
    @State private var headerColor: Color = .gray.opacity(0.8)
    @State private var isShowingProfileActions = false
    @State private var showPairSheet = false

    // MARK: - Seçenekler
    private let options: [(label: String, color: Color)] = [
        ("Watch Movie", Color(red: 16/255, green: 185/255, blue: 129/255)),
        ("Work",        Color(red: 59/255, green: 130/255, blue: 246/255))
    ]

    // MARK: - ViewBuilder’lar
    private var mainContent: some View {
        VStack(spacing: 40) {
            if !userName.isEmpty {
                Text("Hoş geldin, \(userName)!")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 1.2), value: userName)
                    .padding(.top, 20)
            }

            Text(headerText)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(headerColor)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                .animation(.easeInOut, value: headerText)

            // Çark gövdesi
            WheelShapeView(rotationAngle: rotationAngle,
                           profileImageURL: profileImageURL,
                           options: options)

            // Döndür butonu
            Button(action: spinWheel) {
                Text("Çarkı Döndür")
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.horizontal, 48)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 106/255, green: 17/255, blue: 203/255),
                                Color(red: 37/255, green: 117/255, blue: 252/255)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(100)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            }
            .disabled(isSpinning)

            // Multipeer “spin isteği” butonu
            if peer.connectedPeer != nil {
                Button(spin.awaitingAccept ? "İstek Gönderildi" : "Spin İsteği Gönder") {
                    spin.sendRequest()
                }
                .buttonStyle(.borderedProminent)
                .disabled(spin.awaitingAccept || isSpinning)
            }

            statusBar
        }
        .padding()
    }

    /// Alt kısımdaki bağlantı durum çubuğu
    private var statusBar: some View {
        HStack(spacing: 12) {
            Circle()
                .frame(width: 12, height: 12)
                .foregroundStyle(peer.connectedPeer == nil ? .red : .green)

            Text(peer.connectedPeer == nil
                 ? "Bağlı Değil"
                 : "Bağlı: \(peer.connectedPeer!.displayName)")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))

            Spacer()

            Button(peer.connectedPeer == nil ? "Eşleş" : "Bağlantıyı Kes") {
                if peer.connectedPeer == nil {
                    peer.start()
                    showPairSheet = true
                } else {
                    peer.stop()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.top, 4)
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            SparkleBackground()
            mainContent
        }
        .sheet(isPresented: $showPairSheet) {
            PairingView().environmentObject(peer)
        }
        .onChange(of: peer.connectedPeer) { newPeer in
            if newPeer != nil { showPairSheet = false }
        }
        // Diğer cihazdan gelen spin sonucu
        .onChange(of: spin.lastResult) { res in
            guard let res else { return }
            if !isSpinning { spinWheel() }      // öbür tarafta animasyonu başlat

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                if res == "work" {
                    headerText  = "Work!"
                    headerColor = options[1].color
                } else {
                    headerText  = "Watch Movie!"
                    headerColor = options[0].color
                }
            }
        }
        // Gelen “spin isteği” alert’i
        .alert("Spin isteği geldi!", isPresented: $spin.incomingRequest) {
            Button("Kabul Et")   { spinWheel() }
            Button("Reddet", role: .cancel) { }
        }
        // Bizim gönderdiğimiz istek alert’i
        .alert("Spin isteği gönderildi\nkarşı tarafın onayı bekleniyor…",
               isPresented: $spin.awaitingAccept) { }
        // Profil köşesi
        .overlay(alignment: .topTrailing) {
            Button { isShowingProfileActions = true } label: {
                if let url = profileImageURL {
                    AsyncImage(url: url) { image in image.resizable() }
                        placeholder: { ProgressView() }
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                        .padding()
                } else {
                    Image(systemName: "person.crop.circle")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.8))
                        .padding()
                }
            }
        }
        .confirmationDialog("Profil",
                            isPresented: $isShowingProfileActions,
                            titleVisibility: .visible) {
            Button("Çıkış Yap", role: .destructive) { signOut() }
            Button("Vazgeç", role: .cancel) { }
        }
    }

    // MARK: - Spin mantığı
    private func spinWheel() {
        guard !isSpinning else { return }
        isSpinning = true
        headerText  = "Dönüyor..."
        headerColor = .gray.opacity(0.6)

        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif

        let total = Double(Int.random(in: 5...10)) * 360 + Double.random(in: 0..<360)

        withAnimation(.easeOut(duration: 4)) {
            rotationAngle += total
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.1) {
            let finalAngle = rotationAngle.truncatingRemainder(dividingBy: 360)
            updateHeaderForAngle(finalAngle)
            let clean = headerText.replacingOccurrences(of: "!", with: "")
            saveSpinResultToFirestore(clean)
            spin.sendResult(clean.lowercased())   // sonucu peer’e yolla
            isSpinning = false
        }
    }

    private func updateHeaderForAngle(_ finalAngle: Double) {
        let pointerAngle: Double = 270        // Okun gösterdiği açı
        let netAngle   = (pointerAngle - finalAngle).truncatingRemainder(dividingBy: 360)
        let winningAng = netAngle < 0 ? netAngle + 360 : netAngle

        let index = (0..<180).contains(winningAng) ? 0 : 1
        let res   = options[index]
        headerText  = "\(res.label)!"
        headerColor = res.color
    }

    // MARK: - Firestore
    private func saveSpinResultToFirestore(_ label: String) {
        guard let user = Auth.auth().currentUser else { return }

        let spinEntry: [String: Any] = [
            "choice":    label,
            "timestamp": Timestamp(date: Date())
        ]

        db.collection("spins").document(user.uid).setData([
            "email": user.email ?? "anonymous",
            "spins": FieldValue.arrayUnion([spinEntry])
        ], merge: true) { err in
            if let err { print("HATA: Firestore güncellemesi başarısız - \(err.localizedDescription)") }
            else       { print("Spin sonucu eklendi: \(label)") }
        }
    }

    // MARK: - Çıkış
    private func signOut() {
        do {
            try Auth.auth().signOut()
            UserDefaults.standard.set(false, forKey: "isLoggedIn")
            #if canImport(UIKit)
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let win   = scene.windows.first {
                win.rootViewController = UIHostingController(
                    rootView: LoginView(isLoggedIn: .constant(false))
                )
                win.makeKeyAndVisible()
            }
            #endif
        } catch {
            print("Sign out failed: \(error)")
        }
    }
}

// MARK: - Preview
struct WheelSpinView_Previews: PreviewProvider {
    static var previews: some View {
        WheelSpinView(userName: "Kullanıcı",
                      profileImageURL: nil)
            .environmentObject(PeerManager.shared)
            .environmentObject(SpinCoordinator())
            .preferredColorScheme(.dark)
    }
}
