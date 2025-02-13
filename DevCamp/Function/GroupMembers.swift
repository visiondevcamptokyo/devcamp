import Foundation
import Nostr

func handleGroupMembers(appState: AppState, event: Event, relayUrl: String) {
    let tags = event.tags.map { $0 }
    
    guard let groupTag = tags.first(where: { $0.id == "d" }),
          let groupId = groupTag.otherInformation.first else {
        return
    }
    
    let publicKeys = tags.filter { $0.id == "p" }.compactMap { $0.otherInformation.first }
    
    DispatchQueue.main.async {
    
        appState.allGroupMember.removeAll { member in
            member.groupId == groupId && !publicKeys.contains(member.publicKey)
        }
    
        for publicKey in publicKeys {
            let member = GroupMember(
                id: UUID().uuidString,
                publicKey: publicKey,
                groupId: groupId,
                relayUrl: relayUrl
            )
            if !appState.allGroupMember.contains(where: { $0.groupId == groupId && $0.publicKey == publicKey }) {
                appState.allGroupMember.append(member)
            }
            
            if publicKey == appState.selectedOwnerAccount?.publicKey {
                // Update the isMember property of allChatGroup
                if let index = appState.allChatGroup.firstIndex(where: { $0.id == groupId }) {
                    appState.allChatGroup[index].isMember = true
                }
            }
        }
    }
}
