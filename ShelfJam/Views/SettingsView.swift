import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @State private var showingResetConfirmation = false

    init(progressStore: any ProgressStore) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(progressStore: progressStore))
    }

    var body: some View {
        Form {
            Section("Play") {
                Toggle("Background Music", isOn: $viewModel.backgroundMusicEnabled)
                Toggle("Game Sounds", isOn: $viewModel.gameSoundEnabled)
                Toggle("Haptics", isOn: $viewModel.hapticsEnabled)
            }

            Section("Progress") {
                Button(role: .destructive) {
                    showingResetConfirmation = true
                } label: {
                    Label("Reset Progress", systemImage: "arrow.counterclockwise")
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("MVP 1.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog("Reset all local progress?", isPresented: $showingResetConfirmation, titleVisibility: .visible) {
            Button("Reset Progress", role: .destructive) {
                viewModel.resetProgress()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
