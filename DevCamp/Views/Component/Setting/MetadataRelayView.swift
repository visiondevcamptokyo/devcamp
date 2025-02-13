import SwiftUI
import SwiftData

struct MetadataRelayView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    
    @State private var inputText = ""
    
    @Query private var relays: [Relay]
    var metadataRelays: [Relay] {
        //TODO: 【ARERT】Metadata用のリレーとGroup用のリレーが一致する可能性はある。その際にエラーとなりかねないので注意
        relays.filter { !$0.supportsNip29 }
    }
    
    @State private var suggestedRelays: [String] = ["wss://relay.damus.io", "wss://nostr.land", "wss://yabu.me"]
    var filteredSuggestedRelays: [String] {
        let relayUrls = relays.map { $0.url }
        return suggestedRelays.filter { !relayUrls.contains($0) }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            relayIcon
            relayDescription
            Divider()
            relayInput
            relayList
        }
        .padding(.top, 32)
        .padding(.bottom, 6)
        .padding(.horizontal)
    }
    
    private var relayIcon: some View {
        Image(systemName: "network")
            .frame(width: 50, height: 50)
            .foregroundStyle(.white)
            .imageScale(.large)
            .font(.largeTitle)
            .bold()
            .padding()
            .background(LinearGradient(colors: [.purple, .purple.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var relayDescription: some View {
        VStack(spacing: 8) {
            Text("Add Metadata Relay")
                .font(.title)
                .bold()
            Text("Adding a metadata relay allows you to retrieve and store extra info")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var relayInput: some View {
        HStack {
            TextField("wss://<metadata relay>", text: $inputText)
                .textFieldStyle(.roundedBorder)
            Button("Add") {
                Task {
                    await addRelay(relayUrl: inputText)
                }
            }
        }
    }
    
    private var relayList: some View {
        List {
            Section("Connected Metadata Relays") {
                ForEach(metadataRelays) { relay in
                    HStack {
                        Text(relay.url)
                        Spacer()
                        Button(action: {
                            Task {
                                await removeRelay(relay: relay)
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .imageScale(.large)
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Section("Suggested Metadata Relays") {
                ForEach(filteredSuggestedRelays, id: \.self) { (relay: String) in
                    HStack {
                        Text(relay)
                        Spacer()
                        Button(action: {
                            Task {
                                await addRelay(relayUrl: relay)
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .imageScale(.large)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    
    func addRelay(relayUrl: String) async {
        guard !relays.contains(where: { $0.url == relayUrl }) else {
            print("This relay is already in your list.")
            inputText = ""
            return
        }
        
        if let relay = Relay.createNew(withUrl: relayUrl) {
            await relay.updateRelayInfo()
            
            if relay.supportsNip1 {
                inputText = ""
            } else {
                print("This relay does not support Nip 1.")
                return
            }
            
            modelContext.insert(relay)
            do {
                try modelContext.save()
            } catch {
                print("Failed to save relay: \(error)")
                return
            }
            
            await appState.setupYourOwnMetadata()
            await appState.subscribeGroupMetadata()
        }
    }
    
    func removeRelay(relay: Relay) async {
        if let nip29relay = appState.selectedNip29Relay?.url {
            appState.remove(relaysWithUrl: [relay.url, nip29relay])
        }
        appState.selectedGroup = nil
        appState.selectedOwnerAccount = nil
        appState.allGroupMember.removeAll()
        appState.allGroupAdmin.removeAll()
        appState.allChatGroup.removeAll()
        appState.allChatMessage.removeAll()
        appState.allUserMetadata.removeAll()
        appState.ownerPostContents.removeAll()
        appState.profileMetadata = nil
        modelContext.delete(relay)
        do {
            try modelContext.save()
        } catch {
            print("Failed to remove relay: \(error)")
        }
    }
    
    func nextEnabled() -> Bool {
        !relays.isEmpty
    }
}
