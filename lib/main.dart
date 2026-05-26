import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class Task {
  String id;
  String title;
  String day;
  String time;
  String category;
  bool isDone;

  Task({
    this.id = '',
    required this.title,
    required this.day,
    required this.time,
    required this.category,
    this.isDone = false,
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'To Do App',
      theme: ThemeData(useMaterial3: true, fontFamily: 'Arial'),
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLogin = true;
  bool loading = false;

  Future<void> submit() async {
    try {
      setState(() {
        loading = true;
      });

      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StartScreen()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Auth error')));
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7EEF2),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isLogin ? 'Login' : 'Register',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B3F73),
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'Email',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: loading ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B3F73),
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isLogin ? 'Login' : 'Register',
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    isLogin = !isLogin;
                  });
                },
                child: Text(
                  isLogin ? 'Create account' : 'Already have account?',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7EEF2),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 90),
              const Text(
                'My To Do List',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B3F73),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Plan your day',
                style: TextStyle(fontSize: 22, color: Color(0xFF0B3F73)),
              ),
              const SizedBox(height: 80),
              Container(
                width: 190,
                height: 210,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF2F80B7), width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Image.asset('lib/assets/list-icon-1423.png'),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F80B7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TaskScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Start',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  int selectedIndex = 0;
  List<Task> tasks = [];

  // Получаем UID текущего пользователя
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  // Загружаем задачи ТОЛЬКО для конкретного пользователя
  Future<void> loadTasks() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .get();

    setState(() {
      tasks = snapshot.docs.map((doc) {
        final data = doc.data();
        return Task(
          id: doc.id,
          title: data['title'] ?? '',
          day: data['day'] ?? 'Today',
          time: data['time'] ?? '',
          category: data['category'] ?? 'Personal',
          isDone: data['isDone'] ?? false,
        );
      }).toList();
    });
  }

  // Сохраняем задачу в коллекцию конкретного пользователя
  Future<void> saveTaskToFirestore(Task task) async {
    final userTasks = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('tasks');

    if (task.id.isEmpty) {
      final docRef = await userTasks.add({
        'title': task.title,
        'day': task.day,
        'time': task.time,
        'category': task.category,
        'isDone': task.isDone,
      });
      task.id = docRef.id;
    } else {
      await userTasks.doc(task.id).set({
        'title': task.title,
        'day': task.day,
        'time': task.time,
        'category': task.category,
        'isDone': task.isDone,
      });
    }
  }

  List<Task> get visibleTasks {
    if (selectedIndex == 0) {
      return tasks.where((task) => !task.isDone).toList();
    } else if (selectedIndex == 1) {
      return tasks.where((task) => task.isDone).toList();
    } else {
      return tasks;
    }
  }

  int get completedCount {
    return tasks.where((task) => task.isDone).length;
  }

  String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final selectedDate = DateTime(date.year, date.month, date.day);

    if (selectedDate == today) {
      return 'Today';
    } else if (selectedDate == tomorrow) {
      return 'Tomorrow';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  void toggleTask(Task task, bool value) {
    setState(() {
      task.isDone = value;
    });
    saveTaskToFirestore(task);
  }

  // Удаляем задачу из коллекции конкретного пользователя
  void deleteTask(Task task) async {
    setState(() {
      tasks.remove(task);
    });

    if (task.id.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('tasks')
          .doc(task.id)
          .delete();
    }
  }

  void addTask(Task task) {
    setState(() {
      tasks.insert(0, task);
    });
    saveTaskToFirestore(task);
  }

  void showAddTaskSheet() {
    final titleController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedCategory = 'Study';
    TimeOfDay selectedTime = TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFD7EEF2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add new task',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B3F73),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'Task name',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                          );

                          if (pickedDate != null) {
                            setModalState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_month),
                        label: Text(
                          'Date: ${formatDate(selectedDate)}',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Study',
                          child: Text('📚 Study'),
                        ),
                        DropdownMenuItem(value: 'Home', child: Text('🏠 Home')),
                        DropdownMenuItem(value: 'Work', child: Text('💻 Work')),
                        DropdownMenuItem(
                          value: 'Personal',
                          child: Text('⭐ Personal'),
                        ),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          selectedCategory = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );

                          if (pickedTime != null) {
                            setModalState(() {
                              selectedTime = pickedTime;
                            });
                          }
                        },
                        icon: const Icon(Icons.access_time),
                        label: Text(
                          'Time: ${selectedTime.format(context)}',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B3F73),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          if (titleController.text.trim().isEmpty) return;

                          addTask(
                            Task(
                              title: titleController.text.trim(),
                              day: formatDate(selectedDate),
                              time: selectedTime.format(context),
                              category: selectedCategory,
                            ),
                          );

                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Save task',
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildTaskSection(String title, List<Task> sectionTasks) {
    if (sectionTasks.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 25),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 18,
            color: Color(0xFF3A6D8C),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        ...sectionTasks.map(
          (task) => Dismissible(
            key: ValueKey(task.id.isEmpty ? task.title : task.id),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              deleteTask(task);
            },
            background: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.only(right: 20),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.delete, color: Colors.white, size: 30),
            ),
            child: TaskCard(
              task: task,
              onChanged: (value) {
                toggleTask(task, value);
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskDays = visibleTasks.map((task) => task.day).toSet().toList();

    return Scaffold(
      backgroundColor: const Color(0xFFD7EEF2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD7EEF2),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF0B3F73), size: 30),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              if (!context.mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        selectedItemColor: const Color(0xFF0B3F73),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Active'),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Done',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'All'),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                'My Tasks',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B3F73),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${tasks.length} tasks • $completedCount completed',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B3F73),
                ),
              ),
              const SizedBox(height: 22),
              GestureDetector(
                onTap: showAddTaskSheet,
                child: Container(
                  height: 58,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Add new tasks',
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF0B3F73),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(Icons.add_box, color: Color(0xFF0B3F73), size: 34),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: visibleTasks.isEmpty
                    ? const Center(
                        child: Text(
                          'No tasks here',
                          style: TextStyle(
                            fontSize: 22,
                            color: Color(0xFF0B3F73),
                          ),
                        ),
                      )
                    : ListView(
                        children: [
                          ...taskDays.map((day) {
                            final tasksByDay = visibleTasks
                                .where((task) => task.day == day)
                                .toList();

                            return buildTaskSection(day, tasksByDay);
                          }),
                          const SizedBox(height: 40),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  final ValueChanged<bool> onChanged;

  const TaskCard({super.key, required this.task, required this.onChanged});

  String getCategoryIcon(String category) {
    if (category == 'Study') return '📚';
    if (category == 'Home') return '🏠';
    if (category == 'Work') return '💻';
    return '⭐';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: task.isDone ? Colors.white.withOpacity(0.55) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF0B3F73).withOpacity(0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Checkbox(
            value: task.isDone,
            shape: const CircleBorder(),
            activeColor: const Color(0xFF0B3F73),
            onChanged: (value) {
              onChanged(value!);
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0B3F73),
                    decoration: task.isDone
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${getCategoryIcon(task.category)} ${task.category} • ${task.day}, ${task.time}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF3A6D8C),
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
