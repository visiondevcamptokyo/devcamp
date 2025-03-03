import Foundation
import Nostr

func handleGroupMetadata(appState: AppState, event: Event) {
    
    let tags = event.tags.map({ $0 })
    let createdAt = event.createdAt
    guard let groupId = tags.first(where: { $0.id == "d" })?.otherInformation.first else { return }
    let isPublic = tags.first(where: { $0.id == "private" }) == nil
    let isOpen = tags.first(where: { $0.id == "closed" }) == nil
    let name = tags.first(where: { $0.id == "name" })?.otherInformation.first
    var about = ""
    var faceTime = ""
    let picture = tags.first(where: { $0.id == "picture" })?.otherInformation.first
    
    if let aboutJson = tags.first(where: { $0.id == "about" })?.otherInformation.first,
       let data = aboutJson.data(using: .utf8),
       let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
        about = jsonObject["description"] ?? ""
        faceTime = jsonObject["link"] ?? ""
        
    } else {
        return
    }
    
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    dateFormatter.timeZone = TimeZone.current
    let formattedDate = dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(createdAt.timestamp)))
    
    let metadata = GroupMetadata(
        id: groupId,
        createdAt: formattedDate,
        relayUrl: appState.selectedNip29Relay?.url ?? "",
        name: name,
        picture: picture,
        about: about,
        facetime: faceTime,
        isPublic: isPublic,
        isOpen: isOpen,
        isMember: false,
        isAdmin: false
    )
    
    DispatchQueue.main.async {
        if let index = appState.allChatGroup.firstIndex(where: { $0.id == groupId }) {
            appState.allChatGroup[index].name = metadata.name
            appState.allChatGroup[index].picture = metadata.picture
            appState.allChatGroup[index].about = metadata.about
            appState.allChatGroup[index].facetime = metadata.facetime
        } else {
            appState.allChatGroup.append(metadata)
        }
        
        // Extract the top 20 groups from the newest group metadata
        let sorted = appState.allChatGroup.sorted { a, b in
            guard
                let dateA = dateFormatter.date(from: a.createdAt),
                let dateB = dateFormatter.date(from: b.createdAt)
            else {
                return false
            }
            return dateA > dateB
        }
        appState.allChatGroup = Array(sorted.prefix(20))
    }
}
