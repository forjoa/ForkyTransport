import Foundation
import Combine

// MARK: - Service Protocol
protocol EMTAPIServiceProtocol {
    func login(email: String, password: String) -> AnyPublisher<EMTToken, Error>

    /// Fetches all bus stops and returns a decoded array of StopData objects.
    func getAllStops(accessToken: String) -> AnyPublisher<[StopData], Error>

    /// Fetches arrival times for a specific stop.
    func getArrivalTimes(stopId: String, accessToken: String) -> AnyPublisher<ArrivalResponse, Error>
}

// MARK: - Custom Error for API Logic
enum EMTAPIError: Error, LocalizedError {
    case apiError(description: String)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .apiError(let description):
            return description
        case .invalidResponse:
            return "La respuesta de la API no es válida."
        }
    }
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
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: LoginResponse.self, decoder: decoder)
            .tryMap { loginResponse -> EMTToken in
                guard let tokenData = loginResponse.data.first else { throw URLError(.cannotParseResponse) }
                return EMTToken(accessToken: tokenData.accessToken, obtainedAt: Date())
            }
            .eraseToAnyPublisher()
    }
    
    func getAllStops(accessToken: String) -> AnyPublisher<[StopData], Error> {
        guard let url = URL(string: "https://openapi.emtmadrid.es/v1/transport/busemtmad/stops/list/") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(accessToken, forHTTPHeaderField: "accessToken")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("[EMTAPIService] getAllStops: Sending request with accessToken: \(accessToken.prefix(10))...")
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .tryMap { data -> [StopData] in
                let response = try self.decoder.decode(StopsResponse.self, from: data)
                
                // Check the business logic code from the API response
                guard response.code == "00" else {
                    // The API returned a 200 OK, but with an error message inside the JSON.
                    throw EMTAPIError.apiError(description: "API Error: \(response.code), Message: \(response.description)")
                }
                
                return response.data
            }
            .eraseToAnyPublisher()
    }
    
    func getArrivalTimes(stopId: String, accessToken: String) -> AnyPublisher<ArrivalResponse, Error> {
        guard let url = URL(string: "https://openapi.emtmadrid.es/v2/transport/busemtmad/stops/\(stopId)/arrives") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        print("[EMTAPIService] url for arrival")
        print(url)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(accessToken, forHTTPHeaderField: "accessToken")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
          "cultureInfo": "ES",
          "Text_StopRequired_YN": "Y",
          "Text_EstimationsRequired_YN": "Y",
          "Text_IncidencesRequired_YN": "N",
          "DateTime_Referenced_Incidencies_YYYYMMDD": "20231126"
        ]

        do {
          request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
          print("Error serializing JSON:", error)
        }

        print("[EMTAPIService] getArrivalTimes: Sending request for stop \(stopId) with accessToken: \(accessToken.prefix(10))...")

        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: ArrivalResponse.self, decoder: decoder)
            .tryMap { arrivalResponse in
                guard arrivalResponse.code == "00" else {
                    throw EMTAPIError.apiError(description: "API Error (Arrivals): \(arrivalResponse.code) - \(arrivalResponse.description)")
                }

                return arrivalResponse
            }
            .eraseToAnyPublisher()
    }
}
