import Foundation
import Combine

// MARK: - Watchlist Service Protocol
protocol WatchlistServiceProtocol {
    // Watchlist CRUD Operations
    func getWatchlists() -> AnyPublisher<[Watchlist], APIError>
    func getWatchlist(id: String) -> AnyPublisher<Watchlist, APIError>
    func createWatchlist(_ request: CreateWatchlistRequest) -> AnyPublisher<Watchlist, APIError>
    func updateWatchlist(id: String, request: UpdateWatchlistRequest) -> AnyPublisher<Watchlist, APIError>
    func deleteWatchlist(id: String) -> AnyPublisher<Void, APIError>
    
    // Symbol Management
    func addSymbolToWatchlist(watchlistId: String, symbol: String) -> AnyPublisher<Watchlist, APIError>
    func removeSymbolFromWatchlist(watchlistId: String, symbol: String) -> AnyPublisher<Watchlist, APIError>
    func reorderSymbolsInWatchlist(watchlistId: String, symbols: [String]) -> AnyPublisher<Watchlist, APIError>
    
    // Default Watchlist Operations
    func getDefaultWatchlist() -> AnyPublisher<Watchlist?, APIError>
    func setDefaultWatchlist(id: String) -> AnyPublisher<Void, APIError>
    
    // Bulk Operations
    func importWatchlist(name: String, symbols: [String], description: String?) -> AnyPublisher<Watchlist, APIError>
    func exportWatchlist(id: String) -> AnyPublisher<WatchlistExport, APIError>
    func duplicateWatchlist(id: String, newName: String) -> AnyPublisher<Watchlist, APIError>
    
    // Performance & Analytics
    func getWatchlistPerformance(id: String, period: String?) -> AnyPublisher<WatchlistPerformanceReport, APIError>
    func getWatchlistAlerts(id: String) -> AnyPublisher<[PriceAlert], APIError>
    
    // Local Storage Support
    func cacheWatchlistsLocally(_ watchlists: [Watchlist])
    func getCachedWatchlists() -> [Watchlist]?
    func clearWatchlistCache()
}

// MARK: - Supporting Models

struct WatchlistExport: Codable {
    let watchlist: Watchlist
    let exportFormat: ExportFormat
    let exportData: String // CSV, JSON, or other format data
    let createdAt: Date
    
    enum ExportFormat: String, CaseIterable, Codable {
        case csv = "csv"
        case json = "json"
        case txt = "txt"
        
        var displayName: String {
            switch self {
            case .csv: return "CSV"
            case .json: return "JSON"
            case .txt: return "Text"
            }
        }
    }
}

struct WatchlistPerformanceReport: Codable {
    let watchlistId: String
    let period: String
    let summary: WatchlistPerformanceSummary
    let symbolPerformances: [SymbolPerformance]
    let generatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case period, summary, generatedAt
        case watchlistId = "watchlist_id"
        case symbolPerformances = "symbol_performances"
    }
}

struct WatchlistPerformanceSummary: Codable {
    let totalReturn: Double
    let averageReturn: Double
    let bestPerformer: String?
    let worstPerformer: String?
    let volatility: Double?
    let winRate: Double
    let totalSymbols: Int
    let activeSymbols: Int
    
    enum CodingKeys: String, CodingKey {
        case totalReturn = "total_return"
        case averageReturn = "average_return"
        case bestPerformer = "best_performer"
        case worstPerformer = "worst_performer"
        case volatility
        case winRate = "win_rate"
        case totalSymbols = "total_symbols"
        case activeSymbols = "active_symbols"
    }
    
    var formattedTotalReturn: String {
        let sign = totalReturn >= 0 ? "+" : ""
        return "\(sign)\(totalReturn.asPercentage(decimals: 2))"
    }
    
    var formattedAverageReturn: String {
        let sign = averageReturn >= 0 ? "+" : ""
        return "\(sign)\(averageReturn.asPercentage(decimals: 2))"
    }
    
    var formattedWinRate: String {
        return winRate.asPercentage(decimals: 1)
    }
    
    var formattedVolatility: String {
        guard let volatility = volatility else { return "--" }
        return volatility.asPercentage(decimals: 2)
    }
}

struct SymbolPerformance: Codable, Identifiable {
    let symbol: String
    let currentPrice: Double
    let priceChange: Double
    let percentChange: Double
    let volume: Int?
    let marketCap: Double?
    let performance: WatchlistPerformanceRating
    
    var id: String { symbol }
    
