import AppKit
import SwiftUI

private let rightColumnWidth: CGFloat = 300
private let topCardHeight: CGFloat = 156
private let mainCardHeight: CGFloat = 320

enum SupportedLanguage {
    case chinese
    case english
}

enum AppLanguagePreference: String, CaseIterable, Identifiable {
    case system
    case chinese
    case english

    var id: String { rawValue }

    func resolvedLanguage(systemLanguage: SupportedLanguage) -> SupportedLanguage {
        switch self {
        case .system:
            systemLanguage
        case .chinese:
            .chinese
        case .english:
            .english
        }
    }
}

@MainActor
final class LocalizationController: ObservableObject {
    @Published var preference: AppLanguagePreference {
        didSet {
            UserDefaults.standard.set(preference.rawValue, forKey: Self.preferenceKey)
        }
    }

    @Published private(set) var systemLanguage: SupportedLanguage

    private static let preferenceKey = "appLanguagePreference"

    init() {
        let storedValue = UserDefaults.standard.string(forKey: Self.preferenceKey)
        self.preference = AppLanguagePreference(rawValue: storedValue ?? "") ?? .system
        self.systemLanguage = Self.detectSystemLanguage()

        NotificationCenter.default.addObserver(
            forName: NSLocale.currentLocaleDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.systemLanguage = Self.detectSystemLanguage()
            }
        }
    }

    var resolvedLanguage: SupportedLanguage {
        preference.resolvedLanguage(systemLanguage: systemLanguage)
    }

    nonisolated private static func detectSystemLanguage() -> SupportedLanguage {
        let preferred = Locale.preferredLanguages.first?.lowercased() ?? ""
        return preferred.hasPrefix("zh") ? .chinese : .english
    }
}

struct AppStrings {
    let language: SupportedLanguage

    func text(_ chinese: String, _ english: String) -> String {
        switch language {
        case .chinese:
            chinese
        case .english:
            english
        }
    }

    var appTitle: String { text("文件转 Markdown 小工具", "File to Markdown Tool") }
    var appSubtitle: String { text("支持点选和拖拽导入文件。", "Import files by clicking or dragging them in.") }
    var settingsTitle: String { text("输出设置", "Output Settings") }
    var outputModeLabel: String { text("输出方式", "Output Mode") }
    var languageTitle: String { text("语言", "Language") }
    var chooseFolder: String { text("选择文件夹", "Choose Folder") }
    var sameDirectoryHint: String { text("每个文件会在它自己的所在目录里生成 `.md`。", "Each file generates its `.md` in the same folder.") }
    var filesTitle: String { text("待转换文件", "Files to Convert") }
    var filesHint: String { text("可以点“添加文件”，也可以把文件直接拖到这个窗口里。", "Click “Add Files” or drag files directly into this window.") }
    var emptyDropTitle: String { text("拖拽文件到这里", "Drop files here") }
    var emptyDropSubtitle: String { text("或点击下方按钮选择文件", "Or click below to choose files") }
    var addFiles: String { text("添加文件", "Add Files") }
    var clearList: String { text("清空列表", "Clear List") }
    var actionsTitle: String { text("操作", "Actions") }
    var actionsHint: String { text("支持批量处理，默认在源文件旁生成 `.md` 文件。", "Batch conversion is supported. By default, `.md` files are created next to the source files.") }
    var convertingButton: String { text("正在转换…", "Converting...") }
    var convertButton: String { text("一键转换", "Convert") }
    var openOutputDirectory: String { text("打开输出目录", "Open Output Folder") }
    var logsTitle: String { text("运行日志", "Logs") }
    var alertTitle: String { text("提示", "Notice") }
    var alertDismiss: String { text("知道了", "OK") }
    var outputDirectoryUpdated: String { text("输出目录已更新。", "Output folder updated.") }
    var emptySelectionAlert: String { text("请先添加至少一个要转换的文件。", "Please add at least one file first.") }
    var convertingStatus: String { text("正在转换，请稍候…", "Converting, please wait...") }
    var conversionFailedStatus: String { text("转换失败，请查看日志。", "Conversion failed. Please check the logs.") }
    var conversionFailedShort: String { text("转换失败。", "Conversion failed.") }
    var missingMarkitdown: String {
        text(
            """
            未找到全局 markitdown。

            请先确认 pipx 安装成功，并且存在这个命令：
            ~/.local/bin/markitdown
            """,
            """
            Global markitdown was not found.

            Please make sure pipx installed it successfully and this command exists:
            ~/.local/bin/markitdown
            """
        )
    }

