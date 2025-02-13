struct PostMetadata: Identifiable, Encodable {
    var id: String
    var text: String
    var name: String?
    var picture: String?
    var timeStamp: String
}
