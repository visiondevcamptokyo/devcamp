struct ProfileMetadata: Identifiable, Encodable {
    var id: String
    var pubkey: String
    var name: String?
    var about: String?
    var picture: String?
    var nip05: String?
    var displayName: String?
    var website: String?
    var banner: String?
    var bot: Bool?
    var lud16: String?
}
