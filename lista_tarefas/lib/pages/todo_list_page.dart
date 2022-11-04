import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';

class ToDoListPage extends StatefulWidget {
  const ToDoListPage({super.key});

  @override
  State<ToDoListPage> createState() => _ToDoListPageState();
}

class _ToDoListPageState extends State<ToDoListPage> {
  List _toDoList = [];
  final TextEditingController _toDoController = TextEditingController();
  Map<String, dynamic>? _lastRemoved;
  int? _lastRemovedPosi;

  @override
  void initState() {
    super.initState();
    //chama o readData e, quando ela retornar a String, chama a função anônima passando a String como parâmetro
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Tarefas'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(17, 1, 7, 1),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _toDoController,
                    decoration: const InputDecoration(
                      labelText: 'Nova Tarefa',
                      labelStyle: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _addToDo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.all(14),
                    textStyle: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  child: const Text('ADD'),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 10),
                itemCount: _toDoList.length,
                itemBuilder: buildItem,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      //a key serve para identificar qual dos itens está puxando, ela precisa ser única, um nome qualquer
      //portanto foi pego o tempo atual em milissegundos e tranformado em string
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: const Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]['title']),
        value: _toDoList[index]['ok'],
        secondary: CircleAvatar(
          child: Icon(
            _toDoList[index]['ok'] ? Icons.check : Icons.error,
          ),
        ),
        //onChanged é chamado quando clica na lista
        //quando clica: chama a função passando o parâmetro 'checked' (pode ser true ou false)
        onChanged: (checked) {
          setState(() {
            _toDoList[index]['ok'] = checked;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(
          () {
            _lastRemoved = Map.from(_toDoList[index]); //duplica
            _lastRemovedPosi = index;
            _toDoList.removeAt(index);
            _saveData();

            final snack = SnackBar(
              content: Text('Tarefa "${_lastRemoved!['title']}" removida'),
              action: SnackBarAction(
                label: 'Desfazer',
                onPressed: () {
                  setState(() {
                    _toDoList.insert(_lastRemovedPosi!, _lastRemoved);
                    _saveData();
                  });
                },
              ),
              duration: const Duration(seconds: 4),
            );
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(snack);
          },
        );
      },
    );
  }

  void _addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo['title'] = _toDoController.text;
      _toDoController.clear();
      newToDo['ok'] = false;
      _toDoList.add(newToDo);
      _saveData();
    });
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 1));
    //reordenar os itens - não concluídos acima dos concluídos
    setState(() {
      _toDoList.sort(
      (a, b) {
        if (a['ok'] && !b['ok']) {
          return 1;
        } else if (!a['ok'] && b['ok']) {
          return -1;
        } else {
          return 0;
        }
      });
      _saveData();
    });
  }

  Future<File> _getFile() async {
    //pega o local onde pode armazenar os documentos (directory)
    final directory = await getApplicationDocumentsDirectory();
    //pega o caminho do diretório junto com /data.json, e abre o arquivo atrvés do file
    return File('${directory.path}/data.json');
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    //pega o arquivo
    final file = await _getFile();
    //salva no arquivo como uma string
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return '';
    }
  }
}
