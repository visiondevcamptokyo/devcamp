import SwiftUI
import SwiftData

struct SigninView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    
    @State private var inputText = ""
    @Binding var navigationPath: NavigationPath
    @State private var errorMessage: String? = nil
    
    @State private var newOrImport = [0, 1]
    
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
                    .background(LinearGradient(colors: [.orange, .orange.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(spacing: 8) {
                    Text("Account Setup")
                        .font(.title)
                        .bold()
                    Text("Import your nsec or hex key")
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                VStack(alignment: .trailing) {
                    Divider()
                    SecureField("nsec1... or hex", text: $inputText)
                        .textFieldStyle(.roundedBorder)
                    Text("Paste in your nsec1 or hex private key to import")
                        .foregroundStyle(.tertiary)
                        .font(.caption)
                        .italic()
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .bold()
                    }
                }
                .frame(maxWidth: 500)
                .padding(.vertical)
            }
            .padding(.top, 32)
            .padding(.bottom, 6)
            .padding(.horizontal)
        }
        HStack {
            Button("Back") {
                self.navigationPath.removeLast()
            }
            Button(action: {
                if let ownerAccount = OwnerAccount.restore(withPrivateKeyHexOrNsec: inputText) {
                    if let currentOwners = try? modelContext.fetch(FetchDescriptor<OwnerAccount>()) {
                        for owner in currentOwners {
                            owner.selected = false
                        }
                    }
                    ownerAccount.selected = true
                    modelContext.insert(ownerAccount)
                    appState.selectedOwnerAccount = ownerAccount
                    Task {
                        await addRelay()
                    }
                    
                    errorMessage = nil
                    navigationPath.append(2)
                } else {
                    print("Something went wrong")
                    errorMessage = "No account exists"
                }
            }) {
                Text("Import")
            }
            .buttonStyle(.borderedProminent)
            .disabled(inputText.isEmpty)
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
        let nip29relayUrl = "wss://groups.0xchat.com"
        
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
