// Generates the start / end line drawings for the starter exercises Everkinetic has no
// drawing for. Each figure is built from capsules posed by joint angles; outlines come from
// stroking each layer's shapes, then clearing their inside, so nearer layers hide farther ones.
//
//   swiftc -O tools/exercise-drawings/draw.swift -o /tmp/draw
//   /tmp/draw <outDir>                     template PNGs: white lines on transparent
//   /tmp/draw <outDir> preview [slug]      black on white, for looking at
//
// Copy <slug>-start.png / -end.png into Assets.xcassets/Exercises/exercise-<slug>-*.imageset.
import CoreGraphics
import Foundation
import ImageIO

typealias P = CGPoint
func d(_ a: Double) -> P { P(x: cos(a * .pi / 180), y: sin(a * .pi / 180)) }
func + (a: P, b: P) -> P { P(x: a.x + b.x, y: a.y + b.y) }
func - (a: P, b: P) -> P { P(x: a.x - b.x, y: a.y - b.y) }
func * (a: P, k: Double) -> P { P(x: a.x * k, y: a.y * k) }
func len(_ a: P) -> Double { hypot(a.x, a.y) }
func angle(_ a: P) -> Double { atan2(a.y, a.x) * 180 / .pi }

// MARK: Shapes

func capsule(_ a: P, _ ra: Double, _ b: P, _ rb: Double) -> CGPath {
    let p = CGMutablePath()
    let dist = len(b - a)
    if dist <= abs(ra - rb) + 0.01 {
        let (c, r) = ra > rb ? (a, ra) : (b, rb)
        p.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
        return p
    }
    let th = atan2(b.y - a.y, b.x - a.x)
    let be = acos((ra - rb) / dist)
    p.addArc(center: a, radius: ra, startAngle: th + be, endAngle: th - be + 2 * .pi, clockwise: false)
    p.addArc(center: b, radius: rb, startAngle: th - be, endAngle: th + be, clockwise: false)
    p.closeSubpath()
    return p
}

func circle(_ c: P, _ r: Double) -> CGPath {
    CGPath(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r), transform: nil)
}

func ellipse(_ c: P, _ rx: Double, _ ry: Double, _ deg: Double) -> CGPath {
    var t = CGAffineTransform(translationX: c.x, y: c.y).rotated(by: deg * .pi / 180)
    return CGPath(ellipseIn: CGRect(x: -rx, y: -ry, width: 2 * rx, height: 2 * ry), transform: &t)
}

/// Rounded rect centered at c, w along `deg`, h across it.
func rrect(_ c: P, _ w: Double, _ h: Double, _ deg: Double = 0, _ corner: Double = 6) -> CGPath {
    var t = CGAffineTransform(translationX: c.x, y: c.y).rotated(by: deg * .pi / 180)
    let cr = min(corner, w / 2 - 0.1, h / 2 - 0.1)
    return CGPath(roundedRect: CGRect(x: -w / 2, y: -h / 2, width: w, height: h), cornerWidth: cr, cornerHeight: cr, transform: &t)
}

func rectFrom(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ corner: Double = 5) -> CGPath {
    rrect(P(x: (x0 + x1) / 2, y: (y0 + y1) / 2), x1 - x0, y1 - y0, 0, corner)
}

func line(_ pts: [P]) -> CGPath {
    let p = CGMutablePath()
    p.addLines(between: pts)
    return p
}

/// A segment across a limb at fraction t from a to b, for shorts hems and waistbands.
func across(_ a: P, _ b: P, _ t: Double, _ half: Double = 40) -> CGPath {
    let c = a + (b - a) * t
    let n = d(angle(b - a) + 90)
    return line([c - n * half, c + n * half])
}

struct Shape {
    var path: CGPath
    var z: Double
    var details: [CGPath] = []
    var filled = true
    var weight = 1.0
}

// MARK: Side-view figure (facing +x when upright)

struct Arm { var ua: Double; var fa: Double }
struct Leg { var th: Double; var sh: Double; var ft: Double = 0 }

struct Joints { var H, M, T, Sh, E, W, K, A, head: P; var fE, fW, fK, fA: P }

let L1 = 70.0, L2 = 85.0, UA = 92.0, FA = 82.0, TH = 118.0, SH = 112.0

