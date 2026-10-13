import SwiftUI

struct SaveConfirmation: View {
    var needsRestart = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 0
    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.islandAccent.opacity(0.12)).frame(width: 66, height: 66)
                CheckmarkStroke().trim(from: 0, to: progress)
                    .stroke(Color.islandAccent, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    .frame(width: 30, height: 24)
            }
            Text("Gespeichert").font(.headline)
            if needsRestart { Text("Das neue Layout erscheint beim nächsten Start der Live Activity.").font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center).frame(maxWidth: 220) }
        }.padding(28).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 26))
            .overlay { RoundedRectangle(cornerRadius: 26).stroke(.primary.opacity(0.06)) }
            .shadow(color: .black.opacity(0.12), radius: 24, y: 8)
            .accessibilityElement(children: .combine).accessibilityIdentifier("saveConfirmation")
            .onAppear {
                if reduceMotion { progress = 1 }
                else { withAnimation(.easeOut(duration: 0.3)) { progress = 1 } }
                UIAccessibility.post(notification: .announcement, argument: "Design gespeichert")
            }
    }
}
private struct CheckmarkStroke: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.width * 0.35, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }
    }
}
