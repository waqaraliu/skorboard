class Remote {
  final String name;
  final String service;
  final String status;

  Remote({required this.name, required this.service, required this.status});

  factory Remote.fromJson(Map<String, dynamic> json) {
    return Remote(
      name: json['Name'],
      service: json['Service'],
      status: json['Status'],
    );
  }
}
