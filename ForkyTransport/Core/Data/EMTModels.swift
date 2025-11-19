import Foundation

// MARK: - Login Response
struct LoginResponse: Codable {
    let data: [LoginData]
}

struct LoginData: Codable {
    let accessToken: String
}

// MARK: - Stops API Models
struct StopsResponse: Codable {
    let data: [StopData]
}

struct StopData: Codable, Identifiable, Equatable {
    let stopId: Int
    let name: String
    let geometry: Geometry
    let lines: [LineInfo]

    var id: Int { stopId }
    
    // Custom coding keys to map API response to our model
    enum CodingKeys: String, CodingKey {
        case stopId = "stop"
        case name
        case geometry
        case lines
    }
}

struct LineInfo: Codable, Equatable {
    let line: String
    let direction: String
    let destination: String
}

struct Geometry: Codable, Equatable {
    // Implementing Equatable for Geometry
    static func == (lhs: Geometry, rhs: Geometry) -> Bool {
        lhs.type == rhs.type && lhs.coordinates == rhs.coordinates
    }
    
    let type: String
    let coordinates: [Double]
}

// MARK: - Request Body for Stops
// This is not needed if we fetch all stops, but good to have for the future.
struct StopsRequestBody: Codable {
    // Example properties for a more complex request
    let postalCode: String?
    let streetName: String?
    
    init(postalCode: String? = nil, streetName: String? = nil) {
        self.postalCode = postalCode
        self.streetName = streetName
    }
}
