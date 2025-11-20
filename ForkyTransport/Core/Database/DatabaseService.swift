import Foundation
import GRDB
import Combine

// MARK: - Service Protocol
protocol DatabaseServiceProtocol {
    // Token Management
    func saveToken(_ token: EMTToken) -> AnyPublisher<Void, Error>
    func getToken() -> AnyPublisher<EMTToken?, Error>

    // Stop Management
    func processAndSaveStops(from stopData: [StopData]) -> AnyPublisher<Int, Error>
    func getStopsFromDB(limit: Int, offset: Int) -> AnyPublisher<[StopData], Error>
    func searchStopsFromDB(query: String, limit: Int) -> AnyPublisher<[StopData], Error>
}

// MARK: - Concrete Service Implementation
final class DatabaseService: DatabaseServiceProtocol {
    
    private let dbQueue: any DatabaseWriter
    
    init?() {
        print("[DBService] init? called.")
        do {
            let fileManager = FileManager.default
            let dbPath = try fileManager
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("forky.sqlite")
                .path
            print("[DBService] > DB path: \(dbPath)")
            
            self.dbQueue = try DatabaseQueue(path: dbPath)
            print("[DBService] > DatabaseQueue initialized.")
            
            try self.createTables()
            print("[DBService] > createTables() successful.")
            
        } catch {
            print("[DBService] > FATAL: DatabaseService failed to initialize: \(error)")
            return nil
        }
        print("[DBService] init? finished successfully.")
    }
    
    private func createTables() throws {
        print("[DBService] createTables() called.")
        try dbQueue.write { db in
            print("[DBService] > createTables: dbQueue.write block started.")
            // Token Table
            try db.create(table: EMTTokenRecord.databaseTableName, ifNotExists: true) { t in
                t.column("id", .integer).primaryKey(autoincrement: true)
                t.column("accessToken", .text).notNull()
                t.column("obtainedAt", .datetime).notNull()
            }
            print("[DBService] > > Token table created or already exists.")
            
            // Stops Table
            try db.create(table: StopRecord.databaseTableName, ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("name", .text).notNull()
                t.column("lines", .text).notNull()
                t.column("latitude", .double).notNull()
                t.column("longitude", .double).notNull()
            }
            print("[DBService] > > Stops table created or already exists.")
        }
        print("[DBService] > createTables: dbQueue.write block finished.")
    }
    
    // MARK: - Token Methods
    
    func saveToken(_ token: EMTToken) -> AnyPublisher<Void, Error> {
        print("[DBService] saveToken() called.")
        return Future { promise in
            do {
                try self.dbQueue.write { db in
                    var record = EMTTokenRecord(id: nil, accessToken: token.accessToken, obtainedAt: token.obtainedAt)
                    try record.save(db)
                    print("[DBService] > saveToken: success.")
                }
                promise(.success(()))
            } catch {
                print("[DBService] > saveToken: FAILED with error: \(error)")
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func getToken() -> AnyPublisher<EMTToken?, Error> {
        print("[DBService] getToken() called.")
        return Future { promise in
            print("[DBService] > getToken: Future started.")
            do {
                let tokenRecord = try self.dbQueue.read { db -> EMTTokenRecord? in
                    print("[DBService] > > getToken: dbQueue.read block started.")
                    let record = try EMTTokenRecord.order(Column("id").desc).fetchOne(db)
                    print("[DBService] > > > getToken: fetchOne executed. Record is \(record != nil ? "found" : "not found").")
                    if let foundRecord = record {
                        print("[DBService] > > > TokenRecord content: id=\(foundRecord.id ?? -1), accessToken=\(foundRecord.accessToken.prefix(10))..., obtainedAt=\(foundRecord.obtainedAt)")
                    }
                    return record
                }
                
                let token = tokenRecord.map { EMTToken(accessToken: $0.accessToken, obtainedAt: $0.obtainedAt) }
                promise(.success(token))
                print("[DBService] > getToken: Future succeeded.")
            } catch {
                print("[DBService] > getToken: FAILED with error: \(error)")
                promise(.failure(error))
            }
        }
        .subscribe(on: DispatchQueue.global())
        .eraseToAnyPublisher()
    }
    
    // MARK: - Stop Methods
    
    func processAndSaveStops(from stopData: [StopData]) -> AnyPublisher<Int, Error> {
        print("[DBService] processAndSaveStops() called with \(stopData.count) items.")
        return Future { promise in
            do {
                let stopRecords = stopData.map { StopRecord(from: $0) }
                
                try self.dbQueue.write { db in
                    for var record in stopRecords {
                        try record.save(db)
                    }
                }
                print("[DBService] > processAndSaveStops: Successfully saved \(stopRecords.count) stops to DB.")
                promise(.success(stopRecords.count))
            } catch {
                print("[DBService] > processAndSaveStops: FAILED with error: \(error)")
                promise(.failure(error))
            }
        }
        .subscribe(on: DispatchQueue.global()) // Ensure this heavy operation runs in the background
        .eraseToAnyPublisher()
    }
    
    func getStopsFromDB(limit: Int, offset: Int) -> AnyPublisher<[StopData], Error> {
        print("[DBService] getStopsFromDB() called with limit: \(limit), offset: \(offset).")
        return Future { promise in
            do {
                let stopRecords = try self.dbQueue.read { db in
                    try StopRecord.order(Column("id")).limit(limit, offset: offset).fetchAll(db)
                }
                print("[DBService] > getStopsFromDB: Fetched \(stopRecords.count) records from DB.")

                let stops = stopRecords.map { record -> StopData in
                    let lines = (try? JSONDecoder().decode([String].self, from: Data(record.lines.utf8))) ?? []
                    let geometry = Geometry(type: "Point", coordinates: [record.longitude, record.latitude])
                    return StopData(node: record.id, name: record.name, wifi: "0", lines: lines, geometry: geometry)
                }
                promise(.success(stops))
            } catch {
                print("[DBService] > getStopsFromDB: FAILED with error: \(error)")
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }

    func searchStopsFromDB(query: String, limit: Int) -> AnyPublisher<[StopData], Error> {
        print("[DBService] searchStopsFromDB() called with query: \(query), limit: \(limit).")
        return Future { promise in
            do {
                let stopRecords = try self.dbQueue.read { db in
                    // Search in name, id (node), and lines - using LIKE for partial matching
                    let searchPattern = "%\(query)%"
                    let linesPattern = "%\"\(query)\"%" // For searching within the JSON array of lines

                    let matchingRecords = try StopRecord
                        .filter(
                            Column("name").like(searchPattern) ||
                            Column("id").like(searchPattern) ||
                            Column("lines").like(linesPattern)
                        )
                        .limit(limit)
                        .fetchAll(db)

                    return matchingRecords
                }
                print("[DBService] > searchStopsFromDB: Found \(stopRecords.count) matching records from DB.")

                let stops = stopRecords.map { record -> StopData in
                    let lines = (try? JSONDecoder().decode([String].self, from: Data(record.lines.utf8))) ?? []
                    let geometry = Geometry(type: "Point", coordinates: [record.longitude, record.latitude])
                    return StopData(node: record.id, name: record.name, wifi: "0", lines: lines, geometry: geometry)
                }
                promise(.success(stops))
            } catch {
                print("[DBService] > searchStopsFromDB: FAILED with error: \(error)")
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
}
