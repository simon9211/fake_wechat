import 'package:flutter_app/data_source.dart';
import 'package:flutter_app/entities.dart';
import 'package:observable_ui/core.dart';

class HomeModel {
  ObservableList<Entrance> chatItems =
      ObservableList(initValue: CHAT_ENTRANCES);
}
