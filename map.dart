import 'package:flutter/material.dart';
import 'main.dart'; // globalXpNotifier ke liye

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001220), // Deep Sea Blue
      body: Stack(
        children: [
          // --- 1. OCEAN BACKGROUND (Grid/Waves) ---
          _buildOceanBackground(),

          ValueListenableBuilder<int>(
            valueListenable: globalXpNotifier,
            builder: (context, xp, _) {
              // Har island 100 XP par unlock hoga
              double progress = xp / 100.0; 
              if (progress > 6) progress = 6; // Max 7 islands (0 to 6 index)

              return SingleChildScrollView(
                reverse: true, // Niche se upar ki taraf progress dikhane ke liye
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 100),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // --- 2. THE SAILING PATH (Line) ---
                      _buildPathLine(),

                      // --- 3. THE 7 ISLANDS ---
                      Column(
                        children: List.generate(7, (index) {
                          return _buildIslandNode(index, xp);
                        }).reversed.toList(),
                      ),

                      // --- 4. THE BOAT (Moving Indicator) ---
                      _buildMovingBoat(progress),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Samundar ka background
  Widget _buildOceanBackground() {
    return Opacity(
      opacity: 0.1,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 10),
        itemBuilder: (ctx, i) => Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.cyan, width: 0.5)),
        ),
      ),
    );
  }

  // Island Nodes
  Widget _buildIslandNode(int index, int xp) {
    bool isUnlocked = xp >= (index * 100);
    List<String> islandNames = [
      "Starting Port", "Mist Valley", "Iron Coast", "Storm Peak", 
      "Ancient Reef", "Dragon Bay", "Discipline Throne"
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          Text(
            islandNames[index].toUpperCase(),
            style: TextStyle(
              color: isUnlocked ? Colors.cyanAccent : Colors.white24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isUnlocked ? Colors.brown[400] : Colors.grey[900],
              shape: BoxShape.circle,
              border: Border.all(
                color: isUnlocked ? Colors.greenAccent : Colors.white10, 
                width: 4
              ),
              boxShadow: isUnlocked 
                ? [BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 20)] 
                : [],
            ),
            child: Icon(
              Icons.landscape, 
              size: 40, 
              color: isUnlocked ? Colors.green[200] : Colors.white10
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathLine() {
    return Container(
      width: 4,
      height: 1400, // Total height of all islands
      color: Colors.white.withOpacity(0.05),
    );
  }

  // --- ⛵ THE ANIMATED BOAT ---
  Widget _buildMovingBoat(double progress) {
    // 160 is margin + island height (approx calculation)
    // -1 represents bottom to top offset
    double bottomOffset = progress * 215; 

    return AnimatedPositioned(
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOutSine,
      bottom: 20 + bottomOffset,
      child: Column(
        children: [
          const Icon(Icons.directions_boat, color: Colors.orangeAccent, size: 45),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(5)),
            child: const Text("YOU", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}
