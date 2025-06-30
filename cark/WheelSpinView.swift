import SwiftUI
import FirebaseAuth
import FirebaseFirestore
#if canImport(UIKit)
import UIKit
#endif
import MultipeerConnectivity

// MARK: - SparkleBackground
private struct SparkleBackground: View {
    var body: some View {
        ZStack {
            GeometryReader { _ in
                Canvas { context, size in
                    for _ in 0..<100 {
                        let x = CGFloat.random(in: 0..<size.width)
                        let y = CGFloat.random(in: 0..<size.height)
                        let rect = CGRect(x: x, y: y, width: 2, height: 2)
                        context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.25)))
                    }
                }
                .ignoresSafeArea()
            }
            ZStack {
                ForEach(0..<60, id: \.self) { _ in
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: CGFloat.random(in: 1...3),
                               height: CGFloat.random(in: 1...3))
                        .position(
                            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                            y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                        )
                        .opacity(Double.random(in: 0.1...0.6))
                        .blur(radius: 0.5)
                        .animation(
                            Animation.easeInOut(duration: Double.random(in: 1...3))
                                .repeatForever(),
                            value: UUID()
                        )
                }
            }
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 65/255, green: 67/255, blue: 69/255),
                    Color(red: 35/255, green: 37/255, blue: 38/255)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - WheelShapeView
/// Çarkın dairesel gövdesini ayrı bir alt görünüme taşıdık; böylece derleyici yükü azalır.
private struct WheelShapeView: View {
    let rotationAngle: Double
    let profileImageURL: URL?
    let options: [(label: String, color: Color)]

    var body: some View {
        ZStack {
            Diamond()
                .fill(Color(red: 212/255, green: 175/255, blue: 55/255))
                .frame(width: 30, height: 30)
                .rotationEffect(.degrees(180))
                .offset(y: -165)
                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                .zIndex(1)

            ZStack {
                Circle()
                    .strokeBorder(Color.white, lineWidth: 8)
                    .background(
                        Circle()
                            .fill(Self.angularGradient)
                    )
                    .frame(width: 300, height: 300)

                if let url = profileImageURL {
                    AsyncImage(url: url) { image in
                        image.resizable()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color(red: 212/255, green: 175/255, blue: 55/255), lineWidth: 4)
                    )
                    .zIndex(2)
                } else {
                    Circle()
                        .fill(Color(red: 240/255, green: 230/255, blue: 140/255))
                        .frame(width: 25, height: 25)
                        .overlay(
                            Circle()
                                .stroke(Color(red: 212/255, green: 175/255, blue: 55/255), lineWidth: 4)
                        )
                }

                // Etiketler
                HStack(spacing: 8) {
                    Image(systemName: "briefcase.fill")
                        .font(.system(size: 20))
                    Text("Work")
                        .font(.system(size: 19.2, weight: .semibold))
                }
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                .offset(y: -75)

                HStack(spacing: 8) {
                    Image(systemName: "film.fill")
                        .font(.system(size: 20))
                    Text("Watch Movie")
                        .font(.system(size: 19.2, weight: .semibold))
                }
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                .offset(y: 75)
            }
            .rotationEffect(.degrees(rotationAngle))
            .shadow(color: .black.opacity(0.2), radius: 25, x: 0, y: 10)
            .shadow(color: .white.opacity(0.1), radius: 10)
        }
    }

    /// Önceden uzun satır olan gradient
    private static let angularGradient = AngularGradient(
        gradient: Gradient(colors: [
            Color(red: 59/255, green: 130/255, blue: 246/255),
            Color(red: 59/255, green: 130/255, blue: 246/255),
            Color(red: 16/255, green: 185/255, blue: 129/255),
            Color(red: 16/255, green: 185/255, blue: 129/255),
            Color(red: 59/255, green: 130/255, blue: 246/255),
            Color(red: 59/255, green: 130/255, blue: 246/255)
        ]),
        center: .center,
        startAngle: .degrees(-90),
        endAngle: .degrees(270)
    )
}

// MARK: - WheelSpinView
struct WheelSpinView: View {
    let userName: String
    let profileImageURL: URL?
    
    // MARK: - State Properties
    @EnvironmentObject var peer: PeerManager       // bağlantı durumu
    @State private var isSpinning = false
    @State private var rotationAngle: Double = 0
    @State private var headerText: String = "Ne Yapmalıyım?"
    @State private var headerColor: Color = .gray.opacity(0.8)
    @State private var isShowingProfileActions = false
    @State private var showPairSheet = false      // modal görünümü
    @Environment(\.dismiss) private var dismiss
    @State private var db = Firestore.firestore()
    @EnvironmentObject var spin: SpinCoordinator   // multipeer / spin bridge

