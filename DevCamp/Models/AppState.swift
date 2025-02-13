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
    @Published var createdGroupMetadata: (ownerAccount: OwnerAccount?, groupId: String?, name: String?, about: String?, link: String?)
    
    /// Flag to close the EditSessionLink sheet once the Relay returns OK
    @Published var shouldCloseEditSessionLinkSheet: Bool = false
    
    @Published var registeredNsec: Bool = true
    @Published var selectedOwnerAccount: OwnerAccount?
    @Published var selectedNip1Relay: Relay?
    @Published var selectedNip29Relay: Relay?
    @Published var selectedGroup: ChatGroupMetadata? {
        didSet {
            chatMessageNumResults = 50
        }
    }
    @Published var selectedEditingGroup: ChatGroupMetadata?
    @Published var allChatGroup: Array<ChatGroupMetadata> = []
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
        var selectedMetadataRelayDesctiptor = FetchDescriptor<Relay>(predicate: #Predicate { $0.supportsNip1 && !$0.supportsNip29 })
        selectedAccountDescriptor.fetchLimit = 1
        selectedMetadataRelayDesctiptor.fetchLimit = 1
        
        guard
            let context = modelContainer?.mainContext,
            let selectedMetadataRelay = try? context.fetch(selectedMetadataRelayDesctiptor).first
        else {
            print("Context or selectedMetadataRelay is nil.")
            return
        }
        
        do {
            let fetchedAccounts = try context.fetch(selectedAccountDescriptor).first
            self.selectedOwnerAccount = fetchedAccounts
            
            if let account = self.selectedOwnerAccount {
                let publicKey = account.publicKey
                let metadataSubscription = Subscription(filters: [.init(authors: [publicKey], kinds: [Kind.setMetadata])])
                nostrClient.add(relayWithUrl: selectedMetadataRelay.url, subscriptions: [metadataSubscription] )
                self.selectedNip1Relay = selectedMetadataRelay
            }
        } catch {
            print("Error fetching selected account: \(error)")
        }
    }
    
    // MARK: Subscribe to the "Metadata" of the Admins (ideally also Members) of the Group in MetadataRelay
    @MainActor
    func connectAllMetadataRelays() async {
        let relaysDescriptor = FetchDescriptor<Relay>(predicate: #Predicate { $0.supportsNip1 && !$0.supportsNip29 })
        guard let relay = try? modelContainer?.mainContext.fetch(relaysDescriptor).first else { return }
        var pubkeys = Set<String>()

        for admin in self.allGroupAdmin {
            pubkeys.insert(admin.publicKey)
        }

        for member in self.allGroupMember {
            pubkeys.insert(member.publicKey)
        }
        
        let pubkeysArray = Array(pubkeys)
        
        let metadataSubscription = Subscription(
            filters: [Filter(authors: pubkeysArray, kinds: [Kind.setMetadata])],
            id: IdSubPublicMetadata
        )
        nostrClient.add(relayWithUrl: relay.url, subscriptions: [metadataSubscription])
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
        
        let groupIds = self.allChatGroup.compactMap({ $0.id }).sorted()
        let groupAdminAndMembersSubscription = Subscription(filters: [
            Filter(kinds: [
                Kind.groupAdmins,
                Kind.groupMembers
            ], since: nil, tags: [Tag(id: "d", otherInformation: groupIds)]),
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
    
    public func remove(relaysWithUrl relayUrls: [String]) {
        for relayUrl in relayUrls {
            self.nostrClient.remove(relayWithUrl: relayUrl)
        }
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

                case Kind.groupAddUser:
                    print(event)
                    
                case Kind.groupRemoveUser:
                    print(event)
                    
                default:
                    print("event.kind: ", event.kind)
                }
        }
    }
    
    // MARK: Function to join a group you haven't joined yet.
    func joinGroup(ownerAccount: OwnerAccount, group: ChatGroupMetadata) {
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
    
    // TODO: Function to leave a group.
    func leaveGroup(ownerAccount: OwnerAccount, group: ChatGroupMetadata) {
        guard let key = ownerAccount.getKeyPair() else { return }
        let relayUrl = group.relayUrl
        let groupId = group.id
        var leaveEvent = Event(
            pubkey: ownerAccount.publicKey,
            createdAt: .init(),
            kind: Kind.custom(9022), // 9022 was not defined
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
    
    // MARK: Function to send chat messages.
    @MainActor
    func sendChatMessage(ownerAccount: OwnerAccount, group: ChatGroupMetadata, withText text: String) async {
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
        let nip1relayUrl = self.selectedNip1Relay?.url ?? ""
        
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
        
        print("self.selectedOwnerAccount?.publicKey: \(self.selectedOwnerAccount?.publicKey ?? "")")
        
        var event = Event(
            pubkey: self.selectedOwnerAccount?.publicKey ?? "",
            createdAt: .init(),
            kind: Kind.setMetadata,
            tags: [],
            content: jsonString
        )
        
        do {
            try event.sign(with: key)
            print("event: \(event)")
            print("nip1relayUrl: \(nip1relayUrl)")
            
            nostrClient.send(event: event, onlyToRelayUrls: [nip1relayUrl])
            print("Successed to sign or send event")
        } catch {
            print("Failed to sign or send event: \(error)")
        }
        
    }
    
    // MARK: Function used to edit FaceTime links
    @MainActor
    func editFacetimeLink(
        link: String
    )  async{
        guard let key = self.selectedOwnerAccount?.getKeyPair() else {
            print("KeyPair not found.")
            return
        }
        
        let nip1relayUrl = self.selectedNip1Relay?.url ?? ""
        
        let ownerAccount = self.allUserMetadata.filter { $0.publicKey == self.selectedOwnerAccount?.publicKey }.first
        
        let metadata: [String: String?] = [
            "name": ownerAccount?.name,
            "about": ownerAccount?.about,
            "picture": ownerAccount?.picture,
            "nip05": ownerAccount?.nip05,
            "display_name": ownerAccount?.displayName,
            "website": ownerAccount?.website,
            "banner": ownerAccount?.banner,
            "bot": ownerAccount?.bot?.description ?? "false",
            "lud16": ownerAccount?.lud16
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: metadata),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }
        
        let tags: [Tag] = [
            Tag(id: "facetime", otherInformation: link),
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
            
            nostrClient.send(event: event, onlyToRelayUrls: [nip1relayUrl])
            print("Edit group link event sent to \(nip1relayUrl)")
        } catch {
            print("Failed to sign or send event: \(error)")
        }
    }
    
    /// Edit the group's metadata
    @MainActor
    func editGroupMetadata(ownerAccount: OwnerAccount, groupId: String, name: String, about: String) async {
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
                        self.shouldCloseEditSessionLinkSheet = true
                    }
                }
                
                if let lastId = self.lastCreateGroupMetadataEventId,
                   lastId == id,
                   acceptance == true {
                    Task {
                        guard let ownerAccount = self.createdGroupMetadata.ownerAccount,
                              let groupId = self.createdGroupMetadata.groupId,
                              let name = self.createdGroupMetadata.name,
                              let about = self.createdGroupMetadata.about,
                              let link = self.createdGroupMetadata.link else {
                            print("Missing required metadata for editing group")
                            return
                        }
                        await self.editGroupMetadata(ownerAccount: ownerAccount, groupId: groupId, name: name, about: about)
                        await self.editFacetimeLink(link: link)
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
                    case IdSubGroupAdminAndMembers:
                        Task{
                            await connectAllMetadataRelays()
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
