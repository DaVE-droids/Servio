import 'package:flutter/material.dart';

/// Loading indicator for full-screen or inline asynchronous work.
class AppLoading extends StatelessWidget {
  /// Creates a loading indicator.
  const AppLoading({this.message, super.key});

  /// Optional loading message.
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[const SizedBox(height: 16), Text(message!)],
        ],
      ),
    );
  }
}
