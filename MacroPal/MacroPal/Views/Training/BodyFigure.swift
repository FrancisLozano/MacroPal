//
//  BodyFigure.swift
//  MacroPal
//

import SwiftUI

enum BodySide {
    case front, back
}

/// Colors for the six levels, Beginner → World Class, matching the legend.
enum LevelPalette {
    static let colors: [Color] = [
        Color(red: 0.90, green: 0.32, blue: 0.27), // Beginner
        Color(red: 0.96, green: 0.60, blue: 0.20), // Novice
        Color(red: 0.36, green: 0.73, blue: 0.36), // Intermediate
        Color(red: 0.25, green: 0.52, blue: 0.93), // Advanced
        Color(red: 0.60, green: 0.36, blue: 0.85), // Elite
        Color(red: 0.93, green: 0.36, blue: 0.68), // World Class
    ]

    /// `level` is 1…6 (0 = untrained, which isn't a palette color).
    static func color(forLevel level: Int) -> Color {
        colors[min(max(level, 1), colors.count) - 1]
    }
}

/// A stylized front or back figure whose muscles are filled from `colors`. Muscles missing
/// from `colors` draw in the neutral "untrained" gray.
struct BodyFigure: View {
    let side: BodySide
    var colors: [Muscle: Color] = [:]

    private struct Part {
        let muscle: Muscle
        /// Left-half outline in a 100 × 210 space; `mirrored` adds the right-hand copy.
        let points: [CGPoint]
        let mirrored: Bool
    }

    private static func pts(_ raw: [(Double, Double)]) -> [CGPoint] {
        raw.map { CGPoint(x: $0.0, y: $0.1) }
    }

    private static func part(_ muscle: Muscle, _ raw: [(Double, Double)], mirrored: Bool = true) -> Part {
        Part(muscle: muscle, points: pts(raw), mirrored: mirrored)
    }

    // Shared by both sides.
    private static let shoulders = part(.shoulders, [(29, 30), (21, 34), (18, 44), (24, 48), (30, 42), (31, 33)])
    private static let forearms = part(.forearms, [(15, 67), (22, 68), (20, 86), (17, 98), (11, 98), (13, 84)])
    private static let upperArm: [(Double, Double)] = [(18, 49), (25, 50), (25, 63), (21, 67), (15, 63)]

    // Drawn back-to-front, so later parts sit on top of earlier ones.
    private static let frontParts: [Part] = [
        part(.quads, [(36, 106), (49, 106), (48, 130), (46, 148), (37, 148), (33, 130)]),
        part(.calves, [(36, 158), (45, 158), (44, 190), (38, 194), (35, 176)]),
        part(.obliques, [(36, 54), (43, 54), (43, 92), (37, 90), (35, 72)]),
        part(.abs, [(44, 52), (56, 52), (56, 92), (44, 92)], mirrored: false),
        part(.chest, [(49, 31), (37, 30), (31, 35), (31, 44), (37, 50), (49, 49)]),
        shoulders,
        part(.biceps, upperArm),
        forearms,
    ]

    private static let backParts: [Part] = [
        part(.lats, [(49, 54), (41, 42), (33, 46), (34, 62), (40, 84), (49, 86)]),
        part(.lowerBack, [(50, 86), (44, 86), (43, 98), (50, 98)]),
        part(.glutes, [(50, 100), (36, 100), (34, 114), (40, 122), (50, 120)]),
        part(.hamstrings, [(49, 124), (35, 122), (33, 140), (36, 150), (47, 150), (48, 138)]),
        part(.calves, [(36, 156), (45, 156), (45, 176), (42, 190), (37, 184), (35, 170)]),
        shoulders,
        part(.triceps, upperArm),
        forearms,
        part(.traps, [(50, 24), (40, 28), (33, 32), (41, 40), (50, 52)]),
    ]

    // Silhouette pieces (left half; mirrored). Torso runs top-centre to bottom-centre so its
    // mirror closes into a single outline.
    private static let torso = pts([(50, 26), (38, 27), (28, 30), (26, 38), (32, 52), (35, 70), (37, 90), (35, 104), (50, 106)])
    private static let arm = pts([(28, 29), (20, 33), (15, 62), (11, 98), (10, 108), (17, 109), (19, 98), (24, 66), (31, 46)])
    private static let leg = pts([(35, 102), (32, 128), (35, 152), (34, 174), (37, 198), (35, 207), (45, 207), (45, 198), (46, 174), (47, 152), (49, 128), (50, 110), (50, 102)])
    private static let neck = pts([(46, 19), (54, 19), (54, 27), (46, 27)])

    private static func mirror(_ points: [CGPoint]) -> [CGPoint] {
        points.map { CGPoint(x: 100 - $0.x, y: $0.y) }
    }

    private static func path(_ points: [CGPoint]) -> Path {
        var path = Path()
        path.addLines(points)
        path.closeSubpath()
        return path
    }

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width / 100, size.height / 210)
            let transform = CGAffineTransform(
                a: scale, b: 0, c: 0, d: scale,
                tx: (size.width - 100 * scale) / 2, ty: (size.height - 210 * scale) / 2
            )
            let silhouette = Color(.systemGray5)
            let untrained = Color(.systemGray3)

            func fill(_ path: Path, _ color: Color) {
                let scaled = path.applying(transform)
                context.fill(scaled, with: .color(color))
                // A same-color stroke rounds the polygon corners so shapes read as muscle.
                context.stroke(scaled, with: .color(color), style: StrokeStyle(lineWidth: 1.5 * scale, lineJoin: .round))
            }

            fill(Path(ellipseIn: CGRect(x: 41.5, y: 3.5, width: 17, height: 17)), silhouette)
            fill(Self.path(Self.neck), silhouette)
            fill(Self.path(Self.torso + Self.mirror(Self.torso).reversed()), silhouette)
            for outline in [Self.arm, Self.leg] {
                fill(Self.path(outline), silhouette)
                fill(Self.path(Self.mirror(outline)), silhouette)
            }

            for part in side == .front ? Self.frontParts : Self.backParts {
                let color = colors[part.muscle] ?? untrained
                fill(Self.path(part.points), color)
                if part.mirrored {
                    fill(Self.path(Self.mirror(part.points)), color)
                }
            }
        }
        .aspectRatio(100.0 / 210.0, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

#Preview {
    HStack {
        BodyFigure(side: .front, colors: [.chest: LevelPalette.color(forLevel: 4), .quads: LevelPalette.color(forLevel: 2), .abs: LevelPalette.color(forLevel: 1)])
        BodyFigure(side: .back, colors: [.lats: LevelPalette.color(forLevel: 3), .glutes: LevelPalette.color(forLevel: 5), .hamstrings: LevelPalette.color(forLevel: 6)])
    }
    .frame(height: 300)
    .padding()
}
