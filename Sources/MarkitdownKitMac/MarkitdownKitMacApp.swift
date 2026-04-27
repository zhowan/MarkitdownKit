import AppKit
import SwiftUI

private let rightColumnWidth: CGFloat = 300

@main
struct MarkitdownKitMacApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 720, minHeight: 460)
        }
        .windowResizability(.contentMinSize)
    }
}

enum OutputMode: String, CaseIterable, Identifiable {
    case sharedDirectory
    case sameAsSource

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sharedDirectory:
            "统一输出目录"
        case .sameAsSource:
            "输出到原文件目录"
        }
    }
}

struct ConversionLog: Identifiable {
    let id = UUID()
    let message: String
}

@MainActor
final class AppViewModel: ObservableObject {
    @Published var selectedFiles: [URL] = []
    @Published var outputMode: OutputMode = .sameAsSource
    @Published var outputDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Desktop/MarkItDown Output", isDirectory: true)
    @Published var logs: [ConversionLog] = []
    @Published var statusText = "请选择文件，然后点击“一键转换”。"
    @Published var isConverting = false
    @Published var alertMessage: String?

    private let fileManager = FileManager.default

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
                self.statusText = "已选择 \(self.selectedFiles.count) 个文件。"
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
            statusText = "已选择 \(selectedFiles.count) 个文件。"
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
            self?.statusText = "输出目录已更新。"
        }
    }

    func removeSelected(indexSet: IndexSet) {
        selectedFiles.remove(atOffsets: indexSet)
        statusText = selectedFiles.isEmpty ? "文件列表已清空。" : "已保留 \(selectedFiles.count) 个文件。"
    }

    func clearFiles() {
        selectedFiles.removeAll()
        statusText = "文件列表已清空。"
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
            alertMessage = "请先添加至少一个要转换的文件。"
            return
        }

        if outputMode == .sharedDirectory {
            try? fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        }

        logs.removeAll()
        isConverting = true
        statusText = "正在转换，请稍候…"
        appendLog("开始转换任务。")

        Task {
            do {
                try await convertAll()
                isConverting = false
                statusText = "转换完成，共处理 \(selectedFiles.count) 个文件。"
                alertMessage = "全部完成，成功生成 \(selectedFiles.count) 个 Markdown 文件。"
            } catch {
                isConverting = false
                statusText = "转换失败，请查看日志。"
                appendLog("转换失败：\(error.localizedDescription)")
                alertMessage = error.localizedDescription
            }
        }
    }

    private func convertAll() async throws {
        let total = selectedFiles.count
        for (index, sourceURL) in selectedFiles.enumerated() {
            let outputURL = outputMode == .sameAsSource ? sourceURL.deletingLastPathComponent() : outputDirectory
            appendLog("[\(index + 1)/\(total)] 正在处理：\(sourceURL.path)")
            let resultPath = try runConversion(sourceURL: sourceURL, outputURL: outputURL)
            appendLog("已生成：\(resultPath)")
            statusText = "最近完成：\(sourceURL.lastPathComponent)"
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
            throw AppError.message(errorText.isEmpty ? "转换失败。": errorText)
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
            """
            未找到全局 markitdown。

            请先确认 pipx 安装成功，并且存在这个命令：
            ~/.local/bin/markitdown
            """
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
    @StateObject private var viewModel = AppViewModel()

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

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    header
                    topRow
                    mainRow
                    footer
                }
                .padding(12)
            }
        }
        .dropDestination(for: URL.self) { items, _ in
            viewModel.addDroppedFiles(items)
            return !items.isEmpty
        }
        .alert("提示", isPresented: Binding(get: {
            viewModel.alertMessage != nil
        }, set: { newValue in
            if !newValue {
                viewModel.alertMessage = nil
            }
        })) {
            Button("知道了", role: .cancel) {}
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
            Text("文件转 Markdown 小工具")
                .font(.system(size: 20, weight: .bold))
            Text("支持点选和拖拽导入文件。")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 2)
    }

    private var settingsCard: some View {
        CompactCardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("输出设置")
                    .font(.system(size: 15, weight: .bold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("输出方式")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)

                    Picker("输出方式", selection: $viewModel.outputMode) {
                        ForEach(OutputMode.allCases) { mode in
                            Text(mode.title).tag(mode)
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
                        Button("选择文件夹") {
                            viewModel.chooseOutputDirectory()
                        }
                        .controlSize(.small)
                    }
                } else {
                    Text("每个文件会在它自己的所在目录里生成 `.md`。")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        }
    }

    private var filesCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("待转换文件")
                    .font(.system(size: 15, weight: .bold))

                Text("可以点“添加文件”，也可以把文件直接拖到这个窗口里。")
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
                .frame(minHeight: 180)
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
                                    Text("拖拽文件到这里")
                                        .font(.system(size: 13, weight: .medium))
                                    Text("或点击下方按钮选择文件")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(8)
                    }
                }

                HStack(spacing: 10) {
                    Button("添加文件") {
                        viewModel.chooseFiles()
                    }
                    .controlSize(.small)
                    Button("清空列表") {
                        viewModel.clearFiles()
                    }
                    .controlSize(.small)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 320, alignment: .topLeading)
        }
    }

    private var actionsCard: some View {
        CompactCardView {
            VStack(alignment: .leading, spacing: 10) {
                Text("操作")
                    .font(.system(size: 15, weight: .bold))

                Text("支持批量处理，默认在源文件旁生成 `.md` 文件。")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Button(action: {
                    viewModel.startConversion()
                }) {
                    Text(viewModel.isConverting ? "正在转换…" : "一键转换")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(AccentButtonStyle())
                .disabled(viewModel.isConverting)

                Button("打开输出目录") {
                    viewModel.openOutputDirectory()
                }
                .buttonStyle(SoftButtonStyle())
            }
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        }
    }

    private var logCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                Text("运行日志")
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
                .frame(minHeight: 280)
            }
            .frame(maxWidth: .infinity, minHeight: 320, alignment: .topLeading)
        }
    }

    private var footer: some View {
        Text(viewModel.statusText)
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }
}

struct CardView<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading) {
            content
        }
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
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading) {
            content
        }
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
