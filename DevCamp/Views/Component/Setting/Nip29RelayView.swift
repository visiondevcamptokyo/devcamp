import SwiftUI
import SwiftData

struct Nip29RelayView: View {
    
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    
    @State private var inputText = ""
    
    @Query private var relays: [Relay]
    var chatRelays: [Relay] {
        return relays.filter({ $0.supportsNip29 })
    }
    
    @State var suggestedRelays: [String] = ["wss://groups.0xchat.com", "wss://relay.groups.nip29.com", "wss://groups.yugoatobe.com"]
    var filteredSuggestedRelays: [String] {
        return suggestedRelays.filter { s in !chatRelays.contains { r in r.url == s }}
    }
    
    var body: some View {
            ZStack {
                VStack(spacing: 16) {
                    Image(systemName: "network")
                        .frame(width: 50, height: 50)
                        .foregroundStyle(.white)
                        .imageScale(.large)
                        .font(.largeTitle)
                        .bold()
                        .padding()
                        .background(LinearGradient(colors: [.blue, .blue.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    VStack(spacing: 8) {
                        Text("Add Chat Relay")
                            .font(.title)
                            .bold()
                        Text("Let's get started by adding an nip29 enabled relay")
                            .foregroundStyle(.secondary)
                    }

                    
                    Divider()
                   
                    HStack {
                        TextField("wss://<nip29 enabled relay>", text: $inputText)
                            .textFieldStyle(.roundedBorder)
                        Button("Add") {
                            Task {
                                await addRelay(relayUrl: inputText)
                            }
                        }
                    }

                    
                    List {
                        connectedChatRelaysSection
                        suggestedChatRelaysSection
                    }
                }
                .padding(.top, 32)
                .padding(.bottom, 6)
                .padding(.horizontal)
            }
        }
        
        private var connectedChatRelaysSection: some View {
            Section("Connected Chat Relays") {
                ForEach(chatRelays) { relay in
                    relayRow(relay: relay)
                }
            }
        }
        
        private var suggestedChatRelaysSection: some View {
            Section("Suggested Chat Relays") {
                ForEach(filteredSuggestedRelays, id: \.self) { relay in
                    suggestedRelayRow(relay: relay)
                }
            }
        }
        
        private func relayRow(relay: Relay) -> some View {
            HStack {
                Text(relay.url)
                Spacer()
                Button(action: {
                    Task { await removeRelay(relay: relay) }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .imageScale(.large)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
        
        private func suggestedRelayRow(relay: String) -> some View {
            HStack {
                Text(relay)
                Spacer()
                Button(action: {
                    Task { await addRelay(relayUrl: relay) }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
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
            
            if relay.supportsNip29 {
                inputText = ""
            } else {
                print("This relay does not support Nip 29.")
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
        if let nip1relay = appState.selectedNip1Relay?.url {
            appState.remove(relaysWithUrl: [relay.url, nip1relay])
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
        return chatRelays.count > 0
    }
}
