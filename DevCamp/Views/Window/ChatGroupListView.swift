//import SwiftUI
//import SwiftData
//
//struct ChatGroupView: View {
//    
//    @EnvironmentObject var appState: AppState
//    
//    func latestMessage(for groupId: String) -> ChatMessageMetadata? {
//        return appState.allChatMessage
//            .filter({ $0.groupId == groupId })
//            .sorted(by: { $0.createdAt > $1.createdAt }).first
//    }
//    
//    
//    private var sortedGroups: [ChatGroupMetadata] {
//        appState.allChatGroup.sorted { group1, group2 in
//            let lastMessage1 = latestMessage(for: group1.id)
//            let lastMessage2 = latestMessage(for: group2.id)
//            
//            let date1 = lastMessage1?.createdAt ?? Date.distantPast
//            let date2 = lastMessage2?.createdAt ?? Date.distantPast
//            return date1 > date2
//        }
//    }
//    
//    var body: some View {
//        
//        NavigationSplitView {
//            ChatListView(
//                sortedGroups: sortedGroups,
//                latestMessage: latestMessage
//            )
//            
//        } detail: {
//            ChatDetailView()
//        }
//    }
//}
//
