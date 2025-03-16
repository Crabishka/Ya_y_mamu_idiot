import 'message_type.dart';

class NodeEvent {
  final int nodeId;
  final MessageType messageType;
  final DateTime timestamp;

  NodeEvent({
    required this.nodeId,
    required this.messageType,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
} 