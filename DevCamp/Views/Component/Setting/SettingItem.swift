enum SettingItem: Hashable, CaseIterable, Identifiable {
    case profile
    case key
    case metadataRelay
    case nip29Relay
    
    var id: Self { self }
    
    var label: String {
        switch self {
        case .profile:
            return "Profile"
        case .key:
            return "Key"
        case .metadataRelay:
            return "MetadataRelay"
        case .nip29Relay:
            return "Nip29Relay"
        }
    }
    
    var iconName: String {
        switch self {
        case .profile:
            return "person.crop.circle"
        case .key:
            return "lock.shield"
        case .metadataRelay:
            return "antenna.radiowaves.left.and.right"
        case .nip29Relay:
            return "network"
        }
    }
}
