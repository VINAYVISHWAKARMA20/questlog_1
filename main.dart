import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(QuestLogApp());
}

class QuestLogApp extends StatefulWidget {
  @override
  State<QuestLogApp> createState() => _QuestLogAppState();
}

class _QuestLogAppState extends State<QuestLogApp> {
  bool isDarkMode = true;
  double appFontSize = 16.0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // --- DUAL THEME ENGINE (Purple Light / Blue Dark) ---
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.purple,
        scaffoldBackgroundColor: const Color(0xFFF3E5F5), // Premium Lavender
        colorScheme: ColorScheme.light(
          primary: Colors.purple,
          secondary: Colors.deepPurpleAccent,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.purple, foregroundColor: Colors.white),
        cardColor: Colors.white,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.cyanAccent,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.blueAccent,
          surface: const Color(0xFF121212),
        ),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black, foregroundColor: Colors.cyanAccent),
        cardColor: const Color(0xFF1E1E1E),
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: MainNavigation(
        isDarkMode: isDarkMode,
        toggleTheme: (v) => setState(() => isDarkMode = v),
        fontSize: appFontSize,
        updateFontSize: (v) => setState(() => appFontSize = v),
      ),
    );
  }
}

// --- DATABASE HANDLER ---
class DBHelper {
  static Future<Database> db() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(p.join(dbPath, 'quest_log_final_v5.db'),
        version: 1,
        onCreate: (db, version) async {
          await db.execute("CREATE TABLE tasks(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, description TEXT, label TEXT, date TEXT, time TEXT, hour INTEGER, minute INTEGER, is_done INTEGER DEFAULT 0)");
          await db.execute("CREATE TABLE habit_list(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)");
          await db.execute("CREATE TABLE habit_logs(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, day TEXT, status INTEGER)");
        });
  }

  static Future<void> insertTask(String t, String desc, String l, String d, String tm, int h, int m) async {
    final database = await db();
    await database.insert('tasks', {'title': t, 'description': desc, 'label': l, 'date': d, 'time': tm, 'hour': h, 'minute': m, 'is_done': 0});
  }
  static Future<void> updateTaskStatus(int id, int status) async {
    final database = await db();
    await database.update('tasks', {'is_done': status}, where: "id = ?", whereArgs: [id]);
  }
  static Future<void> deleteTask(int id) async {
    final database = await db();
    await database.delete('tasks', where: "id = ?", whereArgs: [id]);
  }
  static Future<List<Map<String, dynamic>>> queryTasks() async => (await db()).query('tasks', orderBy: 'id DESC');

  static Future<void> addHabitName(String name) async {
    final database = await db();
    await database.insert('habit_list', {'name': name});
  }
  static Future<void> deleteHabit(String name) async {
    final database = await db();
    await database.delete('habit_list', where: "name = ?", whereArgs: [name]);
    await database.delete('habit_logs', where: "name = ?", whereArgs: [name]);
  }
  static Future<List<Map<String, dynamic>>> getHabitNames() async => (await db()).query('habit_list');

  static Future<void> toggleHabitLog(String name, String day) async {
    final database = await db();
    var existing = await database.query('habit_logs', where: "name = ? AND day = ?", whereArgs: [name, day]);
    if (existing.isEmpty) {
      await database.insert('habit_logs', {'name': name, 'day': day, 'status': 1});
    } else {
      int newStatus = existing.first['status'] == 1 ? 0 : 1;
      await database.update('habit_logs', {'status': newStatus}, where: "id = ?", whereArgs: [existing.first['id']]);
    }
  }
  static Future<List<Map<String, dynamic>>> getHabitLogs() async => (await db()).query('habit_logs');
}

class MainNavigation extends StatefulWidget {
  final bool isDarkMode; final Function(bool) toggleTheme;
  final double fontSize; final Function(double) updateFontSize;
  MainNavigation({required this.isDarkMode, required this.toggleTheme, required this.fontSize, required this.updateFontSize});
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 1;
  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;
    final List<Widget> _screens = [
      Center(child: Text("STAY TUNED FOR XP SYSTEM", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold))),
      TasksScreen(fontSize: widget.fontSize),
      HabitTrackerScreen(),
      SettingsScreen(isDark: widget.isDarkMode, onThemeChanged: widget.toggleTheme, fontSize: widget.fontSize, onFontChanged: widget.updateFontSize),
    ];
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex, onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: accentColor, unselectedItemColor: Colors.grey,
        backgroundColor: Theme.of(context).cardColor, type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bolt), label: "Stats"),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded), label: "Quests"),
          BottomNavigationBarItem(icon: Icon(Icons.grid_4x4_rounded), label: "Habits"),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: "Settings"),
        ],
      ),
    );
  }
}

