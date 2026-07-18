import AppKit
import Darwin
import Foundation

private struct SessionState: Codable {
    var action: String
    var startedAt: TimeInterval
    var updatedAt: TimeInterval
}

private let staleInterval: TimeInterval = 30 * 60
private let appearanceDelay: TimeInterval = 6

private enum AppLanguage: String {
    case simplifiedChinese = "zh"
    case english = "en"

    static var system: AppLanguage {
        guard let preferred = Locale.preferredLanguages.first?.lowercased(), preferred.hasPrefix("zh") else {
            return .english
        }
        return .simplifiedChinese
    }

    static func previewOverride(_ value: String?) -> AppLanguage {
        guard let value else { return .system }
        return AppLanguage(rawValue: value.lowercased()) ?? .english
    }

    var header: String {
        switch self {
        case .simplifiedChinese: return "VIBE LIVING · 动一动"
        case .english: return "VIBE LIVING · MOVE"
        }
    }

    var pause: String {
        switch self {
        case .simplifiedChinese: return "双击暂停"
        case .english: return "DOUBLE-CLICK TO PAUSE"
        }
    }
}

private struct ExerciseCopy {
    let title: String
    let hint: String
}

// Keep every prompt quiet, low-amplitude, and within one person's desk space.
// Avoid jumping, marching, deep squats, fast arm swings, or equipment.
private enum Exercise: Int, CaseIterable {
    case shoulderRoll
    case seatedTwist
    case wristStretch
    case standReset
    case drinkWater

    func copy(for language: AppLanguage) -> ExerciseCopy {
        switch (self, language) {
        case (.shoulderRoll, .simplifiedChinese):
            return ExerciseCopy(title: "肩膀慢慢画圈", hint: "动作小一点，保持呼吸")
        case (.seatedTwist, .simplifiedChinese):
            return ExerciseCopy(title: "坐姿轻柔转体", hint: "骨盆不动，小幅转动上身")
        case (.wristStretch, .simplifiedChinese):
            return ExerciseCopy(title: "放松手腕和手指", hint: "双手留在身前，轻轻活动")
        case (.standReset, .simplifiedChinese):
            return ExerciseCopy(title: "安静起身，换个姿势", hint: "留在工位旁，缓慢站稳")
        case (.drinkWater, .simplifiedChinese):
            return ExerciseCopy(title: "喝一口水", hint: "手边有水时，小口慢饮")
        case (.shoulderRoll, .english):
            return ExerciseCopy(title: "Slow shoulder circles", hint: "Keep it small and breathe")
        case (.seatedTwist, .english):
            return ExerciseCopy(title: "Gentle seated twist", hint: "Keep hips still; turn gently")
        case (.wristStretch, .english):
            return ExerciseCopy(title: "Relax wrists and fingers", hint: "Hands in front; move gently")
        case (.standReset, .english):
            return ExerciseCopy(title: "Stand and reset posture", hint: "Stay by your desk; rise slowly")
        case (.drinkWater, .english):
            return ExerciseCopy(title: "Take a sip of water", hint: "If water is nearby, sip slowly")
        }
    }
}

private func safeName(_ value: String) -> String {
    let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_.-"))
    let mapped = value.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
    return String(mapped.prefix(120))
}

private func stateDirectory(_ dataDirectory: URL) -> URL {
    dataDirectory.appendingPathComponent("sessions", isDirectory: true)
}

private func stateURL(_ dataDirectory: URL, sessionID: String) -> URL {
    stateDirectory(dataDirectory).appendingPathComponent("\(safeName(sessionID)).json")
}

private func readState(_ url: URL) -> SessionState? {
    guard let data = try? Data(contentsOf: url) else { return nil }
    return try? JSONDecoder().decode(SessionState.self, from: data)
}

private func writeState(action: String, sessionID: String, dataDirectory: URL) {
    let manager = FileManager.default
    let directory = stateDirectory(dataDirectory)
    try? manager.createDirectory(at: directory, withIntermediateDirectories: true)
    let url = stateURL(dataDirectory, sessionID: sessionID)

    if action == "done" {
        try? manager.removeItem(at: url)
        return
    }

    let now = Date().timeIntervalSince1970
    let previous = readState(url)
    let startedAt: TimeInterval
    if let previous, previous.action == "working" || previous.action == "waiting" {
        startedAt = previous.startedAt
    } else {
        startedAt = now
    }
    let state = SessionState(action: action, startedAt: startedAt, updatedAt: now)
    guard let data = try? JSONEncoder().encode(state) else { return }
    try? data.write(to: url, options: .atomic)
}