    enum CodingKeys: String, CodingKey {
        case symbol, volume, performance
        case currentPrice = "current_price"
        case priceChange = "price_change"
        case percentChange = "percent_change"
        case marketCap = "market_cap"
    }
    
    var formattedPrice: String { currentPrice.asCurrency() }
    var formattedChange: String {
        let sign = priceChange >= 0 ? "+" : ""
        return "\(sign)\(priceChange.asCurrency())"
    }
    var formattedPercentChange: String {
        let sign = percentChange >= 0 ? "+" : ""
        return "\(sign)\(percentChange.asPercentage(decimals: 2))"
    }
    var formattedVolume: String { volume?.asAbbreviated() ?? "--" }
    var formattedMarketCap: String { marketCap?.asAbbreviated() ?? "--" }
}

enum WatchlistPerformanceRating: String, CaseIterable, Codable {
    case excellent = "excellent"
    case good = "good"
    case neutral = "neutral"
    case poor = "poor"
    case terrible = "terrible"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var color: PerformanceColor {
        switch self {
        case .excellent: return .darkGreen
        case .good: return .green
        case .neutral: return .gray
        case .poor: return .red
        case .terrible: return .darkRed
        }
    }
}

enum PerformanceColor {
    case darkGreen
    case green
    case gray
    case red
    case darkRed
}

// MARK: - Watchlist Service Implementation
class DefaultWatchlistServiceImpl: WatchlistServiceProtocol {
    private let apiClient: APIClientProtocol
    private let cacheKey = "cached_watchlists"
    private var cancellables = Set<AnyCancellable>()
    
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    // MARK: - Watchlist CRUD Operations
    
    func getWatchlists() -> AnyPublisher<[Watchlist], APIError> {
        let endpoint = APIEndpoint.get("/watchlists")
        
        return apiClient.request(endpoint)
            .map { (response: APIResponse<[Watchlist]>) in
                let watchlists = response.data ?? []
                return watchlists
            }
            .handleEvents(receiveOutput: { [weak self] watchlists in
                self?.cacheWatchlistsLocally(watchlists)
            })
            .eraseToAnyPublisher()
    }
    
