// Alternative CORS proxy services for web deployment
class CorsProxyOptions {
  // Option 1: AllOrigins (what we're currently using)
  static const String allOrigins = 'https://api.allorigins.win/get?url=';

  // Option 2: CORS Anywhere (requires API key for production)
  static const String corsAnywhere = 'https://cors-anywhere.herokuapp.com/';

  // Option 3: ThingProxy
  static const String thingProxy = 'https://thingproxy.freeboard.io/fetch/';

  // Option 4: CORS.io
  static const String corsIo = 'https://cors.io/?';

  // Option 5: JSONProxy
  static const String jsonProxy = 'https://jsonp.afeld.me/?url=';

  // Currently active proxy
  static const String active = allOrigins;

  // Whether the active proxy wraps response in JSON (like allOrigins)
  static const bool activeWrapsResponse = true;
}