func sideFigure(hip H: P, aL: Double = 90, aU: Double = 90, aH: Double? = nil,
                near: Arm, far: Arm? = nil, nearLeg: Leg, farLeg: Leg? = nil,
                farShift: P = P(x: -7, y: 5), armsBehindHead: Bool = false, z: Double = 0) -> ([Shape], Joints) {
    let aH = aH ?? aU
    let M = H + d(aL) * L1
    let T = M + d(aU) * L2
    let Sh = M + d(aU) * 70
    let n = d(aU - 90), nL = d(aL - 90)
    var shapes: [Shape] = []

    func arm(_ s: P, _ a: Arm, _ zz: Double) -> (P, P) {
        let e = s + d(a.ua) * UA, w = e + d(a.fa) * FA
        let p = CGMutablePath()
        p.addPath(capsule(s, 17, e, 13.5))
        p.addPath(capsule(e, 13, w, 10))
        p.addPath(circle(w + d(a.fa) * 9, 12.5))
        shapes.append(Shape(path: p, z: zz))
        return (e, w)
    }
    func leg(_ h: P, _ l: Leg, _ zz: Double) -> (P, P) {
        let k = h + d(l.th) * TH, a = k + d(l.sh) * SH
        let p = CGMutablePath()
        p.addPath(capsule(h, 24, k, 17))
        p.addPath(capsule(k, 16, a, 10.5))
        p.addPath(capsule(a - d(l.ft) * 9, 10, a + d(l.ft) * 36, 7.5))
        shapes.append(Shape(path: p, z: zz, details: [across(h, k, 0.5)]))
        return (k, a)
    }

    let farArm = far ?? near, fLeg = farLeg ?? nearLeg
    let (fE, fW) = arm(Sh + farShift, farArm, z)
    let (fK, fA) = leg(H + farShift, fLeg, z + 0.1)

    let torso = CGMutablePath()
    torso.addPath(capsule(H, 29, M, 31))
    torso.addPath(capsule(M, 31, T, 27))
    torso.addPath(circle(M + (T - M) * 0.45 + n * 6, 30))
    torso.addPath(circle(H - nL * 6 - d(aL) * 2, 27))
    torso.addPath(capsule(T - d(aH) * 6, 13, T + d(aH) * 18, 12))
    let head = T + d(aH) * 42
    torso.addPath(ellipse(head, 24, 30, aH - 90))
    shapes.append(Shape(path: torso, z: z + 1, details: [across(H, M, 0.2, 50)]))

    let (K, A) = leg(H, nearLeg, z + 2)
    let (E, W) = arm(Sh, near, armsBehindHead ? z + 0.9 : z + 3)
    return (shapes, Joints(H: H, M: M, T: T, Sh: Sh, E: E, W: W, K: K, A: A, head: head, fE: fE, fW: fW, fK: fK, fA: fA))
}

// MARK: Front-view figure

struct FLeg { var th: Double; var sh: Double; var thLen = TH; var shLen = SH }

func frontFigure(pelvis P0: P, left: Arm, right: Arm, leftLeg: FLeg, rightLeg: FLeg,
                 legsZ: Double = 0.5, z: Double = 0) -> ([Shape], (lW: P, rW: P)) {
    var shapes: [Shape] = []
    let C = P0 + P(x: 0, y: 105)
    let trunk = CGMutablePath()
    trunk.addPath(capsule(P0, 37, C, 43))
    trunk.addPath(capsule(P0 + P(x: -50, y: 128), 19, P0 + P(x: 50, y: 128), 19))
    trunk.addPath(capsule(P0 + P(x: 0, y: 138), 13, P0 + P(x: 0, y: 162), 12))
    trunk.addPath(ellipse(P0 + P(x: 0, y: 190), 24, 30, 0))
    let waist = line([P0 + P(x: -60, y: 14), P0 + P(x: 60, y: 14)])
    shapes.append(Shape(path: trunk, z: z + 1, details: [waist]))

    for (side, lg) in [(-1.0, leftLeg), (1.0, rightLeg)] {
        let h = P0 + P(x: 21 * side, y: -6)
        let k = h + d(lg.th) * lg.thLen, a = k + d(lg.sh) * lg.shLen
        let p = CGMutablePath()
        p.addPath(capsule(h, 24, k, 18))
        p.addPath(capsule(k, 17, a, 10.5))
        p.addPath(capsule(a + P(x: 0, y: -2), 11, a + P(x: 9 * side, y: -9), 10))
        let hem = lg.thLen > 60 ? [across(h, k, 0.45)] : []
        shapes.append(Shape(path: p, z: z + legsZ, details: hem))
    }
    var wrists: [P] = []
    for (side, a) in [(-1.0, left), (1.0, right)] {
        let s = P0 + P(x: 52 * side, y: 124)
        let e = s + d(a.ua) * UA, w = e + d(a.fa) * FA
        let p = CGMutablePath()
        p.addPath(capsule(s, 18, e, 13.5))
        p.addPath(capsule(e, 13, w, 10))
        p.addPath(circle(w + d(a.fa) * 9, 12.5))
        shapes.append(Shape(path: p, z: z + 2))
        wrists.append(w)
    }
    return (shapes, (wrists[0], wrists[1]))
}