private func daemonIsRunning(_ dataDirectory: URL) -> Bool {
    let pidURL = dataDirectory.appendingPathComponent("daemon.pid")
    guard
        let text = try? String(contentsOf: pidURL, encoding: .utf8),
        let pid = Int32(text.trimmingCharacters(in: .whitespacesAndNewlines)),
        pid > 0
    else { return false }
    return kill(pid, 0) == 0
}

private func startDaemonIfNeeded(_ dataDirectory: URL) {
    guard !daemonIsRunning(dataDirectory) else { return }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
    process.arguments = ["--daemon", dataDirectory.path]
    process.standardInput = FileHandle.nullDevice
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    do {
        try process.run()
        Thread.sleep(forTimeInterval: 0.12)
    } catch {
        return
    }
}

private final class CoachView: NSView {
    var workingSince: TimeInterval = Date().timeIntervalSince1970
    var dataDirectory: URL
    private let language: AppLanguage
    private var animationTimer: Timer?

    init(frame frameRect: NSRect, dataDirectory: URL, language: AppLanguage = .system) {
        self.dataDirectory = dataDirectory
        self.language = language
        super.init(frame: frameRect)
        wantsLayer = true
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 12.0, repeats: true) { [weak self] _ in
            self?.needsDisplay = true
        }
    }

    required init?(coder: NSCoder) { nil }

    override var acceptsFirstResponder: Bool { false }

    override func mouseDown(with event: NSEvent) {
        guard event.clickCount >= 2 else { return }
        let until = Date().addingTimeInterval(10 * 60).timeIntervalSince1970
        let pauseURL = dataDirectory.appendingPathComponent("paused-until")
        try? String(until).write(to: pauseURL, atomically: true, encoding: .utf8)
        window?.orderOut(nil)
    }

    private func drawText(_ value: String, at point: NSPoint, size: CGFloat, color: NSColor, weight: NSFont.Weight = .regular) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: color
        ]
        (value as NSString).draw(at: point, withAttributes: attributes)
    }

    private func pixelLine(_ context: CGContext, from: CGPoint, to: CGPoint, width: CGFloat = 8) {
        context.setLineWidth(width)
        context.setLineCap(.butt)
        context.move(to: CGPoint(x: round(from.x), y: round(from.y)))
        context.addLine(to: CGPoint(x: round(to.x), y: round(to.y)))
        context.strokePath()
    }

    private func rotatedPoint(_ point: CGPoint, around pivot: CGPoint, by angle: CGFloat) -> CGPoint {
        let offsetX = point.x - pivot.x
        let offsetY = point.y - pivot.y
        return CGPoint(
            x: pivot.x + offsetX * cos(angle) - offsetY * sin(angle),
            y: pivot.y + offsetX * sin(angle) + offsetY * cos(angle)
        )
    }

    private func drawRelaxedHand(
        _ context: CGContext,
        wrist: CGPoint,
        mirror: CGFloat,
        wristAngle: CGFloat,
        fingerPhase: CGFloat
    ) {
        let palmBase = CGPoint(x: wrist.x, y: wrist.y - 8)
        let palm = rotatedPoint(palmBase, around: wrist, by: wristAngle)
        pixelLine(context, from: wrist, to: palm, width: 5)

        let fingerOffsets: [(CGFloat, CGFloat)] = [(-4, -8), (0, -10), (4, -8)]
        for (index, offset) in fingerOffsets.enumerated() {
            let fingerAngle = sin((fingerPhase + CGFloat(index) * 0.19) * .pi * 2) * 0.05
            let unrotatedTip = CGPoint(x: palmBase.x + offset.0, y: palmBase.y + offset.1)
            let relaxedTip = rotatedPoint(unrotatedTip, around: palmBase, by: fingerAngle * mirror)
            let tip = rotatedPoint(relaxedTip, around: wrist, by: wristAngle)
            pixelLine(context, from: palm, to: tip, width: 3)
        }

        let thumbBase = CGPoint(x: palmBase.x + mirror * 6, y: palmBase.y - 4)
        let thumb = rotatedPoint(thumbBase, around: wrist, by: wristAngle)
        pixelLine(context, from: palm, to: thumb, width: 3)
    }

    private func drawPerson(_ context: CGContext, exercise: Exercise, phase: CGFloat) {
        context.saveGState()
        context.setShouldAntialias(false)
        context.setStrokeColor(NSColor(calibratedRed: 0.45, green: 0.90, blue: 0.69, alpha: 1).cgColor)
        context.setFillColor(NSColor(calibratedRed: 0.45, green: 0.90, blue: 0.69, alpha: 1).cgColor)

        let wave = sin(phase * .pi * 2)
        var head = CGPoint(x: 138, y: 150)
        var neck = CGPoint(x: 138, y: 134)
        var hip = CGPoint(x: 138, y: 92)
        var leftHand = CGPoint(x: 96, y: 104)
        var rightHand = CGPoint(x: 180, y: 104)
        var leftFoot = CGPoint(x: 116, y: 56)
        var rightFoot = CGPoint(x: 160, y: 56)
        var leftArmOrigin = neck
        var rightArmOrigin = neck
        var leftElbow = leftHand
        var rightElbow = rightHand
        var drawsShoulderBar = false
        var drawsBentArms = false
        var faceOffset: CGFloat = 0
        var drawsRelaxedHands = false
        var leftWristAngle: CGFloat = 0
        var rightWristAngle: CGFloat = 0

        switch exercise {
        case .shoulderRoll:
            let angle = phase * .pi * 2
            leftHand = CGPoint(x: 100 + cos(angle) * 5, y: 106 + sin(angle) * 7)
            rightHand = CGPoint(x: 176 - cos(angle) * 5, y: 106 - sin(angle) * 7)
        case .seatedTwist:
            let turn = wave
            let shoulderHalfWidth = 18 - abs(turn) * 4
            let shoulderDepth = turn * 4
            let elbowHalfWidth = 25 - abs(turn) * 3
            let elbowDepth = turn * 2.5
            let handHalfWidth: CGFloat = 6
            let handDepth = turn
            leftArmOrigin = CGPoint(x: 138 - shoulderHalfWidth, y: 134 - shoulderDepth)
            rightArmOrigin = CGPoint(x: 138 + shoulderHalfWidth, y: 134 + shoulderDepth)
            leftElbow = CGPoint(x: 138 - elbowHalfWidth, y: 114 - elbowDepth)
            rightElbow = CGPoint(x: 138 + elbowHalfWidth, y: 114 + elbowDepth)
            leftHand = CGPoint(x: 138 - handHalfWidth, y: 109 - handDepth)
            rightHand = CGPoint(x: 138 + handHalfWidth, y: 109 + handDepth)
            leftFoot = CGPoint(x: 112, y: 65)
            rightFoot = CGPoint(x: 164, y: 65)
            drawsShoulderBar = true
            drawsBentArms = true
            faceOffset = round(turn * 3)
        case .wristStretch:
            leftHand = CGPoint(x: 116, y: 116)
            rightHand = CGPoint(x: 160, y: 116)
            drawsRelaxedHands = true
            leftWristAngle = wave * 0.14
            rightWristAngle = sin((phase + 0.18) * .pi * 2) * 0.14
        case .standReset:
            let rise = 5 + abs(wave) * 6
            head.y += rise
            neck.y += rise
            hip.y += rise * 0.55
            leftHand = CGPoint(x: 108, y: 102 + rise * 0.45)
            rightHand = CGPoint(x: 168, y: 102 + rise * 0.45)
        case .drinkWater:
            head.x += wave * 2
            leftHand = CGPoint(x: 106, y: 100)
            rightHand = CGPoint(x: 158 + wave * 2, y: 151)
        }

        let shoulder = neck
        pixelLine(context, from: head, to: neck, width: 7)
        pixelLine(context, from: shoulder, to: hip, width: 9)
        if drawsShoulderBar {
            pixelLine(context, from: leftArmOrigin, to: rightArmOrigin, width: 7)
        }
        if drawsBentArms {
            pixelLine(context, from: leftArmOrigin, to: leftElbow)
            pixelLine(context, from: leftElbow, to: leftHand)
            pixelLine(context, from: rightArmOrigin, to: rightElbow)
            pixelLine(context, from: rightElbow, to: rightHand)
        } else {
            pixelLine(context, from: leftArmOrigin, to: leftHand)
            pixelLine(context, from: rightArmOrigin, to: rightHand)
        }
        pixelLine(context, from: hip, to: leftFoot)
        pixelLine(context, from: hip, to: rightFoot)

        if drawsRelaxedHands {
            drawRelaxedHand(
                context,
                wrist: leftHand,
                mirror: -1,
                wristAngle: leftWristAngle,
                fingerPhase: phase
            )
            drawRelaxedHand(
                context,
                wrist: rightHand,
                mirror: 1,
                wristAngle: rightWristAngle,
                fingerPhase: phase + 0.13
            )
        }

        let headRect = CGRect(x: round(head.x - 12), y: round(head.y), width: 24, height: 24)
        context.fill(headRect)
        context.setFillColor(NSColor(calibratedWhite: 0.08, alpha: 1).cgColor)
        context.fill(CGRect(x: headRect.minX + 5 + faceOffset, y: headRect.minY + 14, width: 4, height: 4))
        context.fill(CGRect(x: headRect.maxX - 9 + faceOffset, y: headRect.minY + 14, width: 4, height: 4))

        if exercise == .drinkWater {
            context.setFillColor(NSColor(calibratedRed: 0.35, green: 0.70, blue: 0.95, alpha: 1).cgColor)
            context.fill(CGRect(x: round(rightHand.x - 3), y: round(rightHand.y - 7), width: 13, height: 17))
            context.setStrokeColor(NSColor(calibratedRed: 0.35, green: 0.70, blue: 0.95, alpha: 1).cgColor)
            pixelLine(
                context,
                from: CGPoint(x: rightHand.x + 10, y: rightHand.y + 5),
                to: CGPoint(x: rightHand.x + 15, y: rightHand.y + 1),
                width: 3
            )
        }
        context.restoreGState()
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        NSColor(calibratedRed: 0.055, green: 0.075, blue: 0.11, alpha: 0.96).setFill()
        NSBezierPath(roundedRect: bounds.insetBy(dx: 2, dy: 2), xRadius: 18, yRadius: 18).fill()
        NSColor(calibratedRed: 0.45, green: 0.90, blue: 0.69, alpha: 0.55).setStroke()
        let border = NSBezierPath(roundedRect: bounds.insetBy(dx: 3, dy: 3), xRadius: 17, yRadius: 17)
        border.lineWidth = 2
        border.stroke()

        let elapsed = max(0, Date().timeIntervalSince1970 - workingSince)
        let exerciseDuration: TimeInterval = 24
        let exerciseIndex = Int(elapsed / exerciseDuration) % Exercise.allCases.count
        let exercise = Exercise(rawValue: exerciseIndex) ?? .shoulderRoll
        let copy = exercise.copy(for: language)
        let phase = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 0.25 : CGFloat(elapsed.truncatingRemainder(dividingBy: 2.4) / 2.4)
        let remaining = Int(exerciseDuration - elapsed.truncatingRemainder(dividingBy: exerciseDuration))

        drawText(language.header, at: NSPoint(x: 20, y: 204), size: 13, color: .white, weight: .semibold)
        drawPerson(context, exercise: exercise, phase: phase)
        drawText(copy.title, at: NSPoint(x: 20, y: 30), size: 16, color: .white, weight: .semibold)
        drawText("\(copy.hint)  ·  \(remaining)s", at: NSPoint(x: 20, y: 13), size: 11, color: NSColor(calibratedWhite: 0.72, alpha: 1))
        let pauseOrigin = language == .simplifiedChinese ? NSPoint(x: 205, y: 211) : NSPoint(x: 170, y: 211)
        let pauseSize: CGFloat = language == .simplifiedChinese ? 9 : 8
        drawText(language.pause, at: pauseOrigin, size: pauseSize, color: NSColor(calibratedWhite: 0.52, alpha: 1))
    }
}

