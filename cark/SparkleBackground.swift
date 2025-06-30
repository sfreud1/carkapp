import SwiftUI

/// Ekranın tamamını kaplayan yıldız/parıltı animasyonu
struct SparkleBackground: View {
    var body: some View {
        ZStack {
            // Küçük beyaz pikseller
            GeometryReader { _ in
                Canvas { context, size in
                    for _ in 0..<100 {
                        let x = CGFloat.random(in: 0..<size.width)
                        let y = CGFloat.random(in: 0..<size.height)
                        let rect = CGRect(x: x, y: y, width: 2, height: 2)
                        context.fill(Path(ellipseIn: rect),
                                     with: .color(.white.opacity(0.25)))
                    }
                }
                .ignoresSafeArea()
            }
            // Daha büyük (bulanık) daireler
            ZStack {
                ForEach(0..<60, id: \.self) { _ in
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width:  .random(in: 1...3),
                               height: .random(in: 1...3))
                        .position(
                            x: .random(in: 0...UIScreen.main.bounds.width),
                            y: .random(in: 0...UIScreen.main.bounds.height)
                        )
                        .opacity(Double.random(in: 0.1...0.6))
                        .blur(radius: 0.5)
                        .animation(
                            .easeInOut(duration: .random(in: 1...3))
                                .repeatForever(),
                            value: UUID()
                        )
                }
            }
            // Koyu degrade arkaplan
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
