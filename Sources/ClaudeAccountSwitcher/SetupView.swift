import SwiftUI

struct SetupView: View {
    @EnvironmentObject var appState: AppState
    @State private var draftTokens: [ClaudeAccount: String] = [:]
    @State private var savedFeedback: [ClaudeAccount: Bool] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Configurar cuentas")
                    .font(.title2.bold())
                Text("""
                Por cada cuenta: abre una Terminal, ejecuta \"claude setup-token\", \
                inicia sesión con esa cuenta cuando te lo pida (incluyendo el código \
                del correo) y pega aquí el token que te entregue al final. Solo hay \
                que hacer esto una vez por cuenta.
                """)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }

            ForEach(ClaudeAccount.allCases) { account in
                accountRow(account)
            }

            Spacer()
        }
        .padding(24)
        .frame(width: 460, height: 420)
    }

    @ViewBuilder
    private func accountRow(_ account: ClaudeAccount) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(account.displayName)
                    .font(.headline)
                Spacer()
                if appState.tokenPresence[account] == true {
                    Label("Token guardado", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }

            HStack {
                SecureField(
                    "Pega el token de \"claude setup-token\" aquí",
                    text: Binding(
                        get: { draftTokens[account] ?? "" },
                        set: { draftTokens[account] = $0 }
                    )
                )
                .textFieldStyle(.roundedBorder)

                Button("Guardar") {
                    let token = draftTokens[account] ?? ""
                    let ok = appState.saveToken(token, for: account)
                    savedFeedback[account] = ok
                    if ok { draftTokens[account] = "" }
                }
                .disabled((draftTokens[account] ?? "").isEmpty)

                if appState.tokenPresence[account] == true {
                    Button(role: .destructive) {
                        appState.clearToken(for: account)
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }

            if savedFeedback[account] == false {
                Text("No se pudo guardar el token en el Keychain.")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(.quaternary.opacity(0.3)))
    }
}
