import Foundation
import Combine

// MARK: - Service Protocol
protocol EMTAPIServiceProtocol {
    /// Performs login to the EMT Madrid API.
    func login(email: String, password: String) -> AnyPublisher<EMTToken, Error>
    
    /// Fetches all bus stops from the API.
    func getAllStops(accessToken: String) -> AnyPublisher<[StopData], Error>
}

// MARK: - Concrete Service Implementation
final class EMTAPIService: EMTAPIServiceProtocol {
    
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }
    
    func login(email: String, password: String) -> AnyPublisher<EMTToken, Error> {
        guard let url = URL(string: "https://openapi.emtmadrid.es/v1/mobilitylabs/user/login/") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.addValue(email, forHTTPHeaderField: "email")
        request.addValue(password, forHTTPHeaderField: "password")
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: LoginResponse.self, decoder: decoder)
            .tryMap { loginResponse in
                guard let tokenData = loginResponse.data.first else {
                    throw URLError(.cannotParseResponse)
                }
                return EMTToken(accessToken: tokenData.accessToken, obtainedAt: Date())
            }
            .eraseToAnyPublisher()
    }
    
    func getAllStops(accessToken: String) -> AnyPublisher<[StopData], Error> {
        // Using API v2 for a more modern and complete response
        guard let url = URL(string: "https://openapi.emtmadrid.es/v2/transport/busemtmad/stops/list/") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(accessToken, forHTTPHeaderField: "accessToken")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // An empty JSON body is required for this endpoint to fetch all stops.
        request.httpBody = "{}".data(using: .utf8)
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    // You could decode an error model here for more detailed diagnostics
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: StopsResponse.self, decoder: decoder)
            .map(\.data) // Extract the array of stops from the response object
            .eraseToAnyPublisher()
    }
}