// --- HABIT TRACKER SCREEN ---
class HabitTrackerScreen extends StatefulWidget {
  @override
  _HabitTrackerScreenState createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen> {
  List<String> habitNames = [];
  Map<String, List<String>> habitLogs = {};
  List<String> daysInMonth = List.generate(31, (index) => (index + 1).toString());

  @override
  void initState() { super.initState(); _loadData(); }

  void _loadData() async {
    var names = await DBHelper.getHabitNames();
    var logs = await DBHelper.getHabitLogs();
    Map<String, List<String>> tempLogs = {};
    for (var row in logs) {
      if (row['status'] == 1) {
        tempLogs.putIfAbsent(row['name'] as String, () => []).add(row['day'] as String);
      }
    }
    setState(() {
      habitNames = names.map((e) => e['name'] as String).toList();
      habitLogs = tempLogs;
    });
  }

  void _deleteHabitDialog(String name) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: const Text("Delete Habit?", style: TextStyle(color: Colors.red)),
      content: Text("Do you want to remove '$name'?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel", style: TextStyle(color: Theme.of(context).colorScheme.primary))),
        TextButton(onPressed: () async {
          await DBHelper.deleteHabit(name); _loadData(); Navigator.pop(ctx);
        }, child: const Text("Delete", style: TextStyle(color: Colors.red))),
      ],
    ));
  }

  void _showExpandedGraph() {
    final accent = Theme.of(context).colorScheme.primary;
    showDialog(context: context, builder: (ctx) => Dialog.fullscreen(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Scaffold(
        appBar: AppBar(title: const Text("PERFORMANCE MATRIX"), leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx))),
        body: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: daysInMonth.map((day) {
            int count = 0; habitLogs.forEach((k, v) { if (v.contains(day)) count++; });
            double h = habitNames.isEmpty ? 0 : (count / habitNames.length) * 400;
            return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text("${((h/400)*100).toInt()}%", style: TextStyle(fontSize: 10, color: accent)),
              Container(width: 30, height: h.clamp(5, 400), decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(4)), margin: const EdgeInsets.symmetric(horizontal: 10)),
              const SizedBox(height: 10), Text(day, style: const TextStyle(fontSize: 12)), const SizedBox(height: 20),
            ]);
          }).toList()),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text("HABIT GRID"), actions: [IconButton(icon: const Icon(Icons.add_circle), onPressed: _addManualHabit)]),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 140, color: Theme.of(context).scaffoldBackgroundColor,
                  child: ListView(
                    children: [
                      Container(
                        height: 56, alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.2)), color: accent.withOpacity(0.1)),
                        child: Text("GOALS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: accent, letterSpacing: 1.5)),
                      ),
                      ...habitNames.map((habit) => GestureDetector(
                        onLongPress: () => _deleteHabitDialog(habit),
                        child: Container(
                          height: 52, alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.2))),
                          child: Text(habit, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      )),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 31 * 55.0,
                      child: ListView(
                        children: [
                          Row(
                            children: daysInMonth.map((d) => Container(
                              width: 55, height: 56, alignment: Alignment.center,
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.2)), color: accent.withOpacity(0.1)),
                              child: Text(d, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            )).toList(),
                          ),
                          ...habitNames.map((habit) => Row(
                            children: daysInMonth.map((day) {
                              bool isDone = habitLogs[habit]?.contains(day) ?? false;
                              return GestureDetector(
                                onTap: () async { await DBHelper.toggleHabitLog(habit, day); _loadData(); },
                                child: Container(
                                  width: 55, height: 52,
                                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.2))),
                                  child: Icon(isDone ? Icons.check_circle : Icons.circle_outlined, color: isDone ? accent : Colors.grey[400], size: 26),
                                ),
                              );
                            }).toList(),
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showExpandedGraph,
            child: Container(
              height: 90, width: double.infinity, color: accent.withOpacity(0.05),
              child: Column(children: [
                const Padding(padding: EdgeInsets.all(6.0), child: Text("TAP TO OPEN PERFORMANCE MATRIX", style: TextStyle(fontSize: 9, color: Colors.grey))),
                Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.end, children: daysInMonth.take(15).map((day) {
                  int count = 0; habitLogs.forEach((k, v) { if (v.contains(day)) count++; });
                  double h = habitNames.isEmpty ? 0 : (count / habitNames.length) * 45;
                  return Container(width: 8, height: h.clamp(2, 45), decoration: BoxDecoration(color: accent.withOpacity(0.4), borderRadius: BorderRadius.circular(2)));
                }).toList())),
                const SizedBox(height: 5),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _addManualHabit() {
    TextEditingController hC = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: Text("New Habit", style: TextStyle(color: Theme.of(context).colorScheme.primary)),
      content: TextField(controller: hC, autofocus: true, decoration: const InputDecoration(hintText: "E.g. Yoga")),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
        ElevatedButton(onPressed: () async {
          if(hC.text.isNotEmpty) { await DBHelper.addHabitName(hC.text); _loadData(); Navigator.pop(ctx); }
        }, child: const Text("Add")),
      ],
    ));
  }
}

