import Foundation

// MARK: - KYC Status Enum
enum KYCStatus: String, CaseIterable, Codable {
    case notStarted = "NotStarted"
    case inProgress = "InProgress"
    case underReview = "UnderReview"
    case approved = "Approved"
    case rejected = "Rejected"
    case expired = "Expired"
    
    var displayName: String {
        switch self {
        case .notStarted:
            return "Not Started"
        case .inProgress:
            return "In Progress"
        case .underReview:
            return "Under Review"
        case .approved:
            return "Approved"
        case .rejected:
            return "Rejected"
        case .expired:
            return "Expired"
        }
    }
    
    var color: KYCStatusColor {
        switch self {
        case .notStarted:
            return .gray
        case .inProgress:
            return .blue
        case .underReview:
            return .orange
        case .approved:
            return .green
        case .rejected:
            return .red
        case .expired:
            return .red
        }
    }
    
    var requiresAction: Bool {
        switch self {
        case .notStarted, .rejected, .expired:
            return true
        default:
            return false
        }
    }
    
    var canTrade: Bool {
        return self == .approved
    }
}

// MARK: - User Role Enum
enum UserRole: String, CaseIterable, Codable {
    case user = "User"
    case admin = "Admin"
    case moderator = "Moderator"
    case creator = "Creator"
    
    var displayName: String {
        return rawValue
    }
    
    var permissions: [UserPermission] {
        switch self {
        case .user:
            return [.trade, .viewContent, .createWatchlists]
        case .creator:
            return [.trade, .viewContent, .createWatchlists, .createContent, .receivePayments]
        case .moderator:
            return [.trade, .viewContent, .createWatchlists, .moderateContent]
        case .admin:
            return UserPermission.allCases
        }
    }
}

// MARK: - User Permission Enum
enum UserPermission: String, CaseIterable, Codable {
    case trade = "Trade"
    case viewContent = "ViewContent"
    case createContent = "CreateContent"
    case moderateContent = "ModerateContent"
    case createWatchlists = "CreateWatchlists"
    case receivePayments = "ReceivePayments"
    case adminAccess = "AdminAccess"
    case userManagement = "UserManagement"
    
    var displayName: String {
        switch self {
        case .trade:
            return "Trade Securities"
        case .viewContent:
            return "View Content"
        case .createContent:
            return "Create Content"
        case .moderateContent:
            return "Moderate Content"
        case .createWatchlists:
            return "Create Watchlists"
        case .receivePayments:
            return "Receive Payments"
        case .adminAccess:
            return "Admin Access"
        case .userManagement:
            return "User Management"
        }
    }
}

// MARK: - User Model
struct User: Codable, Identifiable, Equatable {
    let id: String
    let email: String
    let username: String
    let emailVerified: Bool
    let kycStatus: KYCStatus
    let kycSubmittedAt: Date?
    let kycApprovedAt: Date?
    let createdAt: Date
    let roles: [UserRole]
    
    // Profile information (optional)
    let firstName: String?
    let lastName: String?
    let avatarUrl: String?
    let bio: String?
    let website: String?
    
    // Preferences
    let notificationsEnabled: Bool?
    let darkModeEnabled: Bool?
    let timezone: String?
    let language: String?
    
    // Statistics (for creators)
    let followerCount: Int?
    let followingCount: Int?
    let videoCount: Int?
    let totalViews: Int?
    let totalEarnings: Double?
    
    enum CodingKeys: String, CodingKey {
        case id, email, username, roles, bio, website, timezone, language
        case emailVerified = "email_verified"
        case kycStatus = "kyc_status"
        case kycSubmittedAt = "kyc_submitted_at"
        case kycApprovedAt = "kyc_approved_at"
        case createdAt = "created_at"
        case firstName = "first_name"
        case lastName = "last_name"
        case avatarUrl = "avatar_url"
        case notificationsEnabled = "notifications_enabled"
        case darkModeEnabled = "dark_mode_enabled"
        case followerCount = "follower_count"
        case followingCount = "following_count"
        case videoCount = "video_count"
        case totalViews = "total_views"
        case totalEarnings = "total_earnings"
    }
    
    // MARK: - Computed Properties
    
    /// Full display name
    var displayName: String {
        if let firstName = firstName, let lastName = lastName, !firstName.isEmpty, !lastName.isEmpty {
            return "\(firstName) \(lastName)"
        }
        return username
    }
    
    /// Initials for avatar placeholder
    var initials: String {
        if let firstName = firstName, let lastName = lastName,
           !firstName.isEmpty, !lastName.isEmpty {
            let firstInitial = String(firstName.prefix(1)).uppercased()
            let lastInitial = String(lastName.prefix(1)).uppercased()
            return "\(firstInitial)\(lastInitial)"
        }
        return String(username.prefix(2)).uppercased()
    }
    
    /// Whether the user can trade
    var canTrade: Bool {
        return emailVerified && kycStatus.canTrade && hasPermission(.trade)
    }
    
    /// Whether the user is a content creator
    var isCreator: Bool {
        return roles.contains(.creator) || roles.contains(.admin)
    }
    
    /// Whether the user is a moderator
    var isModerator: Bool {
        return roles.contains(.moderator) || roles.contains(.admin)
    }
    
    /// Whether the user is an admin
    var isAdmin: Bool {
        return roles.contains(.admin)
    }
    
