import 'package:flutter/material.dart';
import 'package:xleb/config/models/node_state.dart';
import '../config/network_config.dart';
import '../config/node_model.dart';
import 'dart:math' as math;

class NetworkVisualization extends StatefulWidget {
  final NetworkConfig config;
  final double nodeRadius;
  final Color edgeColor;
  final Map<int, NodeState> nodeStates;
  final Function(int nodeId)? onNodeTap;

  const NetworkVisualization({
    super.key,
    required this.config,
    this.nodeRadius = 30,
    this.edgeColor = Colors.grey,
    this.nodeStates = const {},
    this.onNodeTap,
  });

  @override
  State<NetworkVisualization> createState() => _NetworkVisualizationState();
}

class _NetworkVisualizationState extends State<NetworkVisualization> {
  late Map<int, Offset> nodePositions;

  void _calculateNodePositions(BoxConstraints constraints) {
    final positions = <int, Offset>{};
    final nodeCount = widget.config.nodes.length;
    final radius = math.min(constraints.maxWidth, constraints.maxHeight) * 0.35;
    final center = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);

    for (var i = 0; i < nodeCount; i++) {
      final angle = (2 * math.pi * i) / nodeCount;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      positions[widget.config.nodes[i].id] = Offset(x, y);
    }

    nodePositions = positions;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _calculateNodePositions(constraints);
        
        return Stack(
          children: [
            // Рисуем рёбра
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: EdgePainter(
                nodes: widget.config.nodes,
                nodePositions: nodePositions,
                edgeColor: widget.edgeColor,
              ),
            ),
            // Рисуем вершины
            ...widget.config.nodes.map((node) {
              final position = nodePositions[node.id]!;
              return Positioned(
                left: position.dx - widget.nodeRadius,
                top: position.dy - widget.nodeRadius,
                child: GestureDetector(
                  onTap: () => widget.onNodeTap?.call(node.id),
                  child: Container(
                    width: widget.nodeRadius * 2,
                    height: widget.nodeRadius * 2,
                    decoration: BoxDecoration(
                      color: widget.nodeStates[node.id]?.color ?? NodeState.idle.color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${node.id}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}

class EdgePainter extends CustomPainter {
  final List<Node> nodes;
  final Map<int, Offset> nodePositions;
  final Color edgeColor;

  EdgePainter({
    required this.nodes,
    required this.nodePositions,
    required this.edgeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = edgeColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Набор для отслеживания уже нарисованных двунаправленных рёбер
    final drawnBidirectionalEdges = <String>{};

    for (final node in nodes) {
      final startPosition = nodePositions[node.id]!;
      
      for (final neighborId in node.neighbors.keys) {
        final endPosition = nodePositions[neighborId]!;
        
        // Проверяем, есть ли обратное ребро
        final neighbor = nodes.firstWhere((n) => n.id == neighborId);
        final isBidirectional = neighbor.neighbors.containsKey(node.id);
        
        // Создаём уникальный идентификатор ребра
        final edgeId = [node.id, neighborId]..sort();
        final edgeKey = edgeId.join('-');
        
        if (isBidirectional) {
          // Пропускаем, если уже нарисовали это двунаправленное ребро
          if (drawnBidirectionalEdges.contains(edgeKey)) continue;
          drawnBidirectionalEdges.add(edgeKey);
          
          // Рисуем параллельные линии для двунаправленного ребра
          _drawParallelEdges(
            canvas, 
            startPosition, 
            endPosition, 
            paint,
            node.neighbors[neighborId]!,
            neighbor.neighbors[node.id]!,
          );
        } else {
          // Рисуем однонаправленное ребро со стрелкой
          _drawDirectedEdge(
            canvas, 
            startPosition, 
            endPosition, 
            paint,
            node.neighbors[neighborId]!,
          );
        }
      }
    }
  }

  void _drawParallelEdges(
    Canvas canvas, 
    Offset start, 
    Offset end, 
    Paint paint,
    Duration duration1,
    Duration duration2,
  ) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    
    // Вектор перпендикулярный линии для смещения
    final offsetX = -dy / length * 4;
    final offsetY = dx / length * 4;
    
    // Первая линия (от start к end)
    final start1 = Offset(start.dx + offsetX, start.dy + offsetY);
    final end1 = Offset(end.dx + offsetX, end.dy + offsetY);
    
    // Вторая линия (от end к start)
    final start2 = Offset(end.dx - offsetX, end.dy - offsetY);
    final end2 = Offset(start.dx - offsetX, start.dy - offsetY);

    // Рисуем линии со стрелками
    _drawArrowedLine(canvas, start1, end1, paint);
    _drawArrowedLine(canvas, start2, end2, paint);
    
    // Рисуем веса рёбер
    _drawEdgeWeight(canvas, start1, end1, duration1, paint, true);
    _drawEdgeWeight(canvas, start2, end2, duration2, paint, false);
  }

  void _drawDirectedEdge(
    Canvas canvas, 
    Offset start, 
    Offset end, 
    Paint paint,
    Duration duration,
  ) {
    _drawArrowedLine(canvas, start, end, paint);
    _drawEdgeWeight(canvas, start, end, duration, paint, true);
  }

  void _drawArrowedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    // Рисуем основную линию
    canvas.drawLine(start, end, paint);
    
    // Рисуем стрелку
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    
    final unitX = dx / length;
    final unitY = dy / length;
    
    final arrowLength = 15.0;
    final arrowWidth = 8.0;
    final arrowOffset = 20.0; // Отступ от конца линии
    
    final tipX = end.dx - unitX * arrowOffset;
    final tipY = end.dy - unitY * arrowOffset;
    
    final leftX = tipX - arrowLength * (unitX + unitY * arrowWidth / arrowLength);
    final leftY = tipY - arrowLength * (unitY - unitX * arrowWidth / arrowLength);
    
    final rightX = tipX - arrowLength * (unitX - unitY * arrowWidth / arrowLength);
    final rightY = tipY - arrowLength * (unitY + unitX * arrowWidth / arrowLength);
    
    final arrowPath = Path()
      ..moveTo(tipX + unitX * arrowLength, tipY + unitY * arrowLength)
      ..lineTo(leftX, leftY)
      ..lineTo(rightX, rightY)
      ..close();
    
    canvas.drawPath(arrowPath, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;
  }

  void _drawEdgeWeight(
    Canvas canvas, 
    Offset start, 
    Offset end, 
    Duration duration,
    Paint paint,
    bool isAbove,
  ) {
    final midPoint = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );
    
    // Смещаем текст немного в сторону от линии
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    final offset = isAbove ? 15.0 : -15.0;
    
    final textOffset = Offset(
      -dy / length * offset,
      dx / length * offset,
    );
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${duration.inMilliseconds}ms',
        style: TextStyle(
          color: edgeColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.white.withOpacity(0.8),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      midPoint.translate(
        -textPainter.width / 2 + textOffset.dx,
        -textPainter.height / 2 + textOffset.dy,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 