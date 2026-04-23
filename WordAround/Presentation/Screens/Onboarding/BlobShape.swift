import SwiftUI

struct BlobShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: 0.12 * w, y: 0.24 * h))

        path.addCurve(
            to: CGPoint(x: 0.70 * w, y: 0.08 * h),
            control1: CGPoint(x: 0.20 * w, y: 0.02 * h),
            control2: CGPoint(x: 0.53 * w, y: -0.02 * h)
        )

        path.addCurve(
            to: CGPoint(x: 0.96 * w, y: 0.42 * h),
            control1: CGPoint(x: 0.92 * w, y: 0.12 * h),
            control2: CGPoint(x: 1.05 * w, y: 0.24 * h)
        )

        path.addCurve(
            to: CGPoint(x: 0.84 * w, y: 0.88 * h),
            control1: CGPoint(x: 0.90 * w, y: 0.70 * h),
            control2: CGPoint(x: 1.00 * w, y: 0.92 * h)
        )

        path.addCurve(
            to: CGPoint(x: 0.28 * w, y: 0.96 * h),
            control1: CGPoint(x: 0.62 * w, y: 0.92 * h),
            control2: CGPoint(x: 0.40 * w, y: 1.06 * h)
        )

        path.addCurve(
            to: CGPoint(x: 0.04 * w, y: 0.56 * h),
            control1: CGPoint(x: 0.04 * w, y: 0.82 * h),
            control2: CGPoint(x: -0.04 * w, y: 0.68 * h)
        )

        path.addCurve(
            to: CGPoint(x: 0.12 * w, y: 0.24 * h),
            control1: CGPoint(x: 0.10 * w, y: 0.44 * h),
            control2: CGPoint(x: -0.02 * w, y: 0.28 * h)
        )

        path.closeSubpath()
        return path
    }
}