    /// Check if user has specific permission
    func hasPermission(_ permission: UserPermission) -> Bool {
        return roles.flatMap { $0.permissions }.contains(permission)
    }
    
    /// Primary role (highest priority role)
    var primaryRole: UserRole {
        if roles.contains(.admin) { return .admin }
        if roles.contains(.moderator) { return .moderator }
        if roles.contains(.creator) { return .creator }
        return .user
    }
    
    /// Account age in days
    var accountAge: Int {
        Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
    }
    
    /// Formatted account age
    var formattedAccountAge: String {
        let days = accountAge
        if days < 30 {
            return "\(days) days"
        } else if days < 365 {
            let months = days / 30
            return "\(months) month\(months == 1 ? "" : "s")"
        } else {
            let years = days / 365
            return "\(years) year\(years == 1 ? "" : "s")"
        }
    }
    
    /// Formatted follower count
    var formattedFollowerCount: String {
        guard let followerCount = followerCount else { return "0" }
        return followerCount.asAbbreviated()
    }
    
    /// Formatted following count
    var formattedFollowingCount: String {
        guard let followingCount = followingCount else { return "0" }
        return followingCount.asAbbreviated()
    }
    
    /// Formatted video count
    var formattedVideoCount: String {
        guard let videoCount = videoCount else { return "0" }
        return videoCount.asAbbreviated()
    }
    
    /// Formatted total views
    var formattedTotalViews: String {
        guard let totalViews = totalViews else { return "0" }
        return totalViews.asAbbreviated()
    }
    
    /// Formatted total earnings
    var formattedTotalEarnings: String {
        guard let totalEarnings = totalEarnings else { return "$0.00" }
        return totalEarnings.asCurrency()
    }
    
    /// KYC completion progress (0.0 to 1.0)
    var kycProgress: Double {
        switch kycStatus {
        case .notStarted:
            return 0.0
        case .inProgress:
            return 0.5
        case .underReview:
            return 0.8
        case .approved:
            return 1.0
        case .rejected, .expired:
            return 0.0
        }
    }
    
    /// KYC status message for display
    var kycStatusMessage: String {
        switch kycStatus {
        case .notStarted:
            return "Complete your profile to start trading"
        case .inProgress:
            return "Please complete your KYC application"
        case .underReview:
            return "We're reviewing your application"
        case .approved:
            return "Account approved - ready to trade"
        case .rejected:
            return "Application rejected - please contact support"
        case .expired:
            return "KYC expired - please resubmit documents"
        }
    }
    
    /// Whether user profile is complete
    var isProfileComplete: Bool {
        return emailVerified && firstName != nil && lastName != nil
    }
    
    /// Profile completion percentage
    var profileCompletionPercentage: Double {
        var completed = 0.0
        let total = 6.0
        
        if emailVerified { completed += 1 }
        if firstName != nil && !firstName!.isEmpty { completed += 1 }
        if lastName != nil && !lastName!.isEmpty { completed += 1 }
        if avatarUrl != nil && !avatarUrl!.isEmpty { completed += 1 }
        if bio != nil && !bio!.isEmpty { completed += 1 }
        if kycStatus == .approved { completed += 1 }
        
        return completed / total
    }
}

// MARK: - KYC Status Color
enum KYCStatusColor {
    case gray
    case blue
    case orange
    case green
    case red
}

// MARK: - Sample Data
extension User {
    static let sampleData: [User] = [
        User(
            id: "user-001",
            email: "john.doe@example.com",
            username: "johndoe",
            emailVerified: true,
            kycStatus: .approved,
            kycSubmittedAt: Date().addingTimeInterval(-86400 * 30), // 30 days ago
            kycApprovedAt: Date().addingTimeInterval(-86400 * 25), // 25 days ago
            createdAt: Date().addingTimeInterval(-86400 * 45), // 45 days ago
            roles: [.user],
            firstName: "John",
            lastName: "Doe",
            avatarUrl: nil,
            bio: "Active trader focused on tech stocks",
            website: "https://johndoe.example.com",
            notificationsEnabled: true,
            darkModeEnabled: true,
            timezone: "America/New_York",
            language: "en",
            followerCount: nil,
            followingCount: nil,
            videoCount: nil,
            totalViews: nil,
            totalEarnings: nil
        ),
        User(
            id: "creator-001",
            email: "jane.smith@example.com",
            username: "janefinance",
            emailVerified: true,
            kycStatus: .approved,
            kycSubmittedAt: Date().addingTimeInterval(-86400 * 90), // 90 days ago
            kycApprovedAt: Date().addingTimeInterval(-86400 * 85), // 85 days ago
            createdAt: Date().addingTimeInterval(-86400 * 120), // 120 days ago
            roles: [.creator],
            firstName: "Jane",
            lastName: "Smith",
            avatarUrl: "https://example.com/avatars/jane.jpg",
            bio: "Financial educator helping you navigate the markets",
            website: "https://janefinance.com",
            notificationsEnabled: true,
            darkModeEnabled: false,
            timezone: "America/Los_Angeles",
            language: "en",
            followerCount: 12540,
            followingCount: 156,
            videoCount: 89,
            totalViews: 456789,
            totalEarnings: 2847.52
        )
    ]
    
    static let currentUser: User = sampleData[0]
}