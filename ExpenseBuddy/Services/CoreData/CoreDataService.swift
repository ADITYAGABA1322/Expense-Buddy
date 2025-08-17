import CoreData
import Foundation
import Combine

class CoreDataService: ObservableObject {
    static let shared = CoreDataService()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ExpenseBuddy")
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Core Data error: \(error)")

            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    private init() {}
    
    func save() {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            print("Core Data save error: \(error)")
        }
    }
    
    // MARK: - Expense Operations
    
    func saveExpenseLocally(_ expense: Expense, isDeleted: Bool = false) {
        // Check if expense already exists
        let fetchRequest: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", expense.id)
        
        let entity: ExpenseEntity
        if let existingEntity = try? context.fetch(fetchRequest).first {
            entity = existingEntity
        } else {
            entity = ExpenseEntity(context: context)
        }
        
        entity.id = expense.id
        entity.title = expense.title
        entity.amount = expense.amount
        entity.category = expense.category
        entity.currency = expense.currency
        entity.date = expense.date
        entity.descriptionText = expense.description
        entity.syncedAt = expense.syncedAt
        entity.isDelete = isDeleted
        
        save()
    }
    
    func createOfflineExpense(title: String, amount: Double, category: String, currency: String, date: Date, description: String?) -> String {
        let entity = ExpenseEntity(context: context)
        let id = UUID().uuidString
        
        entity.id = id
        entity.title = title
        entity.amount = amount
        entity.category = category
        entity.currency = currency
        entity.date = date
        entity.descriptionText = description
        entity.syncedAt = nil // Mark as unsynced
        entity.isDelete = false
        
        save()
        return id
    }
    
    // Fix: Return ExpenseEntity array instead of Expense array
    func fetchLocalExpenseEntities() -> [ExpenseEntity] {
        let request: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isDelete == NO")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ExpenseEntity.date, ascending: false)]
        
        return (try? context.fetch(request)) ?? []
    }
    
    // Keep this method for backward compatibility, converting entities to Expenses
    func fetchLocalExpenses() -> [Expense] {
        let entities = fetchLocalExpenseEntities()
        
        return entities.compactMap { entity in
            guard let id = entity.id,
                  let title = entity.title,
                  let category = entity.category,
                  let currency = entity.currency,
                  let date = entity.date else {
                return nil
            }
            
            return Expense(
                id: id,
                title: title,
                amount: entity.amount,
                category: category,
                currency: currency,
                date: date,
                description: entity.descriptionText,
                syncedAt: entity.syncedAt
            )
        }
    }
    
    
    func getUnsyncedExpenses() -> [ExpenseEntity] {
        let request: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
        request.predicate = NSPredicate(format: "syncedAt == nil")
        
        return (try? context.fetch(request)) ?? []
    }
    
    func markExpenseAsSynced(localId: String, serverData: Expense?) {
        let request: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", localId)
        
        if let expense = try? context.fetch(request).first {
            if let serverData = serverData {
                // Update with server data
                expense.id = serverData.id
                expense.syncedAt = Date()
            } else {
                // Delete if it was a delete operation
                context.delete(expense)
            }
            save()
        }
    }
    
    func clearAllData() {
        let request: NSFetchRequest<NSFetchRequestResult> = ExpenseEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(deleteRequest)
            save()
        } catch {
            print("Failed to clear Core Data: \(error)")
        }
    }
}

extension CoreDataService {
    func updateLocalExpense(id: String,
                            title: String,
                            amount: Double,
                            category: String,
                            currency: String,
                            date: Date,
                            description: String?) {
        let expense = Expense(id: id,
                              title: title,
                              amount: amount,
                              category: category,
                              currency: currency,
                              date: date,
                              description: description,
                              syncedAt: nil)
        saveExpenseLocally(expense)
    }
}



extension CoreDataService {
    // Add this new method
    func deleteExpenseCompletely(id: String) {
        let request: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        
        if let expense = try? context.fetch(request).first {
            context.delete(expense)
            save()
        }
    }
    
    // Update existing method to be more explicit
    func markExpenseAsDeleted(id: String) {
        let request: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        
        if let expense = try? context.fetch(request).first {
            expense.isDelete = true
            expense.syncedAt = nil // Mark for sync
            save()
        }
    }
}
