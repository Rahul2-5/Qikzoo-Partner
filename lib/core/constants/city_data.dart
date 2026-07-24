class CityInfo {
  final String name;
  final String state;
  final List<String> nearbyLocations;

  const CityInfo({
    required this.name,
    required this.state,
    this.nearbyLocations = const [],
  });
}

class CityData {
  CityData._();

  static const popularCities = [
    CityInfo(
      name: 'Mumbai',
      state: 'Maharashtra',
      nearbyLocations: [
        'Andheri East',
        'Andheri West',
        'Bandra East',
        'Bandra West',
        'Bhandup',
        'Borivali',
        'Breach Candy',
        'Chembur',
        'Churchgate',
        'Colaba',
        'Dadar',
        'Dahisar',
        'Fort',
        'Ghatkopar',
        'Goregaon',
        'Jogeshwari',
        'Juhu',
        'Kandivali',
        'Khar',
        'King Circle',
        'Kurla',
        'Lower Parel',
        'Mahim',
        'Malad',
        'Marine Lines',
        'Matunga',
        'Mulund',
        'Nariman Point',
        'Parel',
        'Powai',
        'Prabhadevi',
        'Saki Naka',
        'Santacruz',
        'Sewri',
        'Sion',
        'Tardeo',
        'Vikhroli',
        'Vile Parle',
        'Wadala',
        'Worli',
      ],
    ),
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
      if (city.nearbyLocations
          .any((location) => location.toLowerCase() == normalized)) {
        return city;
      }
    }
    return null;
  }
}
