import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flop_list_view/flop_list_view.dart';
import 'package:flutter/material.dart';
import 'package:window_size/window_size.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowMaxSize(const Size(540, 960));
    setWindowMinSize(const Size(540, 960));
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlopListView',
      home: const MyHomePage(title: "Flop's ListView Example"),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: PointerDeviceKind.values.toSet(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _itemCount = 10;
  final _flopListController1 = FlopListController();
  final _flopListController2 = FlopListController();
  final _itemHeights = [50, 80, 280, 400, 410, 420, 430, 440, 450, 460];

  Widget _buildItem(String name, int index) {
    return Card(
      child: SizedBox(
        height: _itemHeights[index].toDouble(),
        child: Center(child: Text('$name $index')),
      ),
    );
  }

  @override
  void dispose() {
    _flopListController1.dispose();
    _flopListController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Row(
        children: [
          Flexible(
            child: FlopListView.builder(
              anchor: 0.0,
              trailing: true,
              anchorMask: true,
              trailingMask: true,
              itemCount: _itemCount,
              controller: _flopListController1,
              initialScrollIndex: 0,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (_, index) => _buildItem('FlopListView', index),
            ),
          ),
          Flexible(
            child: FlopListView.builder(
              anchor: 0.0,
              trailing: true,
              anchorMask: true,
              trailingMask: true,
              itemCount: _itemCount,
              controller: _flopListController2,
              initialScrollIndex: 0,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (_, index) => _buildItem('FlopListView', index),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton(
                    onPressed: () => _flopListController1.jumpTo(0),
                    child: const Icon(Icons.keyboard_double_arrow_up),
                  ),
                  const Flexible(child: Padding(padding: EdgeInsets.all(8.0))),
                  FloatingActionButton(
                    onPressed: () => _flopListController2.jumpTo(0),
                    child: const Icon(Icons.keyboard_double_arrow_up),
                  ),
                ],
              ),
            ),
            const Flexible(child: Padding(padding: EdgeInsets.all(8.0))),
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton(
                    onPressed: () {
                      final position = _flopListController1.position;
                      final delta = position.viewportDimension * 0.587;
                      position.animateTo(
                        curve: Curves.linear,
                        duration: const Duration(milliseconds: 1000),
                        min(position.pixels + delta, position.maxScrollExtent),
                      );
                    },
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                  const Flexible(child: Padding(padding: EdgeInsets.all(8.0))),
                  FloatingActionButton(
                    onPressed: () {
                      final position = _flopListController2.position;
                      final delta = position.viewportDimension * 0.588;
                      position.animateTo(
                        curve: Curves.linear,
                        duration: const Duration(milliseconds: 1000),
                        min(position.pixels + delta, position.maxScrollExtent),
                      );
                    },
                    child: const Icon(Icons.keyboard_arrow_down),
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
