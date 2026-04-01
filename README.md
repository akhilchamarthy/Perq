# Perq - Credit Card Benefits Tracker

A lightweight iOS app for tracking all your credit cards and their benefits, with no bank authentication required.

## Features

### 📱 Local Wallet
- Store all your credit cards locally with SwiftData
- Add/remove cards easily
- Support for custom cards and pre-loaded popular cards

### 💰 Benefits Tracking
- Track statement credits, memberships, and status benefits
- Visual progress bars for credit usage
- Automatic reset period tracking (monthly, quarterly, annual, etc.)
- Usage tracking with manual input

### ⏰ Smart Reminders
- Get notified before benefits expire
- Configurable advance reminder settings
- Color-coded urgency levels
- One-click benefit reset

### 📊 Cashback Categories
- View all cashback categories for each card
- Support for different reward types (cash back, points, miles)
- Clear rate display with proper formatting

### 🎨 Modern UI
- Clean, aesthetic design with smooth animations
- Card-based layouts with proper shadows
- Color-coded benefit categories
- Responsive and intuitive navigation

## App Structure

### Data Models
- **CreditCard**: Main card entity with issuer, network, fees
- **Benefit**: Individual benefits with usage tracking
- **CashbackCategory**: Reward categories with rates

### Views
- **MainTabView**: Bottom navigation with 4 tabs
- **CardListView**: Grid view of all cards
- **CardDetailView**: Detailed card information with tabs
- **AddCardView**: Add new cards from JSON or custom
- **RemindersView**: Upcoming benefit expirations
- **BenefitUsageView**: Track benefit usage

### Services
- **CardDataManager**: Data persistence and JSON loading
- **BenefitTracker**: Automatic expiration checking
- **NotificationManager**: Local notification handling

## Setup Instructions

### Prerequisites
- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+

### Installation
1. Clone the repository
2. Open `Perq.xcodeproj` in Xcode
3. Build and run on simulator or device

### Initial Data
The app comes with a comprehensive `cards.json` file containing:
- 12+ popular credit cards
- 100+ benefits and credits
- Complete cashback categories
- Proper reset periods and amounts

### First Launch
1. App automatically loads cards from JSON on first launch
2. Navigate to Cards tab to see available cards
3. Tap "+" to add cards to your wallet
4. View details and track usage

## Usage Guide

### Adding Cards
1. Tap the "+" button in Cards tab
2. Choose "Browse Cards" to select from pre-loaded options
3. Or choose "Custom Card" to add your own
4. Select issuer and card, then tap "Add Card"

### Tracking Benefits
1. Go to Cards tab and select a card
2. Switch to "Benefits" tab
3. View progress bars for each benefit
4. Tap "Add Usage" to track spending
5. Monitor remaining amounts and reset dates

### Setting Reminders
1. Go to Reminders tab to see upcoming expirations
2. Tap gear icon to configure notification settings
3. Enable notifications and set advance reminder days
4. App will automatically notify you before benefits reset

### Viewing Cashback
1. Select a card from Cards tab
2. Switch to "Cashback" tab
3. View all reward categories with rates
4. Rates shown as % cash back, points/$, or miles/$

## Data Storage

### SwiftData Configuration
- Local SQLite database
- Automatic relationship management
- Model migrations handled automatically
- No external dependencies

### Data Privacy
- All data stored locally on device
- No bank API connections required
- No personal financial information transmitted
- Complete user control over data

## Technical Architecture

### SwiftData Models
```swift
@Model
final class CreditCard {
    var id: String
    var name: String
    var issuer: String
    // ... other properties
    @Relationship var benefits: [Benefit]
    @Relationship var cashbackCategories: [CashbackCategory]
}
```

### Reset Period Logic
- Monthly: 1st of each month
- Quarterly: Jan 1, Apr 1, Jul 1, Oct 1
- Semi-Annual: Jan 1 and Jul 1
- Annual: Card anniversary or Jan 1
- Quadrennial: Every 4 years

### Notification System
- Local notifications only
- Configurable advance timing
- Automatic scheduling based on reset periods
- Permission handling built-in

## Future Enhancements

### Planned Features
- [ ] Analytics dashboard with spending insights
- [ ] Export data to CSV/PDF
- [ ] Widget support for Home Screen
- [ ] Apple Watch companion app
- [ ] iCloud sync support
- [ ] Custom benefit categories
- [ ] Spending goal tracking

### Potential Improvements
- [ ] More card data sources
- [ ] Manual benefit creation
- [ ] Recurring usage patterns
- [ ] Benefit optimization suggestions
- [ ] Multi-currency support

## Contributing

### Development Guidelines
- Follow Swift naming conventions
- Use SwiftUI for all UI components
- Implement proper error handling
- Add unit tests for new features
- Update documentation for API changes

### Code Style
- Use SwiftUI best practices
- Implement proper accessibility
- Follow MVVM architecture
- Use meaningful variable names
- Add comments for complex logic

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions, issues, or feature requests:
1. Check existing issues in the repository
2. Create a new issue with detailed description
3. Include device info and iOS version
4. Provide steps to reproduce any bugs

---

**Perq** - Your personal credit card benefits companion. Never miss a benefit again!
