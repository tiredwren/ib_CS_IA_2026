import 'event_model.dart';
import 'user_model.dart';

// modeling requirement sheet info
class ReqItem {
  final String id;
  final String text;
  const ReqItem({required this.id, required this.text});
}

class ReqCategory {
  final String name;
  final List<ReqItem> items;
  const ReqCategory({required this.name, required this.items});
}

class RankReqs {
  final String rank;
  final List<ReqCategory> categories;
  const RankReqs({required this.rank, required this.categories});
}

// modeling students enrolled in classes for admin
class Roster {
  final EventModel? event;
  final List<UserModel> students;
  Roster({required this.event, required this.students});
}