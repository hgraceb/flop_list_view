import 'dart:math';
import 'dart:ui';

import 'package:flop_list_view/flop_list_view.dart';
import 'package:flutter/material.dart';

void main() {
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
  final _itemCount = 100;
  late final List<int> _itemHeights;

  @override
  void initState() {
    super.initState();
    final heightGenerator = Random(2147483647);
    _itemHeights = List.generate(_itemCount, (index) {
      return 100 + heightGenerator.nextInt(100);
    });
  }

  Widget _buildItem(String name, int index) {
    return FutureBuilder(
      future: Future.delayed(
        Duration(milliseconds: 1000 + _itemHeights[index]),
        () => _itemHeights[index].toDouble(),
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Card(
            child: SizedBox(
              height: snapshot.data!,
              child: Center(child: Text('$name $index')),
            ),
          );
        }
        return Card(
          child: SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Flexible(
                  child: SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                const Flexible(
                  child: SizedBox(width: 10),
                ),
                Flexible(
                  flex: 10,
                  child: Text('$name $index'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Row(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _itemCount,
              controller: ScrollController(initialScrollOffset: 5400),
              itemBuilder: (context, index) {
                return _buildItem('ListView', index);
              },
            ),
          ),
          Expanded(
            child: FlopListView.builder(
              anchor: 0.0,
              itemCount: _itemCount,
              initialScrollIndex: 50,
              itemBuilder: (context, index) {
                return _buildItem('FlopListView', index);
              },
            ),
          ),
        ],
      ),
    );
  }
}