    func getWatchlist(id: String) -> AnyPublisher<Watchlist, APIError> {
        let endpoint = APIEndpoint.get("/watchlists/\(id)")
        
        return apiClient.request<Watchlist>(endpoint)
            .tryMap { (response: APIResponse<Watchlist>) in
                guard let watchlist = response.data else {
                    throw APIError(
                        code: "WATCHLIST_NOT_FOUND",
                        message: "Watchlist not found",
                        details: "The requested watchlist was not found",
                        field: nil
                    )
                }
                return watchlist
            }
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                } else {
                    return APIError(code: "UNKNOWN_ERROR", message: error.localizedDescription, details: nil, field: nil)
                }
            }
            .eraseToAnyPublisher()
    }
    
    func createWatchlist(_ request: CreateWatchlistRequest) -> AnyPublisher<Watchlist, APIError> {
        do {
            let endpoint = try APIEndpoint.post("/watchlists", body: request)
            
            return apiClient.request<Watchlist>(endpoint)
                .tryMap { (response: APIResponse<Watchlist>) in
                    guard let watchlist = response.data else {
                        throw APIError(
                            code: "WATCHLIST_CREATION_FAILED",
                            message: "Failed to create watchlist",
                            details: "No watchlist data received from server",
                            field: nil
                        )
                    }
                    return watchlist
                }
                .mapError { error in
                    if let apiError = error as? APIError {
                        return apiError
                    } else {
                        return APIError(code: "UNKNOWN_ERROR", message: error.localizedDescription, details: nil, field: nil)
                    }
                }
                .mapError { error -> APIError in
                    return error as? APIError ?? APIError(
                        code: "REQUEST_ERROR",
                        message: "Request failed",
                        details: error.localizedDescription,
                        field: nil
                    )
                }
                .eraseToAnyPublisher()
                
        } catch {
            let apiError = error as? APIError ?? APIError(
                code: "REQUEST_ERROR",
                message: "Failed to create watchlist request",
                details: error.localizedDescription,
                field: nil
            )
            return Fail<Watchlist, APIError>(error: apiError).eraseToAnyPublisher()
        }
    }
    
    func updateWatchlist(id: String, request: UpdateWatchlistRequest) -> AnyPublisher<Watchlist, APIError> {
        do {
            let endpoint = try APIEndpoint.put("/watchlists/\(id)", body: request)
            
            return apiClient.request(endpoint)
                .tryMap { (response: APIResponse<Watchlist>) in
                    guard let watchlist = response.data else {
                        throw APIError(
                            code: "WATCHLIST_UPDATE_FAILED",
                            message: "Failed to update watchlist",
                            details: "No watchlist data received from server",
                            field: nil
                        )
                    }
                    return watchlist
                }
                .mapError { error -> APIError in
                    return error as? APIError ?? APIError(
                        code: "REQUEST_ERROR",
                        message: "Request failed",
                        details: error.localizedDescription,
                        field: nil
                    )
                }
                .eraseToAnyPublisher()
                
        } catch {
            let apiError = error as? APIError ?? APIError(
                code: "REQUEST_ERROR",
                message: "Failed to create update request",
                details: error.localizedDescription,
                field: nil
            )
            return Fail<Watchlist, APIError>(error: apiError).eraseToAnyPublisher()
        }
    }
    
    func deleteWatchlist(id: String) -> AnyPublisher<Void, APIError> {
        let endpoint = APIEndpoint.delete("/watchlists/\(id)")
        
        return apiClient.request(endpoint)
            .map { (_: APIResponse<String>) -> String in "" }
            .map { _ in () }
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                } else {
                    return APIError(code: "UNKNOWN_ERROR", message: error.localizedDescription, details: nil, field: nil)
                }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Symbol Management
    
    func addSymbolToWatchlist(watchlistId: String, symbol: String) -> AnyPublisher<Watchlist, APIError> {
        let request = AddSymbolToWatchlistRequest(symbol: symbol.uppercased())
        
        do {
            let endpoint = try APIEndpoint.post("/watchlists/\(watchlistId)/symbols", body: request)
            
            return apiClient.request(endpoint)
                .tryMap { (response: APIResponse<Watchlist>) in
                    guard let watchlist = response.data else {
                        throw APIError(
                            code: "SYMBOL_ADD_FAILED",
                            message: "Failed to add symbol to watchlist",
                            details: "No watchlist data received from server",
                            field: nil
                        )
                    }
                    return watchlist
                }
                .mapError { error -> APIError in
                    return error as? APIError ?? APIError(
                        code: "REQUEST_ERROR",
                        message: "Request failed",
                        details: error.localizedDescription,
                        field: nil
                    )
                }
                .eraseToAnyPublisher()
                
        } catch {
            let apiError = error as? APIError ?? APIError(
                code: "REQUEST_ERROR",
                message: "Failed to create add symbol request",
                details: error.localizedDescription,
                field: nil
            )
            return Fail<Watchlist, APIError>(error: apiError).eraseToAnyPublisher()
        }
    }
    
    func removeSymbolFromWatchlist(watchlistId: String, symbol: String) -> AnyPublisher<Watchlist, APIError> {
        let endpoint = APIEndpoint.delete("/watchlists/\(watchlistId)/symbols/\(symbol.uppercased())")
        
        return apiClient.request(endpoint)
            .tryMap { (response: APIResponse<Watchlist>) in
                guard let watchlist = response.data else {
                    throw APIError(
                        code: "SYMBOL_REMOVE_FAILED",
                        message: "Failed to remove symbol from watchlist",
                        details: "No watchlist data received from server",
                        field: nil
                    )
                }
                return watchlist
            }
            .mapError { error -> APIError in
                return error as? APIError ?? APIError(
                    code: "REQUEST_ERROR",
                    message: "Request failed",
                    details: error.localizedDescription,
                    field: nil
                )
            }
            .eraseToAnyPublisher()
    }
    
    func reorderSymbolsInWatchlist(watchlistId: String, symbols: [String]) -> AnyPublisher<Watchlist, APIError> {
        let request = ReorderSymbolsRequest(symbols: symbols.map { $0.uppercased() })
        
        do {
            let endpoint = try APIEndpoint.put("/watchlists/\(watchlistId)/reorder", body: request)
            
            return apiClient.request(endpoint)
                .tryMap { (response: APIResponse<Watchlist>) in
                    guard let watchlist = response.data else {
                        throw APIError(
                            code: "REORDER_FAILED",
                            message: "Failed to reorder symbols",
                            details: "No watchlist data received from server",
                            field: nil
                        )
                    }
                    return watchlist
                }
                .mapError { error -> APIError in
                    return error as? APIError ?? APIError(
                        code: "REQUEST_ERROR",
                        message: "Request failed",
                        details: error.localizedDescription,
                        field: nil
                    )
                }
                .eraseToAnyPublisher()
                
        } catch {
            let apiError = error as? APIError ?? APIError(
                code: "REQUEST_ERROR",
                message: "Failed to create reorder request",
                details: error.localizedDescription,
                field: nil
            )
            return Fail<Watchlist, APIError>(error: apiError).eraseToAnyPublisher()
        }
    }
    
    // MARK: - Default Watchlist Operations
    
    func getDefaultWatchlist() -> AnyPublisher<Watchlist?, APIError> {
        return getWatchlists()
            .map { (watchlists: [Watchlist]) -> Watchlist? in
                return watchlists.first { $0.isDefaultWatchlist }
            }
            .eraseToAnyPublisher()
    }
    
    func setDefaultWatchlist(id: String) -> AnyPublisher<Void, APIError> {
        let endpoint = APIEndpoint(path: "/watchlists/\(id)/set-default", method: .POST)
        
        return apiClient.request<SimpleResponse>(endpoint)
            .map { (_: APIResponse<SimpleResponse>) in () }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Bulk Operations
    
    func importWatchlist(name: String, symbols: [String], description: String?) -> AnyPublisher<Watchlist, APIError> {
        let request = CreateWatchlistRequest(name: name, symbols: symbols.map { $0.uppercased() })
        return createWatchlist(request)
    }
    
    func exportWatchlist(id: String) -> AnyPublisher<WatchlistExport, APIError> {
        return getWatchlist(id: id)
            .map { watchlist in
                let csvData = self.generateCSVExport(watchlist: watchlist)
                return WatchlistExport(
                    watchlist: watchlist,
                    exportFormat: .csv,
                    exportData: csvData,
                    createdAt: Date()
                )
            }
            .eraseToAnyPublisher()
    }
    
    func duplicateWatchlist(id: String, newName: String) -> AnyPublisher<Watchlist, APIError> {
        return getWatchlist(id: id)
            .flatMap { [weak self] originalWatchlist -> AnyPublisher<Watchlist, APIError> in
                guard let self = self else {
                    return Fail(error: APIError(
                        code: "SERVICE_UNAVAILABLE",
                        message: "Service unavailable",
                        details: nil,
                        field: nil
                    )).eraseToAnyPublisher()
                }
                
                let request = CreateWatchlistRequest(
                    name: newName,
                    symbols: originalWatchlist.symbols
                )
                return self.createWatchlist(request)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Performance & Analytics
    
    func getWatchlistPerformance(id: String, period: String?) -> AnyPublisher<WatchlistPerformanceReport, APIError> {
        var queryItems: [URLQueryItem] = []
        if let period = period {
            queryItems.append(URLQueryItem(name: "period", value: period))
        }
        
        let endpoint = APIEndpoint.get("/watchlists/\(id)/performance", 
                                     queryItems: queryItems.isEmpty ? nil : queryItems)
        
        return apiClient.request(endpoint)
            .tryMap { (response: APIResponse<WatchlistPerformanceReport>) in
                guard let report = response.data else {
                    throw APIError(
                        code: "PERFORMANCE_FETCH_FAILED",
                        message: "Failed to fetch watchlist performance",
                        details: "No performance data received from server",
                        field: nil
                    )
                }
                return report
            }
            .mapError { error -> APIError in
                return error as? APIError ?? APIError(
                    code: "REQUEST_ERROR",
                    message: "Request failed",
                    details: error.localizedDescription,
                    field: nil
                )
            }
            .eraseToAnyPublisher()
    }
    
    func getWatchlistAlerts(id: String) -> AnyPublisher<[PriceAlert], APIError> {
        let endpoint = APIEndpoint.get("/watchlists/\(id)/alerts")
        
        return apiClient.request(endpoint)
            .tryMap { (response: APIResponse<[PriceAlert]>) in
                return response.data ?? []
            }
            .mapError { error -> APIError in
                return error as? APIError ?? APIError(
                    code: "REQUEST_ERROR",
                    message: "Request failed",
                    details: error.localizedDescription,
                    field: nil
                )
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Local Storage Support
    
    func cacheWatchlistsLocally(_ watchlists: [Watchlist]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(watchlists)
            UserDefaults.standard.set(data, forKey: cacheKey)
        } catch {
            print("Failed to cache watchlists: \(error)")
        }
    }
    
    func getCachedWatchlists() -> [Watchlist]? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return nil }
        
        do {
            let decoder = JSONDecoder()
            // Configure date decoding
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            
            return try decoder.decode([Watchlist].self, from: data)
        } catch {
            print("Failed to decode cached watchlists: \(error)")
            return nil
        }
    }
    
    func clearWatchlistCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
    }
    
    // MARK: - Private Helper Methods
    
    private func generateCSVExport(watchlist: Watchlist) -> String {
        var csv = "Symbol,Name,Position\n"
        for (index, symbol) in watchlist.items.enumerated() {
            csv += "\(symbol),\(symbol) Inc.,\(index + 1)\n"
        }
        return csv
    }
}

