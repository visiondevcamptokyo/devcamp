import SwiftData
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @State var groupActivityManager: GroupActivityManager
    @State private var searchText = ""
    @State private var sheetDetail: InventoryItem?
    
    var hasDisconnectedRelay: Bool {
        appState.statuses.values.contains(false) || appState.statuses.isEmpty || appState.statuses.count < 2
    }
    
    var body: some View {
        ZStack {
            VStack {
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
                    
                    Button("Reload") {
                        Task {
                            await resetState()
                            await appState.setupYourOwnMetadata()
                            await appState.subscribeGroupMetadata()
                        }
                    }
                    .padding(.trailing, 10)
                    
                    Button("+ Create Session") {
                        appState.isSheetPresented = true
                    }
                    .sheet(isPresented: $appState.isSheetPresented) {
                        VStack(alignment: .leading, spacing: 20) {
                            SessionLinkView()
                        }
                        .presentationDetents([
                            .large,
                            .large,
                            .height(300),
                            .fraction(1.0)
                        ])
                    }
                }
                .padding([.top, .leading, .trailing], 16)
                
                ScrollView {
                    VStack(alignment: .leading) {
                        Spacer().frame(height: 30)
                        
                        Text("Latest Sessions")
                            .font(.title2.bold())
                            .padding(.leading, 16)
                        
                        GroupListView(groups: filteredAllGroups, groupActivityManager: groupActivityManager)
                        
                        Spacer().frame(height: 30)
                        
                        Text("Sessions you belong to")
                            .font(.title2.bold())
                            .padding(.leading, 16)
                        
                        GroupListView(groups: filteredOwnedGroups, groupActivityManager: groupActivityManager)
                        
                        Spacer().frame(height: 30)
                        
                        Text("Sessions you are an administrator of")
                            .font(.title2.bold())
                            .padding(.leading, 16)
                        
                        GroupListView(groups: filteredAdminGroups, groupActivityManager: groupActivityManager)
                        
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(16)
            }
            
            if hasDisconnectedRelay {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                
                VStack() {
                    Text("Some relays are disconnected. Please reload.\n If relays do not appear after reloading, edit the relay from the Setting Screen.")
                        .multilineTextAlignment(.center)
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding()
                        .cornerRadius(8)
                    
                    Button("Reload") {
                        Task {
                            await resetState()
                            await appState.setupYourOwnMetadata()
                            await appState.subscribeGroupMetadata()
                        }
                    }
                    .cornerRadius(8)
                    .padding(.bottom, 10)
                }
                .background(Color.gray.opacity(0.8))
                .cornerRadius(10)
                .padding()
            }
        }
    }
    
    private var filteredAllGroups: [GroupMetadata] {
        if searchText.isEmpty {
            return Array(appState.allChatGroup)
        } else {
            return appState.allChatGroup.filter { group in
                group.name?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
    
    private var filteredOwnedGroups: [GroupMetadata] {
        let ownedGroups = appState.allChatGroup.filter { $0.isMember || $0.isAdmin }
        if searchText.isEmpty {
            return ownedGroups
        } else {
            return ownedGroups.filter { group in
                group.name?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
    
    private var filteredAdminGroups: [GroupMetadata] {
        let adminGroups = appState.allChatGroup.filter { $0.isAdmin }
        if searchText.isEmpty {
            return adminGroups
        } else {
            return adminGroups.filter { group in
                group.name?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
    
    private func resetState() async {
        do {
            let relays = try modelContext.fetch(FetchDescriptor<Relay>())
            let relaysUrl = relays.map(\.url)
            appState.remove(relaysWithUrl: relaysUrl)
        } catch {
            print("Failed to fetch relays: \(error)")
        }
        
        appState.lastEditGroupMetadataEventId = nil
        appState.lastCreateGroupMetadataEventId = nil
        appState.createdGroupMetadata = (ownerAccount: nil, groupId: nil, picture: nil, name: nil, about: nil)
        appState.isSheetPresented = false
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
