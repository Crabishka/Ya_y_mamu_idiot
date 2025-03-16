import 'dart:isolate';

class IsolateSetup {
  final int nodeId;
  final SendPort receivePort;
  final Map<int, Duration> neighbors;

  IsolateSetup({
    required this.nodeId,
    required this.receivePort,
    required this.neighbors,
  });
} 