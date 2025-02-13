import SwiftUI

struct SettingView: View {
    
    @EnvironmentObject var appState: AppState
    
    @State private var selectedSetting: SettingItem? = .profile
    
    var body: some View {
        NavigationSplitView {
            SettingListView(selectedSetting: $selectedSetting)
        } detail: {
            SettingDetailView(selectedSetting: $selectedSetting)
        }
    }
}

