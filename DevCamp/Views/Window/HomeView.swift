import SwiftData
import SwiftUI

/// A view that presents the app's content library.
struct HomeView: View {
    @EnvironmentObject private var appState: AppState
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
                            .frame(width: 600)
                            .frame(height: 40)
                        Spacer()
                    }
                    .padding()
                    .foregroundColor(Color.gray.opacity(0.4))
                    .cornerRadius(12)
                    .frame(height: 40)
                    
                    Spacer()
                    
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
}

struct InventoryItem: Identifiable {
    var id: String
    let partNumber: String
    let quantity: Int
    let name: String
}
