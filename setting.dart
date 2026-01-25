import 'dart:ui';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/setting.jpeg"), // Aapka path update kar diya
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
          child: Container(
            color: Colors.black.withOpacity(0.4),
            child: Stack(
              children: [
                // 1. TOP HEADER
                Positioned(
                  top: 50, left: 20, right: 20,
                  child: _buildNeonHeader(context),
                ),

                // 2. MAIN CONTENT AREA
                Positioned(
                  top: 130, left: 15, right: 15, bottom: 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT COLUMN: Notifications (Icons Fixed)
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            _buildGlassCard("Quest Reminder", "Morning Workout due in 2 hrs.", Icons.assignment_late),
                            _buildGlassCard("New Island!", "Explore mysterious Sandy Shores.", Icons.explore),
                            _buildGlassCard("Recovery Alert", "Your energy is fully restored.", Icons.bolt),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      // RIGHT COLUMN: AI & Data
                      Expanded(
                        flex: 4,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildSectionCard("AI PERSONALITY", [
                                _buildSlider("Tone: Strict", 0.7),
                                _buildDropdown("Voice", "Default"),
                              ]),
                              _buildSectionCard("DATA", [
                                _buildActionBtn("EXPORT DATA", Colors.cyanAccent),
                                _buildActionBtn("DELETE ACCOUNT", Colors.redAccent),
                              ]),
                              _buildSectionCard("MEMBERSHIP", [
                                _buildActionBtn("UPGRADE TO PREMIUM", Colors.greenAccent, isBig: true),
                              ]),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI Components ---
  Widget _buildNeonHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1219).withOpacity(0.8),
            border: Border.all(color: Colors.cyanAccent, width: 2),
            boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 15)],
          ),
          child: const Text("NOTIFICATIONS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 16)),
        ),
        // BACK BUTTON
        InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: const Text("BACK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }

  Widget _buildGlassCard(String title, String sub, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F25).withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.orangeAccent, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                Text(sub, style: TextStyle(color: Colors.white70, fontSize: 9)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.cyanAccent, fontSize: 9, fontWeight: FontWeight.w900)),
          const Divider(color: Colors.white10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 9)),
        Slider(value: val, onChanged: (v){}, activeColor: Colors.purpleAccent),
      ],
    );
  }

  Widget _buildActionBtn(String label, Color col, {bool isBig = false}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: EdgeInsets.symmetric(vertical: isBig ? 15 : 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: col.withOpacity(0.5)),
        gradient: LinearGradient(colors: [col.withOpacity(0.2), Colors.transparent]),
      ),
      child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: col, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDropdown(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        const Icon(Icons.arrow_drop_down, color: Colors.cyanAccent),
      ],
    );
  }
}