import CoreData
import os.log

/// Manager for deletion/load/save of events
final class EventManager {
    private static var instance: EventManager?
    private let model = "Insights"
    private lazy var persistentContainer: NSPersistentContainer = {
        let modelURL = Bundle(for: EventManager.self).url(forResource: model, withExtension: "momd")!
        let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)
        let container = NSPersistentContainer(name: model, managedObjectModel: managedObjectModel!)
        container.loadPersistentStores { (_, error) in
            if let error = error {
                os_log("Loading of store failed: %@", log: .default, type: .error, error.localizedDescription)
            }
        }
        return container
    }()

    /// Returns the previously initialized instance of the `EventManager` object
    public static var shared: EventManager {
        guard let instance = instance else {
            self.instance = EventManager()
            return self.instance!
        }
        return instance
    }

    /// Deletes events created before given time
    /// - Parameter time: time
    /// - Parameter isStale: is event stale
    func deleteEvents(before time: Int64, isStale: Bool = false) {
        let context = persistentContainer.newBackgroundContext()
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Event.fetchRequest()
        let predicate = NSPredicate(format: "createdOn <= \(time)")
        fetchRequest.predicate = predicate
        let deleteRequest = NSBatchDeleteRequest( fetchRequest: fetchRequest)
        let logMessageToBeDeleted = isStale
            ? "Stale events to be deleted before time \(time)"
            : "Events to be deleted before time \(time)"
        let logMessageDeletedSuccessfully = isStale
            ? "Stale events deleted successfully before time \(time)"
            : "Events deleted successfully before time \(time)"
        do {
            os_log("%@", log: .default, type: .info, logMessageToBeDeleted)
            try context.execute(deleteRequest)
            os_log("%@", log: .default, type: .info, logMessageDeletedSuccessfully)
        } catch {
            os_log("Failed to delete events: %@", log: .default, type: .error, error.localizedDescription)
        }
    }

     /// Gives total events count
    func getEventsCount() -> Int {
        var eventCount = 0
        let context = persistentContainer.newBackgroundContext()
        let fetchRequest: NSFetchRequest<Event> = Event.fetchRequest()
        do {
            eventCount = try context.count(for: fetchRequest)
        } catch {
            os_log("Failed to fetch events count: %@", log: .default, type: .error, error.localizedDescription)
        }
        return eventCount
    }

    /// Loads events created before given current time
    /// - Parameter currentTime: current time
    func loadEvents(before currentTime: Int64) -> [EventInsight] {
        var events = [Event]()
        let context = persistentContainer.newBackgroundContext()

        let fetchRequest: NSFetchRequest<Event> = Event.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "createdOn <= \(currentTime)")
        do {
            events = try context.fetch(fetchRequest)
        } catch {
            os_log("Failed to fetch events: %@", log: .default, type: .error, error.localizedDescription)
        }
        return events.compactMap {
                try? JSONDecoder().decode(EventInsight.self, from: $0.payload)
        }
    }

    /// Saves event created using given payload
    /// - Parameter payload: payload for event
    func saveEvent(payload: Data) {
        let context = persistentContainer.newBackgroundContext()

        let event = Event(context: context)
        event.payload = payload
        event.createdOn = Date().epochMilliseconds()
        do {
            try context.save()
        } catch {
            os_log("Failed to save Event: %@", log: .default, type: .error, error.localizedDescription)
        }
    }
}
