import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:food_printing_app/api_service.dart'; // ADD THIS IMPORT

class MeshyModelPage extends StatefulWidget {
  final String initialPrompt;

  const MeshyModelPage({
    super.key,
    required this.initialPrompt,
  });

  @override
  State<MeshyModelPage> createState() => _MeshyModelPageState();
}

class _MeshyModelPageState extends State<MeshyModelPage> {
  final TextEditingController _promptController = TextEditingController();
  String? _modelUrl;
  String? _thumbnailUrl;
  bool _isGenerating = false;
  bool _hasError = false;
  bool _isDownloading = false;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _promptController.text = widget.initialPrompt;
  }

  Future<void> _downloadFile() async {
    if (_modelUrl == null) return;
    
    setState(() => _isDownloading = true);
    
    try {
      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Storage permission denied');
      }

      // Get download directory
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        throw Exception('Could not access downloads directory');
      }

      // Create filename
      final fileName = 'food_model_${DateTime.now().millisecondsSinceEpoch}.glb';
      final file = File('${directory.path}/$fileName');

      // Download file
      final response = await http.get(Uri.parse(_modelUrl!));
      await file.writeAsBytes(response.bodyBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded to ${file.path}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: ${e.toString()}')),
      );
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  Future<void> _generateModel() async {
    if (_promptController.text.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _hasError = false;
      _modelUrl = null;
      _thumbnailUrl = null;
      _progress = 0;
    });

    try {
      // Call your API service
      final response = await ApiService.generateModel(
        prompt: _promptController.text,
      );
      
      // Update state with the response
      setState(() {
        _modelUrl = response['model_url'];
        _thumbnailUrl = response['thumbnail_url'];
      });
    } catch (e) {
      setState(() => _hasError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Food Model'),
        actions: [
          if (_modelUrl != null && !_isDownloading)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _downloadFile,
              tooltip: 'Download GLB file',
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _promptController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Food Design Prompt',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.edit),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isGenerating ? null : _generateModel,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: _isGenerating
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(width: 16),
                            Text('Generating ${(_progress * 100).toStringAsFixed(0)}%'),
                          ],
                        )
                      : const Text('Generate 3D Model'),
                ),
                if (_hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Generation failed. Please try again.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _buildModelPreview(),
          ),
          if (_isDownloading)
            const LinearProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildModelPreview() {
    if (_modelUrl == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isGenerating)
              const CircularProgressIndicator()
            else
              const Icon(Icons.model_training, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _isGenerating 
                ? 'Generating your 3D food model...' 
                : 'No model generated yet',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Thumbnail preview
        if (_thumbnailUrl != null)
          Container(
            padding: const EdgeInsets.all(8.0),
            height: 200,
            child: Image.network(_thumbnailUrl!),
          ),
        
        // 3D model viewer
        Expanded(
          child: ModelViewer(
            src: _modelUrl!,
            alt: '3D Food Model',
            ar: true,
            autoRotate: true,
            cameraControls: true,
            loading: Loading.eager,
          ),
        ),
      ],
    );
  }
}