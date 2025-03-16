import 'dart:isolate';

import 'package:xleb/config/models/isolate_node.dart';
import 'package:xleb/config/network_config.dart';
import 'package:xleb/services/node_state_service.dart';

import 'isolate_message.dart';
import 'message_type.dart';
import 'node_event.dart';

// Класс для управления сетью изолятов
class IsolateNetwork {
  final NetworkConfig config;
  final Map<int, IsolateNode> _nodes = {};
  final Map<int, SendPort> _nodePorts = {};
  final stateService = NodeStateService();

  IsolateNetwork(this.config);

  // Создание сети изолятов
  Future<void> initialize() async {
    for (final node in config.nodes) {
      final isolateNode = await IsolateNode.create(
        node,
        config,
        /// служит только для отправки во внешний мир
        onMessageReceived: (message) {
          stateService.reportNodeEvent(
            NodeEvent(
              nodeId: node.id,
              messageType: message.type,
            ),
          );
        },
      );
      _nodes[node.id] = isolateNode;
      _nodePorts[node.id] = isolateNode.sendPort;
    }

    // После создания всех узлов передаем им порты соседей
    for (final node in config.nodes) {
      final neighborPorts = <int, SendPort>{};
      for (final neighborId in node.neighbors.keys) {
        neighborPorts[neighborId] = _nodePorts[neighborId]!;
      }
      _nodes[node.id]!.initializeNeighbors(neighborPorts);
    }
  }

  Future<void> _handleNodeMessage(IsolateMessage message) async {
    final targetNode = _nodes[message.toId];
    if (targetNode != null) {
      await targetNode.sendMessage(message);
    }
  }

  Future<void> sendMessageToNode(
    int toId,
    String content, {
    MessageType type = MessageType.regular,
  }) async {
    final targetNode = _nodes[toId];
    if (targetNode == null) {
      throw Exception('Target node $toId not found');
    }

    final message = IsolateMessage(
      fromId: -1,
      toId: toId,
      content: content,
      sentAt: DateTime.now(),
      type: type,
    );

    return targetNode.sendMessage(message);
  }

  Future<void> dispose() async {
    for (final node in _nodes.values) {
      await node.dispose();
    }
    _nodes.clear();
    _nodePorts.clear();
  }
}
