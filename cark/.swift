//
//  WheelCircleView.swift
//  cark
//
//  Created by Doğan Topcu on 16.06.2025.
//

import SwiftUI

struct WheelCircleView: View {
    var rotationAngle: Angle
    var showDiamond: Bool
    var workOrWatchLabel: String
    var profileImage: Image?

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: [.red, .green, .blue, .yellow, .purple, .orange]),
                        center: .center
                    )
                )
                .frame(width: 300, height: 300)
                .rotationEffect(rotationAngle)

            if showDiamond {
                Diamond()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(45))
            }

            VStack(spacing: 10) {
                if let image = profileImage {
                    image
                        .resizable()
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .frame(width: 60, height: 60)
                }

                Text(workOrWatchLabel)
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
    }
}

struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        path.move(to: CGPoint(x: center.x, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: center.y))
        path.addLine(to: CGPoint(x: center.x, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: center.y))
        path.closeSubpath()
        return path
    }
}
