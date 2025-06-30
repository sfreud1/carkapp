import SwiftUI

/// Çarkın dairesel gövdesi + ikon/etiketler
struct WheelShapeView: View {
    let rotationAngle: Double
    let profileImageURL: URL?
    let options: [(label: String, color: Color)]

    var body: some View {
        ZStack {
            // Üstteki altın renkli ok
            Diamond()
                .fill(Color(red: 212/255, green: 175/255, blue: 55/255))
                .frame(width: 30, height: 30)
                .rotationEffect(.degrees(180))
                .offset(y: -165)
                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                .zIndex(1)

            // Çark gövdesi
            ZStack {
                Circle()
                    .strokeBorder(Color.white, lineWidth: 8)
                    .background(
                        Circle()
                            .fill(Self.angularGradient)
                    )
                    .frame(width: 300, height: 300)

                // Profil resmi (varsa) veya merkezdeki sarı nokta
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
                            .stroke(Color(red: 212/255, green: 175/255, blue: 55/255),
                                    lineWidth: 4)
                    )
                    .zIndex(2)
                } else {
                    Circle()
                        .fill(Color(red: 240/255, green: 230/255, blue: 140/255))
                        .frame(width: 25, height: 25)
                        .overlay(
                            Circle()
                                .stroke(Color(red: 212/255, green: 175/255, blue: 55/255),
                                        lineWidth: 4)
                        )
                }

                // Sabit etiketler
                HStack(spacing: 8) {
                    Image(systemName: "briefcase.fill")
                    Text("Work")
                }
                .font(.system(size: 19.2, weight: .semibold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                .offset(y: -75)

                HStack(spacing: 8) {
                    Image(systemName: "film.fill")
                    Text("Watch Movie")
                }
                .font(.system(size: 19.2, weight: .semibold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                .offset(y: 75)
            }
            .rotationEffect(.degrees(rotationAngle))
            .shadow(color: .black.opacity(0.2), radius: 25, x: 0, y: 10)
            .shadow(color: .white.opacity(0.1), radius: 10)
        }
    }

    /// Önceden uzun satır olan gradient sabiti
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