// MARK: Equipment

/// A dumbbell whose handle lies in the picture plane along `deg`.
func dumbbell(_ c: P, _ deg: Double, z: Double) -> [Shape] {
    let u = d(deg)
    let p = CGMutablePath()
    p.addPath(capsule(c - u * 30, 5, c + u * 30, 5))
    p.addPath(rrect(c - u * 32, 17, 52, deg, 5))
    p.addPath(rrect(c + u * 32, 17, 52, deg, 5))
    p.addPath(rrect(c - u * 46, 11, 38, deg, 4))
    p.addPath(rrect(c + u * 46, 11, 38, deg, 4))
    return [Shape(path: p, z: z)]
}

func cable(_ a: P, _ b: P, z: Double) -> Shape {
    Shape(path: line([a, b]), z: z, filled: false, weight: 0.6)
}

func cableTower(x: Double, width: Double = 30, height: Double, pulleyY: Double, pulleyOnRight: Bool, z: Double) -> ([Shape], P) {
    let p = CGMutablePath()
    p.addPath(rectFrom(x - width / 2, 0, x + width / 2, height, 4))
    let px = x + (pulleyOnRight ? width / 2 + 6 : -width / 2 - 6)
    let pulley = P(x: px, y: pulleyY)
    p.addPath(circle(pulley, 12))
    p.addPath(rectFrom(x - width / 2 - 22, 0, x + width / 2 + 22, 12, 3))
    return ([Shape(path: p, z: z)], pulley)
}

// MARK: Poses

struct Pose { var shapes: [Shape] }

func facePull(_ end: Bool) -> Pose {
    let arm = end ? Arm(ua: 150, fa: 10) : Arm(ua: 10, fa: 12)
    let (fig, j) = sideFigure(hip: P(x: 0, y: 240), aL: 92, aU: end ? 97 : 93, aH: 92,
                              near: arm, far: Arm(ua: arm.ua + 3, fa: arm.fa + 3),
                              nearLeg: Leg(th: -82, sh: -95), farLeg: Leg(th: -102, sh: -96))
    let (tower, pulley) = cableTower(x: 345, height: 520, pulleyY: 430, pulleyOnRight: false, z: -1)
    let hand = j.W + d(arm.fa) * 18
    var s = fig + tower
    s.append(cable(hand, pulley, z: 2.5))
    s.append(Shape(path: line([hand, hand + P(x: 4, y: -34)]), z: 3.5, filled: false, weight: 0.6))
    return Pose(shapes: s)
}

func hipThrust(_ end: Bool) -> Pose {
    let bench = CGMutablePath()
    bench.addPath(rectFrom(-260, 100, -40, 124, 7))
    bench.addPath(rectFrom(-230, 0, -214, 100, 3))
    bench.addPath(rectFrom(-86, 0, -70, 100, 3))
    var s: [Shape] = [Shape(path: bench, z: -1)]
    if end {
        let (fig, j) = sideFigure(hip: P(x: 80, y: 152), aL: 180, aU: 179, aH: 172,
                                  near: Arm(ua: -15, fa: 46), nearLeg: Leg(th: -14, sh: -90), farShift: P(x: 6, y: 6))
        s += fig
        s.append(barbellEnd(j.H + P(x: 2, y: 32), z: 2.5))
    } else {
        let (fig, j) = sideFigure(hip: P(x: 50, y: 58), aL: 136, aU: 136, aH: 150,
                                  near: Arm(ua: -63, fa: 4), nearLeg: Leg(th: 33.6, sh: -79.4), farShift: P(x: 6, y: 6))
        s += fig
        s.append(barbellEnd(j.H + d(46) * 30, z: 2.5))
    }
    return Pose(shapes: s)
}

