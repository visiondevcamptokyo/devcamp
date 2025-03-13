import SwiftUI
import SwiftData
import Nostr
import NostrClient

struct SignupView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    
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
                    Text("Name")
                    TextField("Enter name", text: $name)
                        .frame(width: 400)
                        .textFieldStyle(.roundedBorder)
                    Text("About")
                    TextEditor(text: $about)
                        .frame(width: 400, height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                }
                .padding(.vertical)
            }
            .padding()
        }
            
        HStack {
            Button("Back") {
                self.navigationPath.removeLast()
            }
            NavigationLink("Create", value: 2)
                .simultaneousGesture(TapGesture().onEnded {
                    Task {
                        if let ownerAccount = OwnerAccount.createNew() {
                            ownerAccount.selected = true
                            modelContext.insert(ownerAccount)
                            appState.selectedOwnerAccount = ownerAccount
                            
                            await addRelay()
                            
                            // Wait 1 seconds to be connected to relay
                            try? await Task.sleep(nanoseconds: 1_000_000_000)
                            await appState.editUserMetadata(
                                name: "",
                                about: about,
                                picture: "",
                                nip05: "",
                                displayName: name,
                                website: "",
                                banner: "",
                                bot: false,
                                lud16: ""
                            )

                        } else {
                            print("Failed to create OwnerAccount")
                        }
                    }
                })
        }
    }
    
    private func addRelay() async {
//      TODO: Setting up more relays will result in laggy
        let metadataRelayUrls = [
//            "wss://relay.damus.io",
//            "wss://nostr.land",
            "wss://yabu.me",
//            "wss://nos.lol",
        ]
        let nip29relayUrl = "wss://groups.yugoatobe.com"
        
        metadataRelayUrls.forEach { metadataRelayUrl in
            if let metadataRelay = Relay.createNew(withUrl: metadataRelayUrl) {
                modelContext.insert(metadataRelay)
                Task {
                    _ = await metadataRelay.updateRelayInfo()
                    
                    if !metadataRelay.supportsNip1 {
                        print("This relay does not support Nip 1.")
                        modelContext.delete(metadataRelay)
                    }
                }
            }
        }
        
        if let nip29Relay = Relay.createNew(withUrl: nip29relayUrl) {
            modelContext.insert(nip29Relay)
            _ = await nip29Relay.updateRelayInfo()
            
            if !nip29Relay.supportsNip29 {
                print("NO NIP 29")
                modelContext.delete(nip29Relay)
            }
        }
        do {
            try modelContext.save()
        } catch {
            print("Error saving Relay: \(error)")
        }
        await appState.setupYourOwnMetadata()
        await appState.subscribeGroupMetadata()
    }
}
