import 'item.dart';

const miniCardWindowType = 'roosty-mini-card';
const miniCardActionChannel = 'roosty/mini_card_actions';
const miniCardActionMethod = 'miniCardAction';
const miniCardUpdateMethod = 'miniCardUpdate';
const miniCardCloseMethod = 'miniCardClose';

enum MiniCardStatus { loading, ready, failed }

class MiniCardModel {
  const MiniCardModel({
    required this.id,
    required this.item,
    required this.createdAt,
    this.status = MiniCardStatus.loading,
    this.message,
  });

  final String id;
  final Item item;
  final DateTime createdAt;
  final MiniCardStatus status;
  final String? message;

  MiniCardModel copyWith({
    Item? item,
    MiniCardStatus? status,
    String? message,
  }) {
    return MiniCardModel(
      id: id,
      item: item ?? this.item,
      createdAt: createdAt,
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }

  factory MiniCardModel.fromJson(Map<String, dynamic> json) {
    return MiniCardModel(
      id: json['id'] as String,
      item: _itemFromJson(Map<String, dynamic>.from(json['item'] as Map)),
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: MiniCardStatus.values.byName(
        json['status'] as String? ?? MiniCardStatus.loading.name,
      ),
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item': _itemToJson(item),
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'message': message,
    }..removeWhere((_, value) => value == null);
  }
}

class MiniCardState {
  const MiniCardState({this.cards = const []});

  final List<MiniCardModel> cards;

  MiniCardState copyWith({List<MiniCardModel>? cards}) {
    return MiniCardState(cards: cards ?? this.cards);
  }
}

class MiniCardWindowArguments {
  const MiniCardWindowArguments({
    required this.card,
    required this.indexFromBottom,
  });

  final MiniCardModel card;
  final int indexFromBottom;

  factory MiniCardWindowArguments.fromJson(Map<String, dynamic> json) {
    return MiniCardWindowArguments(
      card: MiniCardModel.fromJson(
        Map<String, dynamic>.from(json['card'] as Map),
      ),
      indexFromBottom: json['indexFromBottom'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': miniCardWindowType,
      'card': card.toJson(),
      'indexFromBottom': indexFromBottom,
    };
  }
}

Item _itemFromJson(Map<String, dynamic> json) {
  return Item(
    url: json['url'] as String,
    title: json['title'] as String?,
    source: json['source'] as String? ?? 'web',
    author: json['author'] as String?,
    capturedAt: DateTime.parse(json['capturedAt'] as String),
    rawText: json['rawText'] as String?,
    summary: json['summary'] as String?,
    tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
    status: json['status'] as String? ?? 'unread',
  );
}

Map<String, dynamic> _itemToJson(Item item) {
  return {
    'url': item.url,
    'title': item.title,
    'source': item.source,
    'author': item.author,
    'capturedAt': item.capturedAt.toIso8601String(),
    'rawText': item.rawText,
    'summary': item.summary,
    'tags': item.tags,
    'status': item.status,
  }..removeWhere((_, value) => value == null);
}
