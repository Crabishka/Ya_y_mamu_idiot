class Node {
  final int id;
  final Map<int, Duration> neighbors;

  Node({
    required this.id,
    required this.neighbors,
  });

  factory Node.fromJson(Map<String, dynamic> json) {
    final Map<int, Duration> neighborMap = {};
    (json['neighbors'] as Map<String, dynamic>).forEach((key, value) {
      neighborMap[int.parse(key)] = Duration(milliseconds: value as int);
    });

    return Node(
      id: json['id'] as int,
      neighbors: neighborMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'neighbors': neighbors.map((key, value) => 
          MapEntry(key.toString(), value.inMilliseconds)),
    };
  }
} 