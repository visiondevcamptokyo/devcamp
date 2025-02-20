import Nostr
import NostrClient
import Foundation

func handleSetMetadata(appState: AppState, event: Event) {
    if let metadata = decodeUserMetadata(from: event.content) {
        let (name, about, picture, nip05, displayName, website, banner, bot, lud16) = metadata
        
        let userMetadata = createUserMetadata(from: event, name: name, about: about, picture: picture, nip05: nip05, displayName: displayName, website: website, banner: banner, bot: bot, lud16: lud16)

        if event.pubkey == appState.selectedOwnerAccount?.publicKey && appState.ownerPostContents.count == 0 {
            handleSelectedOwnerProfile(
                pubkey: event.pubkey,
                name: name,
                about: about,
                picture: picture,
                nip05: nip05,
                displayName: displayName,
                website: website,
                banner: banner,
                bot: bot,
                lud16: lud16,
                appState: appState,
                nostrClient: appState.nostrClient
            )
        }

        updateChatMessages(for: event, with: userMetadata, appState: appState)
    }
}

private func decodeUserMetadata(from content: String) -> (
    name: String?,
    about: String?,
    picture: String?,
    nip05: String?,
    displayName: String?,
    website: String?,
    banner: String?,
    bot: Bool?,
    lud16: String?
)? {
    guard let jsonData = content.data(using: .utf8),
          let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
        return nil
    }

    let name = jsonObject["name"] as? String
    let about = jsonObject["about"] as? String
    let picture = jsonObject["picture"] as? String
    let nip05 = jsonObject["nip05"] as? String
    let displayName = jsonObject["display_name"] as? String
    let website = jsonObject["website"] as? String
    let banner = jsonObject["banner"] as? String
    let bot = jsonObject["bot"] as? Bool
    let lud16 = jsonObject["lud16"] as? String

    return (name, about, picture, nip05, displayName, website, banner, bot, lud16)
}

private func createUserMetadata(from event: Event, name: String?, about: String?, picture: String?, nip05: String?, displayName: String?, website: String?, banner: String?, bot: Bool?, lud16: String?) -> UserMetadata {
    
    let tags = event.tags.map({ $0 })
    let link = tags.first(where: { $0.id == "facetime" })?.otherInformation.first
    
    return UserMetadata(
        publicKey: event.pubkey,
        bech32PublicKey: {
            guard let bech32PublicKey = try? event.pubkey.bech32FromHex(hrp: "npub") else {
                return ""
            }
            return bech32PublicKey
        }(),
        name: name,
        about: about,
        picture: picture,
        nip05: nip05,
        displayName: displayName,
        website: website,
        banner: banner,
        bot: bot,
        lud16: lud16,
        createdAt: event.createdAt.date,
        facetime: link
    )
}

private func updateChatMessages(for event: Event, with userMetadata: UserMetadata, appState: AppState) {
    DispatchQueue.main.async {
        // Edit if the same already exists, add if not
        if let index = appState.allUserMetadata.firstIndex(where: { $0.publicKey == userMetadata.publicKey }) {
            appState.allUserMetadata[index] = userMetadata
        } else {
            appState.allUserMetadata.append(userMetadata)
        }
        appState.allChatMessage = appState.allChatMessage.map { message in
            var updatedMessage = message
            if updatedMessage.publicKey == event.pubkey {
                updatedMessage.userMetadata = userMetadata
            }
            return updatedMessage
        }
    }
}

private func handleSelectedOwnerProfile(
    pubkey: String,
    name: String?,
    about: String?,
    picture: String?,
    nip05: String?,
    displayName: String?,
    website: String?,
    banner: String?,
    bot: Bool?,
    lud16: String?,
    appState: AppState,
    nostrClient: NostrClient
) {
    saveProfileMetadata(
        for: pubkey,
        pubkey: pubkey,
        name: name,
        about: about,
        picture: picture,
        nip05: nip05,
        displayName: displayName,
        website: website,
        banner: banner,
        bot: bot,
        lud16: lud16,
        appState: appState
    )
    subscribeToPostsForOwner(appState: appState, nostrClient: nostrClient)
}

private func saveProfileMetadata(
    for key: String,
    pubkey: String,
    name: String?,
    about: String?,
    picture: String?,
    nip05: String?,
    displayName: String?,
    website: String?,
    banner: String?,
    bot: Bool?,
    lud16: String?,
    appState: AppState)
{
    let metadata = ProfileMetadata(
        id: key,
        pubkey: pubkey,
        name: name,
        about: about,
        picture: picture,
        nip05: nip05,
        displayName: displayName,
        website: website,
        banner: banner,
        bot: bot,
        lud16: lud16
    )
    DispatchQueue.main.async {
        appState.profileMetadata = metadata
    }
}

private func subscribeToPostsForOwner(appState: AppState, nostrClient: NostrClient) {
    guard let publicKey = appState.selectedOwnerAccount?.publicKey else { return }
    let postSubscription = Subscription(filters: [.init(authors: [publicKey], kinds: [Kind.textNote])])
    nostrClient.add(subscriptions: [postSubscription])
}

func formatNostrTimestamp(_ nostrTimestamp: Nostr.Timestamp) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(nostrTimestamp.timestamp))
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return dateFormatter.string(from: date)
}

func getProfileMetadata(for key: String, appState: AppState) -> ProfileMetadata? {
    return appState.profileMetadata
}
