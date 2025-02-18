enum SettingItem: Hashable, CaseIterable, Identifiable {
    case profile
    case key
    case metadataRelay
    case groupRelay
    
    var id: Self { self }
    
    var label: String {
        switch self {
        case .profile:
            return "Profile"
        case .key:
            return "Key"
        case .metadataRelay:
            return "MetadataRelay"
        case .groupRelay:
            return "GroupRelay"
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
        case .groupRelay:
            return "network"
        }
    }
}
