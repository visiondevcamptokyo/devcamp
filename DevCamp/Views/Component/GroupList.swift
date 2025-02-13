import SwiftUI

struct GroupCard: View {
    @EnvironmentObject var appState: AppState
    @State var groupActivityManager: GroupActivityManager
    @State private var isShowingDetail = false
    
    let group: ChatGroupMetadata
    
    var body: some View {
        VStack(alignment: .leading) {
            Group{
                if let imageUrl = group.picture, !imageUrl.isEmpty, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 250, height: 250)
                                    .cornerRadius(12)
                            case .success(let image):
                                image
                                    .resizable()
                                    .frame(width: 250, height: 250)
                                    .cornerRadius(12)
                            case .failure:
                                Image("noImage")
                                    .resizable()
                                    .frame(width: 250, height: 250)
                                    .cornerRadius(12)
                            @unknown default:
                                Image("noImage")
                                    .resizable()
                                    .frame(width: 250, height: 250)
                                    .cornerRadius(12)
                        }
                    }
                } else {
                    Image("noImage")
                        .resizable()
                        .frame(width: 250, height: 250)
                        .cornerRadius(12)
                }
            }
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        Text(group.name ?? "")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                            Text("\(countGroupMembers(groupId: group.id))")
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.3))
                    .clipShape(RoundedCorners(cornerRadius: 12, corners: [.bottomLeft, .bottomRight]))
                }
            )
        }
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .cornerRadius(12)
        .hoverEffect()
        .background(Color(UIColor.systemBackground))
        .onTapGesture {
            appState.selectedGroup = group
            isShowingDetail = true
        }
        .navigationDestination(isPresented: $isShowingDetail){
            SessionDetailView(group: group, groupActivityManager: groupActivityManager)
        }
        // MARK: これがないと背景に謎の丸が出てくるので必ず残しておく
        .buttonStyle(PlainButtonStyle())
    }
    
    private func countGroupMembers(groupId: String) -> Int {
        let memberCount = appState.allGroupMember
            .filter { $0.groupId == groupId }
            .count
        return memberCount
    }
}



struct GroupListView: View {
    let groups: Array<ChatGroupMetadata>
    @EnvironmentObject var appState: AppState
    @State var groupActivityManager: GroupActivityManager
    
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(groups, id: \.id) { group in
                        GroupCard(groupActivityManager: groupActivityManager, group: group)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