// MARK: - Additional Request Models
struct ReorderSymbolsRequest: Codable {
    let symbols: [String]
}

// MARK: - Mock Watchlist Service
class MockWatchlistService: WatchlistServiceProtocol {
    private var mockWatchlists = Watchlist.sampleData
    
    func getWatchlists() -> AnyPublisher<[Watchlist], APIError> {
        return Future<[Watchlist], APIError> { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                promise(.success(self?.mockWatchlists ?? []))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getWatchlist(id: String) -> AnyPublisher<Watchlist, APIError> {
        return Future<Watchlist, APIError> { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if let watchlist = self?.mockWatchlists.first(where: { $0.id == id }) {
                    promise(.success(watchlist))
                } else {
                    promise(.failure(APIError(
                        code: "WATCHLIST_NOT_FOUND",
                        message: "Watchlist not found",
                        details: nil,
                        field: nil
                    )))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func createWatchlist(_ request: CreateWatchlistRequest) -> AnyPublisher<Watchlist, APIError> {
        return Future<Watchlist, APIError> { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let newWatchlist = Watchlist(
                    id: UUID().uuidString,
                    accountId: "account-001",
                    name: request.name,
                    items: request.symbols ?? [],
                    createdAt: Date(),
                    updatedAt: Date(),
                    description: nil,
                    isDefault: false,
                    sortOrder: nil,
                    color: WatchlistColor.blue.hexString,
                    isPublic: false,
                    isFavorite: false,
                    dailyPerformance: nil,
                    gainers: 0,
                    losers: 0,
                    lastUpdated: Date()
                )
                
                self?.mockWatchlists.append(newWatchlist)
                promise(.success(newWatchlist))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func updateWatchlist(id: String, request: UpdateWatchlistRequest) -> AnyPublisher<Watchlist, APIError> {
        return Future<Watchlist, APIError> { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                guard let index = self?.mockWatchlists.firstIndex(where: { $0.id == id }) else {
                    promise(.failure(APIError(
                        code: "WATCHLIST_NOT_FOUND",
                        message: "Watchlist not found",
                        details: nil,
                        field: nil
                    )))
                    return
                }
                
                let existingWatchlist = self!.mockWatchlists[index]
                let updatedWatchlist = existingWatchlist.updating(
                    name: request.name,
                    description: nil,
                    color: nil
                )
                
                self?.mockWatchlists[index] = updatedWatchlist
                promise(.success(updatedWatchlist))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteWatchlist(id: String) -> AnyPublisher<Void, APIError> {
        return Future<Void, APIError> { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self?.mockWatchlists.removeAll { $0.id == id }
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func addSymbolToWatchlist(watchlistId: String, symbol: String) -> AnyPublisher<Watchlist, APIError> {
        return Future<Watchlist, APIError> { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                guard let index = self?.mockWatchlists.firstIndex(where: { $0.id == watchlistId }) else {
                    promise(.failure(APIError(
                        code: "WATCHLIST_NOT_FOUND",
                        message: "Watchlist not found",
                        details: nil,
                        field: nil
                    )))
                    return
                }
                
                let updatedWatchlist = self!.mockWatchlists[index].addingSymbol(symbol)
                self?.mockWatchlists[index] = updatedWatchlist
                promise(.success(updatedWatchlist))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func removeSymbolFromWatchlist(watchlistId: String, symbol: String) -> AnyPublisher<Watchlist, APIError> {
        return Future<Watchlist, APIError> { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                guard let index = self?.mockWatchlists.firstIndex(where: { $0.id == watchlistId }) else {
                    promise(.failure(APIError(
                        code: "WATCHLIST_NOT_FOUND",
                        message: "Watchlist not found",
                        details: nil,
                        field: nil
                    )))
                    return
                }
                
                let updatedWatchlist = self!.mockWatchlists[index].removingSymbol(symbol)
                self?.mockWatchlists[index] = updatedWatchlist
                promise(.success(updatedWatchlist))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func reorderSymbolsInWatchlist(watchlistId: String, symbols: [String]) -> AnyPublisher<Watchlist, APIError> {
        return Future<Watchlist, APIError> { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                guard let index = self?.mockWatchlists.firstIndex(where: { $0.id == watchlistId }) else {
                    promise(.failure(APIError(
                        code: "WATCHLIST_NOT_FOUND",
                        message: "Watchlist not found",
                        details: nil,
                        field: nil
                    )))
                    return
                }
                
                let updatedWatchlist = self!.mockWatchlists[index].reorderingSymbols(symbols)
                self?.mockWatchlists[index] = updatedWatchlist
                promise(.success(updatedWatchlist))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getDefaultWatchlist() -> AnyPublisher<Watchlist?, APIError> {
        return getWatchlists()
            .map { watchlists in
                return watchlists.first { $0.isDefaultWatchlist }
            }
            .eraseToAnyPublisher()
    }
    
    func setDefaultWatchlist(id: String) -> AnyPublisher<Void, APIError> {
        return Just(())
            .setFailureType(to: APIError.self)
            .eraseToAnyPublisher()
    }
    
    func importWatchlist(name: String, symbols: [String], description: String?) -> AnyPublisher<Watchlist, APIError> {
        let request = CreateWatchlistRequest(name: name, symbols: symbols)
        return createWatchlist(request)
    }
    
    func exportWatchlist(id: String) -> AnyPublisher<WatchlistExport, APIError> {
        return getWatchlist(id: id)
            .map { watchlist in
                let csvData = watchlist.items.joined(separator: "\n")
                return WatchlistExport(
                    watchlist: watchlist,
                    exportFormat: .csv,
                    exportData: csvData,
                    createdAt: Date()
                )
            }
            .eraseToAnyPublisher()
    }
    
    func duplicateWatchlist(id: String, newName: String) -> AnyPublisher<Watchlist, APIError> {
        return getWatchlist(id: id)
            .flatMap { [weak self] originalWatchlist -> AnyPublisher<Watchlist, APIError> in
                let request = CreateWatchlistRequest(name: newName, symbols: originalWatchlist.items)
                return self?.createWatchlist(request) ?? Fail(error: APIError.networkError).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func getWatchlistPerformance(id: String, period: String?) -> AnyPublisher<WatchlistPerformanceReport, APIError> {
        return Future<WatchlistPerformanceReport, APIError> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let mockReport = MockWatchlistService.generateMockPerformanceReport(watchlistId: id, period: period)
                promise(.success(mockReport))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getWatchlistAlerts(id: String) -> AnyPublisher<[PriceAlert], APIError> {
        return Just([])
            .setFailureType(to: APIError.self)
            .eraseToAnyPublisher()
    }
    
    func cacheWatchlistsLocally(_ watchlists: [Watchlist]) {
        // Mock implementation - could store in memory or UserDefaults
    }
    
    func getCachedWatchlists() -> [Watchlist]? {
        return mockWatchlists
    }
    
    func clearWatchlistCache() {
        // Mock implementation
    }
    
    // MARK: - Helper Methods
    
    private static func generateMockPerformanceReport(watchlistId: String, period: String?) -> WatchlistPerformanceReport {
        let symbols = ["AAPL", "TSLA", "GOOGL", "MSFT", "AMZN"]
        let symbolPerformances = symbols.map { symbol in
            SymbolPerformance(
                symbol: symbol,
                currentPrice: Double.random(in: 50...300),
                priceChange: Double.random(in: -10...10),
                percentChange: Double.random(in: -0.1...0.1),
                volume: Int.random(in: 1000000...50000000),
                marketCap: Double.random(in: 10000000000...2000000000000),
                performance: WatchlistPerformanceRating.allCases.randomElement()!
            )
        }
        
        let summary = WatchlistPerformanceSummary(
            totalReturn: 0.0845,
            averageReturn: 0.0169,
            bestPerformer: "TSLA",
            worstPerformer: "GOOGL",
            volatility: 0.23,
            winRate: 0.6,
            totalSymbols: symbols.count,
            activeSymbols: symbols.count
        )
        
        return WatchlistPerformanceReport(
            watchlistId: watchlistId,
            period: period ?? "1M",
            summary: summary,
            symbolPerformances: symbolPerformances,
            generatedAt: Date()
        )
    }
}

