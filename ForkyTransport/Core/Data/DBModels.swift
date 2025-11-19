import Foundation
import GRDB

// MARK: - GRDB Record for EMTToken
struct EMTTokenRecord: Codable, FetchableRecord, PersistableRecord {
    let id: Int?
    let accessToken: String
    let obtainedAt: Date
    
    init(id: Int? = nil, accessToken: String, obtainedAt: Date) {
        self.id = id
        self.accessToken = accessToken
        self.obtainedAt = obtainedAt
    }
    
    // Para mapear entre EMTToken y EMTTokenRecord
    init(from token: EMTToken) {
        self.id = nil
        self.accessToken = token.accessToken
        self.obtainedAt = token.obtainedAt
    }
}

// MARK: - EMTToken con conversión
struct EMTToken: Codable, Equatable {
    let accessToken: String
    let obtainedAt: Date
    
    // Convertir de EMTTokenRecord
    init(from record: EMTTokenRecord) {
        self.accessToken = record.accessToken
        self.obtainedAt = record.obtainedAt
    }
    
    init(accessToken: String, obtainedAt: Date) {
        self.accessToken = accessToken
        self.obtainedAt = obtainedAt
    }
}
