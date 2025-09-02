import Foundation
import Combine

// MARK: - Market Data Service Protocol
protocol MarketDataServiceProtocol {
    // Quote Operations
    func getQuote(symbol: String) -> AnyPublisher<Quote, APIError>
    func getQuotes(symbols: [String]) -> AnyPublisher<[String: Quote], APIError>
    func subscribeToQuotes(symbols: [String]) -> AnyPublisher<Quote, APIError>
    
    // Historical Data Operations
    func getBars(symbols: [String], timeframe: String, start: Date?, end: Date?, limit: Int?) -> AnyPublisher<[String: [Bar]], APIError>
    func getLatestBar(symbol: String) -> AnyPublisher<Bar?, APIError>
    
    // Market Hours Operations
    func getMarketHours(date: Date?) -> AnyPublisher<MarketHours, APIError>
    func isMarketOpen() -> AnyPublisher<Bool, APIError>
    func getMarketStatus() -> AnyPublisher<MarketStatus, APIError>
    
    // Asset Search Operations
    func searchAssets(query: String, limit: Int?, assetClass: AssetClass?) -> AnyPublisher<[Asset], APIError>
    func getAsset(symbol: String) -> AnyPublisher<Asset, APIError>
    func getPopularAssets(limit: Int?) -> AnyPublisher<[Asset], APIError>
    
    // Market News & Data
    func getTopMovers(direction: MoverDirection?, limit: Int?) -> AnyPublisher<[TopMover], APIError>
    func getMarketSummary() -> AnyPublisher<MarketSummary, APIError>
}

// MARK: - Supporting Models

enum MoverDirection: String, CaseIterable {
    case gainers = "gainers"
    case losers = "losers"
    case mostActive = "most_active"
    
    var displayName: String {
        switch self {
        case .gainers: return "Top Gainers"
        case .losers: return "Top Losers"
        case .mostActive: return "Most Active"
        }
    }
}

struct TopMover: Codable, Identifiable {
    let symbol: String
    let name: String
    let price: Double
    let change: Double
    let changePercent: Double
    let volume: Int
    let marketCap: Double?
    
    var id: String { symbol }
    
    enum CodingKeys: String, CodingKey {
        case symbol, name, price, change, volume
        case changePercent = "change_percent"
        case marketCap = "market_cap"
    }
    
    var formattedPrice: String { price.asCurrency() }
    var formattedChange: String {
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(change.asCurrency())"
    }
    var formattedChangePercent: String {
        let sign = changePercent >= 0 ? "+" : ""
        return "\(sign)\(changePercent.asPercentage(decimals: 2))"
    }
    var formattedVolume: String { volume.asAbbreviated() }
    var formattedMarketCap: String { marketCap?.asAbbreviated() ?? "--" }
}

struct MarketSummary: Codable {
    let indices: [IndexSummary]
    let sectors: [SectorSummary]
    let commodities: [CommoditySummary]?
    let currencies: [CurrencySummary]?
    let marketStatus: MarketStatus
    let lastUpdated: Date
    
    enum CodingKeys: String, CodingKey {
        case indices, sectors, commodities, currencies, lastUpdated
        case marketStatus = "market_status"
    }
}

struct IndexSummary: Codable, Identifiable {
    let symbol: String
    let name: String
    let value: Double
    let change: Double
    let changePercent: Double
    
    var id: String { symbol }
    
    enum CodingKeys: String, CodingKey {
        case symbol, name, value, change
        case changePercent = "change_percent"
    }
    
    var formattedValue: String { value.asFormatted(decimals: 2) }
    var formattedChange: String {
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(change.asFormatted(decimals: 2))"
    }
    var formattedChangePercent: String {
        let sign = changePercent >= 0 ? "+" : ""
        return "\(sign)\(changePercent.asPercentage(decimals: 2))"
    }
}

struct SectorSummary: Codable, Identifiable {
    let name: String
    let changePercent: Double
    let topSymbol: String?
    let topSymbolChange: Double?
    
