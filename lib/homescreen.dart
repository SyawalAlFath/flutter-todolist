import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fluttertokoonline/auth_service.dart';
import 'package:fluttertokoonline/signin_screen.dart';
import 'package:fluttertokoonline/google_calendar_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'google_http_client.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Map<String, dynamic>> todoList = [];
  final TextEditingController _controller = TextEditingController();
  int updateIndex = -1;
  GoogleSignInAccount? _googleUser;
  final GoogleCalendarService _calendarService = GoogleCalendarService();

  @override
  void initState() {
    super.initState();
    _initGoogleSignInUser();
  }

  Future<void> _loadTasksFromFirestore(User user) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .orderBy('createdAt')
        .get();

    setState(() {
      todoList = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'title': doc['title'],
          'eventId': doc['eventId'],
        };
      }).toList();
    });
  }

  void _initGoogleSignInUser() async {
  try {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final googleSignIn = GoogleSignIn();
    final googleUser = googleSignIn.currentUser ?? await googleSignIn.signIn();

    if (firebaseUser != null) {
      setState(() {
        _googleUser = googleUser;
      });
      await _loadTasksFromFirestore(firebaseUser);
    } else {
      print("User belum login ke Firebase.");
    }
  } catch (e) {
    print("Gagal inisialisasi user: $e");
  }
}


  void addList(String task) async {
    if (task.trim().isEmpty || _googleUser == null) return;

    final currentUser = FirebaseAuth.instance.currentUser!;
    final authHeaders = await _googleUser!.authHeaders;
    final calendarApi = calendar.CalendarApi(GoogleHttpClient(authHeaders));

    final event = calendar.Event(
      summary: task,
      start: calendar.EventDateTime(
        dateTime: DateTime.now().add(const Duration(minutes: 5)),
        timeZone: "Asia/Jakarta",
      ),
      end: calendar.EventDateTime(
        dateTime: DateTime.now().add(const Duration(minutes: 65)),
        timeZone: "Asia/Jakarta",
      ),
    );

    final createdEvent = await calendarApi.events.insert(event, "primary");
    final eventId = createdEvent.id;

    final newDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('tasks')
        .add({
      'title': task,
      'createdAt': Timestamp.now(),
      'eventId': eventId,
    });

    final newTask = {
      'id': newDoc.id,
      'title': task,
      'eventId': eventId,
    };

    setState(() {
      todoList.insert(0, newTask);
      _controller.clear();
    });
    _listKey.currentState?.insertItem(0);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Task berhasil ditambahkan!")),
    );
  }

  void deleteItem(int index) async {
    final task = todoList[index];
    final docId = task['id'];
    final eventId = task['eventId'];

    final currentUser = FirebaseAuth.instance.currentUser!;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('tasks')
        .doc(docId)
        .delete();

    if (_googleUser != null && eventId != null) {
      final authHeaders = await _googleUser!.authHeaders;
      final calendarApi = calendar.CalendarApi(GoogleHttpClient(authHeaders));
      await calendarApi.events.delete("primary", eventId);
    }

    final removedTask = todoList.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => SizeTransition(
        sizeFactor: animation,
        child: _buildTaskCard(removedTask, index),
      ),
    );
  }

  void updateListItem(String newTitle, int index) async {
    final docId = todoList[index]['id'];
    final eventId = todoList[index]['eventId'];

    setState(() {
      todoList[index]['title'] = newTitle;
      updateIndex = -1;
      _controller.clear();
    });

    final currentUser = FirebaseAuth.instance.currentUser!;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('tasks')
        .doc(docId)
        .update({'title': newTitle});

    if (_googleUser != null && eventId != null) {
      final authHeaders = await _googleUser!.authHeaders;
      final calendarApi = calendar.CalendarApi(GoogleHttpClient(authHeaders));
      final event = await calendarApi.events.get("primary", eventId);
      event.summary = newTitle;
      await calendarApi.events.update(event, "primary", eventId);
    }
  }

  void _signOut(BuildContext context) async {
    await AuthService().signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreen()),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          title: Text(
            task['title'],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/PawnBlue.png',
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          trailing: Wrap(
            spacing: 12,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.orange),
                onPressed: () {
                  _controller.text = task['title'];
                  setState(() => updateIndex = index);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => deleteItem(index),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TodoList Application", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25)),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Container(
        margin: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              flex: 90,
              child: AnimatedList(
                key: _listKey,
                initialItemCount: todoList.length,
                itemBuilder: (context, index, animation) {
                  return SizeTransition(
                    sizeFactor: animation,
                    child: _buildTaskCard(todoList[index], index),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 70,
                    child: SizedBox(
                      height: 58,
                      child: TextFormField(
                        controller: _controller,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Buat Taskmu.....',
                          hintStyle: const TextStyle(fontWeight: FontWeight.w500),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    onPressed: () {
                      updateIndex != -1
                          ? updateListItem(_controller.text, updateIndex)
                          : addList(_controller.text);
                    },
                    child: Icon(updateIndex != -1 ? Icons.edit : Icons.add),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}