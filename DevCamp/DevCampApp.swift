import SwiftUI
import SwiftData
import Nostr
import NostrClient
import GroupActivities

@main
struct DevCampApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            OwnerAccount.self,
            Relay.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @StateObject var appState = AppState()
    let groupActivityManager = GroupActivityManager()
    @StateObject var groupStateObserver = GroupStateObserver()

    var body: some Scene {

        WindowGroup {
            ContentView(groupActivityManager: groupActivityManager)
                .modelContainer(sharedModelContainer)
                .environmentObject(appState)
                .task {
                    appState.modelContainer = sharedModelContainer
                    await appState.setupYourOwnMetadata()
                    await appState.subscribeGroupMetadata()
                }
                .onChange(of: groupStateObserver.isEligibleForGroupSession) { oldValue, newValue in
                    if newValue {
                        guard let selectedOwnerAccount = appState.selectedOwnerAccount else { return }
                        guard let selectedGroup = appState.selectedGroup else { return }

                        appState.joinGroup(ownerAccount: selectedOwnerAccount, group: selectedGroup)
                    } else {
                        guard let selectedOwnerAccount = appState.selectedOwnerAccount else { return }
                        guard let selectedGroup = appState.selectedGroup else { return }

                        // Exit from Nostr group
                        appState.leaveGroup(ownerAccount: selectedOwnerAccount, group: selectedGroup)
                        // Remove yourself from group membership
                        appState.allGroupMember.removeAll { member in
                            member.publicKey == selectedOwnerAccount.publicKey && member.groupId == selectedGroup.id
                        }
                        for index in appState.allChatGroup.indices {
                            if appState.allChatGroup[index].id == selectedGroup.id {
                                appState.allChatGroup[index].isMember = false
                            }
                        }
                    }
                }
        }
    }
}