    var id: String { name }
    
    enum CodingKeys: String, CodingKey {
        case name
        case changePercent = "change_percent"
        case topSymbol = "top_symbol"
        case topSymbolChange = "top_symbol_change"
    }
    
    var formattedChangePercent: String {
        let sign = changePercent >= 0 ? "+" : ""
        return "\(sign)\(changePercent.asPercentage(decimals: 2))"
    }
}

struct CommoditySummary: Codable, Identifiable {
    let symbol: String
    let name: String
    let price: Double
    let change: Double
    let changePercent: Double
    
    var id: String { symbol }
    
    enum CodingKeys: String, CodingKey {
        case symbol, name, price, change
        case changePercent = "change_percent"
    }
    
    var formattedPrice: String { price.asCurrency() }
    var formattedChange: String {
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(change.asCurrency())"
    }
    var formattedChangePercent: String {
        let sign = changePercent >= 0 ? "+" : ""
        return "\(sign)\(changePercent.asPercentage(decimals: 2))"
    }
}

struct CurrencySummary: Codable, Identifiable {
    let pair: String
    let rate: Double
    let change: Double
    let changePercent: Double
    
    var id: String { pair }
    
    enum CodingKeys: String, CodingKey {
        case pair, rate, change
        case changePercent = "change_percent"
    }
    
    var formattedRate: String { rate.asFormatted(decimals: 4) }
    var formattedChange: String {
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(change.asFormatted(decimals: 4))"
    }
    var formattedChangePercent: String {
        let sign = changePercent >= 0 ? "+" : ""
        return "\(sign)\(changePercent.asPercentage(decimals: 2))"
    }
}

// MARK: - Market Data Service Implementation
class MarketDataService: MarketDataServiceProtocol {
    private let apiClient: APIClientProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    // MARK: - Quote Operations
    
    func getQuote(symbol: String) -> AnyPublisher<Quote, APIError> {
        let queryItems = [URLQueryItem(name: "symbols", value: symbol)]
        let endpoint = APIEndpoint.get("/market-data/quotes", queryItems: queryItems)
        
        return apiClient.request<QuoteResponse>(endpoint)
            .map { response in
                guard let quoteResponse = response.data,
                      let quote = quoteResponse.quotes[symbol] else {
                    throw APIError(
                        code: "QUOTE_NOT_FOUND",
                        message: "Quote not found for symbol \(symbol)",
                        details: "The requested symbol may not be valid or supported",
                        field: "symbol"
                    )
                }
                return quote
            }
            .eraseToAnyPublisher()
    }
    
    func getQuotes(symbols: [String]) -> AnyPublisher<[String: Quote], APIError> {
        let symbolsString = symbols.joined(separator: ",")
        let queryItems = [URLQueryItem(name: "symbols", value: symbolsString)]
        let endpoint = APIEndpoint.get("/market-data/quotes", queryItems: queryItems)
        
        return apiClient.request<QuoteResponse>(endpoint)
            .map { response in
                guard let quoteResponse = response.data else {
                    throw APIError(
                        code: "QUOTES_FETCH_FAILED",
                        message: "Failed to fetch quotes",
                        details: "No quote data received from server",
                        field: nil
                    )
                }
                return quoteResponse.quotes
            }
            .eraseToAnyPublisher()
    }
    