    func outputModeTitle(_ mode: OutputMode) -> String {
        switch mode {
        case .sharedDirectory:
            text("统一输出目录", "Shared Output Folder")
        case .sameAsSource:
            text("输出到原文件目录", "Source File Folder")
        }
    }

    func preferenceTitle(_ preference: AppLanguagePreference) -> String {
        switch preference {
        case .system:
            text("跟随系统", "Follow System")
        case .chinese:
            "中文"
        case .english:
            "English"
        }
    }

    func selectedFilesStatus(_ count: Int) -> String {
        text("已选择 \(count) 个文件。", "\(count) file(s) selected.")
    }

    func clearedFilesStatus() -> String {
        text("文件列表已清空。", "File list cleared.")
    }

    func retainedFilesStatus(_ count: Int) -> String {
        text("已保留 \(count) 个文件。", "\(count) file(s) remaining.")
    }

    func conversionCompletedStatus(_ count: Int) -> String {
        text("转换完成，共处理 \(count) 个文件。", "Conversion complete. Processed \(count) file(s).")
    }

    func conversionCompletedAlert(_ count: Int) -> String {
        text("全部完成，成功生成 \(count) 个 Markdown 文件。", "Done. Generated \(count) Markdown file(s).")
    }

    func latestCompletedStatus(_ filename: String) -> String {
        text("最近完成：\(filename)", "Latest completed: \(filename)")
    }

    func logStartConversion() -> String {
        text("开始转换任务。", "Started conversion task.")
    }

    func logProcessing(index: Int, total: Int, path: String) -> String {
        text("[\(index)/\(total)] 正在处理：\(path)", "[\(index)/\(total)] Processing: \(path)")
    }

    func logGenerated(_ path: String) -> String {
        text("已生成：\(path)", "Generated: \(path)")
    }

    func logFailure(_ message: String) -> String {
        text("转换失败：\(message)", "Conversion failed: \(message)")
    }
}

@main
struct MarkitdownKitMacApp: App {
    @StateObject private var localization = LocalizationController()

    var body: some Scene {
        WindowGroup {
            ContentView(localization: localization)
                .frame(minWidth: 720, minHeight: 560)
        }
        .windowResizability(.contentMinSize)

        Settings {
            SettingsView(localization: localization)
        }
    }
}

enum OutputMode: String, CaseIterable, Identifiable {
    case sharedDirectory
    case sameAsSource

    var id: String { rawValue }
}

struct ConversionLog: Identifiable {
    let id = UUID()
    let message: String
}

@MainActor
final class AppViewModel: ObservableObject {
    enum StatusState {
        case idle
        case selectedFiles(Int)
        case outputDirectoryUpdated
        case filesCleared
        case filesRemaining(Int)
        case converting
        case conversionCompleted(Int)
        case conversionFailed
        case latestCompleted(String)
    }

    enum AlertState {
        case emptySelection
        case conversionCompleted(Int)
        case custom(String)
    }

    @Published var selectedFiles: [URL] = []
    @Published var outputMode: OutputMode = .sameAsSource
    @Published var outputDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Desktop/MarkItDown Output", isDirectory: true)
    @Published var logs: [ConversionLog] = []
    @Published var statusState: StatusState = .idle
    @Published var isConverting = false
    @Published var alertState: AlertState?

    private let fileManager = FileManager.default
    private let stringsProvider: () -> AppStrings

    init(stringsProvider: @escaping () -> AppStrings) {
        self.stringsProvider = stringsProvider
    }

    var statusText: String {
        let strings = stringsProvider()
        switch statusState {
        case .idle:
            return strings.text("请选择文件，然后点击“一键转换”。", "Choose files, then click “Convert”.")
        case .selectedFiles(let count):
            return strings.selectedFilesStatus(count)
        case .outputDirectoryUpdated:
            return strings.outputDirectoryUpdated
        case .filesCleared:
            return strings.clearedFilesStatus()
        case .filesRemaining(let count):
            return strings.retainedFilesStatus(count)
        case .converting:
            return strings.convertingStatus
        case .conversionCompleted(let count):
            return strings.conversionCompletedStatus(count)
        case .conversionFailed:
            return strings.conversionFailedStatus
        case .latestCompleted(let filename):
            return strings.latestCompletedStatus(filename)
        }
    }

