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
///
/// With `onTapMuscle`, tapping a muscle — or near one, since some are only a few points
/// wide — reports it.
///
/// Every outline is a list of points joined by a smooth curve (see `smoothPath`), so the
/// shapes read as muscle rather than as a faceted mannequin. Muscles are kept a little apart
/// from each other so the silhouette shows through as thin separation lines.
struct BodyFigure: View {
    let side: BodySide
    var colors: [Muscle: Color] = [:]
    var onTapMuscle: ((Muscle) -> Void)?

    private struct Part {
        let muscle: Muscle
        /// Outline in a 100 × 210 space, on the figure's left half (screen left) unless
        /// `mirrored` is false; mirrored parts also draw a right-hand copy.
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
    private static let forearms = part(.forearms, [(14.5, 72), (21, 71.5), (22, 77), (18.5, 92), (13, 93), (12, 84)])

    private static let frontParts: [Part] = [
        part(.shoulders, [(30, 36), (24, 37.5), (20.5, 43), (20, 51), (23.5, 53), (27, 46), (31, 40)]),
        part(.chest, [(48.5, 38), (40, 37), (32.5, 40.5), (29.5, 46), (32, 52.5), (40, 56), (48.5, 54)]),
        part(.biceps, [(20.5, 56), (26, 55.5), (27, 61), (24.5, 69), (19.5, 69.5), (18, 63)]),
        forearms,
        // Six-pack: three rows plus the tapering lower abs, each side mirrored.
        part(.abs, [(43.5, 58.5), (49, 58), (49, 66.5), (43.5, 67)]),
        part(.abs, [(43.5, 69), (49, 68.5), (49, 77), (43.5, 77.5)]),
        part(.abs, [(43.5, 79.5), (49, 79), (49, 88), (44, 88.5)]),
        part(.abs, [(44, 90.5), (49, 90), (49, 104), (46.5, 102)]),
        part(.obliques, [(34, 60), (41.5, 60.5), (42, 74), (41.5, 88), (38.5, 91), (35.5, 82), (33.5, 70)]),
        part(.quads, [(34.5, 108), (41, 106), (46, 113), (45.5, 125), (42.5, 136), (39.5, 146.5), (36, 146.5), (33.5, 134), (33, 120)]),
        // Inner thigh: the adductors high up, the inner quad teardrop above the knee.
        part(.adductors, [(46.6, 109), (48.6, 111.5), (49.4, 116), (49.1, 123), (47.9, 129.5), (46.2, 131.5), (45.6, 128), (46.4, 121), (46.4, 114)]),
        part(.quads, [(48, 132.5), (48.4, 137.5), (47.6, 143), (44.5, 148), (41.5, 147.5), (43, 141), (46, 135)]),
        part(.calves, [(35.5, 158), (39, 156.5), (40.5, 167), (39, 183), (36.5, 180), (35, 169)]),
        part(.calves, [(43, 157), (46.5, 158.5), (46.5, 170), (44.5, 182), (42.5, 170)]),
    ]

    /// The muscles each side draws; forearms and shoulders are on both.
    static func muscles(on side: BodySide) -> Set<Muscle> {
        Set((side == .front ? frontParts : backParts).map(\.muscle))
    }

    private static let backParts: [Part] = [
        part(.traps, [(46.5, 25), (44.5, 30.5), (34, 34.5), (30.5, 37.5), (40, 42), (46, 52), (50, 64),
                      (54, 52), (60, 42), (69.5, 37.5), (66, 34.5), (55.5, 30.5), (53.5, 25)], mirrored: false),
        part(.shoulders, [(28.5, 37.5), (23.5, 38.5), (20.5, 43), (20, 51), (23.5, 53), (27.5, 46), (32, 41)]),
        part(.triceps, [(20, 55.5), (26, 55), (27, 61), (25, 69), (20, 69.5), (18, 62)]),
        forearms,
        part(.lats, [(44.5, 57), (38, 45.5), (32, 46), (31.5, 56), (35, 72), (40.5, 86), (45, 82), (46.5, 68)]),
        part(.lowerBack, [(48.5, 67), (49, 99), (43, 99.5), (42.5, 90), (46.5, 82)]),
        part(.glutes, [(49, 102), (40.5, 101.5), (34.5, 106), (33, 116), (37.5, 123), (45.5, 122.5), (49, 118)]),
        part(.hamstrings, [(34.5, 127), (40, 126), (41, 136), (39.5, 150), (36, 150), (33.5, 140)]),
        part(.hamstrings, [(42, 126), (45.4, 126.5), (45.8, 137), (45, 150), (41.5, 150), (42.5, 138)]),
        // The adductor magnus shows as a strip on the inside of the thigh, below the glutes.
        part(.adductors, [(46.7, 125.2), (49.2, 125.5), (49, 131.5), (47.9, 140), (46.8, 135)]),
        part(.calves, [(35.5, 157), (40.5, 155.5), (41, 167), (39.5, 180), (36.5, 177), (34.5, 167)]),
        part(.calves, [(42, 155.5), (46.5, 157), (47, 168), (44.5, 183), (41.5, 170)]),
    ]

