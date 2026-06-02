import SwiftUI

struct StatBlobShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(
            to: CGPoint(
                x: rect.minX + rect.width * 0.12,
                y: rect.minY + rect.height * 0.52
            )
        )

        path.addCurve(
            to: CGPoint(
                x: rect.minX + rect.width * 0.36,
                y: rect.minY + rect.height * 0.14
            ),
            control1: CGPoint(
                x: rect.minX + rect.width * 0.08,
                y: rect.minY + rect.height * 0.28
            ),
            control2: CGPoint(
                x: rect.minX + rect.width * 0.20,
                y: rect.minY + rect.height * 0.14
            )
        )

        path.addCurve(
            to: CGPoint(
                x: rect.minX + rect.width * 0.78,
                y: rect.minY + rect.height * 0.10
            ),
            control1: CGPoint(
                x: rect.minX + rect.width * 0.52,
                y: rect.minY + rect.height * 0.14
            ),
            control2: CGPoint(
                x: rect.minX + rect.width * 0.58,
                y: rect.minY + rect.height * 0.00
            )
        )

        path.addCurve(
            to: CGPoint(
                x: rect.maxX,
                y: rect.minY + rect.height * 0.48
            ),
            control1: CGPoint(
                x: rect.minX + rect.width * 0.96,
                y: rect.minY + rect.height * 0.20
            ),
            control2: CGPoint(
                x: rect.maxX,
                y: rect.minY + rect.height * 0.30
            )
        )

        path.addCurve(
            to: CGPoint(
                x: rect.minX + rect.width * 0.82,
                y: rect.maxY
            ),
            control1: CGPoint(
                x: rect.maxX,
                y: rect.minY + rect.height * 0.72
            ),
            control2: CGPoint(
                x: rect.minX + rect.width * 0.98,
                y: rect.maxY
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.minX + rect.width * 0.30,
                y: rect.maxY
            )
        )

        path.addCurve(
            to: CGPoint(
                x: rect.minX + rect.width * 0.12,
                y: rect.minY + rect.height * 0.52
            ),
            control1: CGPoint(
                x: rect.minX + rect.width * 0.08,
                y: rect.maxY
            ),
            control2: CGPoint(
                x: rect.minX,
                y: rect.minY + rect.height * 0.76
            )
        )

        path.closeSubpath()
        return path
    }
}
