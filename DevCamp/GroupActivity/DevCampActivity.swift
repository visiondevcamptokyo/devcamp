import CoreTransferable
import GroupActivities

struct DevCampActivity: GroupActivity, Transferable {
    var metadata: GroupActivityMetadata = {
        var metadata = GroupActivityMetadata()
        metadata.title = "DevCamp"
        metadata.type = .generic
        return metadata
    }()
}
