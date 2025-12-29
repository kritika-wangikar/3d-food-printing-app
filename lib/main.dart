import 'package:flutter/material.dart';
import 'package:food_printing_app/gemini_chat_page.dart'; // Ensure this import path is correct

void main() => runApp(const Food3DPrinterApp());

class Food3DPrinterApp extends StatelessWidget {
  const Food3DPrinterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food 3D Printer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Food 3D Printer')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GeminiChatPage()),
          ),
          child: const Text('Start Designing'),
        ),
      ),
    );
  }
}