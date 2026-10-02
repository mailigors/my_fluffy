import CoreData
import Foundation

struct StoredPet: Equatable, Sendable {
    var needs: PetNeeds
    var isSleeping: Bool
    var kitchen: KitchenState = .newcomer
}

enum PetStoreError: Error, Equatable {
    case loadFailed
    case saveFailed
}

final class PetStore {
    private let container: NSPersistentContainer
    private var didLoad = false

    init(inMemory: Bool = false) {
        let model = PetStore.makeModel()
        container = NSPersistentContainer(name: "Pet", managedObjectModel: model)
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }
        for description in container.persistentStoreDescriptions {
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func loadStores() async throws {
        if didLoad {
            return
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            var resumed = false
            container.loadPersistentStores { _, error in
                guard resumed == false else { return }
                resumed = true
                if error != nil {
                    continuation.resume(throwing: PetStoreError.loadFailed)
                } else {
                    continuation.resume()
                }
            }
        }
        didLoad = true
    }

    func load() throws -> StoredPet? {
        let context = container.viewContext
        var outcome: Result<StoredPet?, Error> = .success(nil)
        context.performAndWait {
            do {
                let request = PetRecord.fetchRequest()
                request.fetchLimit = 1
                let rows = try context.fetch(request)
                outcome = .success(rows.first.map(StoredPet.init(record:)))
            } catch {
                outcome = .failure(PetStoreError.loadFailed)
            }
        }
        return try outcome.get()
    }

    func save(_ pet: StoredPet) throws {
        let context = container.viewContext
        var outcome: Result<Void, Error> = .success(())
        context.performAndWait {
            do {
                let request = PetRecord.fetchRequest()
                request.fetchLimit = 1
                let record = try context.fetch(request).first ?? PetRecord(context: context)
                record.satiety = pet.needs.satiety
                record.cleanliness = pet.needs.cleanliness
                record.mood = pet.needs.mood
                record.energy = pet.needs.energy
                record.toilet = pet.needs.toilet
                record.lastCalculated = pet.needs.lastCalculated
                record.isSleeping = pet.isSleeping
                record.kitchenData = try JSONEncoder().encode(pet.kitchen)
                if context.hasChanges {
                    try context.save()
                }
            } catch {
                outcome = .failure(PetStoreError.saveFailed)
            }
        }
        try outcome.get()
    }

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = "PetRecord"
        entity.managedObjectClassName = NSStringFromClass(PetRecord.self)
        entity.properties = [
            attribute("satiety", .doubleAttributeType),
            attribute("cleanliness", .doubleAttributeType),
            attribute("mood", .doubleAttributeType),
            attribute("energy", .doubleAttributeType),
            attribute("toilet", .doubleAttributeType),
            attribute("lastCalculated", .dateAttributeType),
            attribute("isSleeping", .booleanAttributeType),
            optionalAttribute("kitchenData", .binaryDataAttributeType)
        ]
        model.entities = [entity]
        return model
    }

    private static func attribute(_ name: String, _ type: NSAttributeType) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = false
        return attribute
    }

    private static func optionalAttribute(_ name: String, _ type: NSAttributeType) -> NSAttributeDescription {
        let attribute = attribute(name, type)
        attribute.isOptional = true
        return attribute
    }
}

@objc(PetRecord)
final class PetRecord: NSManagedObject {
    @NSManaged var satiety: Double
    @NSManaged var cleanliness: Double
    @NSManaged var mood: Double
    @NSManaged var energy: Double
    @NSManaged var toilet: Double
    @NSManaged var lastCalculated: Date
    @NSManaged var isSleeping: Bool
    @NSManaged var kitchenData: Data?

    @nonobjc class func fetchRequest() -> NSFetchRequest<PetRecord> {
        NSFetchRequest<PetRecord>(entityName: "PetRecord")
    }
}

private extension StoredPet {
    init(record: PetRecord) {
        needs = PetNeeds(
            satiety: record.satiety,
            cleanliness: record.cleanliness,
            mood: record.mood,
            energy: record.energy,
            toilet: record.toilet,
            lastCalculated: record.lastCalculated
        )
        isSleeping = record.isSleeping
        kitchen = record.kitchenData.flatMap { try? JSONDecoder().decode(KitchenState.self, from: $0) } ?? .newcomer
    }
}
