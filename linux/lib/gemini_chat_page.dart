import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_printing_app/api_service.dart';
import 'package:food_printing_app/meshy_model_page.dart';

class GeminiChatPage extends StatefulWidget {
  const GeminiChatPage({super.key});

  @override
  State<GeminiChatPage> createState() => _GeminiChatPageState();
}

class _GeminiChatPageState extends State<GeminiChatPage> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  Map<String, dynamic> _conversationState = {};
  String _finalPrompt = '';
  final ScrollController _scrollController = ScrollController();

  bool _isOptionMessage(String text) {
    return RegExp(r'Choose|Select|Options|Pick|option|-\s|\d+\.|\[', 
      caseSensitive: false).hasMatch(text);
  }

  List<Widget> _buildOptionButtons(String text) {
    final options = RegExp(r'(\[([^\]]+)\]|-\s([^\n]+)|\d+\.\s([^\n]+))')
        .allMatches(text)
        .map((match) => match.group(2) ?? match.group(3) ?? match.group(4) ?? '')
        .where((option) => option.trim().isNotEmpty)
        .toList();

    return options.map((option) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: ActionChip(
        label: Text(option.trim()),
        onPressed: () {
          _textController.text = option.trim();
          _sendMessage();
        },
      ),
    )).toList();
  }

  Future<void> _sendMessage() async {
    if (_textController.text.isEmpty) return;

    setState(() {
      _messages.add({
        "text": _textController.text,
        "isUser": true,
        "containsOptions": false,
      });
      _isLoading = true;
    });

    try {
      final response = await ApiService.startChat(
        message: _textController.text,
        conversationState: _conversationState,
      );

      setState(() {
        if (response['is_complete'] == true) {
          _finalPrompt = response['reply'];
        }

        _messages.add({
          "text": response['reply'],
          "isUser": false,
          "isComplete": response['is_complete'] ?? false,
          "containsOptions": _isOptionMessage(response['reply']),
        });
        _conversationState = response['conversation_state'] ?? {};
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    } catch (e) {
      setState(() {
        _messages.add({
          "text": "Error: ${e.toString()}",
          "isUser": false,
          "isComplete": false,
          "containsOptions": false,
        });
        _isLoading = false;
      });
    } finally {
      _textController.clear();
    }
  }

  void _navigateToMeshyPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeshyModelPage(
          // CORRECTED: Changed modelUrl to initialPrompt
          initialPrompt: _finalPrompt,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Design Assistant'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              icon: const Icon(Icons.model_training),
              label: const Text('Generate 3D Model'),
              onPressed: _navigateToMeshyPage,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[_messages.length - 1 - index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: _conversationState.isEmpty
                          ? "What food would you like to design?"
                          : "Type your response...",
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    return Align(
      alignment: msg["isUser"] ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: msg["isUser"] 
              ? Theme.of(context).primaryColor.withOpacity(0.2)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg["containsOptions"] == true)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg["text"].replaceAllMapped(
                      RegExp(r'(\[.*?\]|-\s.*?|\d+\.\s.*?)(?=\n|$)'), 
                      (match) => '',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: _buildOptionButtons(msg["text"]),
                  ),
                ],
              )
            else
              Row(  // FIXED: Added comma after Row
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: SelectableText(
                      msg["text"],
                      style: TextStyle(
                        color: msg["isUser"] 
                            ? Theme.of(context).primaryColor
                            : Colors.black,
                      ),
                    ),
                  ),
                  IconButton(  // FIXED: Added comma after IconButton
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: msg["text"]));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Copied to clipboard!")),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ), 
                ],
              ),  // FIXED: Added comma after closing bracket
            if (msg["isComplete"] == true) ...[
              const SizedBox(height: 8),
              Text(
                "Your design is ready! You can generate it anytime using the button above",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}