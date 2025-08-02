📄 Project Specification: AI-based Stock Pattern Detection Tool

1. Overview

A macOS desktop app built using Flutter, designed to:

Fetch stock price data from Yahoo Finance,

Detect technical chart patterns from time-series data,

Alert users based on pattern detection signals,

Support custom stock watchlists and alert preferences.

2. Key Features

2.1. Stock Data Source

Provider: Yahoo Finance (via public APIs or web scraping libraries like yahoo_fin, yfinance via FFI or isolate service)

Fetch Interval: Configurable by user

Supported Data Frequencies:

1m, 2m, 5m, 15m, 30m, 60m, 90m, 1h, 1d, 5d, 1wk, 1mo, 3mo

2.2. Stock Watchlist

User can input an array of stock symbols (e.g., ["AAPL", "TSLA", "NVDA"])

Watchlist is persistent and editable

UI allows easy add/remove/reorder functionality

2.3. Pattern Detection

Supported Patterns (from uploaded reference):

Head and Shoulders (bearish)

Cup and Handle (bullish)

Double Top / Bottom (bearish/bullish)

Triangle, Ascending / Descending Triangle (breakout)

Flag, Wedge, Pennant (breakout)

AI/ML/Heuristic models scan OHLCV time-series for visual match

Match % score (e.g., 80% match) is calculated and shown

Direction prediction: ⬆️ bullish / ⬇️ bearish

2.4. Local Storage & Caching

Store OHLCV historical data locally in SQLite or Hive

Retain historical analysis results

Auto-refresh based on interval settings

2.5. Alerts

Triggered when a pattern match score exceeds a user-defined threshold

Alert methods:

macOS push notification

Email (via SMTP or API like SendGrid/Mailgun)

Alert content includes:

Stock symbol

Pattern name

Direction (up/down)

Match score

Snapshot (optional chart image)

2.6. Settings Panel

Tracking Interval: e.g., every 1m, 15m, 1h

Alert Method: Email / Push / Both

Pattern Match Threshold: e.g., 70% match

Data Period for Analysis:

Dropdown menu with: 1m, 2m, 5m, 15m, 30m, 60m, 90m, 1h, 1d, 5d, 1wk, 1mo, 3mo

3. Architecture Overview

3.1. Modules

data_service: fetch & cache Yahoo Finance data

pattern_analyzer: ML / heuristic engine to detect patterns

alert_manager: triggers and delivers alerts

ui_module: macOS-specific UI (Flutter macOS support)

settings_manager: persists user preferences

3.2. Suggested Libraries

flutter_local_notifications

mailer (for email)

flutter_secure_storage (for storing API keys, if needed)

charts_flutter or syncfusion_flutter_charts (for visual backtesting)

ffmpeg_kit_flutter (if generating chart snapshots from data)

4. User Flow

Initial Setup

User launches app → prompted to input stock codes → selects alert interval → chooses data period → app begins polling & analyzing

Pattern Detection

For each stock:

Fetch OHLCV → store data → scan for patterns → if matched → trigger alert

Alert Notification

“🚨 Pattern Detected: Cup and Handle on TSLA, ⬆️ Potential Breakout. Confidence: 87%”

5. Roadmap / Optional Enhancements

Add backtesting feature

Include visual candlestick chart with overlaid pattern highlights

Integrate with brokerage APIs for simulated or real trading

Add dark/light mode switch

Export pattern alerts to CSV or PDF