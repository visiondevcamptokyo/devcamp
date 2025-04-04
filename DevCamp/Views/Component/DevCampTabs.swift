import SwiftUI

struct DevCampTabs: View {
    @EnvironmentObject var appState: AppState
    @State var groupActivitymanager: GroupActivityManager
    
    var body: some View {
        TabView {
            NavigationStack { HomeView(groupActivityManager: groupActivitymanager) }
                .tabItem {
                    Label("Home", systemImage: "house")
                }
//            ChatGroupView()
//                .tabItem {
//                    Label("[For Development] Group List", systemImage: "person.3")
//                }
//            TimeLineView()
//                .tabItem {
//                    Label("Timeline", systemImage: "clock")
//                }
            SettingView()
                .tabItem {
                    Label("Setting", systemImage: "gearshape")
                }
        }
        .navigationBarBackButtonHidden()
    }
}
