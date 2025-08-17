import Foundation
import Network
import Combine

class NetworkService: ObservableObject {
    static let shared = NetworkService()
    
    @Published var isConnected = false
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    // Use your actual server URL
    private let baseURL = "https://expense-buddy-backend.vercel.app/api"
    private let session: URLSession
    
    // Custom decoder that handles multiple date formats
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            
            // Try to decode as string first
            if let dateString = try? container.decode(String.self) {
                // Try ISO8601 format first
                if let date = ISO8601DateFormatter().date(from: dateString) {
                    return date
                }
                
                // Try other common formats
                let formatters: [DateFormatter] = [
                    {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                        return formatter
                    }(),
                    {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                        return formatter
                    }(),
                    {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                        return formatter
                    }(),
                    {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        return formatter
                    }(),
                    {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        return formatter
                    }()
                ]
                
                for formatter in formatters {
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                }
                
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Cannot parse date string: \(dateString)"
                )
            }
            
            // Try to decode as timestamp
            if let timestamp = try? container.decode(Double.self) {
                return Date(timeIntervalSince1970: timestamp)
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date from given data"
            )
        }
        return decoder
    }()
    
    private let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    
    enum NetworkError: Error, LocalizedError {
        case noInternet
        case invalidURL
        case noData
        case decodingError(String)
        case serverError(Int)
        case timeout
        case serverUnavailable
        case unknown(Error)
        
        var errorDescription: String? {
            switch self {
            case .noInternet:
                return "No internet connection"
            case .invalidURL:
                return "Invalid URL"
            case .noData:
                return "No data received"
            case .decodingError(let details):
                return "Failed to decode response: \(details)"
            case .serverError(let code):
                return "Server error: \(code)"
            case .timeout:
                return "Request timed out"
            case .serverUnavailable:
                return "Server is not available. Working offline."
            case .unknown(let error):
                return error.localizedDescription
            }
        }
    }
    
    private init() {
        // Configure session with longer timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15.0
        config.timeoutIntervalForResource = 45.0
        config.requestCachePolicy = .useProtocolCachePolicy
        self.session = URLSession(configuration: config)
        
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                
                NotificationCenter.default.post(
                    name: .networkStatusChanged,
                    object: nil
                )
            }
        }
        monitor.start(queue: queue)
    }
    
    func request<T: Codable>(
        endpoint: String,
        method: String = "GET",
        body: Codable? = nil,
        responseType: T.Type,
        requiresAuth: Bool = false,
        retryCount: Int = 1
    ) async throws -> T {
        
        guard isConnected else {
            throw NetworkError.noInternet
        }
        
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if requiresAuth {
            if let token = getAuthToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else {
                throw NetworkError.serverError(401)
            }
        }
        
        if let body = body {
            do {
                request.httpBody = try jsonEncoder.encode(body)
            } catch {
                throw NetworkError.unknown(error)
            }
        }
        
        return try await performRequestWithRetry(request: request, responseType: responseType, retryCount: retryCount)
    }
    
    private func performRequestWithRetry<T: Codable>(
        request: URLRequest,
        responseType: T.Type,
        retryCount: Int
    ) async throws -> T {
        
        for attempt in 0...retryCount {
            do {
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.unknown(URLError(.badServerResponse))
                }
                
                // Debug: Print response for troubleshooting
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response from \(request.url?.absoluteString ?? "unknown"): \(responseString)")
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    do {
                        let decodedData = try jsonDecoder.decode(responseType, from: data)
                        return decodedData
                    } catch {
                        print("Decoding error details: \(error)")
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("Raw response: \(responseString)")
                        }
                        throw NetworkError.decodingError(error.localizedDescription)
                    }
                    
                case 401:
                    clearAuthToken()
                    throw NetworkError.serverError(401)
                    
                case 500...599:
                    if attempt < retryCount {
                        print("Server error \(httpResponse.statusCode), retrying... (attempt \(attempt + 1))")
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                        continue
                    } else {
                        throw NetworkError.serverError(httpResponse.statusCode)
                    }
                    
                default:
                    throw NetworkError.serverError(httpResponse.statusCode)
                }
                
            } catch {
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .timedOut:
                        if attempt < retryCount {
                            print("Request timed out, retrying... (attempt \(attempt + 1))")
                            try await Task.sleep(nanoseconds: 2_000_000_000)
                            continue
                        } else {
                            throw NetworkError.timeout
                        }
                    case .notConnectedToInternet:
                        throw NetworkError.noInternet
                    case .cannotConnectToHost, .cannotFindHost:
                        throw NetworkError.serverUnavailable
                    default:
                        throw NetworkError.unknown(error)
                    }
                } else {
                    throw error
                }
            }
        }
        
        throw NetworkError.timeout
    }
    
    private func getAuthToken() -> String? {
        return UserDefaults.standard.string(forKey: "auth_token")
    }
    
    private func clearAuthToken() {
        UserDefaults.standard.removeObject(forKey: "auth_token")
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .userLoggedOut, object: nil)
        }
    }
}

extension Notification.Name {
    //static let networkStatusChanged = Notification.Name("networkStatusChanged")
    static let userLoggedOut = Notification.Name("userLoggedOut")
}
