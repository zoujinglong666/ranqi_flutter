import 'dart:async';

/// 事件类型枚举
enum EventType {
  recordAdded,    // 新增记录
  recordUpdated,  // 更新记录
  recordDeleted,  // 删除记录
  roomAdded,      // 新增房间
  roomUpdated,    // 更新房间
  roomDeleted,    // 删除房间
}

/// 事件数据类
class EventData {
  final EventType type;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  EventData({
    required this.type,
    this.data,
  }) : timestamp = DateTime.now();
}

/// 事件管理器 - 单例模式
class EventManager {
  static final EventManager _instance = EventManager._internal();
  factory EventManager() => _instance;
  EventManager._internal();

  // 事件流控制器
  final Map<EventType, StreamController<EventData>> _controllers = {};

  /// 获取指定事件类型的流
  Stream<EventData> getEventStream(EventType eventType) {
    if (!_controllers.containsKey(eventType)) {
      _controllers[eventType] = StreamController<EventData>.broadcast();
    }
    return _controllers[eventType]!.stream;
  }

  /// 发布事件
  void publish(EventType eventType, {Map<String, dynamic>? data}) {
    if (!_controllers.containsKey(eventType)) {
      _controllers[eventType] = StreamController<EventData>.broadcast();
    }
    
    final eventData = EventData(type: eventType, data: data);
    _controllers[eventType]!.add(eventData);
  }

  /// 订阅事件
  StreamSubscription<EventData> subscribe(
    EventType eventType,
    void Function(EventData) callback,
  ) {
    return getEventStream(eventType).listen(callback);
  }

  /// 订阅多个事件类型
  List<StreamSubscription<EventData>> subscribeMultiple(
    List<EventType> eventTypes,
    void Function(EventData) callback,
  ) {
    return eventTypes.map((type) => subscribe(type, callback)).toList();
  }

  /// 清理资源
  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }

  /// 清理指定事件类型的控制器
  void disposeEventType(EventType eventType) {
    if (_controllers.containsKey(eventType)) {
      _controllers[eventType]!.close();
      _controllers.remove(eventType);
    }
  }
}

/// 便捷的全局事件管理器实例
final eventManager = EventManager();