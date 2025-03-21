import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'config/network_config.dart';
import 'config/models/isolate_network.dart';
import 'widgets/network_visualization.dart';
import 'config/models/message_type.dart';
import 'config/models/node_state.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'services/node_state_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Network Visualization',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Network Visualization'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  NetworkConfig? config;
  IsolateNetwork? network;
  int selectedNode = 1;
  final textController = TextEditingController();
  StreamSubscription? _nodeEventsSubscription;
  Timer? _resetTimer;

  @override
  void initState() {
    super.initState();
    _initializeNetwork();
  }

  @override
  void dispose() {
    _nodeEventsSubscription?.cancel();

    textController.dispose();
    network?.dispose();
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeNetwork() async {
    try {
      config = await NetworkConfig.fromFile('lib/config/network_config.json');
      network = IsolateNetwork(config!);
      await network!.initialize();
      setState(() {});
    } catch (e) {
      print('Error initializing network: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: config == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder(
              stream: network?.stateService.nodeEventsController,
              builder: (context, snapshot) {
                final data = snapshot.data;
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: NetworkVisualization(
                          config: config!,
                          nodeRadius: 30,
                          edgeColor: Colors.grey.shade600,
                          nodeStates: data ?? {},

                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: textController,
                              decoration: const InputDecoration(
                                labelText: 'Сообщение',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          DropdownButton<int>(
                            value: selectedNode,
                            items: config!.nodes.map((node) {
                              return DropdownMenuItem(
                                value: node.id,
                                child: Text('Узел ${node.id}'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedNode = value!;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              if (textController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Введите сообщение')),
                                );
                                return;
                              }

                              try {
                                final response = await network!.sendMessageToNode(
                                  selectedNode,
                                  textController.text,
                                );
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Ошибка: $e')),
                                  );
                                }
                              }
                            },
                            child: const Text('Отправить сообщение'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              if (textController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Введите сообщение')),
                                );
                                return;
                              }

                              try {
                                final response = await network!.sendMessageToNode(
                                  selectedNode,
                                  textController.text,
                                  type: MessageType.hello,
                                );
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Ошибка: $e')),
                                  );
                                }
                              }
                            },
                            child: const Text('Отправить приветствие'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
    );
  }
}
