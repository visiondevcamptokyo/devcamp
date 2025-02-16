import SwiftUI

struct SettingDetailView: View {
    @Binding var selectedSetting: SettingItem?
    
    var body: some View {
        switch selectedSetting {
        case .profile:
            ProfileView()
        case .key:
            KeyView()
        case .metadataRelay:
            MetadataRelayView()
            
        case .nip29Relay:
            Nip29RelayView()
            
        default:
            Text("Please select a setting")
                .foregroundColor(.secondary)
        }
    }
}
