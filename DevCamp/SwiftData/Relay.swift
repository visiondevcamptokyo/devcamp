import Foundation
import SwiftData
import NostrClient

@Model final class Relay: Identifiable {
    
    @Attribute(.unique) var url: String
    var name: String
    var desc: String
    var publicKey: String
    var contact: String
    var supportedNips: Set<Int>
    var software: String
    var version: String
    var updatedAt: Date
    var icon: String
    var supportsNip1: Bool
    var supportsNip29: Bool
    
    init(url: String, name: String = "", desc: String = "", publicKey: String = "", contact: String = "", supportedNips: Set<Int> = [],
         software: String = "", version: String = "", updatedAt: Date = .now, icon: String = "", supportsNip1: Bool = false, supportsNip29: Bool = false) {
        self.url = url.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        self.name = name
        self.desc = desc
        self.publicKey = publicKey
        self.contact = contact
        self.supportedNips = supportedNips
        self.software = software
        self.version = version
        self.updatedAt = updatedAt
        self.icon = icon
        self.supportsNip1 = supportsNip1
        self.supportsNip29 = supportsNip29
    }
    
    var httpUrl: URL? {
        let httpUrlString = url
            .replacingOccurrences(of: "wss://", with: "https://")
            .replacingOccurrences(of: "ws://", with: "http://")
        return URL(string: httpUrlString)
    }
    
    var urlStringWithoutProtocol: String {
        return url.replacingOccurrences(of: "wss://", with: "")
            .replacingOccurrences(of: "ws://", with: "")
    }
   
    // TODO: Getting a crash in here randomly...
    @MainActor
    func updateRelayInfo() async -> Void {
        if let relayInfo = await NostrClient.fetchRelayInfo(relayUrl: url) {
            self.name = relayInfo.info.name ?? self.name
            self.desc = relayInfo.info.description ?? self.desc
            self.publicKey = relayInfo.info.publicKey ?? self.publicKey
            self.contact = relayInfo.info.contact ?? self.contact
            self.supportedNips = Set(relayInfo.info.supportedNips)
            self.software = relayInfo.info.software ?? self.software
            self.version = relayInfo.info.version ?? self.version
            self.icon = relayInfo.info.icon ?? self.icon
            self.supportsNip1 = self.supportedNips.contains(1)
            self.supportsNip29 = self.supportedNips.contains(29)
        }
    }
}

extension Relay {
    
    static func createNew(withUrl url: String) -> Relay? {
        if url.hasPrefix("wss://") || url.hasPrefix("ws://") {
            return Relay(url: url)
        }
        print("This relay URL is not supported: \(url)")
        return nil
    }
    
}
