import SwiftUI
import SwiftData
import Nostr
import NostrClient

struct SignupView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    
    @State private var userName: String = ""
    @State private var name: String = ""
    @State private var about: String = ""
    
    @Binding var navigationPath: NavigationPath
    
    @State private var newOrImport = [0, 1]
    
    @Query private var relays: [Relay]
    var nostrClient = NostrClient()
    
    var body: some View {
        ZStack {
            
            VStack(spacing: 16) {
                Image(systemName: "key.horizontal")
                    .frame(width: 50, height: 50)
                    .foregroundStyle(.white)
                    .imageScale(.large)
                    .font(.largeTitle)
                    .bold()
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.orange, .orange.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(spacing: 8) {
                    Text("Account Setup")
                        .font(.title)
                        .bold()
                    Text("Keys can be found in the settings screen after account creation.")
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                
                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Username")
                    TextField("Username", text: $userName)
                        .textFieldStyle(.roundedBorder)
                    Text("Name")
                    TextField("Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                    Text("About")
                    TextEditor(text: $about)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                }
                .frame(maxWidth: 600)
                .padding(.vertical)
            }
            .padding()
        }
            
        HStack {
            Button("Back") {
                self.navigationPath.removeLast()
            }
            Button("Create") {
                Task {
                    await appState.editUserMetadata(
                        name: userName,
                        about: about,
                        picture: "",
                        nip05: "",
                        displayName: name,
                        website: "",
                        banner: "",
                        bot: false,
                        lud16: ""
                    )
                }
                appState.registeredNsec = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