    // MARK: - Options
    private let options: [(label: String, color: Color)] = [
        ("Watch Movie", Color(red: 16/255, green: 185/255, blue: 129/255)),
        ("Work", Color(red: 59/255, green: 130/255, blue: 246/255))
    ]
    
    // Daha kolay derlenmesi için ana içerik ayrı bir ViewBuilder
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

            WheelShapeView(rotationAngle: rotationAngle,
                           profileImageURL: profileImageURL,
                           options: options)

            // Döndür butonu
            Button(action: { spinWheel() }) {
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

    // Bağlantı göstergesi HStack'i ayrı ViewBuilder
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
        // Diğer telefondan gelen sonucu yakala
        .onChange(of: spin.lastResult) { res in
            guard let res else { return }

            // Diğer ekranda da animasyonu başlat
            if !isSpinning { spinWheel() }

            // 0.4 sn sonra başlık ve renk güncelle
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
        // Karşı taraftan gelen istek
        .alert("Spin isteği geldi!", isPresented: $spin.incomingRequest) {
            Button("Kabul Et") { spinWheel() }
            Button("Reddet", role: .cancel) { }
        }
        // Biz istek attık, onay bekleniyor
        .alert("Spin isteği gönderildi\nkarşı tarafın onayı bekleniyor…",
               isPresented: $spin.awaitingAccept) { }
        .overlay(alignment: .topTrailing) {
            Button(action: {
                isShowingProfileActions = true
            }) {
                if let url = profileImageURL {
                    AsyncImage(url: url) { image in
                        image.resizable()
                    } placeholder: {
                        ProgressView()
                    }
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
        .confirmationDialog("Profil", isPresented: $isShowingProfileActions, titleVisibility: .visible) {
            Button("Çıkış Yap", role: .destructive) {
                do {
                    try Auth.auth().signOut()
                    UserDefaults.standard.set(false, forKey: "isLoggedIn")
                    #if canImport(UIKit)
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController = UIHostingController(
                            rootView: LoginView(isLoggedIn: .constant(false))
                        )
                        window.makeKeyAndVisible()
                    }
                    #endif
                } catch {
                    print("Sign out failed: \(error)")
                }
            }
            Button("Vazgeç", role: .cancel) {}
        }
    }
    
    private func spinWheel() {
        guard !isSpinning else { return }
        isSpinning = true
        headerText = "Dönüyor..."
        headerColor = .gray.opacity(0.6)

        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif

        let fullRotations = Double(Int.random(in: 5...10))
        let extra = Double.random(in: 0..<360)
        let total = fullRotations * 360 + extra

        withAnimation(.easeOut(duration: 4)) {
            rotationAngle += total
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.1) {
            let finalAngle = rotationAngle.truncatingRemainder(dividingBy: 360)
            updateHeaderForAngle(finalAngle)
            let cleanLabel = headerText.replacingOccurrences(of: "!", with: "")
            saveSpinResultToFirestore(cleanLabel)
            spin.sendResult(cleanLabel.lowercased())           // karşı tarafa sonucu ilet
            isSpinning = false
        }
    }
    
    private func updateHeaderForAngle(_ finalAngle: Double) {
        let pointerAngle: Double = 270.0
        
        let netAngle = (pointerAngle - finalAngle).truncatingRemainder(dividingBy: 360)
        let winningAngle = netAngle < 0 ? netAngle + 360 : netAngle

        let index: Int
        if winningAngle >= 0 && winningAngle < 180 {
            index = 0
        } else {
            index = 1
        }
        
        let result = options[index]
        headerText = "\(result.label)!"
        headerColor = result.color
    }
    
    // MARK: - Firestore Persistence
    private func saveSpinResultToFirestore(_ label: String) {
        guard let user = Auth.auth().currentUser else { return }

        // ⚠️ FieldValue.serverTimestamp() arrayUnion içinde kullanılamaz.
        // Yerine doğrudan Timestamp(date:) ekliyoruz.
        let spinEntry: [String: Any] = [
            "choice": label,
            "timestamp": Timestamp(date: Date())
        ]

        let docRef = db.collection("spins").document(user.uid)

        docRef.setData([
            "email": user.email ?? "anonymous",
            "spins": FieldValue.arrayUnion([spinEntry])
        ], merge: true) { error in
            if let error = error {
                print("HATA: Firestore güncellemesi başarısız - \(error.localizedDescription)")
            } else {
                print("Spin sonucu eklendi: \(label)")
            }
        }
    }
}

// MARK: - Supporting Views & Shapes
struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview
struct WheelSpinView_Previews: PreviewProvider {
    static var previews: some View {
        WheelSpinView(userName: "Kullanıcı", profileImageURL: nil)
            .environmentObject(PeerManager.shared)
            .environmentObject(SpinCoordinator())
            .preferredColorScheme(.dark)
    }
}
