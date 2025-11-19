import Foundation
import GRDB
import Combine

// MARK: - Service Protocol
protocol DatabaseServiceProtocol {
    func saveToken(_ token: EMTToken) -> AnyPublisher<Void, Error>
    func getToken() -> AnyPublisher<EMTToken?, Error>
}

// MARK: - Concrete Service Implementation
final class DatabaseService: DatabaseServiceProtocol {
    
    private let dbQueue: any DatabaseWriter
    
    /// Initializes the database service and sets up the database file and tables.
    init() throws {
        let fileManager = FileManager.default
        let dbPath = try fileManager
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("forky.sqlite")
            .path
        
        self.dbQueue = try DatabaseQueue(path: dbPath)
        try self.createTables()
    }
    
    /// Creates the necessary database tables if they don't exist.
    private func createTables() throws {
        try dbQueue.write { db in
            try db.create(table: EMTTokenRecord.databaseTableName, ifNotExists: true) { t in
                t.column("id", .integer).primaryKey()
                t.column("accessToken", .text).notNull()
                t.column("obtainedAt", .datetime).notNull()
            }
        }
    }
    
    /// Saves or updates the EMT token in the database.
    func saveToken(_ token: EMTToken) -> AnyPublisher<Void, Error> {
        Future { promise in
            do {
                try self.dbQueue.write { db in
                    let record = EMTTokenRecord(accessToken: token.accessToken, obtainedAt: token.obtainedAt)
                    try record.save(db)
                }
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    /// Retrieves the EMT token from the database.
    func getToken() -> AnyPublisher<EMTToken?, Error> {
        Future { promise in
            do {
                let tokenRecord = try self.dbQueue.read { db -> EMTTokenRecord? in
                    try EMTTokenRecord.fetchOne(db)
                }
                
                if let record = tokenRecord {
                    let token = EMTToken(accessToken: record.accessToken, obtainedAt: record.obtainedAt)
                    promise(.success(token))
                } else {
                    promise(.success(nil))
                }
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
}
