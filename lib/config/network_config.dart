import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'node_model.dart';

class NetworkConfig {
  final List<Node> nodes;
  final Map<int, Node> _nodesMap;

  NetworkConfig._(this.nodes) : _nodesMap = {for (var node in nodes) node.id: node};

  static Future<NetworkConfig> fromFile(String filePath) async {
    try {
      // Загружаем файл как ассет
      final jsonString = await rootBundle.loadString(filePath);
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      
      final List<Node> nodes = (jsonData['nodes'] as List)
          .map((nodeJson) => Node.fromJson(nodeJson))
          .toList();

      return NetworkConfig._(nodes);
    } catch (e) {
      throw Exception('Failed to load network configuration: $e');
    }
  }

  Node? getNode(int id) => _nodesMap[id];

  bool canCommunicate(int fromId, int toId) {
    final node = _nodesMap[fromId];
    return node?.neighbors.containsKey(toId) ?? false;
  }

  Duration? getDeliveryTime(int fromId, int toId) {
    final node = _nodesMap[fromId];
    return node?.neighbors[toId];
  }
} 