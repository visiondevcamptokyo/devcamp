import Foundation
import SwiftUI
import SwiftData
import KeychainAccess
import NostrClient
import Nostr

class AppState: ObservableObject {
    
    var modelContainer: ModelContainer?
    var nostrClient = NostrClient()
    
    var checkUnverifiedTimer: Timer?
    var checkVerifiedTimer: Timer?
    var checkBusyTimer: Timer?
    
    /// ID of the last groupEditMetadata event that was sent.
    @Published var lastEditGroupMetadataEventId: String?
    @Published var lastCreateGroupMetadataEventId: String?
    @Published var lastDeleteUserMetadataEventId: String?
    @Published var lastDeleteUserMetadataModelContext : ModelContext?
    @Published var createdGroupMetadata: (ownerAccount: OwnerAccount?, groupId: String?, picture: String?, name: String?, about: String?)
    
    /// Flag to close the EditSessionLink sheet once the Relay returns OK
    @Published var isSheetPresented: Bool = false
    @Published var isCreateLoading: Bool = false
    
    @Published var registeredNsec: Bool = true
    @Published var selectedOwnerAccount: OwnerAccount?
    @Published var selectedNip1Relays: Array<Relay> = []
    @Published var selectedNip29Relay: Relay?
    @Published var selectedGroup: GroupMetadata? {
        didSet {
            chatMessageNumResults = 50
        }
    }
    @Published var selectedEditingGroup: GroupMetadata?
    @Published var allChatGroup: Array<GroupMetadata> = []
    @Published var allChatMessage: Array<ChatMessageMetadata> = []
    @Published var allUserMetadata: Array<UserMetadata> = []
    @Published var allGroupAdmin: Array<GroupAdmin> = []
    @Published var allGroupMember: Array<GroupMember> = []
    
    @Published var chatMessageNumResults: Int = 50
    
    @Published var statuses: [String: Bool] = [:]
    
    @Published var ownerPostContents: Array<PostMetadata> = []
    @Published var profileMetadata: ProfileMetadata?
    
    init() {
        nostrClient.delegate = self
    }
    
    func backgroundContext() -> ModelContext? {
        guard let modelContainer else { return nil }
        return ModelContext(modelContainer)
    }
    
    func getModels<T: PersistentModel>(context: ModelContext, modelType: T.Type, predicate: Predicate<T>) -> [T]? {
        let descriptor = FetchDescriptor<T>(predicate: predicate)
        return try? context.fetch(descriptor)
    }
    
