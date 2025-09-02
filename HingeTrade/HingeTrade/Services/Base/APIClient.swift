import Foundation
import Combine

// MARK: - API Client Protocol
protocol APIClientProtocol {
    func request<T: Codable>(_ endpoint: APIEndpoint) -> AnyPublisher<APIResponse<T>, APIError>
    func requestPaginated<T: Codable>(_ endpoint: APIEndpoint) -> AnyPublisher<PaginatedResponse<T>, APIError>
}

// MARK: - API Endpoint
struct APIEndpoint {
    let path: String
    let method: HTTPMethod
    let headers: [String: String]?
    let body: Data?
    let queryItems: [URLQueryItem]?
    
    init(path: String, 
         method: HTTPMethod = .GET,
         headers: [String: String]? = nil,
         body: Data? = nil,
         queryItems: [URLQueryItem]? = nil) {
        self.path = path
        self.method = method
        self.headers = headers
        self.body = body
        self.queryItems = queryItems
    }
}

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - API Client Implementation
class APIClient: APIClientProtocol {
    private let baseURL: URL
    private let session: URLSession
    private let tokenManager: TokenManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    init(baseURL: URL, tokenManager: TokenManager) {
        self.baseURL = baseURL
        self.tokenManager = tokenManager
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
        
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        
        // Configure date formatting
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
    }
    
    func request<T: Codable>(_ endpoint: APIEndpoint) -> AnyPublisher<APIResponse<T>, APIError> {
        return createRequest(for: endpoint)
            .flatMap { request in
                self.performRequest(request)
            }
            .decode(type: APIResponse<T>.self, decoder: self.decoder)
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                }
                return APIError(
                    code: "DECODE_ERROR",
                    message: "Failed to decode response",
                    details: error.localizedDescription,
                    field: nil
                )
            }
            .eraseToAnyPublisher()
    }
    
    func requestPaginated<T: Codable>(_ endpoint: APIEndpoint) -> AnyPublisher<PaginatedResponse<T>, APIError> {
        return createRequest(for: endpoint)
            .flatMap { request in
                self.performRequest(request)
            }
            .decode(type: PaginatedResponse<T>.self, decoder: self.decoder)
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                }
                return APIError(
                    code: "DECODE_ERROR",
                    message: "Failed to decode paginated response",
                    details: error.localizedDescription,
                    field: nil
                )
            }
            .eraseToAnyPublisher()
    }
    
    private func createRequest(for endpoint: APIEndpoint) -> AnyPublisher<URLRequest, APIError> {
        return Future<URLRequest, APIError> { promise in
            do {
                let request = try self.buildURLRequest(for: endpoint)
                promise(.success(request))
            } catch {
                let apiError = error as? APIError ?? APIError(
                    code: "REQUEST_BUILD_ERROR",
                    message: "Failed to build request",
                    details: error.localizedDescription,
                    field: nil
                )
                promise(.failure(apiError))
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func buildURLRequest(for endpoint: APIEndpoint) throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: true)
        components?.queryItems = endpoint.queryItems
        
        guard let url = components?.url else {
            throw APIError(
                code: "INVALID_URL",
                message: "Invalid URL",
                details: "Could not construct URL from components",
                field: nil
            )
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        // Set default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("HingeTrade-tvOS/1.0", forHTTPHeaderField: "User-Agent")
        
        // Add authorization header if token is available
        if let token = tokenManager.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add custom headers
        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Set body
        request.httpBody = endpoint.body
        
        return request
    }
    
    private func performRequest(_ request: URLRequest) -> AnyPublisher<Data, APIError> {
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError(
                        code: "INVALID_RESPONSE",
                        message: "Invalid response type",
                        details: "Expected HTTPURLResponse",
                        field: nil
                    )
                }
                
                // Handle HTTP error status codes
                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 401:
                    throw APIError.unauthorized
                case 400:
                    // Try to parse error from response body
                    if let errorResponse = try? self.decoder.decode(APIResponse<String>.self, from: data),
                       let error = errorResponse.error {
                        throw error
                    }
                    throw APIError(
                        code: "BAD_REQUEST",
                        message: "Bad request",
                        details: "The request was invalid",
                        field: nil
                    )
                case 403:
                    throw APIError(
                        code: "FORBIDDEN",
                        message: "Access forbidden",
                        details: "You don't have permission to access this resource",
                        field: nil
                    )
                case 404:
                    throw APIError(
                        code: "NOT_FOUND",
                        message: "Resource not found",
                        details: "The requested resource was not found",
                        field: nil
                    )
                case 429:
                    throw APIError(
                        code: "RATE_LIMITED",
                        message: "Too many requests",
                        details: "Please slow down and try again later",
                        field: nil
                    )
                case 500...599:
                    throw APIError(
                        code: "SERVER_ERROR",
                        message: "Server error",
                        details: "The server encountered an error processing your request",
                        field: nil
                    )
                default:
                    throw APIError(
                        code: "HTTP_ERROR",
                        message: "HTTP error \(httpResponse.statusCode)",
                        details: "Unexpected HTTP status code",
                        field: nil
                    )
                }
            }
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                }
                
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .notConnectedToInternet:
                        return APIError(
                            code: "NETWORK_NOT_CONNECTED",
                            message: "No internet connection",
                            details: "Please check your internet connection and try again",
                            field: nil
                        )
                    case .timedOut:
                        return APIError(
                            code: "NETWORK_TIMEOUT",
                            message: "Request timed out",
                            details: "The request took too long to complete",
                            field: nil
                        )
                    case .cannotFindHost:
                        return APIError(
                            code: "NETWORK_HOST_NOT_FOUND",
                            message: "Cannot reach server",
                            details: "Unable to connect to the server",
                            field: nil
                        )
                    default:
                        return APIError(
                            code: "NETWORK_ERROR",
                            message: "Network error",
                            details: urlError.localizedDescription,
                            field: nil
                        )
                    }
                }
                
                return APIError(
                    code: "UNKNOWN_ERROR",
                    message: "Unknown error occurred",
                    details: error.localizedDescription,
                    field: nil
                )
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Token Manager
protocol TokenManagerProtocol {
    var accessToken: String? { get }
    var refreshToken: String? { get }
    var isTokenExpired: Bool { get }
    