    /// Left half of the whole body, from the side of the neck down the outside of the arm,
    /// back up its inside, down the torso and leg, ending at the crotch on the centre line.
    /// Mirrored and joined, it closes into one outline.
    private static let outline = pts([
        (45, 14), (44.5, 25), (44, 31), (36, 33), (27, 34.5), (21.5, 38.5), (18.5, 46), (17, 57), (14.5, 70),
        (11.5, 84), (9.5, 97), (7.5, 103), (7.5, 111), (11, 114.5), (14.5, 108), (15.5, 99),
        (19.5, 86), (23, 73), (27, 60), (29, 51), (31.5, 58), (33.5, 72), (35.5, 86), (33.5, 98),
        (32, 112), (32.5, 130), (35, 150), (34, 166), (36, 184), (38.5, 197), (35.5, 203.5),
        (37, 207.5), (46, 207.5), (46.5, 198), (46.5, 184), (47, 166), (47.5, 150), (48.5, 132),
        (49.5, 114), (50, 112),
    ])

    private static func mirror(_ points: [CGPoint]) -> [CGPoint] {
        points.map { CGPoint(x: 100 - $0.x, y: $0.y) }
    }

    /// A closed Catmull-Rom curve through `points` — passes through every point, with no
    /// corners anywhere.
    private static func smoothPath(_ points: [CGPoint]) -> Path {
        var path = Path()
        let n = points.count
        guard n > 2 else { return path }
        path.move(to: points[0])
        for i in 0..<n {
            let p0 = points[(i - 1 + n) % n], p1 = points[i]
            let p2 = points[(i + 1) % n], p3 = points[(i + 2) % n]
            path.addCurve(
                to: p2,
                control1: CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6),
                control2: CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
            )
        }
        path.closeSubpath()
        return path
    }

    /// How far outside a muscle, in the 100 × 210 space, a tap still picks it.
    private static let tapTolerance: CGFloat = 5

    /// The 100 × 210 space scaled to fit `size` and centred in it.
    private static func transform(for size: CGSize) -> CGAffineTransform {
        let scale = min(size.width / 100, size.height / 210)
        return CGAffineTransform(
            a: scale, b: 0, c: 0, d: scale,
            tx: (size.width - 100 * scale) / 2, ty: (size.height - 210 * scale) / 2
        )
    }

    /// The muscle under `location` in a figure drawn at `size`: the one containing it, else
    /// the nearest within `tapTolerance`.
    static func muscle(at location: CGPoint, in size: CGSize, side: BodySide) -> Muscle? {
        guard size.width > 0, size.height > 0 else { return nil }
        let point = location.applying(transform(for: size).inverted())
        var nearest: (muscle: Muscle, distance: CGFloat)?
        for part in side == .front ? frontParts : backParts {
            for points in part.mirrored ? [part.points, mirror(part.points)] : [part.points] {
                let path = smoothPath(points)
                if path.contains(point) { return part.muscle }
                let box = path.boundingRect
                let distance = hypot(max(box.minX - point.x, 0, point.x - box.maxX),
                                     max(box.minY - point.y, 0, point.y - box.maxY))
                if distance <= tapTolerance, distance < nearest?.distance ?? .infinity {
                    nearest = (part.muscle, distance)
                }
            }
        }
        return nearest?.muscle
    }

    private static let bodyPath = smoothPath(outline + mirror(outline).reversed())
    private static let headPath = Path(ellipseIn: CGRect(x: 40.5, y: 1.5, width: 19, height: 23))

    var body: some View {
        Canvas { context, size in
            let transform = Self.transform(for: size)
            let untrained = Color(.systemGray2)

            // Separate fills: as one path, the head and neck overlap would cancel out.
            for path in [Self.headPath, Self.bodyPath] {
                context.fill(path.applying(transform), with: .color(Color(.systemGray5)))
            }

            for part in side == .front ? Self.frontParts : Self.backParts {
                let color = colors[part.muscle] ?? untrained
                context.fill(Self.smoothPath(part.points).applying(transform), with: .color(color))
                if part.mirrored {
                    context.fill(Self.smoothPath(Self.mirror(part.points)).applying(transform), with: .color(color))
                }
            }
        }
        .aspectRatio(100.0 / 210.0, contentMode: .fit)
        .overlay {
            if let onTapMuscle {
                GeometryReader { proxy in
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            if let muscle = Self.muscle(at: location, in: proxy.size, side: side) {
                                onTapMuscle(muscle)
                            }
                        }
                }
            }
        }
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
