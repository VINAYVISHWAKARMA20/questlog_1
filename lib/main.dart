import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// App files - Ensure these files exist and class names match!
import 'map.dart';
import 'habit.dart';
import 'task.dart';
import 'setting.dart';

/// ================= GLOBAL XP NOTIFIER =================
ValueNotifier<int> globalXpNotifier = ValueNotifier<int>(0);

@pragma('vm:entry-point')
void alarmCallback() {
  AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: 888,
      channelKey: 'quest_reliable_v4',
      title: "⚔️ MISSION ALERT!",
      body: "Utho Fighter! Mission ka samay ho gaya hai.",
      category: NotificationCategory.Alarm,
      notificationLayout: NotificationLayout.BigText,
      wakeUpScreen: true,
      fullScreenIntent: true,
      criticalAlert: true,
    ),
    actionButtons: [
      NotificationActionButton(key: 'ACCEPT', label: 'COMPLETE', color: Colors.orange),
      NotificationActionButton(key: 'DECLINE', label: 'DISMISS', color: Colors.red),
    ],
  );
}

class NotificationController {
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(ReceivedAction action) async {
    if (action.buttonKeyPressed == 'ACCEPT') {
      final prefs = await SharedPreferences.getInstance();
      int updatedXp = (prefs.getInt('xp') ?? 0) + 20;
      await prefs.setInt('xp', updatedXp);
      globalXpNotifier.value = updatedXp;
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();

  final prefs = await SharedPreferences.getInstance();
  globalXpNotifier.value = prefs.getInt('xp') ?? 0;

  await AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'quest_reliable_v4',
        channelName: 'Missions',
        channelDescription: 'Alarm Alerts',
        importance: NotificationImportance.Max,
        defaultRingtoneType: DefaultRingtoneType.Alarm,
        playSound: true,
        criticalAlerts: true,
        locked: true,
      )
    ],
  );

  AwesomeNotifications().setListeners(
    onActionReceivedMethod: NotificationController.onActionReceivedMethod,
  );

  runApp(const SeaOfDiscipline());
}

class SeaOfDiscipline extends StatelessWidget {
  const SeaOfDiscipline({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.orange),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 2;

  // FIXED: Removed 'const' because screens are dynamic objects
  final List<Widget> _screens = [
    const MapPage(),
    const HabitPage(),
    const TaskPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Habits'),
          BottomNavigationBarItem(icon: Icon(Icons.task_alt), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

}
