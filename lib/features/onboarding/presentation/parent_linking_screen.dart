import 'package:flutter/material.dart';

class ParentLinkingScreen extends StatefulWidget {
  const ParentLinkingScreen({super.key});

  @override
  State<ParentLinkingScreen> createState() => _ParentLinkingScreenState();
}

class _ParentLinkingScreenState extends State<ParentLinkingScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Link Student Account')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Connect your child\'s account'),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Student Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitation sent')));
              },
              child: const Text('Send Invitation'),
            )
          ],
        ),
      ),
    );
  }
}


