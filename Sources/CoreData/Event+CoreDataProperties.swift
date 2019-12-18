import CoreData
import Foundation

extension Event {
    /// Request to fetch events
    @nonobjc
    public class func fetchRequest() -> NSFetchRequest<Event> {
        return NSFetchRequest<Event>(entityName: "Event")
    }

    /// Created date in milliseconds
    @NSManaged public var createdOn: Int64
    /// The JSON payload
    @NSManaged public var payload: Data
}
