import SwiftUI
import GroupActivities
import Nostr

struct SessionDetailView: View {
    @State var inputSharePlayLink = ""
    @EnvironmentObject var appState: AppState
    let group: GroupMetadata
    @State var groupActivityManager: GroupActivityManager
    @StateObject private var groupStateObserver = GroupStateObserver()
    @State private var selectedUser: UserMetadata?
    
    var body: some View {
        HStack {
//            PersonaCameraView()
//                .frame(width: 400, height: 400)
//                .background(Color.black)
//                .cornerRadius(10)
//                .padding(.leading, 60)
//            
//            Spacer()

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack{
                        if let pictureURL = group.picture,
                           let url = URL(string: pictureURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                case .failure:
                                    Image("noImage")
                                        .resizable()
                                        .scaledToFill()
                                @unknown default:
                                    Image("noImage")
                                        .resizable()
                                        .scaledToFill()
                                }
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                        } else {
                            Image("noImage")
                                .resizable()
                                .frame(width: 40, height: 40)
                        }
                        Text(group.name ?? "")
                            .font(.title)
                            .bold()
                        
                        Spacer()
                        
                        if appState.allChatGroup.filter({ $0.isAdmin }).contains(where: { $0.id == group.id }) {
                            Button(action: {
                                appState.selectedEditingGroup = group
                                appState.isSheetPresented = true
                            }) {
                                Text("Edit")
                                    .foregroundColor(.white)
                            }
                            .sheet(isPresented: $appState.isSheetPresented) {
                                VStack(alignment: .leading, spacing: 20) {
                                    SessionLinkView()
                                }
                                .presentationDetents([
                                    .large,
                                    .large,
                                    .height(300),
                                    .fraction(1.0),
                                ])
                            }
                        }
                    }
                    HStack(spacing: 8) {
                        Text("By")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text(fetchAdminUserMetadata().first?.displayName ?? "")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Text(group.about ?? "")
                        .font(.body)
                    
                }
                .padding(.horizontal)
                
                
                HStack(spacing: 20) {
                    Button(action: {
                        Task{
                            if let faceTimeLink = group.facetime,
                               let url = URL(string: faceTimeLink) {
                                await UIApplication.shared.open(url)
                            }
                        }
                    }){
                        Text("Facetime")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .disabled(groupStateObserver.isEligibleForGroupSession ||  group.facetime == "")
                    .frame(width: 200, height: 40, alignment: .center)
                    .tint(.green)
                }
                .padding(.horizontal)
                
                if let facetimeLink = group.facetime, !facetimeLink.isEmpty {
                    Text(facetimeLink)
                        .foregroundColor(.blue)
                        .font(.caption)
                        .padding(.horizontal)
                } else {
                    Text("FaceTime Link is not available")
                        .foregroundColor(.blue)
                        .font(.caption)
                        .padding(.horizontal)
                }
                

                VStack(alignment: .leading, spacing: 5) {
                    Text("Admin")
                        .font(.callout)
                    ForEach(fetchAdminUserMetadata(), id: \.publicKey) { user in
                        HStack(alignment: .center, spacing: 10) {
                            if let pictureURL = user.picture,
                               let url = URL(string: pictureURL) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    case .failure:
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .scaledToFill()
                                    @unknown default:
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .scaledToFill()
                                    }
                                }
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 40, height: 40)
                            }
                            
                            VStack(alignment: .leading) {
                                HStack{
                                    Text(user.displayName ?? "")
                                        .font(.body)
                                        .bold()
                                    if user.online == true {
                                        Circle()
                                            .foregroundColor(.green)
                                            .frame(width: 8, height: 8)
                                    }
                                }
                                if let npubkey = try? user.publicKey.bech32FromHex(hrp: "npub") {
                                    Text(npubkey)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                } else {
                                    Text("Invalid Public Key")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                        .onTapGesture {
                            selectedUser = user
                        }
                    }
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Member")
                        .font(.callout)
                    Text("\(countGroupMembers(groupId: group.id))")
                    ScrollView{
                        ForEach(fetchMemberUserMetadata(), id: \.publicKey) { user in
                            HStack(alignment: .center, spacing: 10) {
                                if let pictureURL = user.picture,
                                   let url = URL(string: pictureURL) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        case .failure:
                                            Image(systemName: "person.crop.circle.fill")
                                                .resizable()
                                                .scaledToFill()
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                }

                                VStack(alignment: .leading) {
                                    HStack{
                                        Text(user.displayName ?? "")
                                            .font(.body)
                                            .bold()
                                        if user.online == true {
                                            Circle()
                                                .foregroundColor(.green)
                                                .frame(width: 8, height: 8)
                                        }
                                    }
                                    if let npubkey = try? user.publicKey.bech32FromHex(hrp: "npub") {
                                        Text(npubkey)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    } else {
                                        Text("Invalid Public Key")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            .padding(.vertical, 5)
                            .onTapGesture {
                                selectedUser = user
                            }
                        }
                        .sheet(item: $selectedUser) { user in
                            NavigationView {
                                UserDetailView(user: user)
                                    .navigationTitle(user.displayName ?? user.name ?? "User Detail")
                                    .navigationBarTitleDisplayMode(.inline)
                                    .toolbar {
                                        ToolbarItem(placement: .cancellationAction) {
                                            Button {
                                                selectedUser = nil
                                            } label: {
                                                Image(systemName: "xmark")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 15, height: 15)
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                            }
                            .presentationDetents([.medium, .large])
                        }
                    }}
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
            .padding(.trailing, 100)
            .frame(maxWidth: 500)
        }
    }
                         
    private func countGroupMembers(groupId: String) -> Int {
     let memberCount = appState.allGroupMember
         .filter { $0.groupId == groupId }
         .count
     return memberCount
    }
    
    private func fetchAdminUserMetadata() -> [UserMetadata] {
        let adminPublicKeys = appState.allGroupAdmin
            .filter { $0.groupId == group.id }
            .map { $0.publicKey }

        let adminMetadatas = appState.allUserMetadata.filter { user in
            adminPublicKeys.contains(user.publicKey)
        }
        return adminMetadatas
    }
    
    private func fetchMemberUserMetadata() -> [UserMetadata] {
        
        let memberPublicKeys = appState.allGroupMember
            .filter { $0.groupId == group.id }
            .map { $0.publicKey }
        
        let memberMetadatas = appState.allUserMetadata.filter { user in
            memberPublicKeys.contains(user.publicKey)
        }
        return memberMetadatas
    }
}

struct UserDetailView: View {
    let user: UserMetadata
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                Group {
                    if let pictureURL = user.picture,
                       let url = URL(string: pictureURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 200, height: 200)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200, height: 200)
                            case .failure:
                                Text("No Image")
                                    .frame(width: 200, height: 200)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                            @unknown default:
                                Text("Unknown status")
                                    .frame(width: 200, height: 200)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                            }
                        }
                    } else {
                        Text("No Image")
                            .frame(width: 200, height: 200)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                Group {
                    Text("Public Key")
                        .font(.title2.bold())
                    if let npubkey = try? user.publicKey.bech32FromHex(hrp: "npub") {
                        Text(npubkey)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    } else {
                        Text("No public key available")
                            .foregroundColor(.red)
                            .font(.body)
                            .fontWeight(.bold)
                            .padding(.top, 2)
                    }
                }
                
                Divider().padding(.vertical, 8)
                
                Group {
                    Text("Name")
                        .font(.title2.bold())
                    Text(user.displayName ?? user.name ?? "Unknown")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
                
                Divider().padding(.vertical, 8)
                
                Group {
                    Text("About")
                        .font(.title2.bold())
                    Text(user.about ?? "No information available")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                        .lineLimit(nil)
                }
            }
            .padding(32)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}



