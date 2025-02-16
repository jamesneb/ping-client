import Foundation
import SwiftUI

public struct ControlPanelView: View {
    @State private var selectedItem: String? = nil
    @State private var noiseImage: NSImage?
    
    // This function generates gradients dynamically based on the item type and selection state
    private func getGradient(for type: String, isSelected: Bool) -> Gradient {
        switch type {
        case "newMeeting":
            return Gradient(colors: [
                Color(.sRGB, red: isSelected ? 1.0 : 0.9, green: isSelected ? 0.5 : 0.4, blue: isSelected ? 0.4 : 0.3, opacity: 1),
                Color(.sRGB, red: isSelected ? 0.9 : 0.8, green: isSelected ? 0.3 : 0.2, blue: isSelected ? 0.4 : 0.3, opacity: 1)
            ])
        case "archive":
            return Gradient(colors: [
                Color(.sRGB, red: 0.2, green: isSelected ? 0.9 : 0.8, blue: isSelected ? 0.8 : 0.7, opacity: 1),
                Color(.sRGB, red: 0.1, green: isSelected ? 0.7 : 0.6, blue: isSelected ? 0.7 : 0.6, opacity: 1)
            ])
        case "schedule":
            return Gradient(colors: [
                Color(.sRGB, red: isSelected ? 0.7 : 0.6, green: isSelected ? 0.5 : 0.4, blue: isSelected ? 1.0 : 0.9, opacity: 1),
                Color(.sRGB, red: isSelected ? 0.5 : 0.4, green: isSelected ? 0.3 : 0.2, blue: isSelected ? 0.9 : 0.8, opacity: 1)
            ])
        default:
            return Gradient(colors: [.gray, .gray])
        }
    }
    
    // A helper function to create navigation items, reducing repetition in the main view
    private func navigationItem(type: String, icon: String, title: String) -> some View {
        VStack(alignment: .center, spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .frame(width: 48, height: 48)
                .foregroundColor(.white)
                .background(
                    LinearGradient(
                        gradient: getGradient(for: type, isSelected: selectedItem == type),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(selectedItem == type ? 0.3 : 0.1), lineWidth: 1)
                )
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }
    
    public var body: some View {
        NavigationSplitView {
            List(selection: $selectedItem) {
                Group {
                    NavigationLink(value: "newMeeting") {
                        navigationItem(type: "newMeeting", icon: "video.badge.plus", title: "New Meeting")
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink(value: "archive") {
                        navigationItem(type: "archive", icon: "archivebox.fill", title: "Archive")
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink(value: "schedule") {
                        navigationItem(type: "schedule", icon: "calendar", title: "My Schedule")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }
            .listStyle(.sidebar)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.sRGB, red: 0.2, green: 0.3, blue: 0.5, opacity: 0.95),
                        Color(.sRGB, red: 0.1, green: 0.2, blue: 0.4, opacity: 0.95)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .scrollContentBackground(.hidden)
        } detail: {
            ZStack {
                if let image = noiseImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                }
                
                if let selectedItem = selectedItem {
                    switch selectedItem {
                    case "newMeeting":
                        ContentView()
                    case "archive":
                        Text("Archive View")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppColors.primaryText)
                    case "schedule":
                        Text("Schedule View")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppColors.primaryText)
                    default:
                        Text("Select an item")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppColors.primaryText)
                    }
                } else {
                    Text("Select an item")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.primaryText)
                }
            }
        }
        .onAppear {
            noiseImage = loadNoiseImage(from: "background")
        }
    }
}
