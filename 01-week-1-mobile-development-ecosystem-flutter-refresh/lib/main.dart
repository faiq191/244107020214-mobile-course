import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Student Profile'), centerTitle: true),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.school, size: 72, color: Colors.blue),
              SizedBox(height: 16),
              Text(
                'Faiq Razzan Afifie',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'NIM: 244107020214',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              Text(
                'Information Technology - Politeknik Negeri Malang',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                'Mobile Programming - Week 1',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
