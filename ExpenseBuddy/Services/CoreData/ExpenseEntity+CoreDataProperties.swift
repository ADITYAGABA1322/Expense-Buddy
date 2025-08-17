public import Foundation
public import CoreData


public typealias ExpenseEntityCoreDataPropertiesSet = NSSet

extension ExpenseEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExpenseEntity> {
        return NSFetchRequest<ExpenseEntity>(entityName: "ExpenseEntity")
    }

    @NSManaged public var id: String?
    @NSManaged public var title: String?
    @NSManaged public var amount: Double
    @NSManaged public var category: String?
    @NSManaged public var currency: String?
    @NSManaged public var date: Date?
    @NSManaged public var descriptionText: String?
    @NSManaged public var syncedAt: Date?
    @NSManaged public var isDelete: Bool

}

extension ExpenseEntity : Identifiable {

}
