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
struct StopRecord: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "stops" }

    var id: String
    let name: String
    let lines: String // Store the array of lines as a single JSON string
    let latitude: Double
    let longitude: Double

    init(from stopData: StopData) {
        self.id = stopData.node
        self.name = stopData.name

        if let linesData = try? JSONEncoder().encode(stopData.lines) {
            self.lines = String(data: linesData, encoding: .utf8) ?? "[]"
        } else {
            self.lines = "[]"
        }

        self.latitude = stopData.geometry.coordinates.last ?? 0.0
        self.longitude = stopData.geometry.coordinates.first ?? 0.0
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, lines, latitude, longitude
    }
}
