import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'model/todo_model.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  List<Todo> todos = [];
  String filter = "all";

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    String? todoString = prefs.getString('todos');

    if (todoString != null) {
      List<dynamic> jsonList = jsonDecode(todoString);
      setState(() {
        todos = jsonList.map((j) => Todo.fromJson(j)).toList();
      });
    }
  }

  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> jsonList = todos
        .map((todo) => todo.toJson())
        .toList();

    await prefs.setString('todos', jsonEncode(jsonList));
  }

  void _addTodo(String title, String content) {
    setState(() {
      todos.add(
        Todo(
          id: DateTime.now().toString(),
          title: title,
          content: content,
          createdAt: DateTime.now(),
        ),
      );
    });
    _saveTodos();
  }

  void _deleteTodo(int index) {
    setState(() => todos.removeAt(index));
    _saveTodos();
  }

  void _toggleTodo(int index) {
    setState(() {
      todos[index].isCompleted = !todos[index].isCompleted;
    });
    _saveTodos();
  }

  void _editTodo(int index, String title, String content) {
    setState(() {
      todos[index].title = title;
      todos[index].content = content;
    });
    _saveTodos();
  }

  List<Todo> _applyFilter() {
    if (filter == "completed") {
      return todos.where((t) => t.isCompleted).toList();
    } else if (filter == "uncompleted") {
      return todos.where((t) => !t.isCompleted).toList();
    }
    return todos;
  }

  void _showTodoDialog({int? index}) {
    final isEdit = index != null;

    final titleController = TextEditingController(
      text: isEdit ? todos[index].title : '',
    );

    final contentController = TextEditingController(
      text: isEdit ? todos[index].content : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? "Edit Todo" : "Tambah Todo"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Judul",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: contentController,
              decoration: InputDecoration(
                labelText: "Deskripsi",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isEmpty ||
                  contentController.text.isEmpty)
                return;

              if (isEdit) {
                _editTodo(index, titleController.text, contentController.text);
              } else {
                _addTodo(titleController.text, contentController.text);
              }

              Navigator.pop(context);
            },
            child: Text(isEdit ? "Update" : "Simpan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleTodos = _applyFilter();

    return Scaffold(
      appBar: AppBar(
        title: Text("Todo List"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => filter = value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: "all", child: Text("Semua")),
              PopupMenuItem(value: "completed", child: Text("Selesai")),
              PopupMenuItem(value: "uncompleted", child: Text("Belum Selesai")),
            ],
          ),
        ],
      ),
      body: visibleTodos.isEmpty
          ? Center(
              child: Text(
                "Belum ada data",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: visibleTodos.length,
              itemBuilder: (context, index) {
                final todo = visibleTodos[index];

                return Card(
                  child: ListTile(
                    leading: Checkbox(
                      value: todo.isCompleted,
                      onChanged: (_) => _toggleTodo(todos.indexOf(todo)),
                    ),
                    title: Text(
                      todo.title,
                      style: TextStyle(
                        decoration: todo.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    subtitle: Text(todo.content),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteTodo(todos.indexOf(todo)),
                    ),
                    onTap: () => _showTodoDialog(index: todos.indexOf(todo)),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showTodoDialog(),
      ),
    );
  }
}
