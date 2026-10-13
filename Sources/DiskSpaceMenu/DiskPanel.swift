import AppKit
import ServiceManagement
import SwiftUI

func amount(_ bytes: UInt64) -> String {
    let value = Double(bytes)
    let unit: String
    let divisor: Double
    if value >= 1_000_000_000_000 { (unit, divisor) = ("ТБ", 1_000_000_000_000) }
    else if value >= 1_000_000_000 { (unit, divisor) = ("ГБ", 1_000_000_000) }
    else { (unit, divisor) = ("МБ", 1_000_000) }
    let number = NumberFormatter()
    number.locale = Locale(identifier: "ru_RU")
    number.maximumFractionDigits = value / divisor < 10 ? 1 : 0
    number.minimumFractionDigits = 0
    return "\(number.string(from: NSNumber(value: value / divisor)) ?? "—") \(unit)"
}

struct DiskPanel: View {
    @ObservedObject var store: DiskStore
    @ObservedObject var displaySettings: StatusDisplaySettings
    @State private var launchAtLogin = false
    @State private var loginError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Text("Место на дисках").font(.headline)
                Spacer()
                Button { store.refresh() } label: { Image(systemName: "arrow.clockwise") }
                    .buttonStyle(.borderless)
                    .help("Обновить")
                    .accessibilityLabel("Обновить сведения о дисках")
            }
            if store.volumes.isEmpty {
                Text(store.updating ? "Загрузка…" : "Диски недоступны")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(store.volumes) { volume in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Image(systemName: volume.isInternal ? "internaldrive" : "externaldrive")
                            Text(volume.name).fontWeight(.medium).lineLimit(1)
                            Spacer()
                            Text(volume.isInternal ? "Внутренний" : "Внешний")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        ProgressView(value: Double(volume.used), total: Double(volume.total))
                        HStack(alignment: .firstTextBaseline) {
                            metric("Ёмкость тома", volume.total)
                            Spacer(minLength: 6)
                            metric("Занято", volume.used)
                            Spacer(minLength: 6)
                            metric("Свободно", volume.free)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(volume.name). Ёмкость тома \(amount(volume.total)), занято \(amount(volume.used)), свободно \(amount(volume.free))")
                    }
                    if volume.id != store.volumes.last?.id { Divider() }
                }
            }
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Text("Индикатор в строке меню")
                    .font(.subheadline).fontWeight(.medium)
                Picker("Расположение чисел", selection: $displaySettings.layout) {
                    Text("Одна строка").tag(StatusLayout.oneLine)
                    Text("Две строки").tag(StatusLayout.twoLines)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                HStack {
                    Text("Размер цифр")
                    Slider(
                        value: Binding(
                            get: { displaySettings.activeSize },
                            set: { displaySettings.activeSize = $0 }
                        ),
                        in: displaySettings.activeSizeRange,
                        step: 1
                    )
                    Text("\(Int(displaySettings.activeSize)) pt")
                        .monospacedDigit()
                        .frame(width: 38, alignment: .trailing)
                }
                .font(.caption)
                Text(displaySettings.layout == .oneLine
                     ? "Ёмкость / свободно (в ГБ)"
                     : "Ёмкость сверху, свободно снизу (в ГБ)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Divider()
            Toggle("Открывать при входе", isOn: Binding(
                get: { launchAtLogin },
                set: { newValue in
                    do {
                        if newValue { try SMAppService.mainApp.register() }
                        else { try SMAppService.mainApp.unregister() }
                        syncLoginStatus()
                        loginError = SMAppService.mainApp.status == .requiresApproval
                            ? "Разрешите автозапуск в настройках macOS." : nil
                    } catch {
                        syncLoginStatus()
                        loginError = "Не удалось изменить автозапуск: \(error.localizedDescription)"
                    }
                }
            )).toggleStyle(.switch).controlSize(.small)
            if let loginError { Text(loginError).font(.caption).foregroundStyle(.red) }
            HStack {
                Text("Обновление каждую минуту").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("Выход") { NSApplication.shared.terminate(nil) }
                    .buttonStyle(.borderless)
            }
        }
        .padding(16)
        .frame(width: 340)
        .onAppear {
            syncLoginStatus()
            store.refresh()
        }
    }

    private func metric(_ title: String, _ value: UInt64) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(amount(value)).font(.caption).monospacedDigit()
        }
    }

    private func syncLoginStatus() {
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }
}
