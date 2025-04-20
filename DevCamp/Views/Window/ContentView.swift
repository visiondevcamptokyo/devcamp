import GroupActivities
import SwiftUI
import SwiftData


struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Query private var ownerAccounts: [OwnerAccount]
    @State var groupActivityManager: GroupActivityManager
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    
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
            // MARK: Check whether or not a Shareplay session is activated
            for await session in DevCampActivity.sessions() {
                await groupActivityManager.configureGroupSession(session: session, appState: appState)
            }
        }
        .onChange(of: scenePhase) {
            switch scenePhase {
            case .active:
                print("App is active")
                Task {
                    await resetState()
                    await appState.setupYourOwnMetadata()
                    await appState.subscribeGroupMetadata()
                    try? await Task.sleep(nanoseconds: 5 * 1_000_000_000)
                    await appState.changeOnlineStatus(status: "true")
                }
            case .inactive:
                print("App is inactive")
                Task {
                    await appState.changeOnlineStatus(status: "false")
                }
            case .background:
                print("App is in background")
            @unknown default:
                print("Unknown scene phase")
            }
        }
    }
    
    private func resetState() async {
        do {
            let relays = try modelContext.fetch(FetchDescriptor<Relay>());
            let relaysUrl = relays.map(\.url)
            appState.remove(relaysWithUrl: relaysUrl)
        } catch {
            print("Failed to fetch relays: \(error)")
        }
        
        appState.lastEditGroupMetadataEventId = nil
        appState.lastCreateGroupMetadataEventId = nil
        appState.createdGroupMetadata = (ownerAccount: nil, groupId: nil, picture: nil, name: nil, about: nil)
        appState.isSheetPresented = false
        appState.selectedOwnerAccount = nil
        appState.selectedNip1Relays = []
        appState.selectedNip29Relay = nil
        appState.selectedGroup = nil
        appState.selectedEditingGroup = nil
        appState.allChatGroup = []
        appState.allChatMessage = []
        appState.allUserMetadata = []
        appState.allGroupAdmin = []
        appState.allGroupMember = []
        appState.chatMessageNumResults = 50
        appState.statuses = [:]
        appState.ownerPostContents = []
        appState.profileMetadata = nil
    }
}
