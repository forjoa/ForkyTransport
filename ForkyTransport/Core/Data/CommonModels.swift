import Foundation

// MARK: - App-specific Token Model
struct EMTToken: Codable, Equatable {
    let accessToken: String
    let obtainedAt: Date
}

// MARK: - Login API Models
struct LoginResponse: Codable {
    let data: [LoginData]
}

struct LoginData: Codable {
    let accessToken: String
}

// MARK: - Stops API Models (for V1 Endpoint)
struct StopsResponse: Codable {
    let code: String
    let description: String
    let data: [StopData]
}

struct StopData: Codable, Identifiable, Equatable {
    let node: String
    let name: String
    let wifi: String
    let lines: [String]
    let geometry: Geometry

    var id: String { node }
}

struct Geometry: Codable, Equatable {
    let type: String
    let coordinates: [Double]
}

// MARK: - Arrival Times API Models (for V2 Endpoint)
struct ArrivalResponse: Codable {
    let code: String
    let description: String
    let datetime: String
    let data: [ArrivalData]
}

struct ArrivalData: Codable {
    let arrive: [BusArrival]?
    let stopInfo: [StopInfo]?
    let extraInfo: [String]?
    let incident: [String: String]?

    private enum CodingKeys: String, CodingKey {
        case arrive = "Arrive"
        case stopInfo = "StopInfo"
        case extraInfo = "ExtraInfo"
        case incident = "Incident"
    }
}

struct BusArrival: Codable, Identifiable {
    let line: String
    let stop: String
    let isHead: String
    let destination: String
    let deviation: Int?
    let bus: Int?
    let geometry: Geometry?
    let _estimateArrive: String
    let distanceBus: Int
    let positionTypeBus: String?

    var estimateArrive: Int {
        return Int(_estimateArrive) ?? 0
    }

    var id: String { "\(line)-\(stop)-\(bus ?? 0)-\(estimateArrive)" }

    private enum CodingKeys: String, CodingKey {
        case line, stop, isHead, destination, deviation, bus, geometry, estimateArrive = "estimateArrive", distanceBus = "DistanceBus", positionTypeBus
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        line = try container.decode(String.self, forKey: .line)
        stop = try container.decode(String.self, forKey: .stop)
        isHead = try container.decode(String.self, forKey: .isHead)
        destination = try container.decode(String.self, forKey: .destination)
        deviation = try container.decodeIfPresent(Int.self, forKey: .deviation)
        bus = try container.decodeIfPresent(Int.self, forKey: .bus)
        geometry = try container.decodeIfPresent(Geometry.self, forKey: .geometry)
        // Handle estimateArrive which can be string or int from API
        if let intValue = try? container.decode(Int.self, forKey: .estimateArrive) {
            _estimateArrive = String(intValue)
        } else if let stringValue = try? container.decode(String.self, forKey: .estimateArrive) {
            _estimateArrive = stringValue
        } else {
            _estimateArrive = "0"
        }
        distanceBus = try container.decode(Int.self, forKey: .distanceBus)
        positionTypeBus = try container.decodeIfPresent(String.self, forKey: .positionTypeBus)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(line, forKey: .line)
        try container.encode(stop, forKey: .stop)
        try container.encode(isHead, forKey: .isHead)
        try container.encode(destination, forKey: .destination)
        try container.encodeIfPresent(deviation, forKey: .deviation)
        try container.encodeIfPresent(bus, forKey: .bus)
        try container.encodeIfPresent(geometry, forKey: .geometry)
        try container.encode(_estimateArrive, forKey: .estimateArrive)
        try container.encode(distanceBus, forKey: .distanceBus)
        try container.encodeIfPresent(positionTypeBus, forKey: .positionTypeBus)
    }
}

// Extension to handle optional decoding
private extension KeyedDecodingContainer {
    func decodeIfNil<T>(_ type: T.Type, forKey key: Key) throws -> T? where T: Decodable {
        return try decodeIfPresent(type, forKey: key)
    }
}

struct StopInfo: Codable {
    let lines: [LineDetail]?
    let stopId: String?
    let stopName: String?
    let geometry: Geometry?
    let direction: String?
    let forecolor: String? // Added to handle optional forecolor field

    private enum CodingKeys: String, CodingKey {
        case lines, stopId, stopName, geometry, direction = "Direction", forecolor
    }
}

struct LineDetail: Codable, Identifiable {
    let label: String?
    let line: String?
    let nameA: String?
    let nameB: String?
    let metersFromHeader: Int?
    let to: String?
    let color: String?
    let forecolor: String? // Added to handle optional forecolor field

    var id: String {
        line ?? label ?? UUID().uuidString
    }

    private enum CodingKeys: String, CodingKey {
        case label, line, nameA, nameB, metersFromHeader, to, color, forecolor
    }
}
