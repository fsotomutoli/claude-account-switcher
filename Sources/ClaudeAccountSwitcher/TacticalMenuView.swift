import SwiftUI

struct TacticalMenuView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider().overlay(Tactical.phosphorDim)

            VStack(spacing: 10) {
                ForEach(ClaudeAccount.allCases) { account in
                    AccountCard(
                        account: account,
                        isActive: appState.lastLaunched == account,
                        hasToken: appState.tokenPresence[account] == true
                    ) {
                        appState.launch(account)
                    }
                }
            }
            .padding(14)

            if let error = appState.launchErrorMessage {
                Text(error.uppercased())
                    .font(Tactical.mono(10))
                    .foregroundStyle(Tactical.amber)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider().overlay(Tactical.phosphorDim)

            footer
        }
        .frame(width: 300)
        .background(ScanlineBackground())
    }

    private var header: some View {
        HStack {
            Image(systemName: "shield.lefthalf.filled")
                .foregroundStyle(Tactical.phosphor)
            Text("CLAUDE ACCESS CONTROL")
                .font(Tactical.mono(11, weight: .bold))
                .foregroundStyle(Tactical.textPrimary)
                .tracking(1.2)
            Spacer()
            Text("v1.0")
                .font(Tactical.mono(9))
                .foregroundStyle(Tactical.textMuted)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var footer: some View {
        HStack(spacing: 0) {
            TacticalTextButton(label: "CONFIGURAR") {
                appState.refreshTokenPresence()
                openWindow(id: "setup")
                NSApp.activate(ignoringOtherApps: true)
            }
            Spacer()
            TacticalTextButton(label: "SALIR", tint: Tactical.amber) {
                NSApp.terminate(nil)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

private struct AccountCard: View {
    let account: ClaudeAccount
    let isActive: Bool
    let hasToken: Bool
    let action: () -> Void

    @State private var isHovering = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    private var statusText: String {
        if !hasToken { return "SIN TOKEN" }
        return isActive ? "ACTIVO" : "EN ESPERA"
    }

    private var statusColor: Color {
        if !hasToken { return Tactical.amber }
        return isActive ? Tactical.phosphor : Tactical.textMuted
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Hexagon()
                        .stroke(hasToken ? Tactical.phosphor : Tactical.textMuted, lineWidth: 1.2)
                        .frame(width: 34, height: 34)
                    Image(systemName: account.iconName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(hasToken ? Tactical.phosphor : Tactical.textMuted)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(account.displayName.uppercased())
                        .font(Tactical.mono(12, weight: .bold))
                        .foregroundStyle(Tactical.textPrimary)
                    Text(account.callsign)
                        .font(Tactical.mono(9))
                        .foregroundStyle(Tactical.textMuted)
                }

                Spacer()

                HStack(spacing: 5) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                        .opacity(isActive && !reduceMotion && pulse ? 0.35 : 1.0)
                        .animation(
                            isActive && !reduceMotion
                                ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true)
                                : .default,
                            value: pulse
                        )
                    Text(statusText)
                        .font(Tactical.mono(9, weight: .semibold))
                        .foregroundStyle(statusColor)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovering ? Tactical.bgCardHover : Tactical.bgCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isHovering ? Tactical.phosphor : Tactical.phosphorDim, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .onAppear { pulse = true }
    }
}

private struct TacticalTextButton: View {
    let label: String
    var tint: Color = Tactical.phosphor
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Tactical.mono(10, weight: .semibold))
                .foregroundStyle(isHovering ? tint : Tactical.textMuted)
                .tracking(0.8)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

/// Insignia hexagonal para el ícono de cada cuenta.
private struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let points = [
            CGPoint(x: w * 0.5, y: 0),
            CGPoint(x: w, y: h * 0.25),
            CGPoint(x: w, y: h * 0.75),
            CGPoint(x: w * 0.5, y: h),
            CGPoint(x: 0, y: h * 0.75),
            CGPoint(x: 0, y: h * 0.25),
        ]
        var path = Path()
        path.move(to: points[0])
        for point in points.dropFirst() { path.addLine(to: point) }
        path.closeSubpath()
        return path
    }
}

/// Fondo con un sutil patrón de scanlines horizontales, look consola/CRT.
private struct ScanlineBackground: View {
    var body: some View {
        Tactical.bgBase.overlay(
            GeometryReader { proxy in
                Path { path in
                    var y: CGFloat = 0
                    while y < proxy.size.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                        y += 3
                    }
                }
                .stroke(Color.white.opacity(0.015), lineWidth: 1)
            }
        )
    }
}
