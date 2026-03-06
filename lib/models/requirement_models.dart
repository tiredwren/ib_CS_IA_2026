import 'event_model.dart';
import 'user_model.dart';

// modeling requirement sheet info
class RequirementItem {
  final String id;
  final String text;
  const RequirementItem({required this.id, required this.text});
}

class RequirementCategory {
  final String name;
  final List<RequirementItem> items;
  const RequirementCategory({required this.name, required this.items});
}

class RankRequirements {
  final String rank;
  final List<RequirementCategory> categories;
  const RankRequirements({required this.rank, required this.categories});
}

// modeling students enrolled in classes for admin
class ClassRoster {
  final EventModel? event;
  final List<UserModel> students;
  ClassRoster({required this.event, required this.students});
}