/// A barbell seen end-on: the near plate.
func barbellEnd(_ c: P, z: Double) -> Shape {
    Shape(path: circle(c, 36), z: z, details: [circle(c, 7), circle(c, 24)])
}

func plank(_ end: Bool) -> Pose {
    if end {
        let (fig, _) = sideFigure(hip: P(x: -139.8, y: 106 - 24.7), aL: 10, aU: 10, aH: 14,
                                  near: Arm(ua: -90, fa: 0), far: Arm(ua: -90, fa: 2),
                                  nearLeg: Leg(th: 190, sh: 190, ft: -70), farShift: P(x: -6, y: 5))
        return Pose(shapes: fig)
    }
    let H = P(x: 0, y: 106) - d(20) * 142
    let (fig, _) = sideFigure(hip: H, aL: 20, aU: 20, aH: 22,
                              near: Arm(ua: -90, fa: 0), far: Arm(ua: -90, fa: 2),
                              nearLeg: Leg(th: 198.5, sh: 180, ft: 180), farShift: P(x: -6, y: 5))
    return Pose(shapes: fig)
}

func hangingLegRaise(_ end: Bool) -> Pose {
    let tilt = end ? 104.0 : 93.0
    let (fig0, j0) = sideFigure(hip: P(x: 0, y: 0), aL: tilt, aU: tilt, aH: tilt - 14,
                                near: Arm(ua: 80, fa: 82), far: Arm(ua: 82, fa: 84),
                                nearLeg: end ? Leg(th: 2, sh: 6, ft: 80) : Leg(th: -90, sh: -92, ft: -60),
                                farLeg: end ? Leg(th: 5, sh: 9, ft: 82) : Leg(th: -94, sh: -94, ft: -62),
                                armsBehindHead: true)
    // Hang from the bar: move the figure so the hand meets it.
    let grip = j0.W + d(82) * 9
    let bar = P(x: 0, y: 640)
    let shift = bar - grip
    var t = CGAffineTransform(translationX: shift.x, y: shift.y)
    var s = fig0.map { sh -> Shape in
        var c = sh
        c.path = sh.path.copy(using: &t)!
        c.details = sh.details.map { $0.copy(using: &t)! }
        return c
    }
    s.append(Shape(path: circle(bar, 11), z: 2.5))
    s.append(Shape(path: line([bar + P(x: -60, y: 0), bar + P(x: 60, y: 0)]), z: -1, filled: false, weight: 0.5))
    return Pose(shapes: s)
}

func dumbbellShoulderPress(_ end: Bool) -> Pose {
    let P0 = P(x: 0, y: 170)
    let bench = CGMutablePath()
    bench.addPath(rectFrom(-95, 118, 95, 140, 7))
    bench.addPath(rectFrom(-62, 140, 62, 390, 12))
    bench.addPath(rectFrom(-10, 0, 10, 118, 3))
    bench.addPath(rectFrom(-80, 0, 80, 12, 3))
    let lA = end ? Arm(ua: 98, fa: 94) : Arm(ua: 182, fa: 90)
    let rA = Arm(ua: 180 - lA.ua, fa: 180 - lA.fa)
    let (fig, w) = frontFigure(pelvis: P0, left: lA, right: rA,
                               leftLeg: FLeg(th: -140, sh: -95, thLen: 40),
                               rightLeg: FLeg(th: -40, sh: -85, thLen: 40), legsZ: 1.5)
    var s = [Shape(path: bench, z: -1)] + fig
    s += dumbbell(w.lW + P(x: 0, y: 6), 0, z: 1.8)
    s += dumbbell(w.rW + P(x: 0, y: 6), 0, z: 1.8)
    return Pose(shapes: s)
}

