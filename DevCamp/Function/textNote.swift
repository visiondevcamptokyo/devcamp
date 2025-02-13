import Foundation
import Nostr

func handleTextNote(appState: AppState, event: Event) {
    if let metadata = getProfileMetadata(for: event.pubkey, appState: appState) {
        let timeStampString = formatNostrTimestamp(event.createdAt)
        let post = PostMetadata(
            id: UUID().uuidString,
            text: event.content,
            name: metadata.name,
            picture: metadata.picture,
            timeStamp: timeStampString
        )
        appendOwnerPost(post, appState: appState)
        sortOwnerPostsByTimestamp(appState: appState)
    }
}

private func appendOwnerPost(_ post: PostMetadata, appState: AppState) {
    DispatchQueue.main.async {
        appState.ownerPostContents.append(post)
    }
}

private func sortOwnerPostsByTimestamp(appState: AppState) {
    DispatchQueue.main.async {
        appState.ownerPostContents.sort { post1, post2 in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            if let date1 = dateFormatter.date(from: post1.timeStamp),
               let date2 = dateFormatter.date(from: post2.timeStamp) {
                return date1 > date2
            }
            return false
        }
    }
}