    func getOwnerAccount(forPublicKey publicKey: String, modelContext: ModelContext?) async -> OwnerAccount? {
        let desc = FetchDescriptor<OwnerAccount>(predicate: #Predicate<OwnerAccount>{ pkm in
            pkm.publicKey == publicKey
        })
        return try? modelContext?.fetch(desc).first
    }
    
    
    // MARK: Retrieve your own data from SwiftData in the MetadataRelay, and then get the profile/timeline data from it.
    @MainActor
    func setupYourOwnMetadata() async {
        var selectedAccountDescriptor = FetchDescriptor<OwnerAccount>(predicate: #Predicate { $0.selected })
        let selectedMetadataRelayDesctiptor = FetchDescriptor<Relay>(predicate: #Predicate { $0.supportsNip1 && !$0.supportsNip29 })
        selectedAccountDescriptor.fetchLimit = 1
        
        guard
            let context = modelContainer?.mainContext,
            let metadataRelays = try? context.fetch(selectedMetadataRelayDesctiptor)
        else {
            print("Context or selectedMetadataRelay is nil.")
            return
        }
        
        let metadataRelayUrls = metadataRelays.map(\.url)
        
        do {
            let fetchedAccounts = try context.fetch(selectedAccountDescriptor).first
            self.selectedOwnerAccount = fetchedAccounts
            
            if let account = self.selectedOwnerAccount {
                let publicKey = account.publicKey
                let metadataSubscription = Subscription(filters: [.init(authors: [publicKey], kinds: [Kind.setMetadata])])
                metadataRelayUrls.forEach { metadataRelayUrl in
                    nostrClient.add(relayWithUrl: metadataRelayUrl, subscriptions: [metadataSubscription] )
                }
                self.selectedNip1Relays = metadataRelays
            }
        } catch {
            print("Error fetching selected account: \(error)")
        }
    }
    
    func subscribeUserStatusFromPubkey(publicKey: String) {
        let metadataSubscription = Subscription(filters: [Filter(authors: [publicKey], kinds: [Kind.custom(30315)])])
        
        let metadataRelayUrls = self.selectedNip1Relays.map(\.url)
        metadataRelayUrls.forEach { metadataRelayUrl in
            nostrClient.add(relayWithUrl: metadataRelayUrl, subscriptions: [metadataSubscription] )
        }
    }
    
    func subscribeMetadataFromPubkey(publicKey: String) {
        let metadataSubscription = Subscription(
            filters: [Filter(authors: [publicKey], kinds: [Kind.setMetadata])],
            id: IdSubPublicMetadata
        )
        
        let metadataRelayUrls = self.selectedNip1Relays.map(\.url)
        metadataRelayUrls.forEach { metadataRelayUrl in
            nostrClient.add(relayWithUrl: metadataRelayUrl, subscriptions: [metadataSubscription] )
        }
    }
    
    // MARK: Subscribe to group information (group name, etc.) on NIP-29-compatible relays
    @MainActor
    func subscribeGroupMetadata() async {
        let descriptor = FetchDescriptor<Relay>(predicate: #Predicate { $0.supportsNip29 })
        if let relay = try? modelContainer?.mainContext.fetch(descriptor).first {
            let groupMetadataSubscription = Subscription(filters: [Filter(kinds: [Kind.groupMetadata])], id: IdSubGroupList)
            nostrClient.add(relayWithUrl: relay.url, subscriptions: [groupMetadataSubscription])
            self.selectedNip29Relay = relay
        }
    }
    
    // MARK: Subscribe to messages on NIP-29-compatible relays
    @MainActor
    func subscribeChatMessages() async {
        let descriptor = FetchDescriptor<Relay>(predicate: #Predicate { $0.supportsNip29 })
        if let relay = try? modelContainer?.mainContext.fetch(descriptor).first {
            let groupIds = self.allChatGroup.compactMap({ $0.id }).sorted()
            let groupMessageSubscription = Subscription(filters: [
                Filter(kinds: [Kind.groupChatMessage], since: nil, tags: [Tag(id: "h", otherInformation: groupIds)]),
            ], id: IdSubChatMessages)
            
            nostrClient.add(relayWithUrl: relay.url, subscriptions: [groupMessageSubscription])
        }
    }
    
    // MARK: Subscribe to each group's Admins and Members on NIP-29-compatible relays
    @MainActor
    func subscribeGroupAdminAndMembers() async {
        let descriptor = FetchDescriptor<Relay>(predicate: #Predicate { $0.supportsNip29 })
        let groupAdminAndMembersSubscription = Subscription(filters: [
            Filter(kinds: [
                Kind.groupAdmins,
                Kind.groupMembers
            ], since: nil),
        ], id: IdSubGroupAdminAndMembers)
        
        if let relay = try? modelContainer?.mainContext.fetch(descriptor).first {
            nostrClient.add(relayWithUrl: relay.url, subscriptions: [groupAdminAndMembersSubscription])
        }
    }
    
    // MARK: The following three functions are used when you want to remove relay information.
    //    ・ removeDataFor
    //    ・ updateRelayInformationForAll
    //    ・ remove
    @MainActor
    func removeDataFor(relayUrl: String) async {
        Task.detached {
            guard let modelContext = self.backgroundContext() else { return }
            try? modelContext.save()
        }
    }
    
    @MainActor
    func updateRelayInformationForAll() async {
        Task.detached {
            guard let modelContext = self.backgroundContext() else { return }
            guard let relays = try? modelContext.fetch(FetchDescriptor<Relay>()) else { return }
            await withTaskGroup(of: Void.self) { group in
                for relay in relays {
                    group.addTask {
                        await relay.updateRelayInfo()
                    }
                }
                try? modelContext.save()
            }
        }
    }
    
    @MainActor
    func remove(relaysWithUrl relayUrls: [String]) {
        for relayUrl in relayUrls {
            self.nostrClient.remove(relayWithUrl: relayUrl)
        }
    }
    
    @MainActor
    func deleteAllSwiftData(modelContext: ModelContext) {
        do {
            let ownerAccounts = try modelContext.fetch(FetchDescriptor<OwnerAccount>())
            for account in ownerAccounts {
                modelContext.delete(account)
            }
            
            let relays = try modelContext.fetch(FetchDescriptor<Relay>())
            for relay in relays {
                modelContext.delete(relay)
            }
            
            try modelContext.save()
        } catch {
            print("Failed to delete all data: \(error)")
        }
    }
    
    @MainActor
    func resetState() {
        self.lastEditGroupMetadataEventId = nil
        self.lastCreateGroupMetadataEventId = nil
        self.createdGroupMetadata = (ownerAccount: nil, groupId: nil, picture: nil, name: nil, about: nil)
        self.isSheetPresented = false
        self.registeredNsec = false
        self.selectedOwnerAccount = nil
        self.selectedNip1Relays = []
        self.selectedNip29Relay = nil
        self.selectedGroup = nil
        self.selectedEditingGroup = nil
        self.allChatGroup = []
        self.allChatMessage = []
        self.allUserMetadata = []
        self.allGroupAdmin = []
        self.allGroupMember = []
        self.chatMessageNumResults = 50
        self.statuses = [:]
        self.ownerPostContents = []
        self.profileMetadata = nil
    }
    
    // MARK: By running this, you can retrieve the data you are subscribed to.
    func process(event: Event, relayUrl: String) {
        Task.detached {
            switch event.kind {
                case Kind.setMetadata:
                    handleSetMetadata(appState: self, event: event)
                
                case Kind.textNote:
                    handleTextNote(appState: self, event: event)
                
                case Kind.groupMetadata:
                    handleGroupMetadata(appState: self, event: event)
                                        
                case Kind.groupAdmins:
                    handleGroupAdmins(appState: self, event: event, relayUrl: relayUrl)
                
                case Kind.groupMembers:
                    handleGroupMembers(appState: self, event: event, relayUrl: relayUrl)
                    
                case Kind.groupChatMessage:
                    handleGroupChatMessage(appState: self, event: event)
                
                case Kind.custom(30315):
                    handleUserStatus(appState: self, event: event)
                    
                default:
                    print("event.kind: ", event.kind)
                }
        }
    }

    func setPicture(fileData: Data, fileExtension: String) async throws -> String? {
        guard let ownerAccount = self.selectedOwnerAccount else {
            print("No owner account")
            return nil
        }
        guard let key = ownerAccount.getKeyPair() else {
            print("No keypair found")
            return nil
        }
        
        let tags: [Tag] = [
            Tag(id: "u", otherInformation: ["https://nostr.build/api/v2/nip96/upload"]),
            Tag(id: "method", otherInformation: ["POST"])
        ]

        var signEvent = Event(
            pubkey: ownerAccount.publicKey,
            createdAt: .init(),
            kind: .custom(27235),
            tags: tags,
            content: ""
        )

        do {
            try signEvent.sign(with: key)
        } catch {
            print("Failed to sign event: \(error.localizedDescription)")
            return nil
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        let jsonData = try encoder.encode(signEvent)
        let base64String = jsonData.base64EncodedString()

        guard let url = URL(string: "https://nostr.build/api/v2/nip96/upload") else {
            print("Invalid URL")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Nostr \(base64String)", forHTTPHeaderField: "Authorization")

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var httpBody = Data()

        // file
        httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        httpBody.append("Content-Disposition: form-data; name=\"file\"; filename=\"upload.\(fileExtension)\"\r\n".data(using: .utf8)!)
        httpBody.append("Content-Type: image/\(fileExtension)\r\n\r\n".data(using: .utf8)!)
        httpBody.append(fileData)
        httpBody.append("\r\n".data(using: .utf8)!)

        // caption
        httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        httpBody.append("Content-Disposition: form-data; name=\"caption\"\r\n\r\n".data(using: .utf8)!)
        httpBody.append("devCampAvatarPicture\r\n".data(using: .utf8)!)

        // expiration
        httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        httpBody.append("Content-Disposition: form-data; name=\"expiration\"\r\n\r\n".data(using: .utf8)!)
        httpBody.append("\r\n".data(using: .utf8)!)

        // content_type
        httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        httpBody.append("Content-Disposition: form-data; name=\"content_type\"\r\n\r\n".data(using: .utf8)!)
        httpBody.append("avatar\r\n".data(using: .utf8)!)

        httpBody.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = httpBody

        let (data, response) = try await URLSession.shared.data(for: request)

        guard
            let httpResponse = response as? HTTPURLResponse,
            (200..<300).contains(httpResponse.statusCode)
        else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode
            print("Upload failed. Status code: \(String(describing: statusCode))")
            if let str = String(data: data, encoding: .utf8) {
                print("Response: \(str)")
            }
            return nil
        }

        guard !data.isEmpty else {
            print("No response data or data is empty.")
            return nil
        }

        if let topLevel = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let nip94Event = topLevel["nip94_event"] as? [String: Any],
           let tags = nip94Event["tags"] as? [[String]]
        {
            if let urlTag = tags.first(where: { $0.first == "url" }), urlTag.count >= 2 {
                let uploadedUrlString = urlTag[1]
                return uploadedUrlString
            }
        }
        return nil
    }


    // MARK: Function to join a group you haven't joined yet.
    func joinGroup(ownerAccount: OwnerAccount, group: GroupMetadata) {
        guard let key = ownerAccount.getKeyPair() else { return }
        let relayUrl = group.relayUrl
        let groupId = group.id
        var joinEvent = Event(
            pubkey: ownerAccount.publicKey,
            createdAt: .init(),
            kind: Kind.groupJoinRequest,
            tags: [Tag(id: "h", otherInformation: groupId)],
            content: ""
        )
        
        do {
            try joinEvent.sign(with: key)
        } catch {
            print("join group error: \(error.localizedDescription)")
        }
        
        nostrClient.send(event: joinEvent, onlyToRelayUrls: [relayUrl])
    }
    
    // Function to leave a group.
    func leaveGroup(ownerAccount: OwnerAccount, group: GroupMetadata) {
        guard let key = ownerAccount.getKeyPair() else { return }
        let relayUrl = group.relayUrl
        let groupId = group.id
        var leaveEvent = Event(
            pubkey: ownerAccount.publicKey,
            createdAt: .init(),
            kind: Kind.custom(9022),
            tags: [
                Tag(id: "h", otherInformation: groupId),
            ],
            content: ""
        )
        
        do {
            try leaveEvent.sign(with: key)
        } catch {
            print(error.localizedDescription)
        }
        
        nostrClient.send(event: leaveEvent, onlyToRelayUrls: [relayUrl])
    }
    
    // Function to change online or not
    func changeOnlineStatus(status: String) async {
        guard let ownerAccount = self.selectedOwnerAccount else { return }
        guard let key = ownerAccount.getKeyPair() else { return }
        let nip1relayUrls = self.selectedNip1Relays.map { $0.url }
        var leaveEvent = Event(
            pubkey: ownerAccount.publicKey,
            createdAt: .init(),
            kind: Kind.custom(30315),
            tags: [
                Tag(id: "d", otherInformation: "online"),
            ],
            content: status
        )
        
        do {
            try leaveEvent.sign(with: key)
        } catch {
            print(error.localizedDescription)
        }
        
        nostrClient.send(event: leaveEvent, onlyToRelayUrls: nip1relayUrls)
    }
    
    // MARK: Function to send chat messages.
    @MainActor
    func sendChatMessage(ownerAccount: OwnerAccount, group: GroupMetadata, withText text: String) async {
        guard let key = ownerAccount.getKeyPair() else { return }
        let relayUrl = group.relayUrl
        let groupId = group.id
    
        var event = Event(
            pubkey: ownerAccount.publicKey,
            createdAt: .init(),
            kind: Kind.groupChatMessage,
            tags: [Tag(id: "h", otherInformation: groupId)],
            content: text
        )
        
        do {
            try event.sign(with: key)
        } catch {
            print(error.localizedDescription)
        }
        
        nostrClient.send(event: event, onlyToRelayUrls: [relayUrl])
    }
    
    // MARK: Function used to change user data in ProfileView.
    @MainActor
    func editUserMetadata(
        name: String?,
        about: String?,
        picture: String?,
        nip05: String?,
        displayName: String?,
        website: String?,
        banner: String?,
        bot: Bool?,
        lud16: String?
    )  async {
        guard let key = self.selectedOwnerAccount?.getKeyPair() else {
            print("KeyPair not found.")
            return
        }
        let nip1relayUrls = self.selectedNip1Relays.map { $0.url }
        
        let metadata: [String: String?] = [
            "name": name,
            "about": about,
            "picture": picture,
            "nip05": nip05,
            "display_name": displayName,
            "website": website,
            "banner": banner,
            "bot": bot?.description ?? "false",
            "lud16": lud16
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: metadata),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }
        
        var event = Event(
            pubkey: self.selectedOwnerAccount?.publicKey ?? "",
            createdAt: .init(),
            kind: Kind.setMetadata,
            tags: [],
            content: jsonString
        )
        
        do {
            try event.sign(with: key)
            
            nostrClient.send(event: event, onlyToRelayUrls: nip1relayUrls)
        } catch {
            print("Failed to sign or send event: \(error)")
        }
        
    }
    
    // MARK: Function used to delete user data.
    @MainActor
    func deleteUserMetadata() {
        guard let key = self.selectedOwnerAccount?.getKeyPair() else {
            print("KeyPair not found.")
            return
        }
        let nip1relayUrls = self.selectedNip1Relays.map { $0.url }
        
        let metadata: [String: String?] = [
            "name": "",
            "about": "account deleted",
            "picture": "",
            "nip05": "",
            "display_name": "nobody",
            "website": "",
            "banner": "",
            "bot": "",
            "lud16": ""
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: metadata),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }
        
        let tags: [Tag] = [
            Tag(id: "deleted", otherInformation: ["true"]),
        ]
        
        var event = Event(
            pubkey: self.selectedOwnerAccount?.publicKey ?? "",
            createdAt: .init(),
            kind: Kind.setMetadata,
            tags: tags,
            content: jsonString
        )
        
        
        do {
            try event.sign(with: key)
            
            self.lastDeleteUserMetadataEventId = event.id
            
            nostrClient.send(event: event, onlyToRelayUrls: nip1relayUrls)
        } catch {
            print("Failed to sign or send event: \(error)")
        }
        
    }
    
    /// Edit the group's metadata
    @MainActor
    func editGroupMetadata(ownerAccount: OwnerAccount, groupId: String, picture: String, name: String, about: String) async {
        guard let key = ownerAccount.getKeyPair() else {
            print("KeyPair not found.")
            return
        }
        
        guard let relayUrl = self.selectedNip29Relay?.url else{
            print("Nip29 relay not selected")
            return
        }
        
        let tags: [Tag] = [
            Tag(id: "h", otherInformation: groupId),
            Tag(id: "picture", otherInformation: [picture]),
            Tag(id: "name", otherInformation: [name]),
            Tag(id: "about", otherInformation: [about]),
        ]
        
        var event = Event(
            pubkey: ownerAccount.publicKey,
            createdAt: .init(),
            kind: Kind.groupEditMetadata,
            tags: tags,
            content: ""
        )

        
        do {
            try event.sign(with: key)
            
            self.lastEditGroupMetadataEventId = event.id
            
            nostrClient.send(event: event, onlyToRelayUrls: [relayUrl])
        } catch {
            print("Failed to sign or send event: \(error)")
        }
    }
    
    /// Create a group
    @MainActor
    func createGroup(ownerAccount: OwnerAccount, groupId: String) async {
        guard let key = ownerAccount.getKeyPair() else {
            print("KeyPair not found.")
            return
        }
        
        guard let relayUrl = self.selectedNip29Relay?.url else{
            print("Nip29 relay not selected")
            return
        }
        
        let tags: [Tag] = [
            Tag(id: "h", otherInformation: groupId),
        ]
        
        var event = Event(
            pubkey: ownerAccount.publicKey,
            createdAt: .init(),
            kind: Kind.groupCreate,
            tags: tags,
            content: ""
        )

        
        do {
            try event.sign(with: key)
            
            self.lastCreateGroupMetadataEventId = event.id
            
            nostrClient.send(event: event, onlyToRelayUrls: [relayUrl])
        } catch {
            print("Failed to sign or send event: \(error)")
        }
    }
    
    /// Add a user to the group as an Admin
    func addUserAsAdminToGroup(userPubKey: String, groupId: String) {
        guard let owner = self.selectedOwnerAccount,
              let key = owner.getKeyPair(),
              let relay = self.selectedNip29Relay
        else {
            return
        }
        
        // kind:9000 => "put-user"
        var event = Event(
            pubkey: owner.publicKey,
            createdAt: .init(),
            kind: Kind.groupAddUser,
            tags: [
                Tag(id: "h", otherInformation: [groupId]),
                Tag(id: "p", otherInformation: [userPubKey, "admin"])
            ],
            content: "Add user as admin"
        )
        
        do {
            try event.sign(with: key)
            nostrClient.send(event: event, onlyToRelayUrls: [relay.url])
        } catch {
            print(error.localizedDescription)
        }
    }
    
    /// Add a user to the group as a general member
    func addUserAsMemberToGroup(userPubKey: String, groupId: String) {
        guard let owner = self.selectedOwnerAccount,
              let key = owner.getKeyPair(),
              let relay = self.selectedNip29Relay
        else {
            return
        }
        
        // kind:9000 => "put-user"
        var event = Event(
            pubkey: owner.publicKey,
            createdAt: .init(),
            kind: Kind.groupAddUser,
            tags: [
                Tag(id: "h", otherInformation: [groupId]),
                Tag(id: "p", otherInformation: [userPubKey, "member"])
            ],
            content: "Add user as member"
        )
        
        do {
            try event.sign(with: key)
            nostrClient.send(event: event, onlyToRelayUrls: [relay.url])
        } catch {
            print(error.localizedDescription)
        }
    }
    
    /// Remove a user from the group (leave)
    func removeUserFromGroup(userPubKey: String, groupId: String) {
        guard let owner = self.selectedOwnerAccount,
              let key = owner.getKeyPair(),
              let relay = self.selectedNip29Relay
        else {
            return
        }
        
        // kind:9001 => "remove-user"
        var event = Event(
            pubkey: owner.publicKey,
            createdAt: .init(),
            kind: Kind.groupRemoveUser, // => 9001
            tags: [
                Tag(id: "h", otherInformation: [groupId]),
                Tag(id: "p", otherInformation: [userPubKey])
            ],
            content: "Remove user"
        )
        
        do {
            try event.sign(with: key)
            nostrClient.send(event: event, onlyToRelayUrls: [relay.url])
        } catch {
            print(error.localizedDescription)
        }
    }
}

extension AppState: NostrClientDelegate {
    func didConnect(relayUrl: String) {
        DispatchQueue.main.async {
            self.statuses[relayUrl] = true
        }
    }
    
    func didDisconnect(relayUrl: String) {
        DispatchQueue.main.async {
            self.statuses[relayUrl] = false
        }
    }
    
    func didReceive(message: Nostr.RelayMessage, relayUrl: String) {
        switch message {
            case .event(_, let event):
                if event.isValid() {
                    process(event: event, relayUrl: relayUrl)
                } else {
                    print("\(event.id ?? "") is an invalid event on \(relayUrl)")
                }
            case .notice(let notice):
                print(notice)
            case .ok(let id, let acceptance, let m):
                print("Relay OK: eventID=\(id), acceptance=\(acceptance), message=\(m)")
                
                // Once the Relay side returns "OK (accepted)" for the sent editGroupMetadata event, set a flag to close the sheet
                if let lastId = self.lastEditGroupMetadataEventId,
                   lastId == id,
                   acceptance == true
                {
                    DispatchQueue.main.async {
                        self.isSheetPresented = false
                        self.isCreateLoading = false
                        self.selectedEditingGroup = nil
                    }
                }
                
                if let lastId = self.lastCreateGroupMetadataEventId,
                   lastId == id,
                   acceptance == true {
                    Task {
                        guard let ownerAccount = self.createdGroupMetadata.ownerAccount,
                              let groupId = self.createdGroupMetadata.groupId,
                              let picture = self.createdGroupMetadata.picture,
                              let name = self.createdGroupMetadata.name,
                              let about = self.createdGroupMetadata.about else {
                            print("Missing required metadata for editing group")
                            return
                        }
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        await self.editGroupMetadata(ownerAccount: ownerAccount, groupId: groupId, picture: picture, name: name, about: about)
                    }
                }
            if let lastId = self.lastDeleteUserMetadataEventId,
               lastId == id,
               acceptance == true {
                
                DispatchQueue.main.async {
                    guard let modelContext = self.lastDeleteUserMetadataModelContext else { return }
                    do {
                        let relays = try modelContext.fetch(FetchDescriptor<Relay>());
                        let relaysUrl = relays.map(\.url)
                        self.remove(relaysWithUrl: relaysUrl)
                    } catch {
                        print("Failed to fetch relays: \(error)")
                    }
                    self.resetState()
                    self.deleteAllSwiftData(modelContext: modelContext)
                }
            }
            
            case .eose(let id):
                // EOSE (End of Stored Events Notice) is a mechanism for the Relay to notify that it has finished sending stored data
                switch id {
                    case IdSubGroupList:
                        Task {
                            await subscribeChatMessages()
                            await subscribeGroupAdminAndMembers()
                        }
                    
                    default:
                        ()
                    }
            case .closed(let id, let message):
                print("case: .closed")
                print(id, message)
            case .other(let other):
                print("case: .other")
                print(other)
            case .auth(let challenge):
                print("Auth: \(challenge)")
            }
    }
}