// --- TASKS SCREEN (Fixed with Dynamic Labels Filter) ---
class TasksScreen extends StatefulWidget {
  final double fontSize;
  TasksScreen({required this.fontSize});
  @override
  _TasksScreenState createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Map<String, dynamic>> _allTasks = [];
  List<Map<String, dynamic>> _filteredTasks = [];
  List<String> _dynamicFilters = ["All"];
  String _selectedFilter = "All";
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _lastAlertId;

  @override
  void initState() { super.initState(); _load(); _startChecker(); }

  void _load() async {
    final d = await DBHelper.queryTasks();

    // Dynamic Label logic: Collect unique labels from database
    Set<String> uniqueLabels = {"All"};
    for (var task in d) {
      if (task['label'] != null && task['label'].toString().trim().isNotEmpty) {
        uniqueLabels.add(task['label']);
      }
    }

    setState(() {
      _allTasks = d;
      _dynamicFilters = uniqueLabels.toList();
      _applyFilter(_selectedFilter);
    });
  }

  void _applyFilter(String f) {
    setState(() {
      _selectedFilter = f;
      if (f == "All") {
        _filteredTasks = _allTasks;
      } else {
        _filteredTasks = _allTasks.where((t) => t['label'] == f).toList();
      }
    });
  }

  void _startChecker() {
    _timer = Timer.periodic(const Duration(seconds: 10), (t) {
      DateTime now = DateTime.now();
      String today = DateFormat('dd-MM-yyyy').format(now);
      for (var task in _allTasks) {
        if (task['is_done'] == 0 && task['date'] == today && task['hour'] == now.hour && task['minute'] == now.minute && _lastAlertId != task['id']) {
          _lastAlertId = task['id'];
          _showCall(task['id'], task['title'], task['label']);
          break;
        }
      }
    });
  }

  void _stopAndPop(BuildContext ctx) async {
    await _audioPlayer.stop();
    await _audioPlayer.release();
    Navigator.of(ctx, rootNavigator: true).pop();
  }

