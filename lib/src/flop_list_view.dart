import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show CacheExtentStyle;
import 'package:flutter/scheduler.dart';

import 'widgets/scroll_view.dart';
import 'widgets/viewport.dart';

class FlopListView extends StatefulWidget {
  const FlopListView.builder({
    super.key,
    this.physics,
    this.controller,
    this.anchor = 0.0,
    this.trailing = true,
    this.cacheExtent = 1.0,
    this.anchorMask = false,
    this.trailingMask = false,
    this.initialScrollIndex = 0,
    this.scrollDirection = Axis.vertical,
    this.cacheExtentStyle = CacheExtentStyle.viewport,
    required this.itemCount,
    required this.itemBuilder,
  })  : assert(anchor >= 0.0 && anchor <= 1.0),
        assert(initialScrollIndex >= 0 && initialScrollIndex < itemCount);

  /// 列表项数量
  final int itemCount;

  /// 列表锚点
  final double anchor;

  /// 是否为列表锚点添加遮罩显示
  final bool anchorMask;

  /// 是否填充列表末尾空白部分
  final bool trailing;

  /// 是否为列表末尾空白部分添加遮罩显示
  final bool trailingMask;

  /// 滚动方向
  final Axis scrollDirection;

  /// 初始索引位置
  final int initialScrollIndex;

  /// 物理滚动效果
  final ScrollPhysics? physics;

  /// 列表控制器
  final FlopListController? controller;

  /// 列表项构建器
  final IndexedWidgetBuilder itemBuilder;

  /// 预渲染区域范围
  final double cacheExtent;

  /// 预渲染区域计算方式
  final CacheExtentStyle cacheExtentStyle;

  @override
  State<StatefulWidget> createState() => _FlopListViewState();
}

class _FlopListViewState extends State<FlopListView> {
  late int _centerIndex;
  late int _initialIndex;
  bool _isItemsUpdating = false;
  final Key _listKey = UniqueKey();
  final Key _centerKey = UniqueKey();
  late final ScrollController _scrollController;
  late final FlopListController _listController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _centerIndex = _initialIndex = widget.initialScrollIndex;
    _listController = widget.controller ?? FlopListController();
    _listController._attach(this);
  }

  @override
  void dispose() {
    _listController._detach();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FlopListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // TODO Update widget
  }

  @override
  Widget build(BuildContext context) {
    return UnboundedCustomScrollView(
      center: _centerKey,
      physics: widget.physics,
      controller: _scrollController,
      cacheExtent: widget.cacheExtent,
      onPerformLayout: _scheduleUpdateItems,
      scrollDirection: widget.scrollDirection,
      cacheExtentStyle: widget.cacheExtentStyle,
      slivers: [
        if (centerIndex > 0)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildItem(centerIndex - index - 1),
              childCount: centerIndex,
            ),
          ),
        SliverList(
          key: _centerKey,
          delegate: SliverChildBuilderDelegate(
            (context, index) => Container(
              foregroundDecoration: BoxDecoration(
                color: widget.anchorMask ? Colors.purple.withOpacity(.5) : null,
              ),
              child: _buildItem(centerIndex),
            ),
            childCount: widget.itemCount > 0 ? 1 : 0,
          ),
        ),
        if (centerIndex >= 0 && centerIndex < widget.itemCount - 1)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildItem(centerIndex + index + 1),
              childCount: widget.itemCount - centerIndex - 1,
            ),
          ),
        if (widget.trailing && trailingFraction > 0)
          SliverFillViewport(
            padEnds: false,
            viewportFraction: trailingFraction,
            delegate: SliverChildBuilderDelegate(
              (context, index) => Container(
                color: widget.trailingMask ? Colors.red.withOpacity(0.5) : null,
              ),
              childCount: 1,
            ),
          ),
      ],
    );
  }

  int get centerIndex {
    if (_centerIndex == _initialIndex) {
      return _centerIndex;
    }
    for (final item in _listController.items) {
      if (item.index == _initialIndex) {
        _centerIndex = _initialIndex;
        final position = _scrollController.position;
        // 更新锚点列表项后校正当前位置
        position.correctBy(-item.offset - position.pixels);
        break;
      }
    }
    return _centerIndex;
  }

  /// 列表末尾空白部分占比
  double _trailingFraction = 1.0;
  double get trailingFraction => _trailingFraction;
  set trailingFraction(value) {
    // 列表末尾空白部分占比只能减少不能增加
    if (_trailingFraction > 0 && value < _trailingFraction) {
      setState(() => _trailingFraction = value);
    }
  }

  Widget _buildItem(int index) {
    final globalKey = _FlopListViewChildGlobalKey(_listKey, index);
    return globalKey.currentWidget ??
        KeyedSubtree(
          key: globalKey,
          child: widget.itemBuilder(context, index),
        );
  }

  void _scheduleUpdateItems() {
    if (_isItemsUpdating) {
      return;
    }
    _isItemsUpdating = true;
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      RenderViewportBase? viewport;
      int initialIndex = _initialIndex;
      final List<FlopListItem> items = [];
      for (int index = 0; index < widget.itemCount; index++) {
        final globalKey = _FlopListViewChildGlobalKey(_listKey, index);
        final box = globalKey.currentContext?.findRenderObject() as RenderBox?;
        viewport ??= RenderAbstractViewport.of(box) as RenderViewportBase?;
        if (box == null || !box.hasSize || viewport == null) {
          continue;
        }

        final offset = viewport.getOffsetToReveal(box, 0.0).offset;
        final item = FlopListItem(
          index: index,
          size: box.size,
          axis: widget.scrollDirection,
          offset: offset - viewport.offset.pixels,
          viewport: _scrollController.position.viewportDimension,
        );
        // 如果是最后一个列表项
        if (widget.trailing && item.index == widget.itemCount - 1) {
          trailingFraction = 1.0 - item.trailing;
        }
        // 遍历获取最后符合条件的列表项作为锚点列表项
        if (item.leading <= widget.anchor && item.trailing >= widget.anchor) {
          // 仅在 [ScrollPosition.activity] 不为 [DrivenScrollActivity] 类型时才改变
          // 锚点列表项，因为 [DrivenScrollActivity] 使用的是目标点的绝对位置，在改变锚点
          // 列表项时调用 [ScrollPosition.correctBy] 后又会被马上还原，进而导致锚点列表项
          // 快速变动，目前只有使用 [ScrollPosition.animateTo] 方法时可能出现此问题。
          // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
          if (_scrollController.position.activity is! DrivenScrollActivity) {
            initialIndex = item.index;
          }
        }
        items.add(item);
      }
      if (initialIndex != _initialIndex) {
        setState(() => _initialIndex = initialIndex);
      }
      _listController.updateItems(items);
      _isItemsUpdating = false;
    });
  }

  /// 跳转到指定列表项位置
  void _jumpTo(int index) {
    if (index < 0) {
      index = 0;
    } else if (index > widget.itemCount - 1) {
      index = widget.itemCount - 1;
    }
    setState(() {
      _scrollController.jumpTo(0);
      _centerIndex = _initialIndex = index;
      // 在锚点列表项改变后再重置列表末尾空白部分占比
      _trailingFraction = 1.0;
    });
  }
}

