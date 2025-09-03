import Foundation
import Combine
#if os(iOS)
import UIKit
#endif

// MARK: - Authentication Service Protocol
protocol AuthenticationServiceProtocol {
    var currentUser: User? { get }
    var isAuthenticated: Bool { get }
    var authenticationState: AnyPublisher<AuthState, Never> { get }
    
    func login(email: String, password: String) -> AnyPublisher<User, APIError>
    func logout() -> AnyPublisher<Void, APIError>
    func refreshToken() -> AnyPublisher<AuthTokens, APIError>
    func getCurrentUser() -> AnyPublisher<User, APIError>
    func updateUser(_ user: User) -> AnyPublisher<User, APIError>
    func changePassword(currentPassword: String, newPassword: String) -> AnyPublisher<Void, APIError>
    func requestPasswordReset(email: String) -> AnyPublisher<Void, APIError>
}

// MARK: - Authentication State
enum AuthState {
    case unauthenticated
    case authenticating
    case authenticated(User)
    case error(APIError)
    
    var user: User? {
        if case .authenticated(let user) = self {
            return user
        }
        return nil
    }
    
    var isAuthenticated: Bool {
        if case .authenticated = self {
            return true
        }
        return false
    }
    
    var error: APIError? {
        if case .error(let error) = self {
            return error
        }
        return nil
    }
}

// MARK: - Authentication Service Implementation
class AuthenticationService: AuthenticationServiceProtocol {
    private let apiClient: APIClientProtocol
    private let tokenManager: TokenManagerProtocol
    
    @Published private var _currentUser: User?
    @Published private var _authenticationState: AuthState = .unauthenticated
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Properties
    
    var currentUser: User? {
        return _currentUser
    }
    
    var isAuthenticated: Bool {
        return _authenticationState.isAuthenticated && !tokenManager.isTokenExpired
    }
    
