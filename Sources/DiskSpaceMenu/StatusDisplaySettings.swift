import Combine
import Foundation

enum StatusLayout: String, CaseIterable, Identifiable {
    case oneLine
    case twoLines

    var id: String { rawValue }
}

@MainActor
final class StatusDisplaySettings: ObservableObject {
    @Published var layout: StatusLayout {
        didSet { defaults.set(layout.rawValue, forKey: "statusLayout") }
    }
    @Published var oneLineSize: Double {
        didSet { defaults.set(oneLineSize, forKey: "statusOneLineSize") }
    }
    @Published var twoLineSize: Double {
        didSet { defaults.set(twoLineSize, forKey: "statusTwoLineSize") }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        layout = StatusLayout(rawValue: defaults.string(forKey: "statusLayout") ?? "") ?? .oneLine
        oneLineSize = Self.size(defaults.object(forKey: "statusOneLineSize") as? Double, default: 9, range: 8...16)
        twoLineSize = Self.size(defaults.object(forKey: "statusTwoLineSize") as? Double, default: 9, range: 7...11)
    }

    var activeSize: Double {
        get { layout == .oneLine ? oneLineSize : twoLineSize }
        set {
            if layout == .oneLine { oneLineSize = newValue }
            else { twoLineSize = newValue }
        }
    }

    var activeSizeRange: ClosedRange<Double> {
        layout == .oneLine ? 8...16 : 7...11
    }

    private static func size(_ value: Double?, default fallback: Double, range: ClosedRange<Double>) -> Double {
        guard let value, value.isFinite else { return fallback }
        return min(max(value, range.lowerBound), range.upperBound)
    }
}
