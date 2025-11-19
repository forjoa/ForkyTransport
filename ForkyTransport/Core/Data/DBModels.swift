import Foundation
import GRDB

// MARK: - GRDB Record for EMTToken
struct EMTTokenRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "emtToken" }
    
    var id: Int64?
    let accessToken: String
    let obtainedAt: Date
}

// MARK: - GRDB Record for Stop
// This struct is designed to be stored efficiently in the database.
struct StopRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "stops" }
    
    // We use the 'node' from the API as the primary key, as it's unique.
    var id: String
    let name: String
    let lines: String // Store the array of lines as a single JSON string
    let latitude: Double
    let longitude: Double
    
    // Custom initializer to map from the API's StopData model
    init(from stopData: StopData) {
        self.id = stopData.node
        self.name = stopData.name
        
        // Encode the array of strings into a single JSON string for storage.
        if let linesData = try? JSONEncoder().encode(stopData.lines) {
            self.lines = String(data: linesData, encoding: .utf8) ?? "[]"
        } else {
            self.lines = "[]"
        }
        
        self.latitude = stopData.geometry.coordinates.last ?? 0.0
        self.longitude = stopData.geometry.coordinates.first ?? 0.0
    }
    
    // Required by Codable, but we use the custom init for mapping.
    private enum CodingKeys: String, CodingKey {
        case id, name, lines, latitude, longitude
    }
}