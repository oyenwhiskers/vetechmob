import 'package:flutter/material.dart';

// Conditional imports to avoid web compilation errors
import 'scan_tag_screen_mobile.dart' if (dart.library.html) 'scan_tag_screen_web.dart';

class ScanTagScreen extends StatelessWidget {
  const ScanTagScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScanTagScreenImpl();
  }
}

// Manual input fallback for web and desktop platforms
class _ManualTagInput extends StatefulWidget {
  @override
  State<_ManualTagInput> createState() => _ManualTagInputState();
}

class _ManualTagInputState extends State<_ManualTagInput> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Tag Code')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                'QR scanning is not available on this platform. Please enter the tag code manually.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Tag Code',
                  hintText: 'e.g., 1000',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                autofocus: true,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Assign Tag'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
