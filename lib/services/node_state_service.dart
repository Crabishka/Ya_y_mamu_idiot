import 'package:flutter/material.dart';
import 'package:rxdart/subjects.dart';
import 'package:xleb/config/models/isolate_node.dart';
import 'package:xleb/config/models/message_type.dart';
import 'package:xleb/config/models/node_event.dart';
import 'package:xleb/config/models/node_state.dart';


class NodeStateService {
  static final NodeStateService _instance = NodeStateService._internal();
  factory NodeStateService() => _instance;

  final nodeEventsController = BehaviorSubject<Map<int, Color>>.seeded({});

  NodeStateService._internal();

  void reportNodeEvent(NodeEvent event) {
    final value = nodeEventsController.value;
    final newMap = {...value};
    newMap[event.nodeId] = mapColor[event.messageType]!;
    nodeEventsController.add(newMap);
  }


  void dispose() {
    nodeEventsController.close();
  }
} 