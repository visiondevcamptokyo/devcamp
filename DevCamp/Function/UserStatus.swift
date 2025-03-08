import Nostr
import NostrClient
import Foundation

func handleUserStatus(appState: AppState, event: Event) {
    let tags = event.tags.map { $0 }
    guard let statusTag = tags.first(where: { $0.id == "d" }),
          let statusName = statusTag.otherInformation.first else {
        return
    }
    
    DispatchQueue.main.async {
        if statusName == "online" {
            let statusInfo = event.content
            if let index = appState.allUserMetadata.firstIndex(where: { $0.publicKey == event.pubkey }) {
                appState.allUserMetadata[index].online = Bool(statusInfo) ?? false
            }
        }
        print("パブリックキー: \(event.pubkey)")
        print("content: \(event.content)")
    }
}
