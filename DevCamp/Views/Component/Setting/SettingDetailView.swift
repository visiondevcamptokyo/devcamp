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
            
        case .groupRelay:
            GroupRelayView()
            
        default:
            Text("Please select a setting")
                .foregroundColor(.secondary)
        }
    }
}
