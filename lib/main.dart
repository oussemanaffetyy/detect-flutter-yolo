import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import 'package:ultralytics_yolo/widgets/yolo_controller.dart';

void main() {
  runApp(const DetectionApp());
}

class DetectionApp extends StatelessWidget {
  const DetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DETECT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const LiveDetectionScreen(),
    );
  }
}

class LiveDetectionScreen extends StatefulWidget {
  const LiveDetectionScreen({super.key});

  @override
  State<LiveDetectionScreen> createState() => _LiveDetectionScreenState();
}

class _LiveDetectionScreenState extends State<LiveDetectionScreen> {
  static const String _modelPath = 'best';
  static const double _defaultConfidenceThreshold = 0.35;
  static const List<String> _targetLabels = <String>[
    'mouse',
    'headphones',
    'notepad',
  ];
  static const Map<int, String> _classMap = <int, String>{
    0: 'headphones',
    1: 'mouse',
    2: 'notepad',
  };

  final YOLOViewController _yoloController = YOLOViewController();
  List<YOLOResult> _trackedResults = <YOLOResult>[];
  bool _frontCamera = false;
  double _confidenceThreshold = _defaultConfidenceThreshold;
  final double _iouThreshold = 0.45;

  @override
  void dispose() {
    _yoloController.stop();
    super.dispose();
  }

  void _onResults(List<YOLOResult> results) {
    setState(() {
      _trackedResults = results.where(_isTargetResult).toList();
    });
  }

  bool _isTargetResult(YOLOResult result) {
    final String className = _mappedClassName(result);
    return _targetLabels.contains(className);
  }

  String _mappedClassName(YOLOResult result) {
    final String? mappedByIndex = _classMap[result.classIndex];
    if (mappedByIndex != null) {
      return mappedByIndex;
    }
    return result.className.toLowerCase().trim();
  }

  Map<String, double?> _maxConfidenceByLabel() {
    final Map<String, double?> values = <String, double?>{
      for (final String label in _targetLabels) label: null,
    };

    for (final YOLOResult result in _trackedResults) {
      final String label = _mappedClassName(result);
      final double? currentMax = values[label];
      if (currentMax == null || result.confidence > currentMax) {
        values[label] = result.confidence;
      }
    }

    return values;
  }

  void _setConfidenceThreshold(double value) {
    setState(() {
      _confidenceThreshold = value;
    });
    _yoloController.setConfidenceThreshold(value);
  }

  Widget _buildTopControls() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: const Color(0xAA111111),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'Confidence: ${_confidenceThreshold.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    _setConfidenceThreshold(_defaultConfidenceThreshold),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Reset 0.35'),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.tealAccent,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.tealAccent,
              overlayColor: Colors.tealAccent.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _confidenceThreshold,
              min: 0.1,
              max: 0.9,
              divisions: 16,
              onChanged: _setConfidenceThreshold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomLabels(Map<String, double?> confidenceByLabel) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xAA111111),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Detected Labels',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _targetLabels.map((String label) {
              final double? confidence = confidenceByLabel[label];
              final bool detected = confidence != null;
              return Chip(
                backgroundColor: detected
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.2),
                side: BorderSide(
                  color: detected
                      ? Colors.green.shade300
                      : Colors.grey.shade500,
                ),
                label: Text(
                  detected
                      ? '$label ${(confidence * 100).toStringAsFixed(1)}%'
                      : '$label --',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobilePlatform =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    if (!isMobilePlatform) {
      return Scaffold(
        appBar: AppBar(title: const Text('DETECT')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Run this app on Android or iOS to use camera stream detection.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final Map<String, double?> confidenceByLabel = _maxConfidenceByLabel();

    return Scaffold(
      appBar: AppBar(
        title: const Text('DETECT'),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              _yoloController.switchCamera();
              setState(() {
                _frontCamera = !_frontCamera;
              });
            },
            icon: const Icon(Icons.flip_camera_android),
            tooltip: 'Switch camera',
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(
            child: YOLOView(
              controller: _yoloController,
              modelPath: _modelPath,
              task: YOLOTask.detect,
              showOverlays: false,
              confidenceThreshold: _confidenceThreshold,
              iouThreshold: _iouThreshold,
              streamingConfig: const YOLOStreamingConfig.minimal(),
              lensFacing: _frontCamera ? LensFacing.front : LensFacing.back,
              onResult: _onResults,
            ),
          ),
          if (_trackedResults.isNotEmpty)
            Positioned.fill(
              child: CustomPaint(
                painter: DetectionPainter(
                  results: _trackedResults,
                  mapClassName: _mappedClassName,
                  mirrorHorizontal: _frontCamera,
                ),
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(bottom: false, child: _buildTopControls()),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: _buildBottomLabels(confidenceByLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class DetectionPainter extends CustomPainter {
  const DetectionPainter({
    required this.results,
    required this.mapClassName,
    required this.mirrorHorizontal,
  });

  final List<YOLOResult> results;
  final String Function(YOLOResult result) mapClassName;
  final bool mirrorHorizontal;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint boxPaint = Paint()
      ..color = const Color(0xFF00E676)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    for (final YOLOResult result in results) {
      final Rect box = result.normalizedBox;
      final double left = mirrorHorizontal
          ? (1.0 - box.right) * size.width
          : box.left * size.width;
      final double top = box.top * size.height;
      final double width = (box.right - box.left) * size.width;
      final double height = (box.bottom - box.top) * size.height;
      final Rect rect = Rect.fromLTWH(left, top, width, height);

      canvas.drawRect(rect, boxPaint);

      final String label =
          '${mapClassName(result)} ${(result.confidence * 100).toStringAsFixed(1)}%';
      final TextSpan span = TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          backgroundColor: Color(0xCC000000),
        ),
      );
      final TextPainter textPainter = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width * 0.8);

      final double textTop = (top - textPainter.height - 2).clamp(
        0.0,
        size.height - textPainter.height,
      );
      final double textLeft = left.clamp(0.0, size.width - textPainter.width);
      textPainter.paint(canvas, Offset(textLeft, textTop));
    }
  }

  @override
  bool shouldRepaint(covariant DetectionPainter oldDelegate) {
    return oldDelegate.results != results ||
        oldDelegate.mirrorHorizontal != mirrorHorizontal;
  }
}