  void _showCall(int id, String title, String label) async {
    final accent = Theme.of(context).colorScheme.primary;
    try {
      await _audioPlayer.setSource(AssetSource('ringtone.mp3'));
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.resume();
    } catch (e) { print(e); }

    showGeneralDialog(
      context: context, barrierDismissible: false, useRootNavigator: true,
      pageBuilder: (ctx, a1, a2) => Scaffold(
        backgroundColor: Colors.black,
        body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Spacer(),
          Icon(Icons.warning_amber_rounded, size: 100, color: accent),
          const SizedBox(height: 20),
          Text("MISSION CALL: $label", style: TextStyle(color: accent, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
          const Spacer(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size(130, 50)),
                onPressed: () => _stopAndPop(ctx), child: const Text("DISMISS", style: TextStyle(color: Colors.white))),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(130, 50)),
                onPressed: () async {
                  await DBHelper.updateTaskStatus(id, 1); _load(); _stopAndPop(ctx);
                }, child: const Text("DONE", style: TextStyle(color: Colors.white))),
          ]),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text("MISSION LOG"), centerTitle: true),
      floatingActionButton: FloatingActionButton(backgroundColor: accent, onPressed: () => _addTask(), child: const Icon(Icons.add, color: Colors.white)),
      body: Column(
        children: [
          // WhatsApp Style Dynamic Filter Bar
          Container(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _dynamicFilters.length,
              itemBuilder: (ctx, i) {
                bool isSel = _selectedFilter == _dynamicFilters[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                  child: ChoiceChip(
                    label: Text(_dynamicFilters[i]),
                    selected: isSel,
                    onSelected: (v) => _applyFilter(_dynamicFilters[i]),
                    selectedColor: accent,
                    labelStyle: TextStyle(color: isSel ? Colors.white : accent, fontWeight: isSel ? FontWeight.bold : FontWeight.normal),
                    backgroundColor: accent.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _filteredTasks.isEmpty
                ? Center(child: Text("No Quests in '$_selectedFilter'"))
                : ListView.builder(itemCount: _filteredTasks.length, itemBuilder: (ctx, i) {
              var task = _filteredTasks[i];
              bool isDone = task['is_done'] == 1;
              String desc = task['description'] ?? "";
              return Dismissible(
                key: Key(task['id'].toString()),
                direction: DismissDirection.endToStart,
                background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                onDismissed: (dir) async { await DBHelper.deleteTask(task['id']); _load(); },
                child: Card(
                  elevation: isDone ? 0 : 2,
                  color: isDone ? Colors.transparent : Theme.of(context).cardColor,
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: Checkbox(activeColor: accent, value: isDone, onChanged: (v) async { await DBHelper.updateTaskStatus(task['id'], v! ? 1 : 0); _load(); }),
                    title: Text(task['title'], style: TextStyle(fontSize: widget.fontSize, fontWeight: FontWeight.bold, decoration: isDone ? TextDecoration.lineThrough : null)),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("${task['date']} @ ${task['time']}", style: const TextStyle(fontSize: 12)),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                      ]
                    ]),
                    trailing: Text(task['label'], style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _addTask() {
    final accent = Theme.of(context).colorScheme.primary;
    TextEditingController c = TextEditingController();
    TextEditingController dC = TextEditingController();
    TextEditingController l = TextEditingController();
    TimeOfDay tTime = TimeOfDay.now(); DateTime dDate = DateTime.now();
    List<String> suggestedLabels = ["Work", "Gym", "Study", "Coding"];

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Theme.of(context).cardColor, builder: (ctx) => StatefulBuilder(
      builder: (context, setST) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(controller: c, decoration: const InputDecoration(hintText: "Mission Name")),
            const SizedBox(height: 10),
            TextField(controller: dC, maxLines: 2, maxLength: 300, decoration: const InputDecoration(hintText: "Description (Optional)")),
            const SizedBox(height: 15),
            const Text("Quick Labels:", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Container(height: 40, child: ListView(scrollDirection: Axis.horizontal, children: suggestedLabels.map((sl) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(label: Text(sl), onPressed: () => setST(() => l.text = sl), backgroundColor: l.text == sl ? accent : null, labelStyle: TextStyle(color: l.text == sl ? Colors.white : null)),
            )).toList())),
            TextField(controller: l, decoration: const InputDecoration(hintText: "Custom Label...")),
            const SizedBox(height: 15),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              TextButton.icon(icon: const Icon(Icons.calendar_today), label: Text(DateFormat('dd-MM-yyyy').format(dDate)),
                  onPressed: () async {
                    final p = await showDatePicker(context: ctx, initialDate: dDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
                    if(p != null) setST(() => dDate = p);
                  }),
              TextButton.icon(icon: const Icon(Icons.access_time), label: Text(tTime.format(ctx)),
                  onPressed: () async {
                    final p = await showTimePicker(context: ctx, initialTime: tTime);
                    if(p != null) setST(() => tTime = p);
                  }),
            ]),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: accent, minimumSize: const Size(double.infinity, 45)),
                onPressed: () async {
                  if(c.text.isEmpty) return;
                  await DBHelper.insertTask(c.text, dC.text, l.text.isEmpty ? "Quest" : l.text, DateFormat('dd-MM-yyyy').format(dDate), tTime.format(ctx), tTime.hour, tTime.minute);
                  _load(); Navigator.pop(ctx);
                }, child: const Text("INITIALIZE QUEST", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    ));
  }
}

class SettingsScreen extends StatelessWidget {
  final bool isDark; final Function(bool) onThemeChanged;
  final double fontSize; final Function(double) onFontChanged;
  SettingsScreen({required this.isDark, required this.onThemeChanged, required this.fontSize, required this.onFontChanged});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("SETTINGS")),
    body: Column(children: [
      SwitchListTile(title: const Text("Dark Mode"), value: isDark, onChanged: onThemeChanged, activeColor: Theme.of(context).colorScheme.primary),
      const SizedBox(height: 20),
      const Text("Adjust Font Size", style: TextStyle(fontWeight: FontWeight.bold)),
      Slider(min: 14, max: 24, value: fontSize, onChanged: onFontChanged, activeColor: Theme.of(context).colorScheme.primary),
    ]),
  );
}