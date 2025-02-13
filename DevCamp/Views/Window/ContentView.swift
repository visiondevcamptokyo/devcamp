import GroupActivities
import SwiftUI
import SwiftData


struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Query private var ownerAccounts: [OwnerAccount]
    @State var groupActivityManager: GroupActivityManager
    
    var body: some View {
        Group {
            if appState.registeredNsec {
                DevCampTabs(groupActivitymanager: groupActivityManager)
            } else {
                StartView()
            }
        }.onAppear {
            if ownerAccounts.isEmpty {
                appState.registeredNsec = false
            }
        }
        .task {
            // MARK: Shareplayのセッションが起動されているか否かをチェックする
            for await session in DevCampActivity.sessions() {
                await groupActivityManager.configureGroupSession(session: session, appState: appState)
            }
        }
    }
}
