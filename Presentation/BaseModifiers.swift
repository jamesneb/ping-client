// File: internal/presentation/components/BaseModifiers.swift
import SwiftUI

struct PressAction: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

extension View {
    func pressAction(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.modifier(PressAction(onPress: onPress, onRelease: onRelease))
    }
}


struct BaseButton: ViewModifier {
    let gradient: Gradient
    let pressedGradient: Gradient
    @State private var isPressed = false
    @State private var isHovering = false
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    gradient: isPressed ? pressedGradient : gradient,
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
            .foregroundColor(.white)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovering = hovering
                }
            }
            .pressAction(onPress: {
                isPressed = true
            }, onRelease: {
                isPressed = false
            })
    }
}

struct BaseContainer: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(24)
            .background(AppColors.messageBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
}

struct BaseInput: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(height: 36)
            .padding(.horizontal, 12)
            .background(AppColors.inputBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.inputBorder, lineWidth: 1)
            )
    }
}
