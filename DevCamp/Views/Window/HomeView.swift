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
                    
                    GroupListView(groups: Array(appState.allChatGroup.suffix(20)), groupActivityManager: groupActivityManager)
                    
                    Spacer().frame(height: 30)
                    
                    Text("Groups you belong to")
                        .font(.title2.bold())
                        .padding(.leading, 16)
                    
                    GroupListView(groups: appState.allChatGroup.filter({$0.isMember || $0.isAdmin }), groupActivityManager: groupActivityManager)
                    
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(16)
        }
    }
}

struct InventoryItem: Identifiable {
    var id: String
    let partNumber: String
    let quantity: Int
    let name: String
}
