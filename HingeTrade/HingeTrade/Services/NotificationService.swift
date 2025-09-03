//
//  NotificationService.swift
//  HingeTrade
//
//  Created by Jeff Boggs on 2025-09-02.
//

import Foundation
import UserNotifications
import Combine
import SwiftUI

@MainActor
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var pendingNotifications: [HingeNotification] = []
    @Published var deliveredNotifications: [HingeNotification] = []
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        #if !os(tvOS)
        notificationCenter.delegate = self
        #endif
        Task {
            await checkAuthorizationStatus()
        }
        setupBindings()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            
            await checkAuthorizationStatus()
            
            if granted {
                await registerForRemoteNotifications()
            }
            
            return granted
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }
    
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }
    
    private func registerForRemoteNotifications() async {
        // Register for remote notifications
        // This would integrate with your push notification provider
        print("Registering for remote notifications")
    }
    
    // MARK: - Notification Scheduling
    
    func schedulePriceAlert(_ alert: PriceAlert) async throws {
        #if os(tvOS)
        // tvOS doesn't support UserNotifications the same way
        // For tvOS, we'll just track the notification internally
        let notification = HingeNotification(
            id: alert.id,
            type: .priceAlert,
            title: "Price Alert: \(alert.symbol)",
            body: priceAlertBody(for: alert),
            timestamp: Date(),
            data: ["alert": alert],
            isRead: false
        )
        pendingNotifications.append(notification)
        return
        #else
        let content = UNMutableNotificationContent()
        content.title = "Price Alert: \(alert.symbol)"
        content.body = priceAlertBody(for: alert)
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.priceAlert.rawValue
        content.userInfo = [
            "alertId": alert.id,
            "symbol": alert.symbol,
            "type": alert.condition.rawValue
        ]
        
        // For price alerts, we'll use a trigger based on market data updates
        // In a real implementation, this would be handled server-side
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: alert.id,
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
        
        // Track the notification
        let notification = HingeNotification(
            id: alert.id,
            type: .priceAlert,
            title: content.title,
            body: content.body,
            timestamp: Date(),
            data: ["alert": alert],
            isRead: false
        )
        
        pendingNotifications.append(notification)
        #endif
    }
    
    func scheduleOrderFillNotification(_ order: Order) async throws {
        #if os(tvOS)
        // tvOS doesn't support UserNotifications the same way
        return
        #else
        let content = UNMutableNotificationContent()
        content.title = "Order Filled"
        content.body = "Your \(order.side.rawValue) order for \(order.qty ?? "0") shares of \(order.symbol) has been filled"
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.orderFill.rawValue
        content.userInfo = [
            "orderId": order.id,
            "symbol": order.symbol,
            "side": order.side.rawValue
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "order-\(order.id)",
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
        #endif
    }
    
    func scheduleCreatorContentNotification(_ video: VideoContent) async throws {
        #if os(tvOS)
        // tvOS doesn't support UserNotifications the same way
        return
        #else
        let content = UNMutableNotificationContent()
        content.title = "New Video from \(video.creator.displayName)"
        content.body = video.title
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.creatorContent.rawValue
        content.userInfo = [
            "videoId": video.id,
            "creatorId": video.creator.id
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "video-\(video.id)",
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
        #endif
    }
    
    func scheduleMarketNewsAlert(_ newsItem: MarketNewsItem) async throws {
        #if os(tvOS)
        // tvOS doesn't support UserNotifications the same way
        return
        #else
        let content = UNMutableNotificationContent()
        content.title = newsItem.headline
        content.body = newsItem.summary
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.marketNews.rawValue
        content.userInfo = [
            "newsId": newsItem.id,
            "symbols": newsItem.relatedSymbols
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "news-\(newsItem.id)",
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
        #endif
    }
    
    // MARK: - Notification Management
    
    func removePendingNotification(withId id: String) async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
        pendingNotifications.removeAll { $0.id == id }
    }
    
    func removeAllPendingNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
        pendingNotifications.removeAll()
    }
    
    func getDeliveredNotifications() async {
        #if os(tvOS)
        // tvOS doesn't support deliveredNotifications the same way
        deliveredNotifications = []
        #else
        let delivered = await notificationCenter.deliveredNotifications()
        
        deliveredNotifications = delivered.map { notification in
            HingeNotification(
                id: notification.request.identifier,
                type: NotificationType(from: notification.request.content.categoryIdentifier),
                title: notification.request.content.title,
                body: notification.request.content.body,
                timestamp: notification.date,
                data: notification.request.content.userInfo,
                isRead: false
            )
        }
        #endif
    }
    
    func markNotificationAsRead(_ notificationId: String) {
        if let index = deliveredNotifications.firstIndex(where: { $0.id == notificationId }) {
            deliveredNotifications[index].isRead = true
        }
    }
    
    func clearDeliveredNotifications() {
        #if !os(tvOS)
        notificationCenter.removeAllDeliveredNotifications()
        #endif
        deliveredNotifications.removeAll()
    }
    
    // MARK: - Helper Methods
    
    private func priceAlertBody(for alert: PriceAlert) -> String {
        switch alert.condition {
        case .above:
            return "\(alert.symbol) is now above \(alert.price.formatted(.currency(code: "USD")))"
        case .below:
            return "\(alert.symbol) is now below \(alert.price.formatted(.currency(code: "USD")))"
        case .crossesAbove:
            return "\(alert.symbol) has crossed above \(alert.price.formatted(.currency(code: "USD")))"
        case .crossesBelow:
            return "\(alert.symbol) has crossed below \(alert.price.formatted(.currency(code: "USD")))"
        }
    }
    
    private func setupBindings() {
        // Monitor authorization status changes
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task {
                    await self?.checkAuthorizationStatus()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - UNUserNotificationCenterDelegate

#if os(iOS)
extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Handle notification while app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification tap
        let userInfo = response.notification.request.content.userInfo
        
        switch response.notification.request.content.categoryIdentifier {
        case NotificationCategory.priceAlert.rawValue:
            handlePriceAlertTap(userInfo: userInfo)
        case NotificationCategory.orderFill.rawValue:
            handleOrderFillTap(userInfo: userInfo)
        case NotificationCategory.creatorContent.rawValue:
            handleCreatorContentTap(userInfo: userInfo)
        case NotificationCategory.marketNews.rawValue:
            handleMarketNewsTap(userInfo: userInfo)
        default:
            break
        }
        
        completionHandler()
    }
    
    private func handlePriceAlertTap(userInfo: [AnyHashable: Any]) {
        guard let symbol = userInfo["symbol"] as? String else { return }
        
        // Post notification to navigate to symbol
        NotificationCenter.default.post(
            name: .navigateToSymbol,
            object: nil,
            userInfo: ["symbol": symbol]
        )
    }
    
    private func handleOrderFillTap(userInfo: [AnyHashable: Any]) {
        guard let orderId = userInfo["orderId"] as? String else { return }
        
        // Post notification to navigate to order
        NotificationCenter.default.post(
            name: .navigateToOrder,
            object: nil,
            userInfo: ["orderId": orderId]
        )
    }
    
    private func handleCreatorContentTap(userInfo: [AnyHashable: Any]) {
        guard let videoId = userInfo["videoId"] as? String else { return }
        
        // Post notification to navigate to video
        NotificationCenter.default.post(
            name: .navigateToVideo,
            object: nil,
            userInfo: ["videoId": videoId]
        )
    }
    
    private func handleMarketNewsTap(userInfo: [AnyHashable: Any]) {
        guard let newsId = userInfo["newsId"] as? String else { return }
        
        // Post notification to navigate to news
        NotificationCenter.default.post(
            name: .navigateToNews,
            object: nil,
            userInfo: ["newsId": newsId]
        )
    }
}
#endif

// MARK: - Notification Models

struct HingeNotification: Identifiable {
    let id: String
    let type: NotificationType
    let title: String
    let body: String
    let timestamp: Date
    let data: [AnyHashable: Any]
    var isRead: Bool
}

enum NotificationType {
    case priceAlert
    case orderFill
    case creatorContent
    case marketNews
    case system
    
    init(from categoryIdentifier: String) {
        switch categoryIdentifier {
        case NotificationCategory.priceAlert.rawValue:
            self = .priceAlert
        case NotificationCategory.orderFill.rawValue:
            self = .orderFill
        case NotificationCategory.creatorContent.rawValue:
            self = .creatorContent
        case NotificationCategory.marketNews.rawValue:
            self = .marketNews
        default:
            self = .system
        }
    }
    
    var displayName: String {
        switch self {
        case .priceAlert: return "Price Alerts"
        case .orderFill: return "Order Updates"
        case .creatorContent: return "Creator Updates"
        case .marketNews: return "Market News"
        case .system: return "System"
        }
    }
    
    var systemImage: String {
        switch self {
        case .priceAlert: return "bell.fill"
        case .orderFill: return "checkmark.circle.fill"
        case .creatorContent: return "tv.fill"
        case .marketNews: return "newspaper.fill"
        case .system: return "gear"
        }
    }
    
    var color: Color {
        switch self {
        case .priceAlert: return .orange
        case .orderFill: return .green
        case .creatorContent: return .blue
        case .marketNews: return .purple
        case .system: return .gray
        }
    }
}

enum NotificationCategory: String {
    case priceAlert = "PRICE_ALERT"
    case orderFill = "ORDER_FILL"
    case creatorContent = "CREATOR_CONTENT"
    case marketNews = "MARKET_NEWS"
}

// MARK: - Price Alert Model (using import from APIModels)

// MARK: - Market News Model

struct MarketNewsItem: Identifiable {
    let id: String
    let headline: String
    let summary: String
    let content: String?
    let source: String
    let publishedAt: Date
    let relatedSymbols: [String]
    let category: NewsCategory
    let imageURL: String?
    let importance: NewsImportance
    
    enum NewsCategory: String, CaseIterable {
        case earnings = "earnings"
        case economicData = "economic_data"
        case companyNews = "company_news"
        case marketMovers = "market_movers"
        case sectorNews = "sector_news"
        case regulatory = "regulatory"
        
        var displayName: String {
            switch self {
            case .earnings: return "Earnings"
            case .economicData: return "Economic Data"
            case .companyNews: return "Company News"
            case .marketMovers: return "Market Movers"
            case .sectorNews: return "Sector News"
            case .regulatory: return "Regulatory"
            }
        }
    }
    
    enum NewsImportance: String {
        case high = "high"
        case medium = "medium"
        case low = "low"
        
        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .gray
            }
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let navigateToSymbol = Notification.Name("navigateToSymbol")
    static let navigateToOrder = Notification.Name("navigateToOrder")
    static let navigateToVideo = Notification.Name("navigateToVideo")
    static let navigateToNews = Notification.Name("navigateToNews")
}