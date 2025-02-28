struct GroupMetadata: Identifiable, Encodable, Hashable {
    var id: String
    var createdAt: String
    var relayUrl: String
    var name: String?
    var picture: String?
    var about: String?
    var facetime: String?
    var isPublic: Bool
    var isOpen: Bool
    var isMember: Bool
    var isAdmin: Bool
}
