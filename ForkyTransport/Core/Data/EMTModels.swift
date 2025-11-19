import Foundation
import GRDB

// MARK: - App-specific Token Model
struct EMTToken: Codable, Equatable {
    let accessToken: String
    let obtainedAt: Date
}

// MARK: - Login Response
struct LoginResponse: Codable {
    let data: [LoginData]
}

struct LoginData: Codable {
    let accessToken: String
}

// MARK: - Stops API Models (for V1 Endpoint)
// This structure now perfectly matches the user's Postman response.
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