    var alertMessage: String? {
        guard let alertState else { return nil }
        let strings = stringsProvider()
        switch alertState {
        case .emptySelection:
            return strings.emptySelectionAlert
        case .conversionCompleted(let count):
            return strings.conversionCompletedAlert(count)
        case .custom(let message):
            return message
        }
    }

    func chooseFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.begin { [weak self] response in
            guard response == .OK, let self else { return }
            let newFiles = panel.urls.filter { !self.selectedFiles.contains($0) }
            self.selectedFiles.append(contentsOf: newFiles)
            if !newFiles.isEmpty {
                self.statusState = .selectedFiles(self.selectedFiles.count)
            }
        }
    }

    func addDroppedFiles(_ urls: [URL]) {
        let fileURLs = urls
            .filter { $0.isFileURL }
            .filter { !$0.hasDirectoryPath }

        let newFiles = fileURLs.filter { !selectedFiles.contains($0) }
        selectedFiles.append(contentsOf: newFiles)

        if !newFiles.isEmpty {
            statusState = .selectedFiles(selectedFiles.count)
        }
    }

    func chooseOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.outputDirectory = url
            self?.statusState = .outputDirectoryUpdated
        }
    }

    func removeSelected(indexSet: IndexSet) {
        selectedFiles.remove(atOffsets: indexSet)
        statusState = selectedFiles.isEmpty ? .filesCleared : .filesRemaining(selectedFiles.count)
    }

    func clearFiles() {
        selectedFiles.removeAll()
        statusState = .filesCleared
    }

    func openOutputDirectory() {
        let target = outputMode == .sameAsSource ? selectedFiles.first?.deletingLastPathComponent() : outputDirectory
        guard let target else { return }
        try? fileManager.createDirectory(at: target, withIntermediateDirectories: true)
        NSWorkspace.shared.open(target)
    }

    func startConversion() {
        guard !isConverting else { return }
        guard !selectedFiles.isEmpty else {
            alertState = .emptySelection
            return
        }

        if outputMode == .sharedDirectory {
            try? fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        }

        logs.removeAll()
        isConverting = true
        statusState = .converting
        appendLog(stringsProvider().logStartConversion())

        Task {
            do {
                try await convertAll()
                isConverting = false
                statusState = .conversionCompleted(selectedFiles.count)
                alertState = .conversionCompleted(selectedFiles.count)
            } catch {
                isConverting = false
                statusState = .conversionFailed
                appendLog(stringsProvider().logFailure(error.localizedDescription))
                alertState = .custom(error.localizedDescription)
            }
        }
    }

    private func convertAll() async throws {
        let total = selectedFiles.count
        for (index, sourceURL) in selectedFiles.enumerated() {
            let outputURL = outputMode == .sameAsSource ? sourceURL.deletingLastPathComponent() : outputDirectory
            appendLog(stringsProvider().logProcessing(index: index + 1, total: total, path: sourceURL.path))
            let resultPath = try runConversion(sourceURL: sourceURL, outputURL: outputURL)
            appendLog(stringsProvider().logGenerated(resultPath))
            statusState = .latestCompleted(sourceURL.lastPathComponent)
        }
    }

    private func runConversion(sourceURL: URL, outputURL: URL) throws -> String {
        let markitdownURL = try resolveMarkItDownExecutable()
        try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true)

        let outputFileURL = buildOutputFileURL(sourceURL: sourceURL, outputDirectory: outputURL)

        let process = Process()
        process.currentDirectoryURL = outputURL
        process.executableURL = markitdownURL
        process.arguments = [
            sourceURL.path,
            "-o",
            outputFileURL.path,
        ]

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        let outputData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errorData = stderr.fileHandleForReading.readDataToEndOfFile()
        let outputText = String(decoding: outputData, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        let errorText = String(decoding: errorData, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)

        guard process.terminationStatus == 0 else {
            throw AppError.message(errorText.isEmpty ? stringsProvider().conversionFailedShort : errorText)
        }

        return outputText.isEmpty ? outputFileURL.path : outputText
    }

    private func appendLog(_ message: String) {
        logs.append(ConversionLog(message: message))
    }

    private func resolveMarkItDownExecutable() throws -> URL {
        let homeDirectory = fileManager.homeDirectoryForCurrentUser
        let candidates = [
            homeDirectory.appendingPathComponent(".local/bin/markitdown"),
            URL(fileURLWithPath: "/opt/homebrew/bin/markitdown"),
            URL(fileURLWithPath: "/usr/local/bin/markitdown"),
        ]

        if let directHit = candidates.first(where: { fileManager.isExecutableFile(atPath: $0.path) }) {
            return directHit
        }

        let shellProcess = Process()
        shellProcess.executableURL = URL(fileURLWithPath: "/bin/zsh")
        shellProcess.arguments = ["-lc", "command -v markitdown"]
        let pipe = Pipe()
        shellProcess.standardOutput = pipe
        shellProcess.standardError = pipe

        do {
            try shellProcess.run()
            shellProcess.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let resolvedPath = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            if shellProcess.terminationStatus == 0, !resolvedPath.isEmpty {
                return URL(fileURLWithPath: resolvedPath)
            }
        } catch {
            // Fall through to the friendly installation error below.
        }

        throw AppError.message(
            stringsProvider().missingMarkitdown
        )
    }

    private func buildOutputFileURL(sourceURL: URL, outputDirectory: URL) -> URL {
        let baseName = sourceURL.deletingPathExtension().lastPathComponent.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeBaseName = baseName.isEmpty ? "converted" : baseName
        var candidate = outputDirectory.appendingPathComponent("\(safeBaseName).md")
        var counter = 1

        while fileManager.fileExists(atPath: candidate.path) {
            candidate = outputDirectory.appendingPathComponent("\(safeBaseName)_\(counter).md")
            counter += 1
        }

        return candidate
    }
}

