import Foundation

struct UserMetadata: Encodable, Hashable {
    var publicKey: String
    var bech32PublicKey: String
    var name: String?
    var about: String?
    var picture: String?
    var nip05: String?
    var displayName: String?
    var website: String?
    var banner: String?
    var bot: Bool?
    var lud16: String?
    var createdAt: Date
    var facetime: String?
}
