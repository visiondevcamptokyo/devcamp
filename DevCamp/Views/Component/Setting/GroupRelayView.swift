import SwiftUI
import SwiftData

struct GroupRelayView: View {
    
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    
    @State private var inputText = ""
    
    @Query private var relays: [Relay]
    var groupRelay: Relay? {
        relays.first(where: { $0.supportsNip29 })
    }
    
    @State var suggestedRelays: [String] = [
        "wss://groups.yugoatobe.com",
        "wss://groups.0xchat.com",
        "wss://relay.groups.nip29.com"
    ]
    
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
                        Text("Group Relay")
                            .font(.title)
                            .bold()
                        Text("Please select the relay corresponding to the group you use.")
                            .foregroundStyle(.secondary)
                    }
                    
                    Divider()
                    
                    if let groupRelay = groupRelay {
                        List {
                            Section("Connected Group Relays") {
                                relayRow(relay: groupRelay)
                            }
                        }
                    } else {
                        VStack {
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
                                suggestedGroupRelaysSection
                            }
                            .padding(.top, 8)
                        }
                    }
                }
                .padding(.top, 32)
                .padding(.bottom, 6)
                .padding(.horizontal)
            }
        }
        
        private var suggestedGroupRelaysSection: some View {
            Section("Suggested Chat Relays") {
                ForEach(suggestedRelays, id: \.self) { relay in
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
            
            await appState.subscribeGroupMetadata()
        }
    }

    
    func removeRelay(relay: Relay) async {
        appState.remove(relaysWithUrl: [relay.url])
        
        appState.selectedGroup = nil
        appState.allGroupMember.removeAll()
        appState.allGroupAdmin.removeAll()
        appState.allChatGroup.removeAll()
        appState.allChatMessage.removeAll()
        modelContext.delete(relay)
        do {
            try modelContext.save()
        } catch {
            print("Failed to remove relay: \(error)")
        }
    }
}
