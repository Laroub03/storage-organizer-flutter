class LocationModel {
  final int id;
  final String name;
  final String description;
  final String address;
  final String city;
  final String state;
  final String country;
  final String zipCode;

  LocationModel({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.zipCode,
  });

  // Factory constructor to create a LocationModel from JSON
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      zipCode: json['zipCode'] ?? '',
    );
  }

  // Convert LocationModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'zipCode': zipCode,
    };
  }
  
  // Create location request (excluding id and name which are handled separately)
  Map<String, dynamic> toCreateRequest() {
    return {
      'description': description,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'zipCode': zipCode,
    };
  }

  // Create a copy of this location with updated fields
  LocationModel copyWith({
    int? id,
    String? name,
    String? description,
    String? address,
    String? city,
    String? state,
    String? country,
    String? zipCode,
  }) {
    return LocationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      zipCode: zipCode ?? this.zipCode,
    );
  }
  
  // Format the address as a single string for display
  String get formattedAddress {
    final parts = <String>[];
    if (address.isNotEmpty) parts.add(address);
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    if (zipCode.isNotEmpty) parts.add(zipCode);
    if (country.isNotEmpty) parts.add(country);
    
    return parts.join(', ');
  }
}