private final class CoachApp: NSObject, NSApplicationDelegate {
    private let dataDirectory: URL
    private var panel: NSPanel!
    private var coachView: CoachView!
    private var stateTimer: Timer?

    init(dataDirectory: URL) {
        self.dataDirectory = dataDirectory
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        try? String(ProcessInfo.processInfo.processIdentifier).write(
            to: dataDirectory.appendingPathComponent("daemon.pid"),
            atomically: true,
            encoding: .utf8
        )

        let size = NSSize(width: 280, height: 244)
        panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        coachView = CoachView(frame: NSRect(origin: .zero, size: size), dataDirectory: dataDirectory)
        panel.contentView = coachView

        if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(x: frame.maxX - size.width - 24, y: frame.minY + 24))
        }
        panel.orderOut(nil)

        stateTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] _ in
            self?.refreshState()
        }
        refreshState()
    }

    func applicationWillTerminate(_ notification: Notification) {
        let pidURL = dataDirectory.appendingPathComponent("daemon.pid")
        let ownPID = String(ProcessInfo.processInfo.processIdentifier)
        let recordedPID = try? String(contentsOf: pidURL, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if recordedPID == ownPID {
            try? FileManager.default.removeItem(at: pidURL)
        }
    }

    private func paused() -> Bool {
        let url = dataDirectory.appendingPathComponent("paused-until")
        guard
            let text = try? String(contentsOf: url, encoding: .utf8),
            let timestamp = TimeInterval(text.trimmingCharacters(in: .whitespacesAndNewlines))
        else { return false }
        return timestamp > Date().timeIntervalSince1970
    }

    private func activeState() -> SessionState? {
        let directory = stateDirectory(dataDirectory)
        guard let urls = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else {
            return nil
        }
        let now = Date().timeIntervalSince1970
        return urls.compactMap(readState).filter {
            $0.action == "working" && now - $0.updatedAt < staleInterval
        }.max { $0.updatedAt < $1.updatedAt }
    }

    private func refreshState() {
        guard !paused(), let state = activeState() else {
            panel.orderOut(nil)
            return
        }
        coachView.workingSince = state.startedAt
        let hasWaitedLongEnough = Date().timeIntervalSince1970 - state.startedAt >= appearanceDelay
        if hasWaitedLongEnough {
            panel.orderFrontRegardless()
        } else {
            panel.orderOut(nil)
        }
    }
}

