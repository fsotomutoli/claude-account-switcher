import SwiftUI

/// Paleta y tipografía para el popover del menu bar — estética "consola táctica":
/// fondo casi negro, acento verde fósforo para estado activo, ámbar para alertas.
/// Usa SF Mono (`.monospaced`) en vez de fuentes externas para no agregar
/// dependencias nuevas al proyecto.
enum Tactical {
    static let bgBase = Color(red: 0.035, green: 0.045, blue: 0.035)
    static let bgCard = Color(red: 0.07, green: 0.09, blue: 0.075)
    static let bgCardHover = Color(red: 0.10, green: 0.13, blue: 0.10)

    static let phosphor = Color(red: 0.29, green: 1.0, blue: 0.45)
    static let phosphorDim = Color(red: 0.16, green: 0.42, blue: 0.24)
    static let amber = Color(red: 1.0, green: 0.70, blue: 0.10)

    static let textPrimary = Color(red: 0.90, green: 0.97, blue: 0.92)
    static let textMuted = Color(red: 0.52, green: 0.60, blue: 0.54)

    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}