class FlopListItem {
  /// 列表项索引
  final int index;

  /// 列表项起点位置坐标
  final double offset;

  /// 主轴方向的视窗长度
  final double viewport;

  /// 列表项主轴方向长度
  late final double extent;

  /// 列表项起点位置比例
  late final double leading;

  /// 列表项终点位置比例
  late final double trailing;

  FlopListItem({
    required Size size,
    required Axis axis,
    required this.index,
    required this.offset,
    required this.viewport,
  }) {
    extent = axis == Axis.vertical ? size.height : size.width;
    leading = _edge(offset / viewport);
    trailing = _edge((offset + extent) / viewport);
  }

  /// 取边缘近似值
  double _edge(double value, {double tolerance = 0.001}) {
    if ((value - 0.0).abs() < tolerance) {
      return 0.0;
    }
    if ((value - 1.0).abs() < tolerance) {
      return 1.0;
    }
    return value;
  }

  @override
  String toString() {
    return '$runtimeType(index: $index, '
        'offset: ${offset.toStringAsFixed(2)}, '
        'viewport: ${viewport.toStringAsFixed(2)}, '
        'extent: ${extent.toStringAsFixed(2)}, '
        'leading: ${leading.toStringAsFixed(2)}, '
        'trailing: ${trailing.toStringAsFixed(2)})';
  }
}

class FlopListController extends ChangeNotifier {
  FlopListController();

  _FlopListViewState? _state;

  /// 列表项信息
  List<FlopListItem> _items = [];

  /// 列表项信息
  UnmodifiableListView<FlopListItem> get items => UnmodifiableListView(_items);

  bool get isAttached => _state?._scrollController.hasClients == true;

  ScrollPosition get position => _state!._scrollController.position;

  /// 更新列表项信息
  void updateItems(List<FlopListItem> items) {
    _items = items;
    notifyListeners();
  }

  /// 跳转到指定列表项位置
  void jumpTo(int index) {
    _state!._jumpTo(index);
  }

  void _attach(_FlopListViewState state) {
    assert(_state == null);
    _state = state;
  }

  void _detach() {
    _state = null;
  }
}

class _FlopListViewChildGlobalKey extends GlobalObjectKey {
  const _FlopListViewChildGlobalKey(this.key, this.index) : super(key);

  /// 列表唯一标识符
  final Key key;

  /// 当前列表项索引
  final int index;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is _FlopListViewChildGlobalKey &&
        other.key == key &&
        other.index == index;
  }

  @override
  int get hashCode => Object.hash(key, index);
}
