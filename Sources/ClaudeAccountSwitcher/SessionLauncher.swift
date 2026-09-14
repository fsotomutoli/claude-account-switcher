import Foundation

/// Abre una nueva ventana de Terminal.app con `claude` ya autenticado como la cuenta
/// elegida, vía `CLAUDE_CODE_OAUTH_TOKEN`.
///
/// El token nunca se escribe a disco: se entrega a través de un FIFO (named pipe).
/// `open()` para escritura no-bloqueante en el FIFO solo tiene éxito cuando ya hay un
/// lector esperando (la ventana de Terminal, vía `cat`), así que el token viaja
/// directo por un pipe del kernel entre este proceso y esa Terminal — nunca queda
/// como bytes persistidos en el filesystem, a diferencia de un archivo temporal.
enum SessionLauncher {
    enum LaunchError: Error {
        case tokenMissing
        case fifoCreationFailed
        case appleScriptFailed(String)
    }

    static func launch(account: ClaudeAccount) throws {
        guard let token = KeychainStore.load(for: account) else {
            throw LaunchError.tokenMissing
        }

        let fifoPath = NSTemporaryDirectory() + "claude-switch-\(UUID().uuidString)"

        guard mkfifo(fifoPath, 0o600) == 0 else {
            throw LaunchError.fifoCreationFailed
        }

        DispatchQueue.global(qos: .userInitiated).async {
            writeTokenToFifo(token, path: fifoPath)
        }

        let shellCommand =
            "export CLAUDE_CODE_OAUTH_TOKEN=\"$(cat \(shellSingleQuoted(fifoPath)))\" && clear && claude"

        let script = """
        tell application "Terminal"
            activate
            do script "\(appleScriptEscaped(shellCommand))"
        end tell
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]

        let stderrPipe = Pipe()
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let errText = String(data: errData, encoding: .utf8) ?? "error desconocido"
            unlink(fifoPath) // nadie va a leer el FIFO si Terminal no se abrió; liberamos al escritor pendiente
            throw LaunchError.appleScriptFailed(errText)
        }
    }

    /// Escribe el token al FIFO solo cuando aparece un lector, con timeout — así un
    /// fallo aguas abajo (Terminal nunca abrió el pipe) no deja un hilo bloqueado
    /// para siempre. Corre en background, nunca en el hilo principal.
    private static func writeTokenToFifo(_ token: String, path: String, timeout: TimeInterval = 10) {
        defer { unlink(path) }

        let deadline = Date().addingTimeInterval(timeout)
        var fd: Int32 = -1
        while Date() < deadline {
            fd = open(path, O_WRONLY | O_NONBLOCK)
            if fd >= 0 { break }
            usleep(50_000)
        }
        guard fd >= 0 else { return }
        defer { close(fd) }

        // Vuelve a modo bloqueante para garantizar que se escriban todos los bytes
        // de una vez que ya hay un lector conectado.
        let flags = fcntl(fd, F_GETFL, 0)
        _ = fcntl(fd, F_SETFL, flags & ~O_NONBLOCK)

        let bytes = Array((token + "\n").utf8)
        bytes.withUnsafeBufferPointer { buffer in
            _ = write(fd, buffer.baseAddress, buffer.count)
        }
    }

    private static func shellSingleQuoted(_ raw: String) -> String {
        "'" + raw.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private static func appleScriptEscaped(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
