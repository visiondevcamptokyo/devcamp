import SwiftData
import SwiftUI

/// A view that presents the app's content library.
struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @State var groupActivityManager: GroupActivityManager
    @State private var searchText = ""
    @State private var sheetDetail: InventoryItem?

    var body: some View {
        ScrollView {
            VStack {
                Spacer().frame(height: 10)
                
                HStack {
                    Spacer()
                    HStack {
                        TextField("Search", text: $searchText)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.gray.opacity(0.4))
                            .cornerRadius(32)
                            .frame(width: 500)
                            .frame(height: 40)
                        Spacer()
                    }
                    .padding()
                    .foregroundColor(Color.gray.opacity(0.4))
                    .cornerRadius(12)
                    .frame(height: 40)
                    
                    Spacer()
                    
                    Button("Reload"){
                        Task {
                            await resetState()
                            await appState.setupYourOwnMetadata()
                            await appState.subscribeGroupMetadata()
                        }
                    }
                    .padding(.trailing, 10)
                    
                    Button("+ Start Session") {
                        sheetDetail = InventoryItem(
                            id: "0123456789",
                            partNumber: "Z-1234A",
                            quantity: 100,
                            name: "Widget")
                    }
                    .sheet(item: $sheetDetail) { detail in
                        VStack(alignment: .leading, spacing: 20) {
                            CreateSessionView(sheetDetail: $sheetDetail)
                        }
                        .presentationDetents([
                            .large,
                            .large,
                            .height(300),
                            .fraction(1.0),
                        ])
                    }
                    
                }
                
                VStack(alignment: .leading) {
                    
                    Spacer().frame(height: 30)
                    
                    Text("Recent Groups")
                        .font(.title2.bold())
                        .padding(.leading, 16)
                    
                    GroupListView(groups: filteredAllGroups, groupActivityManager: groupActivityManager)
                    
                    Spacer().frame(height: 30)
                    
                    Text("Groups you belong to")
                        .font(.title2.bold())
                        .padding(.leading, 16)
                    
                    GroupListView(groups: filteredOwnedGroups, groupActivityManager: groupActivityManager)
                    
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(16)
        }
    }
    
    // To get search results for allChatGroup
    private var filteredAllGroups: [ChatGroupMetadata] {
        if searchText.isEmpty {
            return Array(appState.allChatGroup)
        } else {
            return appState.allChatGroup.filter { group in
                group.name?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }

    // further narrow down the search results to groups to which you belong
    private var filteredOwnedGroups: [ChatGroupMetadata] {
        let ownedGroups = appState.allChatGroup.filter { $0.isMember || $0.isAdmin }
        if searchText.isEmpty {
            return ownedGroups
        } else {
            return ownedGroups.filter { group in
                group.name?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
    
    private func resetState() async {
        do {
            let relays = try modelContext.fetch(FetchDescriptor<Relay>());
            let relaysUrl = relays.map(\.url)
            appState.remove(relaysWithUrl: relaysUrl)
        } catch {
            print("Failed to fetch relays: \(error)")
        }
        
        appState.lastEditGroupMetadataEventId = nil
        appState.lastCreateGroupMetadataEventId = nil
        appState.createdGroupMetadata = (ownerAccount: nil, groupId: nil, name: nil, about: nil)
        appState.shouldCloseEditSessionLinkSheet = false
        appState.selectedOwnerAccount = nil
        appState.selectedNip1Relays = []
        appState.selectedNip29Relay = nil
        appState.selectedGroup = nil
        appState.selectedEditingGroup = nil
        appState.allChatGroup = []
        appState.allChatMessage = []
        appState.allUserMetadata = []
        appState.allGroupAdmin = []
        appState.allGroupMember = []
        appState.chatMessageNumResults = 50
        appState.statuses = [:]
        appState.ownerPostContents = []
        appState.profileMetadata = nil
    }
}

struct InventoryItem: Identifiable {
    var id: String
    let partNumber: String
    let quantity: Int
    let name: String
}
