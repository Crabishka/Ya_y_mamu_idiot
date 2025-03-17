import 'dart:isolate';

import 'package:xleb/config/models/isolate_node.dart';

class IsolateSetup {
  final int nodeId;
  final SendPort receivePort;
  final Map<int, Duration> neighbors;
  final MessageHandler? onMessageReceived;

  IsolateSetup({
    required this.nodeId,
    required this.receivePort,
    required this.neighbors,
    this.onMessageReceived,
  });
}