    var authenticationState: AnyPublisher<AuthState, Never> {
        return $_authenticationState.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init(apiClient: APIClientProtocol, tokenManager: TokenManagerProtocol) {
        self.apiClient = apiClient
        self.tokenManager = tokenManager
        
        // Check for existing valid session on init
        checkExistingSession()
    }
    
    // MARK: - Public Methods
    
    func login(email: String, password: String) -> AnyPublisher<User, APIError> {
        _authenticationState = .authenticating
        
        let request = LoginRequest(
            email: email,
            password: password,
            deviceId: {
                #if os(iOS)
                return UIDevice.current.identifierForVendor?.uuidString
                #else
                return UUID().uuidString // Fallback for tvOS
                #endif
            }(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        )
        
        do {
            let endpoint = try APIEndpoint.post("/auth/login", body: request)
            
            return apiClient.request<LoginResponse>(endpoint)
                .tryMap { (response: APIResponse<LoginResponse>) -> LoginResponse in
                    guard let loginResponse = response.data else {
                        throw APIError(
                            code: "LOGIN_FAILED",
                            message: "Login failed",
                            details: "No data received from server",
                            field: nil
                        )
                    }
                    return loginResponse
                }
                .handleEvents(receiveOutput: { [weak self] loginResponse in
                    // Store tokens and user
                    self?.tokenManager.setTokens(loginResponse.tokens)
                    self?._currentUser = loginResponse.user
                    self?._authenticationState = .authenticated(loginResponse.user)
                })
                .map { (loginResponse: LoginResponse) -> User in
                    return loginResponse.user
                }
                .catch { [weak self] error -> AnyPublisher<User, APIError> in
                    let apiError = error as? APIError ?? APIError(
                        code: "AUTH_ERROR",
                        message: "Authentication failed",
                        details: error.localizedDescription,
                        field: nil
                    )
                    self?._authenticationState = .error(apiError)
                    return Fail<User, APIError>(error: apiError).eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
                
        } catch {
            let apiError = error as? APIError ?? APIError(
                code: "REQUEST_ERROR",
                message: "Failed to create login request",
                details: error.localizedDescription,
                field: nil
            )
            _authenticationState = .error(apiError)
            return Fail<User, APIError>(error: apiError).eraseToAnyPublisher()
        }
    }
    
    func logout() -> AnyPublisher<Void, APIError> {
        do {
            let endpoint = try APIEndpoint.post("/auth/logout", body: EmptyRequest())
            
            return apiClient.request<SimpleResponse>(endpoint)
                .map { (_: APIResponse<SimpleResponse>) in () }
                .handleEvents(receiveOutput: { [weak self] _ in
                    self?.clearSession()
                }, receiveCompletion: { [weak self] completion in
                    // Clear session regardless of API response
                    // (in case the server is unreachable)
                    if case .failure = completion {
                        self?.clearSession()
                    }
                })
                .map { _ in () }
                .catch { [weak self] error in
                    // Still clear local session even if logout API fails
                    self?.clearSession()
                    return Just(()).setFailureType(to: APIError.self)
                }
                .eraseToAnyPublisher()
                
        } catch {
            // If we can't even create the request, still clear the session
            clearSession()
            let apiError = error as? APIError ?? APIError(
                code: "REQUEST_ERROR",
                message: "Failed to create logout request",
                details: error.localizedDescription,
                field: nil
            )
            return Fail<Void, APIError>(error: apiError).eraseToAnyPublisher()
        }
    }
    
    func refreshToken() -> AnyPublisher<AuthTokens, APIError> {
        guard let refreshToken = tokenManager.refreshToken else {
            let error = APIError(
                code: "NO_REFRESH_TOKEN",
                message: "No refresh token available",
                details: "Please log in again",
                field: nil
            )
            return Fail<AuthTokens, APIError>(error: error).eraseToAnyPublisher()
        }
        
        let request = RefreshTokenRequest(refreshToken: refreshToken)
        
        do {
            let endpoint = try APIEndpoint.post("/auth/refresh", body: request)
            
            return apiClient.request<AuthTokens>(endpoint)
                .tryMap { (response: APIResponse<AuthTokens>) -> AuthTokens in
                    guard let tokens = response.data else {
                        throw APIError(
                            code: "REFRESH_FAILED",
                            message: "Token refresh failed",
                            details: "No token data received from server",
                            field: nil
                        )
                    }
                    return tokens
                }
                .handleEvents(receiveOutput: { [weak self] tokens in
                    self?.tokenManager.setTokens(tokens)
                })
                .mapError { error -> APIError in
                    error as? APIError ?? APIError(
                        code: "REFRESH_ERROR",
                        message: "Token refresh failed",
                        details: error.localizedDescription,
                        field: nil
                    )
                }
                .catch { [weak self] error -> AnyPublisher<AuthTokens, APIError> in
                    // If refresh fails, clear session
                    self?.clearSession()
                    return Fail<AuthTokens, APIError>(error: error).eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
                
        } catch {
            let apiError = error as? APIError ?? APIError(
                code: "REQUEST_ERROR",
                message: "Failed to create refresh request",
                details: error.localizedDescription,
                field: nil
            )
            return Fail<AuthTokens, APIError>(error: apiError).eraseToAnyPublisher()
        }
    }
    
    func getCurrentUser() -> AnyPublisher<User, APIError> {
        let endpoint = APIEndpoint.get("/auth/me")
        
        return apiClient.request<User>(endpoint)
            .tryMap { (response: APIResponse<User>) -> User in
                guard let user = response.data else {
                    throw APIError(
                        code: "USER_FETCH_FAILED",
                        message: "Failed to get current user",
                        details: "No user data received from server",
                        field: nil
                    )
                }
                return user
            }
            .handleEvents(receiveOutput: { [weak self] user in
                self?._currentUser = user
                self?._authenticationState = .authenticated(user)
            })
            .mapError { error -> APIError in
                error as? APIError ?? APIError(
                    code: "USER_FETCH_ERROR",
                    message: "Failed to fetch user",
                    details: error.localizedDescription,
                    field: nil
                )
            }
            .eraseToAnyPublisher()
    }
    
    func updateUser(_ user: User) -> AnyPublisher<User, APIError> {
        do {
            let endpoint = try APIEndpoint.put("/auth/me", body: user)
            
            return apiClient.request<User>(endpoint)
                .tryMap { (response: APIResponse<User>) -> User in
                    guard let updatedUser = response.data else {
                        throw APIError(
                            code: "USER_UPDATE_FAILED",
                            message: "Failed to update user",
                            details: "No user data received from server",
                            field: nil
                        )
                    }
                    return updatedUser
                }
                .handleEvents(receiveOutput: { [weak self] updatedUser in
                    self?._currentUser = updatedUser
                    self?._authenticationState = .authenticated(updatedUser)
                })
                .mapError { error -> APIError in
                    error as? APIError ?? APIError(
                        code: "USER_UPDATE_ERROR",
                        message: "Failed to update user",
                        details: error.localizedDescription,
                        field: nil
                    )
                }
                .eraseToAnyPublisher()
                
        } catch {
            let apiError = error as? APIError ?? APIError(
                code: "REQUEST_ERROR",
                message: "Failed to create user update request",
                details: error.localizedDescription,
                field: nil
            )
            return Fail<User, APIError>(error: apiError).eraseToAnyPublisher()
        }
    }
    
    func changePassword(currentPassword: String, newPassword: String) -> AnyPublisher<Void, APIError> {
        let request = ChangePasswordRequest(
            currentPassword: currentPassword,
            newPassword: newPassword
        )
        
        do {
            let endpoint = try APIEndpoint.post("/auth/change-password", body: request)
            
            return apiClient.request<SimpleResponse>(endpoint)
                .map { (_: APIResponse<SimpleResponse>) in () }
                .mapError { error -> APIError in
                    error as? APIError ?? APIError(
                        code: "CHANGE_PASSWORD_ERROR",
                        message: "Failed to change password",
                        details: error.localizedDescription,
                        field: nil
                    )
                }
                .eraseToAnyPublisher()
                
        } catch {
            let apiError = error as? APIError ?? APIError(
                code: "REQUEST_ERROR",
                message: "Failed to create password change request",
                details: error.localizedDescription,
                field: nil
            )
            return Fail<Void, APIError>(error: apiError).eraseToAnyPublisher()
        }
    }
    
    func requestPasswordReset(email: String) -> AnyPublisher<Void, APIError> {
        let request = PasswordResetRequest(email: email)
        
        do {
            let endpoint = try APIEndpoint.post("/auth/reset-password", body: request)
            
            return apiClient.request<SimpleResponse>(endpoint)
                .map { (_: APIResponse<SimpleResponse>) in () }
                .mapError { error -> APIError in
                    error as? APIError ?? APIError(
                        code: "PASSWORD_RESET_ERROR",
                        message: "Failed to request password reset",
                        details: error.localizedDescription,
                        field: nil
                    )
                }
                .eraseToAnyPublisher()
                
        } catch {
            let apiError = error as? APIError ?? APIError(
                code: "REQUEST_ERROR",
                message: "Failed to create password reset request",
                details: error.localizedDescription,
                field: nil
            )
            return Fail<Void, APIError>(error: apiError).eraseToAnyPublisher()
        }
    }
    
    // MARK: - Private Methods
    
    private func checkExistingSession() {
        guard !tokenManager.isTokenExpired, tokenManager.accessToken != nil else {
            _authenticationState = .unauthenticated
            return
        }
        
        // Try to get current user to validate session
        getCurrentUser()
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?._authenticationState = .error(error)
                    }
                },
                receiveValue: { [weak self] user in
                    self?._currentUser = user
                    self?._authenticationState = .authenticated(user)
                }
            )
            .store(in: &cancellables)
    }
    
    private func clearSession() {
        tokenManager.clearTokens()
        _currentUser = nil
        _authenticationState = .unauthenticated
    }
}

// MARK: - Additional Request Models
struct ChangePasswordRequest: Codable {
    let currentPassword: String
    let newPassword: String
    
