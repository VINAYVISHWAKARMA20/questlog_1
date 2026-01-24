import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;

void main() => runApp(const MaterialApp(home: HabitPage(), debugShowCheckedModeBanner: false));

class HabitPage extends StatefulWidget {
  const HabitPage({super.key});
  @override
  State<HabitPage> createState() => _HabitPageState();
}

class _HabitPageState extends State<HabitPage> {
  final TextEditingController _habitController = TextEditingController();
  int hp = 100;
  int xp = 0;
  int level = 1;
  int? selectedTaskIndex;
  int currentDay = DateTime.now().day;
  List<Map<String, dynamic>> habits = [];

  bool showAnim = false;
  bool isGain = true;
  String animMsg = "";

  final Color gold = const Color(0xFFFFD700);
  final Color cyan = Colors.cyanAccent;
  final Color hotPink = const Color(0xFFFF2D55);

  final List<String> taskEmojis = ["⚡", "⚔️", "🦾", "🐉", "☄️", "🔥", "🎯", "🧬"];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hp = prefs.getInt('hp') ?? 100;
      xp = prefs.getInt('xp') ?? 0;
      level = (xp / 500).floor() + 1;
      String? saved = prefs.getString('my_habits');
      if (saved != null) habits = List<Map<String, dynamic>>.from(json.decode(saved));
    });
  }

  _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('my_habits', json.encode(habits));
    prefs.setInt('hp', hp);
    prefs.setInt('xp', xp);
  }

  void _runAnimation(bool gain, String msg) {
    setState(() { isGain = gain; animMsg = msg; showAnim = true; });
    Timer(const Duration(milliseconds: 2000), () => setState(() => showAnim = false));
  }

  void _handleEntry(int hIdx, int dIdx) {
    int dayClicked = dIdx + 1;
    if (dayClicked > currentDay) return;
    setState(() {
      String status = habits[hIdx]["data"][dIdx];
      if (status == "OK") {
        habits[hIdx]["data"][dIdx] = "EMPTY";
        xp = (xp - 50).clamp(0, 999999);
      } else {
        habits[hIdx]["data"][dIdx] = "OK";
        if (dayClicked < currentDay) {
          hp = (hp - 5).clamp(0, 100);
          xp = (xp - 20).clamp(0, 999999);
          _runAnimation(false, "VITALITY LOW: -5 HP ⚠️");
        } else {
          xp += 50;
          _runAnimation(true, "DOMINANCE: +50 XP 💎");
        }
      }
      level = (xp / 500).floor() + 1;
    });
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF010203),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 60),
              _buildCaptionRow(), // Task 2: Captain's Log Upgraded
              const SizedBox(height: 25),
              _buildStats(),
              const SizedBox(height: 20),
              Expanded(child: selectedTaskIndex == null ? _buildMainDashboard() : _buildIndividualDashboard()),
            ],
          ),
          if (showAnim) _buildEnhancedAnimation(),
        ],
      ),
      floatingActionButton: selectedTaskIndex == null ? FloatingActionButton(
        backgroundColor: cyan, onPressed: _showAddDialog, mini: true,
        child: const Icon(Icons.bolt, color: Colors.black, size: 30),
      ) : null,
    );
  }

  // --- TASK 2: CAPTAIN'S LOG PENDING FIX ---
  Widget _buildCaptionRow() => Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: cyan.withOpacity(0.1), width: 0.5))
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Solid Icon Left
        Icon(Icons.radio_button_checked, color: cyan.withOpacity(0.5), size: 10),
        const SizedBox(width: 8),
        Text("STREAK: ${habits.length} ACTIVE", style: TextStyle(color: cyan.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.bold)),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text("CAPTAIN'S LOG", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 6, shadows: [Shadow(color: cyan, blurRadius: 12)])),
        ),

        Text("SYSTEM: ONLINE", style: TextStyle(color: Colors.greenAccent.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        // Solid Icon Right
        Icon(Icons.shield, color: Colors.greenAccent.withOpacity(0.5), size: 10),
      ],
    ),
  );

  Widget _buildStats() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    child: Row(
      children: [
        _statCard("VITALITY CORE", "$hp%", hotPink, Icons.favorite),
        const SizedBox(width: 12),
        _statCard("COMMAND RANK", "LVL $level", gold, Icons.workspace_premium),
      ],
    ),
  );

  Widget _statCard(String label, String val, Color col, IconData icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [col.withOpacity(0.15), Colors.transparent], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: col.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: col.withOpacity(0.05), blurRadius: 15, spreadRadius: 2)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: col.withOpacity(0.5), fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
              Icon(icon, color: col.withOpacity(0.3), size: 12),
            ],
          ),
          const SizedBox(height: 6),
          Text(val, style: TextStyle(color: col, fontSize: 26, fontWeight: FontWeight.w900, shadows: [Shadow(color: col, blurRadius: 10)])),
        ],
      ),
    ),
  );

  Widget _buildMainDashboard() => Container(
    margin: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        color: const Color(0xFF0A0F15), borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)]
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Row(
        children: [
          Container(
            width: 115,
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), border: const Border(right: BorderSide(color: Colors.white10))),
            child: Column(
              children: [
                Container(
                  height: 50, alignment: Alignment.center,
                  child: Text("MISSIONS 🧬", style: TextStyle(color: cyan, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, shadows: [Shadow(color: cyan, blurRadius: 5)])),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: habits.length,
                    itemBuilder: (context, i) => InkWell(
                      onTap: () => setState(() => selectedTaskIndex = i),
                      child: Container(
                        height: 70,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.03)))),
                        // --- TASK 3: FONT SIZE FOR MANUAL ENTRIES ---
                        child: Text(
                            "${taskEmojis[i % taskEmojis.length]} ${habits[i]["name"]}",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: gold, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5)
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                children: [
                  Container(
                    height: 50, color: Colors.black45,
                    child: Row(children: List.generate(31, (i) => Container(width: 55, alignment: Alignment.center, child: Text("${i+1}", style: TextStyle(color: (i+1) == currentDay ? cyan : Colors.white54, fontSize: 14, fontWeight: FontWeight.bold))))),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: List.generate(habits.length, (hIdx) => Row(
                          children: List.generate(31, (dIdx) => GestureDetector(
                            onTap: () => _handleEntry(hIdx, dIdx),
                            child: Container(
                                width: 55, height: 70,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white.withOpacity(0.01)),
                                  color: (dIdx + 1) == currentDay ? cyan.withOpacity(0.03) : Colors.transparent,
                                ),
                                child: _getIcon(habits[hIdx]["data"][dIdx], dIdx + 1)
                            ),
                          )),
                        )),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildIndividualDashboard() {
    final task = habits[selectedTaskIndex!];
    return Column(
      children: [
        ListTile(
          leading: IconButton(onPressed: () => setState(() => selectedTaskIndex = null), icon: Icon(Icons.arrow_back_ios_new, color: cyan, size: 20)),
          title: Text(task["name"], style: TextStyle(color: gold, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 2)),
          trailing: Text("🎯 TARGET: 31/31", style: TextStyle(color: cyan.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        _buildGraph(task),
        const SizedBox(height: 20),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(15), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 12, crossAxisSpacing: 12),
            itemCount: 31,
            itemBuilder: (context, i) => GestureDetector(
              onTap: () => _handleEntry(selectedTaskIndex!, i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                    color: const Color(0xFF0B1218), borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: (i+1) == currentDay ? cyan : Colors.white.withOpacity(0.05)),
                    boxShadow: [(i+1) == currentDay ? BoxShadow(color: cyan.withOpacity(0.15), blurRadius: 10) : const BoxShadow(color: Colors.transparent)]
                ),
                child: _getIcon(task["data"][i], i + 1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGraph(var task) => Container(
    height: 90, margin: const EdgeInsets.symmetric(horizontal: 20),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: const Color(0xFF0B1218), borderRadius: BorderRadius.circular(20), border: Border.all(color: cyan.withOpacity(0.1))),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        int dIdx = (currentDay - 7 + i).clamp(0, 30);
        bool isOk = task["data"][dIdx] == "OK";
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: 20, height: isOk ? 45 : 8,
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: isOk ? [cyan, cyan.withOpacity(0.3)] : [Colors.white10, Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: [if(isOk) BoxShadow(color: cyan.withOpacity(0.2), blurRadius: 5)]
              ),
            ),
            const SizedBox(height: 4),
            Text("${dIdx+1}", style: const TextStyle(color: Colors.white24, fontSize: 8)),
          ],
        );
      }),
    ),
  );

  // --- TASK 1: BONE REPLACED WITH 🚫 ---
  Widget _getIcon(String status, int day) {
    if (day > currentDay) return Icon(Icons.lock_clock_outlined, color: gold.withOpacity(0.4), size: 18);
    if (status == "OK") return Icon(Icons.verified, color: cyan, size: 28, shadows: [Shadow(color: cyan, blurRadius: 15)]);
    return const Center(child: Text("🚫", style: TextStyle(fontSize: 18)));
  }

  Widget _buildEnhancedAnimation() => Positioned.fill(
    child: Container(
      color: Colors.black.withOpacity(0.5),
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 1800),
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, double val, child) {
          double rx = -1.5 + (val * 3); double ry = 1.5 - (val * 3);
          double sx = 0.5 - (val * 1.5); double sy = -1.2 + (val * 2.5);

          return Stack(
            children: [
              if (isGain) ...[
                Align(alignment: Alignment(rx - 0.1, ry + 0.1), child: Icon(Icons.auto_awesome, color: cyan.withOpacity(0.3), size: 50 * val)),
                Align(alignment: Alignment(rx, ry), child: Transform.rotate(angle: -math.pi / 4, child: Icon(Icons.rocket_launch, color: cyan, size: 90, shadows: [Shadow(color: cyan, blurRadius: 40)]))),
              ] else ...[
                Align(alignment: Alignment(sx + 0.1, sy - 0.1), child: Icon(Icons.brightness_3, color: Colors.red.withOpacity(0.2), size: 30)),
                Align(alignment: Alignment(sx, sy), child: Transform.rotate(angle: val * 4, child: Icon(Icons.star, color: Color.lerp(gold, Colors.red, val), size: 85 * (1 - (val * 0.4)), shadows: [Shadow(color: Colors.orange, blurRadius: 25 * (1 - val))]))),
              ],
              Center(
                child: Opacity(
                  opacity: (1 - (val - 0.5).abs() * 2).clamp(0, 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: isGain ? [Colors.black, cyan.withOpacity(0.2)] : [Colors.black, Colors.red.withOpacity(0.2)]),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: isGain ? cyan : hotPink, width: 2.5),
                        boxShadow: [BoxShadow(color: isGain ? cyan : hotPink, blurRadius: 20)]
                    ),
                    child: Text(animMsg, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );

  void _showAddDialog() {
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF0B1218),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: BorderSide(color: cyan.withOpacity(0.3))),
      title: Text("DEPLOY MISSION 🚀", style: TextStyle(color: cyan, fontWeight: FontWeight.bold)),
      content: TextField(controller: _habitController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "Objective Name...", hintStyle: TextStyle(color: Colors.white10))),
      actions: [TextButton(onPressed: () {
        if (_habitController.text.isNotEmpty) {
          setState(() => habits.add({"name": _habitController.text.toUpperCase(), "data": List.generate(31, (i) => "EMPTY")}));
          _saveData(); _habitController.clear(); Navigator.pop(context);
        }
      }, child: Text("INITIALIZE", style: TextStyle(color: cyan, fontWeight: FontWeight.bold)))],
    ));
  }
}