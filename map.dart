import 'package:flutter/material.dart';
import 'habit.dart'; // DatabaseHelper ke liye import zaroori hai

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Image (Wahi purani cyberpunk city)
          Positioned.fill(
            child: Image.asset(
              "assets/setting.jpeg",
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.5),
            ),
          ),

          // Center Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.map_outlined,
                  color: Colors.cyanAccent,
                  size: 80,
                ),
                const SizedBox(height: 20),
                Text(
                  "NEW SECTOR LOADING...",
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    shadows: [
                      Shadow(color: Colors.cyanAccent.withOpacity(0.8), blurRadius: 20)
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "COMING SOON",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 30),
                // Ek chota sa loading bar visual ke liye
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white10,
                    color: Colors.cyanAccent,
                    minHeight: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}