func cableLateralRaise(_ end: Bool) -> Pose {
    let P0 = P(x: 0, y: 250)
    let right = end ? Arm(ua: 4, fa: -2) : Arm(ua: -110, fa: -125)
    let (fig, w) = frontFigure(pelvis: P0, left: Arm(ua: -96, fa: -93), right: right,
                               leftLeg: FLeg(th: -92, sh: -91), rightLeg: FLeg(th: -88, sh: -89))
    let (tower, pulley) = cableTower(x: -215, height: 520, pulleyY: 40, pulleyOnRight: true, z: -1)
    var s = fig + tower
    s.append(cable(w.rW + d(right.fa) * 10, pulley, z: 1.6))
    return Pose(shapes: s)
}

func machineShoulderPress(_ end: Bool) -> Pose {
    let H = P(x: 0, y: 145)
    let lean = 98.0
    let frame = CGMutablePath()
    frame.addPath(rectFrom(-62, 100, 62, 120, 7))
    frame.addPath(rectFrom(-12, 0, 12, 100, 3))
    frame.addPath(rectFrom(-200, 0, 80, 12, 3))
    frame.addPath(rectFrom(-185, 0, -161, 345, 4))
    let padC = H + d(lean) * 120 + d(lean + 90) * 43
    frame.addPath(rrect(padC, 230, 24, lean, 10))
    let arm = end ? Arm(ua: 82, fa: 84) : Arm(ua: -38, fa: 99)
    let (fig, j) = sideFigure(hip: H, aL: lean, aU: lean, aH: 94,
                              near: arm, far: Arm(ua: arm.ua + 2, fa: arm.fa + 1),
                              nearLeg: Leg(th: -12, sh: -92), farLeg: Leg(th: -14, sh: -96))
    let pivot = P(x: -173, y: 334)
    let grip = j.W + d(arm.fa) * 9
    var s = [Shape(path: frame, z: -2)]
    s.append(Shape(path: capsule(pivot, 10, grip, 9), z: -1, details: []))
    s.append(Shape(path: circle(pivot, 15), z: -0.9))
    s.append(Shape(path: capsule(grip + P(x: 0, y: -24), 8, grip + P(x: 0, y: 24), 8), z: 2.9))
    s += fig
    return Pose(shapes: s)
}

func chestSupportedRow(_ end: Bool) -> Pose {
    let tilt = 35.0
    let c0 = P(x: -40, y: 245)
    let bench = CGMutablePath()
    bench.addPath(rectFrom(-48, 0, -28, 238, 3))
    bench.addPath(rectFrom(-160, 0, 90, 12, 3))
    let pad = rrect(c0, 230, 24, tilt, 10)
    let H = c0 + d(tilt) * -110 + d(tilt + 90) * 42
    let arm = end ? Arm(ua: 190, fa: -90) : Arm(ua: -90, fa: -90)
    let (fig, j) = sideFigure(hip: H, aL: tilt, aU: tilt, aH: 42,
                              near: arm, far: Arm(ua: arm.ua + 2, fa: -90),
                              nearLeg: Leg(th: 248, sh: 240), farLeg: Leg(th: 244, sh: 236),
                              farShift: P(x: -5, y: 6))
    var s = [Shape(path: bench, z: -2), Shape(path: pad, z: 0.5)]
    s += fig
    s += dumbbell(j.W + P(x: 0, y: -8), 0, z: 3.5)
    s += dumbbell(j.fW + P(x: 0, y: -8), 0, z: -0.5)
    return Pose(shapes: s)
}

func machineAbCrunch(_ end: Bool) -> Pose {
    let H = P(x: 0, y: 145)
    let frame = CGMutablePath()
    frame.addPath(rectFrom(-62, 100, 62, 120, 7))
    frame.addPath(rectFrom(-12, 0, 12, 100, 3))
    frame.addPath(rectFrom(-110, 0, 175, 12, 3))
    let padC = H + d(96) * 125 + d(186) * 44
    frame.addPath(rrect(padC, 220, 24, 96, 10))
    frame.addPath(rectFrom(-80, 0, -60, padC.y, 3))
    frame.addPath(rectFrom(150, 0, 166, 64, 3))
    frame.addPath(circle(P(x: 158, y: 64), 17))
    frame.addPath(circle(P(x: 158, y: 64), 5))
    let aL = end ? 62.0 : 95.0, aU = end ? 32.0 : 95.0
    let arm = end ? Arm(ua: -95, fa: 55) : Arm(ua: -30, fa: 120)
    let (fig, j) = sideFigure(hip: H, aL: aL, aU: aU, aH: end ? 14 : 92,
                              near: arm, far: Arm(ua: arm.ua + 2, fa: arm.fa + 2),
                              nearLeg: Leg(th: -8, sh: -96), farLeg: Leg(th: -10, sh: -99))
    let pivot = P(x: -9.7, y: 158)
    let grip = j.W + d(arm.fa) * 9
    var s = [Shape(path: frame, z: -2)]
    s.append(Shape(path: capsule(pivot, 10, grip, 9), z: -1))
    s.append(Shape(path: capsule(grip - d(arm.fa + 90) * 22, 8, grip + d(arm.fa + 90) * 22, 8), z: 3.5))
    s += fig
    return Pose(shapes: s)
}