private func runDaemon(dataDirectory: URL) -> Never {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    let delegate = CoachApp(dataDirectory: dataDirectory)
    app.delegate = delegate
    app.run()
    exit(0)
}

private func renderPreview(
    to outputURL: URL,
    dataDirectory: URL,
    elapsed: TimeInterval = 10,
    language: AppLanguage = .system
) {
    _ = NSApplication.shared
    let frame = NSRect(x: 0, y: 0, width: 280, height: 244)
    let view = CoachView(frame: frame, dataDirectory: dataDirectory, language: language)
    view.workingSince = Date().timeIntervalSince1970 - elapsed
    guard let bitmap = view.bitmapImageRepForCachingDisplay(in: frame) else { return }
    view.cacheDisplay(in: frame, to: bitmap)
    guard let png = bitmap.representation(using: .png, properties: [:]) else { return }
    try? png.write(to: outputURL, options: .atomic)
}

let arguments = CommandLine.arguments
if arguments.count >= 4, arguments[1] == "--render-preview" {
    let elapsed = arguments.count >= 5 ? TimeInterval(arguments[4]) ?? 10 : 10
    let language = AppLanguage.previewOverride(arguments.count >= 6 ? arguments[5] : nil)
    renderPreview(
        to: URL(fileURLWithPath: arguments[2]),
        dataDirectory: URL(fileURLWithPath: arguments[3], isDirectory: true),
        elapsed: elapsed,
        language: language
    )
    exit(0)
}
if arguments.count >= 3, arguments[1] == "--daemon" {
    runDaemon(dataDirectory: URL(fileURLWithPath: arguments[2], isDirectory: true))
}

guard arguments.count >= 4 else { exit(0) }
let action = arguments[1]
let sessionID = arguments[2]
let dataDirectory = URL(fileURLWithPath: arguments[3], isDirectory: true)
try? FileManager.default.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
writeState(action: action, sessionID: sessionID, dataDirectory: dataDirectory)
if action != "done" {
    startDaemonIfNeeded(dataDirectory)
}
