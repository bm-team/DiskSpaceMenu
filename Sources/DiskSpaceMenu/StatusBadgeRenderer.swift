import AppKit
import CoreText

enum StatusBadgeRenderer {
    static func image(for volume: DiskVolume?, layout: StatusLayout, fontSize: Double) -> NSImage {
        let total = gigabytes(volume?.total)
        let free = gigabytes(volume?.free)
        let lines = layout == .oneLine ? ["\(total)/\(free)"] : [total, free]
        let font = NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .regular)
        let textWidth = lines.map { ($0 as NSString).size(withAttributes: [.font: font]).width }.max() ?? 0
        let iconSize: CGFloat = 11
        let gap: CGFloat = 3
        let height = max(18, NSStatusBar.system.thickness - 2)
        let width = ceil(iconSize + gap + textWidth + 2)
        let image = NSImage(size: NSSize(width: width, height: height), flipped: false) { bounds in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            let icon = NSImage(systemSymbolName: "internaldrive", accessibilityDescription: nil)
            icon?.draw(in: NSRect(x: 0, y: (bounds.height - iconSize) / 2, width: iconSize, height: iconSize))

            context.textMatrix = .identity
            let baselines: [CGFloat]
            if layout == .oneLine {
                baselines = [(bounds.height - font.capHeight) / 2]
            } else {
                baselines = [bounds.height - 1 - font.capHeight, 2]
            }

            for (line, baseline) in zip(lines, baselines) {
                let attributed = NSAttributedString(string: line, attributes: [
                    .font: font,
                    NSAttributedString.Key(kCTForegroundColorAttributeName as String): NSColor.black.cgColor
                ])
                let ctLine = CTLineCreateWithAttributedString(attributed)
                context.textPosition = CGPoint(x: iconSize + gap, y: baseline)
                CTLineDraw(ctLine, context)
            }
            return true
        }
        image.isTemplate = true
        return image
    }

    static func gigabytes(_ bytes: UInt64?) -> String {
        guard let bytes else { return "—" }
        let value = Double(bytes) / 1_000_000_000
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.maximumFractionDigits = value < 0.1 ? 3 : value < 1 ? 2 : value < 10 ? 1 : 0
        return formatter.string(from: NSNumber(value: value)) ?? "—"
    }
}