let exercises: [(String, (Bool) -> Pose)] = [
    ("face-pull", facePull),
    ("hip-thrust", hipThrust),
    ("plank", plank),
    ("hanging-leg-raise", hangingLegRaise),
    ("dumbbell-shoulder-press", dumbbellShoulderPress),
    ("cable-lateral-raise", cableLateralRaise),
    ("machine-shoulder-press", machineShoulderPress),
    ("chest-supported-dumbbell-row", chestSupportedRow),
    ("machine-ab-crunch", machineAbCrunch),
]

// MARK: Rendering

let lineWidth = 6.5
let pad = 14.0
let maxSide = 600.0

func bounds(_ shapes: [Shape]) -> CGRect {
    shapes.reduce(CGRect.null) { $0.union($1.path.boundingBoxOfPath) }
}

func render(_ shapes: [Shape], scale s: Double, preview: Bool) -> CGImage {
    let b = bounds(shapes).insetBy(dx: -lineWidth / s, dy: -lineWidth / s)
    let w = Int(ceil(b.width * s + 2 * pad)), h = Int(ceil(b.height * s + 2 * pad))
    let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    if preview {
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
    }
    ctx.translateBy(x: pad - b.minX * s, y: pad - b.minY * s)
    ctx.scaleBy(x: s, y: s)
    let ink = preview ? CGColor(red: 0, green: 0, blue: 0, alpha: 1) : CGColor(red: 1, green: 1, blue: 1, alpha: 1)
    let paper = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    let lw = lineWidth / s
    for z in Set(shapes.map(\.z)).sorted() {
        let group = shapes.filter { $0.z == z }
        let filled = group.filter(\.filled)
        ctx.setStrokeColor(ink)
        ctx.setBlendMode(.normal)
        if !filled.isEmpty {
            for f in filled { ctx.addPath(f.path) }
            ctx.setLineWidth(2 * lw)
            ctx.strokePath()
            for f in filled { ctx.addPath(f.path) }
            if preview { ctx.setFillColor(paper) } else { ctx.setBlendMode(.clear) }
            ctx.fillPath(using: .winding)
            ctx.setBlendMode(.normal)
        }
        ctx.setLineWidth(lw)
        for f in filled where !f.details.isEmpty {
            ctx.saveGState()
            ctx.addPath(f.path)
            ctx.clip()
            for dt in f.details { ctx.addPath(dt) }
            ctx.setLineWidth(lw * 0.8)
            ctx.strokePath()
            ctx.restoreGState()
        }
        for f in group where !f.filled {
            ctx.addPath(f.path)
            ctx.setLineWidth(lw * f.weight)
            ctx.strokePath()
        }
    }
    return ctx.makeImage()!
}

func save(_ img: CGImage, _ path: String) {
    let dst = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(dst, img, nil)
    CGImageDestinationFinalize(dst)
}

let out = CommandLine.arguments[1]
let preview = CommandLine.arguments.count > 2
let only = CommandLine.arguments.count > 3 ? CommandLine.arguments[3] : nil
for (slug, make) in exercises where only == nil || only == slug {
    let start = make(false).shapes, end = make(true).shapes
    let biggest = max(bounds(start).width, bounds(start).height, bounds(end).width, bounds(end).height)
    let s = (maxSide - 2 * pad) / (biggest + 2 * lineWidth)
    save(render(start, scale: s, preview: preview), "\(out)/\(slug)-start.png")
    save(render(end, scale: s, preview: preview), "\(out)/\(slug)-end.png")
}