    func setTokens(_ tokens: AuthTokens)
    func clearTokens()
    func refreshTokenIfNeeded() -> AnyPublisher<AuthTokens, APIError>
}

class TokenManager: TokenManagerProtocol {
    private let keychain = Keychain()
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"
    private let tokenExpiryKey = "token_expiry"
    
    private var _currentTokens: AuthTokens?
    
    var accessToken: String? {
        return _currentTokens?.accessToken ?? keychain.get(accessTokenKey)
    }
    
    var refreshToken: String? {
        return _currentTokens?.refreshToken ?? keychain.get(refreshTokenKey)
    }
    
    var isTokenExpired: Bool {
        if let tokens = _currentTokens {
            return tokens.isExpired
        }
        
        guard let expiryString = keychain.get(tokenExpiryKey),
              let expiry = TimeInterval(expiryString) else {
            return true
        }
        
        return Date().timeIntervalSince1970 >= expiry
    }
    
    func setTokens(_ tokens: AuthTokens) {
        _currentTokens = tokens
        keychain.set(tokens.accessToken, forKey: accessTokenKey)
        keychain.set(tokens.refreshToken, forKey: refreshTokenKey)
        keychain.set(String(tokens.expiresAt.timeIntervalSince1970), forKey: tokenExpiryKey)
    }
    
    func clearTokens() {
        _currentTokens = nil
        keychain.delete(accessTokenKey)
        keychain.delete(refreshTokenKey)
        keychain.delete(tokenExpiryKey)
    }
    
    func refreshTokenIfNeeded() -> AnyPublisher<AuthTokens, APIError> {
        // Implementation would make API call to refresh endpoint
        // This is a placeholder that would need to be implemented based on your auth API
        return Fail(error: APIError(code: "NOT_IMPLEMENTED", message: "Token refresh not implemented", details: nil, field: nil))
            .eraseToAnyPublisher()
    }
}

// MARK: - Simple Keychain Wrapper
class Keychain {
    func set(_ value: String, forKey key: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func get(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == noErr {
            if let data = dataTypeRef as? Data {
                return String(data: data, encoding: .utf8)
            }
        }
        
        return nil
    }
    
    func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - API Endpoint Extensions
extension APIEndpoint {
    static func get(_ path: String, queryItems: [URLQueryItem]? = nil) -> APIEndpoint {
        return APIEndpoint(path: path, method: .GET, queryItems: queryItems)
    }
    
    static func post<T: Codable>(_ path: String, body: T) throws -> APIEndpoint {
        let encoder = JSONEncoder()
        let data = try encoder.encode(body)
        return APIEndpoint(path: path, method: .POST, body: data)
    }
    
    static func put<T: Codable>(_ path: String, body: T) throws -> APIEndpoint {
        let encoder = JSONEncoder()
        let data = try encoder.encode(body)
        return APIEndpoint(path: path, method: .PUT, body: data)
    }
    
    static func delete(_ path: String) -> APIEndpoint {
        return APIEndpoint(path: path, method: .DELETE)
    }
}