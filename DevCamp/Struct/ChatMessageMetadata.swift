import Foundation

struct ChatMessageMetadata: Identifiable, Hashable {
    var id: String
    var createdAt: Date
    var groupId: String
    var publicKey: String
    var userMetadata: UserMetadata?
    var content: String
}
