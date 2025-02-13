struct GroupMember: Identifiable, Hashable {
//    enum Capability: String, CaseIterable, Codable {
//        case PutUser = "put-user"
//        case EditMetadata = "edit-metadata"
//        case DeleteEvent = "delete-event"
//        case RemoveUser = "remove-user"
//        case AddPermission = "add-permission"
//        case RemovePermission = "remove-permission"
//    }
    
    var id: String
    
    var publicKey: String
    var groupId: String
//    var capabilities: Set<Capability>
    var relayUrl: String
    var userMetadata: UserMetadata?
}