    func subscribeToQuotes(symbols: [String]) -> AnyPublisher<Quote, APIError> {
        // This would typically use WebSocket connection
        // For now, we'll simulate with periodic updates
        return Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .flatMap { _ in
                self.getQuotes(symbols: symbols)
            }
            .compactMap { quotes in
                quotes.values.first // Return first quote for demo
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Historical Data Operations
    
    func getBars(symbols: [String], timeframe: String, start: Date?, end: Date?, limit: Int?) -> AnyPublisher<[String: [Bar]], APIError> {
        var queryItems = [
            URLQueryItem(name: "symbols", value: symbols.joined(separator: ",")),
            URLQueryItem(name: "timeframe", value: timeframe)
        ]
        
        if let start = start {
            let formatter = ISO8601DateFormatter()
            queryItems.append(URLQueryItem(name: "start", value: formatter.string(from: start)))
        }
        
        if let end = end {
            let formatter = ISO8601DateFormatter()
            queryItems.append(URLQueryItem(name: "end", value: formatter.string(from: end)))
        }
        
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        
        let endpoint = APIEndpoint.get("/market-data/bars", queryItems: queryItems)
        
        return apiClient.request<BarsResponse>(endpoint)
            .map { response in
                guard let barsResponse = response.data else {
                    throw APIError(
                        code: "BARS_FETCH_FAILED",
                        message: "Failed to fetch historical data",
                        details: "No bar data received from server",
                        field: nil
                    )
                }
                return barsResponse.bars
            }
            .eraseToAnyPublisher()
    }
    
    func getLatestBar(symbol: String) -> AnyPublisher<Bar?, APIError> {
        return getBars(symbols: [symbol], timeframe: "1Day", start: nil, end: nil, limit: 1)
            .map { barsDict in
                return barsDict[symbol]?.first
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Market Hours Operations
    
    func getMarketHours(date: Date?) -> AnyPublisher<MarketHours, APIError> {
        var queryItems: [URLQueryItem] = []
        
        if let date = date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            queryItems.append(URLQueryItem(name: "date", value: formatter.string(from: date)))
        }
        
        let endpoint = APIEndpoint.get("/market-data/hours", 
                                     queryItems: queryItems.isEmpty ? nil : queryItems)
        
        return apiClient.request<MarketHours>(endpoint)
            .map { response in
                guard let marketHours = response.data else {
                    throw APIError(
                        code: "MARKET_HOURS_FETCH_FAILED",
                        message: "Failed to fetch market hours",
                        details: "No market hours data received from server",
                        field: nil
                    )
                }
                return marketHours
            }
            .eraseToAnyPublisher()
    }
    
    func isMarketOpen() -> AnyPublisher<Bool, APIError> {
        return getMarketHours(date: Date())
            .map { marketHours in
                return marketHours.currentStatus == .open
            }
            .eraseToAnyPublisher()
    }
    
    func getMarketStatus() -> AnyPublisher<MarketStatus, APIError> {
        return getMarketHours(date: Date())
            .map { marketHours in
                return marketHours.currentStatus
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Asset Search Operations
    
    func searchAssets(query: String, limit: Int?, assetClass: AssetClass?) -> AnyPublisher<[Asset], APIError> {
        var queryItems = [URLQueryItem(name: "query", value: query)]
        
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        
        if let assetClass = assetClass {
            queryItems.append(URLQueryItem(name: "asset_class", value: assetClass.rawValue))
        }
        
        let endpoint = APIEndpoint.get("/market-data/search", queryItems: queryItems)
        
        return apiClient.request<AssetSearchResponse>(endpoint)
            .map { response in
                guard let searchResponse = response.data else {
                    throw APIError(
                        code: "SEARCH_FAILED",
                        message: "Asset search failed",
                        details: "No search results received from server",
                        field: nil
                    )
                }
                return searchResponse.assets
            }
            .eraseToAnyPublisher()
    }
    
    func getAsset(symbol: String) -> AnyPublisher<Asset, APIError> {
        let endpoint = APIEndpoint.get("/market-data/assets/\(symbol)")
        
        return apiClient.request<Asset>(endpoint)
            .map { response in
                guard let asset = response.data else {
                    throw APIError(
                        code: "ASSET_NOT_FOUND",
                        message: "Asset not found",
                        details: "The requested symbol was not found",
                        field: "symbol"
                    )
                }
                return asset
            }
            .eraseToAnyPublisher()
    }
    
    func getPopularAssets(limit: Int?) -> AnyPublisher<[Asset], APIError> {
        var queryItems: [URLQueryItem] = []
        
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        
        let endpoint = APIEndpoint.get("/market-data/popular", 
                                     queryItems: queryItems.isEmpty ? nil : queryItems)
        
        return apiClient.request<[Asset]>(endpoint)
            .map { response in
                return response.data ?? []
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Market News & Data
    
    func getTopMovers(direction: MoverDirection?, limit: Int?) -> AnyPublisher<[TopMover], APIError> {
        var queryItems: [URLQueryItem] = []
        
        if let direction = direction {
            queryItems.append(URLQueryItem(name: "direction", value: direction.rawValue))
        }
        
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        
        let endpoint = APIEndpoint.get("/market-data/movers", 
                                     queryItems: queryItems.isEmpty ? nil : queryItems)
        
        return apiClient.request<[TopMover]>(endpoint)
            .map { response in
                return response.data ?? []
            }
            .eraseToAnyPublisher()
    }
    
    func getMarketSummary() -> AnyPublisher<MarketSummary, APIError> {
        let endpoint = APIEndpoint.get("/market-data/summary")
        
        return apiClient.request<MarketSummary>(endpoint)
            .map { response in
                guard let summary = response.data else {
                    throw APIError(
                        code: "MARKET_SUMMARY_FETCH_FAILED",
                        message: "Failed to fetch market summary",
                        details: "No market summary data received from server",
                        field: nil
                    )
                }
                return summary
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Mock Market Data Service
class MockMarketDataService: MarketDataServiceProtocol {
    private var mockQuotes = Dictionary(uniqueKeysWithValues: Quote.sampleData.map { ($0.symbol, $0) })
    private let mockAssets = Asset.sampleData
    
    func getQuote(symbol: String) -> AnyPublisher<Quote, APIError> {
        return Future<Quote, APIError> { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if let quote = self?.mockQuotes[symbol] {
                    promise(.success(quote))
                } else {
                    promise(.failure(APIError(
                        code: "QUOTE_NOT_FOUND",
                        message: "Quote not found for symbol \(symbol)",
                        details: nil,
                        field: "symbol"
                    )))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getQuotes(symbols: [String]) -> AnyPublisher<[String: Quote], APIError> {
        return Future<[String: Quote], APIError> { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                var quotes: [String: Quote] = [:]
                symbols.forEach { symbol in
                    if let quote = self?.mockQuotes[symbol] {
                        quotes[symbol] = quote
                    }
                }
                promise(.success(quotes))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func subscribeToQuotes(symbols: [String]) -> AnyPublisher<Quote, APIError> {
        return Timer.publish(every: 2.0, on: .main, in: .common)
            .autoconnect()
            .compactMap { [weak self] _ in
                // Return random quote updates
                return symbols.compactMap { symbol in
                    self?.mockQuotes[symbol]
                }.randomElement()
            }
            .setFailureType(to: APIError.self)
            .eraseToAnyPublisher()
    }
    
    func getBars(symbols: [String], timeframe: String, start: Date?, end: Date?, limit: Int?) -> AnyPublisher<[String: [Bar]], APIError> {
        return Future<[String: [Bar]], APIError> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                var barsDict: [String: [Bar]] = [:]
                
                symbols.forEach { symbol in
                    let bars = Bar.generateSampleIntradayData(symbol: symbol, count: limit ?? 100)
                    barsDict[symbol] = bars
                }
                
                promise(.success(barsDict))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getLatestBar(symbol: String) -> AnyPublisher<Bar?, APIError> {
        return Future<Bar?, APIError> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                let bar = Bar.generateSampleIntradayData(symbol: symbol, count: 1).first
                promise(.success(bar))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getMarketHours(date: Date?) -> AnyPublisher<MarketHours, APIError> {
        return Future<MarketHours, APIError> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let marketHours = MarketHours.sampleData.first!
                promise(.success(marketHours))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func isMarketOpen() -> AnyPublisher<Bool, APIError> {
        return Just(true)
            .setFailureType(to: APIError.self)
            .eraseToAnyPublisher()
    }
    
    func getMarketStatus() -> AnyPublisher<MarketStatus, APIError> {
        return Just(MarketStatus.open)
            .setFailureType(to: APIError.self)
            .eraseToAnyPublisher()
    }
    
    func searchAssets(query: String, limit: Int?, assetClass: AssetClass?) -> AnyPublisher<[Asset], APIError> {
        return Future<[Asset], APIError> { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                var results = self?.mockAssets ?? []
                
                // Simple search filtering
                results = results.filter { asset in
                    asset.symbol.lowercased().contains(query.lowercased()) ||
                    asset.name.lowercased().contains(query.lowercased())
                }
                
                if let assetClass = assetClass {
                    results = results.filter { $0.assetClass == assetClass }
                }
                
                if let limit = limit {
                    results = Array(results.prefix(limit))
                }
                
                promise(.success(results))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getAsset(symbol: String) -> AnyPublisher<Asset, APIError> {
        return Future<Asset, APIError> { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if let asset = self?.mockAssets.first(where: { $0.symbol == symbol }) {
                    promise(.success(asset))
                } else {
                    promise(.failure(APIError(
                        code: "ASSET_NOT_FOUND",
                        message: "Asset not found",
                        details: nil,
                        field: "symbol"
                    )))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getPopularAssets(limit: Int?) -> AnyPublisher<[Asset], APIError> {
        return Future<[Asset], APIError> { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                var assets = self?.mockAssets ?? []
                if let limit = limit {
                    assets = Array(assets.prefix(limit))
                }
                promise(.success(assets))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getTopMovers(direction: MoverDirection?, limit: Int?) -> AnyPublisher<[TopMover], APIError> {
        return Future<[TopMover], APIError> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                let mockMovers = MockMarketDataService.generateMockTopMovers(direction: direction, limit: limit)
                promise(.success(mockMovers))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getMarketSummary() -> AnyPublisher<MarketSummary, APIError> {
        return Future<MarketSummary, APIError> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let mockSummary = MockMarketDataService.generateMockMarketSummary()
                promise(.success(mockSummary))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Helper Methods
    
    private static func generateMockTopMovers(direction: MoverDirection?, limit: Int?) -> [TopMover] {
        let symbols = ["AAPL", "TSLA", "GOOGL", "MSFT", "AMZN", "NVDA", "META", "NFLX", "CRM", "AMD"]
        let maxCount = limit ?? 10
        
        return symbols.prefix(maxCount).map { symbol in
            let baseChange = direction == .losers ? 
                Double.random(in: -8.0...(-0.5)) : 
                Double.random(in: 0.5...8.0)
            
            let price = Double.random(in: 50...300)
            let change = price * (baseChange / 100)
            
            return TopMover(
                symbol: symbol,
                name: "\(symbol) Inc.",
                price: price,
                change: change,
                changePercent: baseChange / 100,
                volume: Int.random(in: 500000...10000000),
                marketCap: Double.random(in: 10000000000...2000000000000)
            )
        }
    }
    
    private static func generateMockMarketSummary() -> MarketSummary {
        let indices = [
            IndexSummary(symbol: "SPY", name: "S&P 500", value: 4567.89, change: 12.34, changePercent: 0.0027),
            IndexSummary(symbol: "QQQ", name: "NASDAQ 100", value: 378.45, change: -2.67, changePercent: -0.0070),
            IndexSummary(symbol: "IWM", name: "Russell 2000", value: 198.76, change: 5.43, changePercent: 0.0281)
        ]
        
        let sectors = [
            SectorSummary(name: "Technology", changePercent: 0.0145, topSymbol: "AAPL", topSymbolChange: 2.34),
            SectorSummary(name: "Healthcare", changePercent: -0.0067, topSymbol: "JNJ", topSymbolChange: -1.23),
            SectorSummary(name: "Financials", changePercent: 0.0234, topSymbol: "JPM", topSymbolChange: 3.45)
        ]
        
        return MarketSummary(
            indices: indices,
            sectors: sectors,
            commodities: nil,
            currencies: nil,
            marketStatus: .open,
            lastUpdated: Date()
        )
    }
}