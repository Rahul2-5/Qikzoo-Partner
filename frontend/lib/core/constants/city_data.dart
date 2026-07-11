class CityInfo {
  final String name;
  final String state;

  const CityInfo({required this.name, required this.state});
}

class CityData {
  CityData._();

  static const popularCities = [
    CityInfo(name: 'Mumbai', state: 'Maharashtra'),
    CityInfo(name: 'Delhi', state: 'Delhi'),
    CityInfo(name: 'Bangalore', state: 'Karnataka'),
    CityInfo(name: 'Pune', state: 'Maharashtra'),
    CityInfo(name: 'Hyderabad', state: 'Telangana'),
  ];

  /// Matches a free-text locality/city name (e.g. from reverse geocoding)
  /// against the supported cities, case-insensitively.
  static CityInfo? findByName(String name) {
    final normalized = name.trim().toLowerCase();
    for (final city in popularCities) {
      if (city.name.toLowerCase() == normalized) return city;
    }
    return null;
  }
}
