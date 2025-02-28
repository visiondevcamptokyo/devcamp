import SwiftUI
import GroupActivities
import Nostr

struct SessionDetailView: View {
    @State var inputSharePlayLink = ""
    @EnvironmentObject var appState: AppState
    let group: GroupMetadata
    @State var groupAbout: String = ""
    @State var faceTimeLink: String = ""
    @State var groupActivityManager: GroupActivityManager
    @StateObject private var groupStateObserver = GroupStateObserver()
    
    @State private var sharePlayStatus: String = ""
    
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
                    }
                    HStack(spacing: 8) {
                        Text("By")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        Text(fetchAdminUserMetadata().first?.displayName ?? "")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Text(groupAbout)
                        .font(.body)

                }
                .padding(.horizontal)

                
                HStack(spacing: 20) {
                    // MARK: When a SharePlay session has already been established
                    if groupActivityManager.isSharePlaying {
                        Button(action: {
                            Task {
                                // End The SharePlay Session
                                let didActivate = await groupActivityManager.endSession()
                                if didActivate {
                                    sharePlayStatus = "You have withdrawn from the session."
                                } else {
                                    sharePlayStatus = "Failed to leave session."
                                }
                            }
                        }) {
                            Text("Leave Chat")
                                .frame(maxWidth: .infinity)
                                .padding()
                        }.tint(.red)
                    // MARK: When a Shareplay session has not been established
                    } else {
                        Button(action: {
                            Task{
                                if let url = URL(string: faceTimeLink) {
                                    await UIApplication.shared.open(url)
                                }
                            }
                        }){
                            Text("Facetime")
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .disabled(groupStateObserver.isEligibleForGroupSession ||  faceTimeLink == "")
                        .tint(.green)
                        Button(action: {
                            Task {
                                let activationResult = await DevCampActivity().prepareForActivation()
                                switch activationResult {
                                    case .activationPreferred:
                                        await groupActivityManager.startSession()
                                        sharePlayStatus = "You are in session."

                                    case .activationDisabled:

                                        sharePlayStatus = "SharePlay is not available"
                                    
                                    case .cancelled:
                                        sharePlayStatus = "SharePlay is not available"
                                    @unknown default:
                                        sharePlayStatus = "An unexpected error has occurred."
                                }
                            }
                        }) {
                            Text("Shareplay")
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .disabled(!groupStateObserver.isEligibleForGroupSession)
                        .tint(.green)
                    }
                }
                .padding(.horizontal)
                
                Text(sharePlayStatus)
                    .foregroundColor(.blue)
                    .font(.caption)
                    .padding(.horizontal)

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
                                Text(user.displayName ?? "")
                                    .font(.body)
                                    .bold()
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
                                    Text(user.displayName ?? "")
                                        .font(.body)
                                        .bold()
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
                        }
                    }}
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
            .padding(.trailing, 100)
            .frame(maxWidth: 500)
        }
        .onAppear {
            if let data = group.about?.data(using: .utf8),
               let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
                groupAbout = jsonObject["description"] ?? ""
                faceTimeLink = jsonObject["link"] ?? ""
            }
            if faceTimeLink.isEmpty == true {
                sharePlayStatus = "Facetime link is not set."
            } else {
                sharePlayStatus = faceTimeLink
            }
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
