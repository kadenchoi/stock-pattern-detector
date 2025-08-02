# Financial Pattern Detector

An AI-based stock pattern detection tool built with Flutter for macOS. This application automatically analyzes stock price data from Yahoo Finance to detect technical chart patterns and alert users when patterns are found.

## Features

- **Real-time Pattern Detection**: Automatically scans for common technical patterns like Head & Shoulders, Cup & Handle, Double Top/Bottom, Triangles, Flags, and more
- **Smart Alerts**: Configurable notifications via macOS notifications and email
- **Customizable Watchlist**: Add/remove stock symbols to monitor
- **Historical Data Storage**: Local SQLite database for caching stock data and pattern history
- **Adjustable Settings**: Configure analysis intervals, pattern confidence thresholds, and alert preferences
- **Beautiful UI**: Modern Material Design 3 interface optimized for macOS

## Supported Patterns

- **Head and Shoulders** (Bearish reversal)
- **Cup and Handle** (Bullish continuation)
- **Double Top/Bottom** (Reversal patterns)
- **Ascending/Descending Triangles** (Breakout patterns)
- **Flags, Wedges, Pennants** (Continuation patterns)

## Installation

### Prerequisites

- Flutter SDK (latest stable version)
- macOS development environment
- Xcode command line tools

### Setup

1. Clone or download the project
2. Navigate to the project directory:
   ```bash
   cd financial_pattern_detector
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Generate code for models:
   ```bash
   flutter packages pub run build_runner build
   ```

5. Run the application:
   ```bash
   flutter run -d macos
   ```

## Quick Start

1. **Add Stock Symbols**: Click the "+" button to add symbols like AAPL, TSLA, NVDA
2. **Configure Settings**: Set your preferred analysis interval and confidence threshold
3. **Monitor Patterns**: Watch the Patterns tab for detected patterns and alerts

## Configuration

### Initial Setup

1. **Add Stock Symbols**: Click the "+" button to add stock symbols (e.g., AAPL, TSLA, NVDA) to your watchlist
2. **Configure Settings**: Access the settings panel to customize:
   - Analysis interval (how often to check for patterns)
   - Data period (timeframe for pattern analysis)
   - Pattern confidence threshold
   - Alert methods (notifications, email, or both)

### Alert Configuration

- **Notifications**: Enable macOS system notifications for pattern alerts
- **Email Alerts**: Configure SMTP settings for email notifications
- **Threshold**: Set minimum confidence score (50-95%) to trigger alerts

## Technical Architecture

### Core Components

- **AppManager**: Central coordinator for all services
- **YahooFinanceService**: Fetches stock data from Yahoo Finance API
- **PatternAnalyzer**: AI/ML algorithms for detecting chart patterns
- **DatabaseService**: Local data persistence with SQLite
- **AlertManager**: Handles notifications and email alerts
- **SettingsManager**: User preferences and configuration

### Pattern Detection

The application uses a combination of heuristic algorithms and mathematical analysis to identify patterns:

- **Time Series Analysis**: Analyzes OHLCV (Open, High, Low, Close, Volume) data
- **Trend Line Detection**: Identifies support and resistance levels
- **Pattern Matching**: Compares price movements to known pattern templates
- **Confidence Scoring**: Calculates match probability (0-100%)

## Disclaimer

This application is for educational and informational purposes only. It should not be considered as financial advice. Always conduct your own research and consult with financial professionals before making investment decisions.