enum AppError: LocalizedError {
    case message(String)

    var errorDescription: String? {
        switch self {
        case .message(let text):
            text
        }
    }
}

struct ContentView: View {
    @ObservedObject private var localization: LocalizationController
    @StateObject private var viewModel: AppViewModel

    init(localization: LocalizationController) {
        self._localization = ObservedObject(wrappedValue: localization)
        _viewModel = StateObject(
            wrappedValue: AppViewModel(
                stringsProvider: {
                    AppStrings(language: localization.resolvedLanguage)
                }
            )
        )
    }

    private var strings: AppStrings {
        AppStrings(language: localization.resolvedLanguage)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.97, green: 0.94, blue: 0.89),
                    Color(red: 0.93, green: 0.88, blue: 0.81),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 10) {
                header
                topRow
                mainRow
                footer
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .dropDestination(for: URL.self) { items, _ in
            viewModel.addDroppedFiles(items)
            return !items.isEmpty
        }
        .alert(strings.alertTitle, isPresented: Binding(get: {
            viewModel.alertState != nil
        }, set: { newValue in
            if !newValue {
                viewModel.alertState = nil
            }
        })) {
            Button(strings.alertDismiss, role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
    }

    private var topRow: some View {
        HStack(alignment: .top, spacing: 10) {
            settingsCard
                .frame(maxWidth: .infinity)
            actionsCard
                .frame(width: rightColumnWidth)
        }
    }

    private var mainRow: some View {
        HStack(alignment: .top, spacing: 10) {
            filesCard
                .frame(maxWidth: .infinity)
            logCard
                .frame(width: rightColumnWidth)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(strings.appTitle)
                .font(.system(size: 20, weight: .bold))
            Text(strings.appSubtitle)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 2)
    }

    private var settingsCard: some View {
        CompactCardView(fixedHeight: topCardHeight) {
            VStack(alignment: .leading, spacing: 12) {
                Text(strings.settingsTitle)
                    .font(.system(size: 15, weight: .bold))

                VStack(alignment: .leading, spacing: 8) {
                    Text(strings.outputModeLabel)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)

                    Picker(strings.outputModeLabel, selection: $viewModel.outputMode) {
                        ForEach(OutputMode.allCases) { mode in
                            Text(strings.outputModeTitle(mode)).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                if viewModel.outputMode == .sharedDirectory {
                    HStack(spacing: 8) {
                        TextField("", text: .constant(viewModel.outputDirectory.path))
                            .textFieldStyle(.roundedBorder)
                            .disabled(true)
                        Button(strings.chooseFolder) {
                            viewModel.chooseOutputDirectory()
                        }
                        .controlSize(.small)
                    }
                } else {
                    Text(strings.sameDirectoryHint)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var filesCard: some View {
        CardView(fixedHeight: mainCardHeight) {
            VStack(alignment: .leading, spacing: 8) {
                Text(strings.filesTitle)
                    .font(.system(size: 15, weight: .bold))

                Text(strings.filesHint)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                List {
                    ForEach(viewModel.selectedFiles, id: \.path) { fileURL in
                        Text(fileURL.path)
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                            .lineLimit(2)
                    }
                    .onDelete(perform: viewModel.removeSelected)
                }
                .frame(maxHeight: .infinity)
                .scrollIndicators(.visible)
                .overlay {
                    if viewModel.selectedFiles.isEmpty {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
                            .foregroundStyle(Color.secondary.opacity(0.35))
                            .overlay {
                                VStack(spacing: 6) {
                                    Image(systemName: "tray.and.arrow.down")
                                        .font(.system(size: 22))
                                        .foregroundStyle(.secondary)
                                    Text(strings.emptyDropTitle)
                                        .font(.system(size: 13, weight: .medium))
                                    Text(strings.emptyDropSubtitle)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(8)
                    }
                }

                HStack(spacing: 10) {
                    Button(strings.addFiles) {
                        viewModel.chooseFiles()
                    }
                    .controlSize(.small)
                    Button(strings.clearList) {
                        viewModel.clearFiles()
                    }
                    .controlSize(.small)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var actionsCard: some View {
        CompactCardView(fixedHeight: topCardHeight) {
            VStack(alignment: .leading, spacing: 10) {
                Text(strings.actionsTitle)
                    .font(.system(size: 15, weight: .bold))

                Text(strings.actionsHint)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Button(action: {
                    viewModel.startConversion()
                }) {
                    Text(viewModel.isConverting ? strings.convertingButton : strings.convertButton)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AccentButtonStyle())
                .disabled(viewModel.isConverting)

                Button(strings.openOutputDirectory) {
                    viewModel.openOutputDirectory()
                }
                .buttonStyle(SoftButtonStyle())

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var logCard: some View {
        CardView(fixedHeight: mainCardHeight) {
            VStack(alignment: .leading, spacing: 10) {
                Text(strings.logsTitle)
                    .font(.system(size: 15, weight: .bold))

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.logs) { item in
                            Text(item.message)
                                .font(.system(size: 10, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
                .scrollIndicators(.visible)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var footer: some View {
        Text(viewModel.statusText)
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }
}

struct SettingsView: View {
    @ObservedObject var localization: LocalizationController

    private var strings: AppStrings {
        AppStrings(language: localization.resolvedLanguage)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(strings.languageTitle)
                .font(.system(size: 16, weight: .bold))

            Picker(strings.languageTitle, selection: $localization.preference) {
                ForEach(AppLanguagePreference.allCases) { preference in
                    Text(strings.preferenceTitle(preference)).tag(preference)
                }
            }
            .pickerStyle(.radioGroup)
            .labelsHidden()

            Spacer()
        }
        .padding(20)
        .frame(width: 320, height: 180, alignment: .topLeading)
    }
}

struct CardView<Content: View>: View {
    var fixedHeight: CGFloat? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading) {
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .frame(height: fixedHeight)
        .padding(14)
        .background(.white.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color(red: 0.91, green: 0.84, blue: 0.77), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 20, y: 8)
    }
}

struct CompactCardView<Content: View>: View {
    var fixedHeight: CGFloat? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading) {
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .frame(height: fixedHeight)
        .padding(14)
        .background(.white.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(red: 0.91, green: 0.84, blue: 0.77), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 16, y: 6)
    }
}

struct AccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(configuration.isPressed ? Color(red: 0.60, green: 0.28, blue: 0.13) : Color(red: 0.72, green: 0.36, blue: 0.22))
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .font(.system(size: 13, weight: .semibold))
    }
}

struct SoftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .padding(.horizontal, 14)
            .background(configuration.isPressed ? Color(red: 0.93, green: 0.88, blue: 0.82) : .white.opacity(0.92))
            .foregroundStyle(Color.primary)
            .overlay(
                Capsule().stroke(Color(red: 0.91, green: 0.84, blue: 0.77), lineWidth: 1)
            )
            .clipShape(Capsule())
            .font(.system(size: 13, weight: .medium))
    }
}
