import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/item.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "To do",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  var items = new List<Item>();
  var itemsDone = new List<Item>();

  HomePage() {
    itemsDone = [];
    items = [];
  }

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var newTask = TextEditingController();
  int _optionBottomBar = 0;
  final dbDataDone = 'dataDone';
  final dbData = 'data';

  void _onItemTapped(int index) {
    setState(() {
      _optionBottomBar = index;
    });
  }

  void add() {
    if (newTask.text.isEmpty) return;
    setState(() {
      widget.items.add(Item(title: newTask.text, done: false));
      newTask.clear();
      save();
    });
  }

  void undo(Item item) {
    setState(() {
      widget.items.add(item);
      save();
      widget.itemsDone.remove(item);
      saveDone();
    });
  }

  void done(Item item) {
    setState(() {
      widget.itemsDone.add(item);
      saveDone();
      remove(widget.items.indexOf(item));
    });
  }

  void remove(int item) {
    setState(() {
      widget.items.removeAt(item);
      save();
    });
  }

  saveDone() async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.setString(dbDataDone, jsonEncode(widget.itemsDone));
  }

  save() async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.setString(dbData, jsonEncode(widget.items));
  }

  Future load() async {
    var prefs = await SharedPreferences.getInstance();
    var data = prefs.getString(dbData);
    if (data != null) {
      Iterable decoded = jsonDecode(data);
      List<Item> result = decoded.map((x) => Item.fromJson(x)).toList();
      setState(() {
        widget.items = result;
      });
    }
    data = prefs.getString(dbDataDone);
    if (data != null) {
      Iterable decoded = jsonDecode(data);
      List<Item> result = decoded.map((x) => Item.fromJson(x)).toList();
      setState(() {
        widget.itemsDone = result;
      });
    }
  }

  _HomePageState() {
    load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextFormField(
          controller: newTask,
          keyboardType: TextInputType.text,
          cursorColor: Colors.white,
          style: TextStyle(color: Colors.white, fontSize: 20),
          decoration: const InputDecoration(
            labelText: "New task",
            labelStyle: TextStyle(color: Colors.white),
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(icon: Icon(Icons.done), tooltip: "Add", onPressed: add),
          ),
        ],
      ),
      body: Container(
          child: <Widget>[
        ListView.builder(
          itemCount: widget.items.length,
          itemBuilder: (ctxt, index) {
            final item = widget.items[index];
            return Dismissible(
              child: CheckboxListTile(
                title: Text(item.title),
                value: item.done,
                onChanged: (value) {
                  item.done = value;
                  done(item);
                },
              ),
              key: UniqueKey(),
              background: Container(
                color: Colors.red,
                child: Center(
                    child: Text(
                  "REMOVE",
                  style: TextStyle(fontSize: 22, color: Colors.white),
                )),
              ),
              onDismissed: (val) {
                remove(index);
              },
            );
          },
        ),
        ListView.builder(
          key: UniqueKey(),
          itemCount: widget.itemsDone.length,
          itemBuilder: (ctxt, index) {
            final item = widget.itemsDone[index];
            return CheckboxListTile(
              title: Text(item.title),
              value: item.done,
              onChanged: (value) {
                item.done = value;
                undo(item);
              },
            );
          },
        ),
      ][_optionBottomBar]),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.list),
              title: Text("${widget.items.length} To do")),
          BottomNavigationBarItem(
              icon: Icon(Icons.playlist_add_check),
              title: Text("${widget.itemsDone.length} Done")),
        ],
        currentIndex: _optionBottomBar,
        selectedItemColor: Colors.purple,
        onTap: _onItemTapped,
      ),
    );
  }
}
