import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- 1. NOTIFICATION CONTROLLER ---
class NotificationController {
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(ReceivedAction action) async {
    final prefs = await SharedPreferences.getInstance();
    if (action.buttonKeyPressed == 'ACCEPT') {
      int currentXp = prefs.getInt('xp') ?? 0;
      await prefs.setInt('xp', currentXp + 20);

      if (action.payload?['repeat'] == 'Once') {
        final dbPath = await getDatabasesPath();
        final path = p.join(dbPath, 'quest_final_v12.db');
        final db = await openDatabase(path);
        int taskId = int.parse(action.payload!['id']!);
        await db.delete('tasks', where: 'id = ?', whereArgs: [taskId]);
      }
    }
    await AwesomeNotifications().dismiss(action.id!);
  }
}

// --- 2. DATABASE LAYER ---
class TaskDatabase {
  static final TaskDatabase instance = TaskDatabase._init();
  static Database? _database;
  TaskDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('quest_final_v12.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE tasks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT, description TEXT, label TEXT, time TEXT, date TEXT, repeat TEXT
        )
      ''');
    });
  }

  Future<int> addTask(Map<String, dynamic> task) async {
    final db = await instance.database;
    return await db.insert('tasks', task);
  }

  Future<List<Map<String, dynamic>>> fetchTasks() async {
    final db = await instance.database;
    return await db.query('tasks', orderBy: 'id DESC');
  }

  Future<int> deleteTask(int id) async {
    final db = await instance.database;
    await AwesomeNotifications().cancel(id);
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}

// --- 3. MAIN UI ---
class TaskPage extends StatefulWidget {
  const TaskPage({super.key});
  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  bool _isAllowed = false;
  List<Map<String, dynamic>> _tasks = [];
  String _selectedFilter = "All";
  String _selectedRepeat = "Once";
  final Color cyan = Colors.cyanAccent;
  int _xp = 0;
  int _level = 1;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _initNotifications();
    _refreshData();
  }

  void _checkPermissions() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    setState(() { _isAllowed = isAllowed; });
  }

  void _initNotifications() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'task_alarm_final',
          channelName: 'Quest Alarms',
          channelDescription: 'RPG Calling Style Alerts',
          importance: NotificationImportance.Max,
          defaultRingtoneType: DefaultRingtoneType.Alarm,
          criticalAlerts: true,
          playSound: true,
          soundSource: 'resource://raw/ringtone',
          locked: true,
          defaultColor: Colors.cyanAccent,
        )
      ],
    );
    AwesomeNotifications().setListeners(onActionReceivedMethod: NotificationController.onActionReceivedMethod);
  }

  _refreshData() async {
    final data = await TaskDatabase.instance.fetchTasks();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tasks = data;
      _xp = prefs.getInt('xp') ?? 0;
      _level = (_xp / 100).floor() + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Permission screen if not allowed
    if (!_isAllowed) {
      return _buildPermissionScreen();
    }

    Set<String> labels = {"All", ..._tasks.map((e) => e['label'].toString())};

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset("assets/bg.jpeg", fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.7), colorBlendMode: BlendMode.darken,
              errorBuilder: (c,e,s) => Container(color: Colors.black))),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildFilter(labels.toList()),
                Expanded(child: _buildList()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: cyan,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add, color: Colors.black, size: 30),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildPermissionScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.security, color: cyan, size: 80),
              const SizedBox(height: 20),
              Text("AUTHORIZATION REQUIRED", style: TextStyle(color: cyan, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              const Text("Enable 'Display over other apps' and 'Alarms' to start your journey.",
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: cyan),
                onPressed: () async {
                  await AwesomeNotifications().requestPermissionToSendNotifications(
                    permissions: [
                      NotificationPermission.Alert, NotificationPermission.Sound,
                      NotificationPermission.CriticalAlert, NotificationPermission.FullScreenIntent,
                      NotificationPermission.PreciseAlarms, NotificationPermission.OverrideDnD,
                    ],
                  );
                  _checkPermissions();
                },
                child: const Text("GRANT PERMISSIONS", style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("QUESTLOG-⚔️", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 15)])),
          const SizedBox(height: 10),
          Text("LEVEL $_level", style: TextStyle(color: cyan, fontSize: 18, fontWeight: FontWeight.bold)),
          LinearProgressIndicator(value: (_xp % 100) / 100, backgroundColor: Colors.white10, color: cyan, minHeight: 8),
          Align(alignment: Alignment.centerRight, child: Text("XP $_xp", style: TextStyle(color: cyan, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildFilter(List<String> labels) {
    return SizedBox(height: 50, child: ListView(scrollDirection: Axis.horizontal, children: labels.map((l) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ChoiceChip(label: Text(l), selected: _selectedFilter == l, onSelected: (v) => setState(() => _selectedFilter = l), selectedColor: cyan),
    )).toList()));
  }

  Widget _buildList() {
    final list = _selectedFilter == "All" ? _tasks : _tasks.where((t) => t['label'] == _selectedFilter).toList();
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (ctx, i) => Card(
        color: Colors.white10, margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: cyan.withOpacity(0.2))),
        child: ListTile(
          title: Text(list[i]['title'], style: TextStyle(color: cyan, fontWeight: FontWeight.bold)),
          subtitle: Text("${list[i]['description']}\nMode: ${list[i]['repeat']} | ${list[i]['time']}", style: const TextStyle(color: Colors.white60)),
          trailing: IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.redAccent), onPressed: () async {
            await TaskDatabase.instance.deleteTask(list[i]['id']);
            _refreshData();
          }),
        ),
      ),
    );
  }

  void _showAddDialog() {
    TextEditingController t = TextEditingController(), d = TextEditingController(), l = TextEditingController();
    DateTime? sd; TimeOfDay? st;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (dCtx, setS) => AlertDialog(
      backgroundColor: Colors.grey[900], title: Text("ASSIGN MISSION", style: TextStyle(color: cyan)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _input(t, "Title"), _input(d, "Description"), _input(l, "Label"),
        const SizedBox(height: 10),
        DropdownButton<String>(
          value: _selectedRepeat, dropdownColor: Colors.grey[850], style: TextStyle(color: cyan),
          items: ["Once", "Daily", "Weekly", "Monthly"].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) => setS(() => _selectedRepeat = v!),
        ),
        ListTile(title: Text(sd == null ? "Select Date" : DateFormat('yyyy-MM-dd').format(sd!), style: const TextStyle(color: Colors.white)), onTap: () async { sd = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030)); setS(() {}); }),
        ListTile(title: Text(st == null ? "Select Time" : st!.format(context), style: const TextStyle(color: Colors.white)), onTap: () async { st = await showTimePicker(context: context, initialTime: TimeOfDay.now()); setS(() {}); }),
      ])),
      actions: [ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: cyan), onPressed: () async {
        if (t.text.isNotEmpty && sd != null && st != null) {
          int id = await TaskDatabase.instance.addTask({
            'title': t.text, 'description': d.text, 'label': l.text.isEmpty ? "General" : l.text,
            'time': st!.format(context), 'date': DateFormat('yyyy-MM-dd').format(sd!), 'repeat': _selectedRepeat
          });
          _schedule(id, t.text, d.text, l.text, sd!, st!, _selectedRepeat);
          _refreshData(); Navigator.pop(ctx);
        }
      }, child: const Text("START MISSION", style: TextStyle(color: Colors.black)))],
    )));
  }

  void _schedule(int id, String title, String desc, String label, DateTime d, TimeOfDay t, String repeat) async {
    NotificationCalendar schedule;
    if (repeat == "Once") {
      schedule = NotificationCalendar.fromDate(date: DateTime(d.year, d.month, d.day, t.hour, t.minute));
    } else if (repeat == "Daily") {
      schedule = NotificationCalendar(hour: t.hour, minute: t.minute, second: 0, repeats: true);
    } else if (repeat == "Weekly") {
      schedule = NotificationCalendar(weekday: d.weekday, hour: t.hour, minute: t.minute, second: 0, repeats: true);
    } else {
      schedule = NotificationCalendar(day: d.day, hour: t.hour, minute: t.minute, second: 0, repeats: true);
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id, channelKey: 'task_alarm_final', title: "⚔️ QUEST LOG: $title",
        body: "CATEGORY: $label\n$desc", payload: {"id": id.toString(), "repeat": repeat},
        category: NotificationCategory.Alarm, wakeUpScreen: true, fullScreenIntent: true,
        customSound: 'resource://raw/ringtone', autoDismissible: false,
      ),
      actionButtons: [
        NotificationActionButton(key: 'ACCEPT', label: 'ACCEPT QUEST', color: cyan, actionType: ActionType.Default),
        NotificationActionButton(key: 'DECLINE', label: 'ABANDON', color: Colors.redAccent, actionType: ActionType.DismissAction),
      ],
      schedule: schedule,
    );
  }

  Widget _input(TextEditingController c, String h) => TextField(controller: c, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: h, hintStyle: const TextStyle(color: Colors.white24)));
}
