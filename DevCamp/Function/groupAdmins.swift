import Foundation
import Nostr

func handleGroupAdmins(appState: AppState, event: Event, relayUrl: String) {
    let tags = event.tags.map { $0 }
    
    guard let groupTag = tags.first(where: { $0.id == "d" }),
          let groupId = groupTag.otherInformation.first else {
        return
    }
    
    let pTags = tags.filter { $0.id == "p" }.compactMap { $0.otherInformation.first }
    guard let publicKey = pTags.first else { return }
    
    let capabilities: Set<GroupAdmin.Capability> = Set(
        pTags.dropFirst(2).compactMap { GroupAdmin.Capability(rawValue: $0) }
    )
    
    let admin = GroupAdmin(
        id: UUID().uuidString,
        publicKey: publicKey,
        groupId: groupId,
        capabilities: capabilities,
        relayUrl: relayUrl
    )
    
    DispatchQueue.main.async {
        if !appState.allGroupAdmin.contains(where: { $0.groupId == admin.groupId }){
            appState.allGroupAdmin.append(admin)
        }
    
        if publicKey == appState.selectedOwnerAccount?.publicKey {
            // Update isAdmin of allChatGroup
            if let index = appState.allChatGroup.firstIndex(where: { $0.id == groupId }) {
                appState.allChatGroup[index].isAdmin = true
            } else {
                let adminGroupSubscription = Subscription(
                    filters: [Filter(
                        kinds: [Kind.groupMetadata],
                        tags: [Tag(id: "d", otherInformation: groupId)]
                    ),],
                    id: AddAdminGroup
                )
                if let relayUrl = appState.selectedNip29Relay?.url {
                    appState.nostrClient.add(relayWithUrl: relayUrl, subscriptions: [adminGroupSubscription])
                }
            }
        }
    }
}