    enum CodingKeys: String, CodingKey {
        case currentPassword = "current_password"
        case newPassword = "new_password"
    }
}

struct PasswordResetRequest: Codable {
    let email: String
}

// MARK: - Mock Authentication Service
class MockAuthenticationService: AuthenticationServiceProtocol {
    @Published private var _authenticationState: AuthState = .unauthenticated
    private var _currentUser: User?
    
    var currentUser: User? {
        return _currentUser
    }
    
    var isAuthenticated: Bool {
        return _authenticationState.isAuthenticated
    }
    
    var authenticationState: AnyPublisher<AuthState, Never> {
        return $_authenticationState.eraseToAnyPublisher()
    }
    
    func login(email: String, password: String) -> AnyPublisher<User, APIError> {
        _authenticationState = .authenticating
        
        return Future<User, APIError> { promise in
            // Simulate network delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                if email == "demo@hingetrade.com" && password == "demo123" {
                    let user = User.sampleData.first!
                    self?._currentUser = user
                    self?._authenticationState = .authenticated(user)
                    promise(.success(user))
                } else {
                    let error = APIError(
                        code: "INVALID_CREDENTIALS",
                        message: "Invalid email or password",
                        details: "Please check your credentials and try again",
                        field: "password"
                    )
                    self?._authenticationState = .error(error)
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func logout() -> AnyPublisher<Void, APIError> {
        return Future<Void, APIError> { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?._currentUser = nil
                self?._authenticationState = .unauthenticated
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func refreshToken() -> AnyPublisher<AuthTokens, APIError> {
        return Just(AuthTokens(
            accessToken: "mock_access_token",
            refreshToken: "mock_refresh_token",
            expiresAt: Date().addingTimeInterval(3600),
            tokenType: "Bearer"
        ))
        .setFailureType(to: APIError.self)
        .eraseToAnyPublisher()
    }
    
    func getCurrentUser() -> AnyPublisher<User, APIError> {
        if let user = _currentUser {
            return Just(user)
                .setFailureType(to: APIError.self)
                .eraseToAnyPublisher()
        } else {
            return Fail(error: APIError.unauthorized)
                .eraseToAnyPublisher()
        }
    }
    
    func updateUser(_ user: User) -> AnyPublisher<User, APIError> {
        return Future<User, APIError> { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?._currentUser = user
                self?._authenticationState = .authenticated(user)
                promise(.success(user))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func changePassword(currentPassword: String, newPassword: String) -> AnyPublisher<Void, APIError> {
        return Future<Void, APIError> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func requestPasswordReset(email: String) -> AnyPublisher<Void, APIError> {
        return Future<Void, APIError> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Authentication Service Extensions
extension AuthenticationService {
    /// Convenience method to check if current user has specific role
    func hasRole(_ role: UserRole) -> Bool {
        return currentUser?.roles.contains(role) ?? false
    }
    
    /// Convenience method to check if current user has specific permission
    func hasPermission(_ permission: UserPermission) -> Bool {
        return currentUser?.hasPermission(permission) ?? false
    }
    
    /// Convenience method to check if current user can trade
    var canTrade: Bool {
        return currentUser?.canTrade ?? false
    }
    
    /// Convenience method to check if current user is creator
    var isCreator: Bool {
        return currentUser?.isCreator ?? false
    }
}