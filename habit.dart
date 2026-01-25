import 'dart:ui';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

void main() => runApp(const MaterialApp(home: HabitPage(), debugShowCheckedModeBanner: false));

class HabitPage extends StatefulWidget {
  const HabitPage({super.key});
  @override
  State<HabitPage> createState() => _HabitPageState();
}

class _HabitPageState extends State<HabitPage> {
  final TextEditingController _habitController = TextEditingController();
  final ScrollController _dateScrollController = ScrollController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  int hp = 100, xp = 0, level = 1;
  int? selectedTaskIndex;
  int currentDay = DateTime.now().day;
  late int daysInMonth;

  List<Map<String, dynamic>> habits = [];
  bool showAnim = false;
  bool isGain = true;
  String animMsg = "";

  final Color gold = const Color(0xFFFFD700);
  final Color cyan = Colors.cyanAccent;
  final Color neonGreen = const Color(0xFF39FF14);
  final Color brightOrange = const Color(0xFFFFAC1C);

  @override
  void initState() {
    super.initState();
    daysInMonth = DateUtils.getDaysInMonth(DateTime.now().year, DateTime.now().month);
    _loadData().then((_) => _scrollToToday());
  }

  void _scrollToToday() {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (_dateScrollController.hasClients) {
        double cellWidth = 65.0;
        double screenWidth = MediaQuery.of(context).size.width;
        double offset = (currentDay - 1) * cellWidth;
        double finalOffset = (offset - (screenWidth / 2) + 150).clamp(0.0, _dateScrollController.position.maxScrollExtent);

        _dateScrollController.animateTo(
            finalOffset,
            duration: const Duration(seconds: 1),
            curve: Curves.easeOutQuart
        );
      }
    });
  }

  _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hp = prefs.getInt('hp') ?? 100;
      xp = prefs.getInt('xp') ?? 0;
      level = (xp / 500).floor() + 1;
      String? saved = prefs.getString('my_habits');
      if (saved != null) {
        habits = List<Map<String, dynamic>>.from(json.decode(saved));
        for (var h in habits) {
          if (h["data"].length != daysInMonth) {
            h["data"] = List.generate(daysInMonth, (i) => "EMPTY");
          }
        }
      }
    });
  }

  _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('my_habits', json.encode(habits));
    prefs.setInt('hp', hp);
    prefs.setInt('xp', xp);
  }

  void _playSound(String fileName) async {
    try { await _audioPlayer.stop(); await _audioPlayer.play(AssetSource(fileName)); } catch (e) {}
  }

  void _handleEntry(int hIdx, int dIdx) {
    int dayClicked = dIdx + 1;
    if (dayClicked > currentDay) return;

    setState(() {
      if (habits[hIdx]["data"][dIdx] == "OK") {
        habits[hIdx]["data"][dIdx] = "EMPTY";
        xp = (xp - 50).clamp(0, 999999);
      } else {
        habits[hIdx]["data"][dIdx] = "OK";
        if (dayClicked < currentDay) {
          hp = (hp - 5).clamp(0, 100);
          _playSound('danger.mp3');
          _runAnimation(false, "VITALITY DECREASED: -5 HP ⚠️");
        } else {
          xp += 50;
          _playSound('victory.mp3');
          _runAnimation(true, "MISSION UPDATE: +50 XP 💎");
        }
      }
      level = (xp / 500).floor() + 1;
    });
    _saveData();
  }

  void _runAnimation(bool gain, String msg) {
    setState(() { isGain = gain; animMsg = msg; showAnim = true; });
    Timer(const Duration(milliseconds: 2000), () => setState(() => showAnim = false));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset("assets/setting.jpeg", fit: BoxFit.cover)),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text("✨⚔️QUESTBOARD⚔️✨",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 4, shadows: [Shadow(color: cyan, blurRadius: 20)])),
                const SizedBox(height: 20),
                _buildStats(),
                const SizedBox(height: 15),
                Expanded(child: selectedTaskIndex == null ? _buildMainDashboard() : _buildIndividualView()),
              ],
            ),
          ),
          if (showAnim) _buildRocketOverlay(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: cyan, onPressed: _showAddDialog, mini: true,
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
    );
  }

  Widget _statBox(String label, String val, Color col, IconData icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: col, width: 2),
          boxShadow: [BoxShadow(color: col.withOpacity(0.3), blurRadius: 10)]
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.bold)),
          Icon(icon, color: col, size: 14)
        ]),
        const SizedBox(height: 5),
        FittedBox(child: Text(val, style: TextStyle(color: col, fontSize: 32, fontWeight: FontWeight.w900, shadows: [Shadow(color: col, blurRadius: 10)]))),
      ]),
    ),
  );

  Widget _buildStats() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    child: Row(children: [
      _statBox("VITALITY CORE", "$hp%", brightOrange, Icons.favorite),
      const SizedBox(width: 12),
      _statBox("RANK", "LVL $level", gold, Icons.workspace_premium),
    ]),
  );

  Widget _buildMainDashboard() {
    double missionWidth = MediaQuery.of(context).size.width * 0.3;
    if (missionWidth > 120) missionWidth = 120;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: cyan.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: missionWidth,
            decoration: BoxDecoration(border: Border(right: BorderSide(color: cyan.withOpacity(0.2)))),
            child: Column(
              children: [
                Container(height: 50, alignment: Alignment.center, child: Text("MISSIONS", style: TextStyle(color: cyan, fontSize: 10, fontWeight: FontWeight.bold))),
                Expanded(
                  child: ListView.builder(
                    itemCount: habits.length,
                    itemBuilder: (context, i) => GestureDetector(
                      onTap: () => setState(() => selectedTaskIndex = i),
                      onLongPress: () => _confirmDelete(i),
                      child: Container(
                        height: 75, alignment: Alignment.center,
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
                        child: Text(habits[i]["name"], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _dateScrollController,
              scrollDirection: Axis.horizontal,
              child: Column(
                children: [
                  Container(
                    height: 50,
                    child: Row(children: List.generate(daysInMonth, (i) => Container(
                        width: 65, alignment: Alignment.center,
                        child: Text("${i+1}", style: TextStyle(color: (i+1) == currentDay ? cyan : neonGreen, fontWeight: FontWeight.w900, fontSize: 20))
                    ))),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: List.generate(habits.length, (hIdx) => Row(
                          children: List.generate(daysInMonth, (dIdx) => GestureDetector(
                            onTap: () => _handleEntry(hIdx, dIdx),
                            child: Container(
                                width: 65, height: 75,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                                  color: (dIdx + 1) == currentDay ? cyan.withOpacity(0.15) : Colors.transparent,
                                ),
                                child: _getGridIcon(habits[hIdx]["data"][dIdx], dIdx + 1)
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
    );
  }

  Widget _getGridIcon(String status, int day) {
    if (day > currentDay) return Icon(Icons.lock, color: Colors.white.withOpacity(0.5), size: 18);
    if (status == "OK") return Icon(Icons.check_circle, color: gold, size: 30, shadows: [Shadow(color: gold, blurRadius: 10)]);

    // TODAY NO RESTRICTION
    if (day == currentDay) {
      return Center(child: Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: cyan, boxShadow: [BoxShadow(color: cyan, blurRadius: 10)])));
    }
    // PAST RESTRICTION
    return const Center(child: Text("🚫", style: TextStyle(fontSize: 18)));
  }

  Widget _buildIndividualView() {
    final task = habits[selectedTaskIndex!];
    int completed = task["data"].where((e) => e == "OK").length;
    double progress = completed / daysInMonth;

    return Column(
      children: [
        ListTile(
          leading: IconButton(onPressed: () => setState(() => selectedTaskIndex = null), icon: Icon(Icons.arrow_back, color: cyan)),
          title: Text(task["name"], style: TextStyle(color: gold, fontWeight: FontWeight.w900, fontSize: 22)),
          trailing: IconButton(onPressed: () => _confirmDelete(selectedTaskIndex!), icon: Icon(Icons.delete_sweep, color: brightOrange)),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(15),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisExtent: 80, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: daysInMonth,
            itemBuilder: (context, i) => GestureDetector(
              onTap: () => _handleEntry(selectedTaskIndex!, i),
              child: Container(
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(10), border: Border.all(color: (i+1) == currentDay ? cyan : Colors.white10)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text("${i+1}", style: TextStyle(color: neonGreen, fontWeight: FontWeight.bold)),
                  _getGridIcon(task["data"][i], i + 1),
                ]),
              ),
            ),
          ),
        ),
        _buildPerformanceGraph(progress),
      ],
    );
  }

  Widget _buildPerformanceGraph(double progress) => Container(
    padding: const EdgeInsets.all(25),
    decoration: BoxDecoration(color: Colors.black.withOpacity(0.8), borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text("PERFORMANCE", style: TextStyle(color: neonGreen, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
        Text("${(progress * 100).toInt()}%", style: TextStyle(color: neonGreen, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 12),
      Stack(children: [
        Container(height: 8, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10))),
        AnimatedContainer(duration: const Duration(seconds: 1), height: 8, width: (MediaQuery.of(context).size.width - 50) * progress, decoration: BoxDecoration(color: neonGreen, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: neonGreen, blurRadius: 10)])),
      ]),
    ]),
  );

  Widget _buildRocketOverlay() => Positioned.fill(
    child: Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(isGain ? Icons.rocket_launch : Icons.report_problem, color: isGain ? gold : brightOrange, size: 100, shadows: [Shadow(color: isGain ? gold : brightOrange, blurRadius: 30)]),
          const SizedBox(height: 20),
          Text(animMsg, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ]),
      ),
    ),
  );

  void _showAddDialog() {
    showDialog(context: context, builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(side: BorderSide(color: cyan), borderRadius: BorderRadius.circular(20)),
        title: Text("NEW MISSION", style: TextStyle(color: cyan, fontWeight: FontWeight.bold)),
        content: TextField(controller: _habitController, style: const TextStyle(color: Colors.white)),
        actions: [TextButton(onPressed: () {
          if (_habitController.text.isNotEmpty) {
            setState(() { habits.add({"name": _habitController.text.toUpperCase(), "data": List.generate(daysInMonth, (i) => "EMPTY")}); });
            _saveData(); _habitController.clear(); Navigator.pop(context);
          }
        }, child: Text("START", style: TextStyle(color: cyan)))]
    ));
  }

  void _confirmDelete(int index) {
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: Colors.black,
      title: const Text("DELETE MISSION?", style: TextStyle(color: Colors.red)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("NO", style: TextStyle(color: Colors.white))),
        TextButton(onPressed: () {
          setState(() { habits.removeAt(index); selectedTaskIndex = null; });
          _saveData(); Navigator.pop(context);
        }, child: const Text("YES", style: TextStyle(color: Colors.red))),
      ],
    ));
  }
}
