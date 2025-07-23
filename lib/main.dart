import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(home: Home()));
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _toDoController = TextEditingController();
  final List _todoList = [];

  Map<String, dynamic>? _lastRemoved;
  int? _lastRemovedPos;

  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      if (data != null) {
        setState(() {
          _todoList.addAll(
            json
                .decode(data)
                .map<Map<String, dynamic>>(
                  (item) => Map<String, dynamic>.from(item),
                ),
          );
        });
      }
    });
  }

  void _addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = {};
      newToDo["title"] = _toDoController.text;
      _toDoController.text = "";
      newToDo["ok"] = false;
      _todoList.add(newToDo);
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.deepPurpleAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _toDoController,
                    decoration: InputDecoration(
                      labelText: "Nova Tarefa",
                      labelStyle: TextStyle(color: Colors.deepPurpleAccent),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _addToDo,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      Colors.deepPurpleAccent,
                    ),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                    padding: MaterialStateProperty.all(EdgeInsets.all(10)),
                    textStyle: MaterialStateProperty.all(TextStyle(fontSize: 15)),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  child: Text("ADD"),
                ),
              ],
            ),
          ),
          Expanded(
            child: _todoList.isEmpty
                ? Center(
                    child: Text(
                      "Nenhuma tarefa ainda!",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(top: 10.0),
                    itemCount: _todoList.length,
                    itemBuilder: buildItem,
                  ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_todoList[index]["title"]),
        value: _todoList[index]["ok"],
        onChanged: (value) {
          setState(() {
            _todoList[index]["ok"] = value;
            _saveData();
          });
        },
        secondary: CircleAvatar(
          child: Icon(_todoList[index]["ok"] ? Icons.check : Icons.error),
        ),
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_todoList[index]);
          _lastRemovedPos = index;
          _todoList.removeAt(index);

          _saveData();

          final snack = SnackBar(
            content: Text("Tarefa \"${_lastRemoved!["title"]}\" removida!"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  _todoList.insert(_lastRemovedPos!, _lastRemoved!);
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 3),
          );
          ScaffoldMessenger.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_todoList);

    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String?> _readData() async {
    try {
      final file = await _getFile();

      if (await file.exists()) {
        return await file.readAsString();
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
