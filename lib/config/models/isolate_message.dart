import 'message_type.dart';

class IsolateMessage {
  final int fromId;
  final int toId;
  final String content;
  final DateTime sentAt;
  final bool delivered;
  final DateTime? deliveredAt;
  final MessageType type;

  IsolateMessage({
    required this.fromId,
    required this.toId,
    required this.content,
    required this.sentAt,
    this.delivered = false,
    this.deliveredAt,
    this.type = MessageType.regular,
  });

  IsolateMessage copyWith({
    bool? delivered,
    DateTime? deliveredAt,
    String? content,
    MessageType? type,
  }) {
    return IsolateMessage(
      fromId: fromId,
      toId: toId,
      content: content ?? this.content,
      sentAt: sentAt,
      delivered: delivered ?? this.delivered,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      type: type ?? this.type,
    );
  }
} 