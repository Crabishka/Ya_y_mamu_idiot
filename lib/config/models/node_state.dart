import 'package:flutter/material.dart';

enum NodeState {
  idle(Colors.blue),
  receivedHello(Colors.green),
  receivedMessage(Colors.orange),
  receivedResponse(Colors.purple);

  final Color color;
  const NodeState(this.color);
} 