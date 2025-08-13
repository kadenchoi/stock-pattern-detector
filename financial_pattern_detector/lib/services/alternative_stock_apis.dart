// Alternative stock data APIs that support CORS
class AlternativeStockAPIs {
  // Free alternatives:

  // 1. Alpha Vantage (free tier: 5 API requests per minute, 500 per day)
  // https://www.alphavantage.co/
  static const String alphaVantage = 'https://www.alphavantage.co/query';

  // 2. IEX Cloud (free tier available)
  // https://iexcloud.io/
  static const String iexCloud = 'https://cloud.iexapis.com/stable';

  // 3. Finnhub (free tier: 60 API calls/minute)
  // https://finnhub.io/
  static const String finnhub = 'https://finnhub.io/api/v1';

  // 4. Twelvedata (free tier: 800 API calls/day)
  // https://twelvedata.com/
  static const String twelveData = 'https://api.twelvedata.com';

  // 5. Financial Modeling Prep (free tier: 250 requests/day)
  // https://financialmodelingprep.com/
  static const String fmp = 'https://financialmodelingprep.com/api/v3';
}

// Note: Most of these require API keys but have built-in CORS support
// and are more reliable for production applications.
