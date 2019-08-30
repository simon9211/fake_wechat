import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/photo_preview.dart';
import 'package:flutter_app/test.dart';

import 'package:flutter_package/image_banner.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import 'package:observable_ui/widgets.dart';
import 'chat_model.dart';

import 'moments.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          primarySwatch: Colors.blue,
          backgroundColor: Colors.transparent),
      home: ChangeNotifierProvider<ChatModel>(
        child: ChatDetailPage(title: 'Flutter Demo Home Page'),
        builder: (context) => ChatModel(),
      ),
    );
  }
}

class ChatDetailPage extends StatefulWidget {
  ChatDetailPage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _ChatDetailPageState createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<ChatModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: WillPopScope(
          onWillPop: () {
            if (model.panelVisible.value) {
              model.panelVisible.setValue(!model.panelVisible.value);
              return Future.value(false);
            }
            return Future.value(true);
          },
          child: Stack(children: <Widget>[
            Center(
                child: Column(
              children: <Widget>[
                Expanded(child: DialoguePanel()),
                ControlPanel(),
                VisibilityEx(
                  child: ToolkitPanel(),
                  visible: model.panelVisible,
                )
              ],
            )),
            Center(
                child: VisibilityEx(
              child: SoundRecordingIndicator(),
              visible: model.recording,
            ))
          ])),
    );
  }
}

class DialoguePanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xfff1f1f1),
      padding: EdgeInsets.only(left: 16, right: 16),
      child: Consumer<ChatModel>(builder: (context, chatModel, child) {
        return ListViewEx(
            items: chatModel.msgList,
            itemBuilder: (context, item) {
              StatelessWidget itemWidget;
              if (item is Message) {
                switch (item.type) {
                  case 0:
                    itemWidget = TextMessage(item);
                    break;
                  case 1:
                    itemWidget = ImageMessage(item);
                    break;
                  case 2:
                    itemWidget = SoundMessage(item);
                    break;
                  default:
                    itemWidget = Text("暂不支持此类型消息");
                    break;
                }
              } else if (item is Marker) {
                switch (item.type) {
                  case 0:
                    itemWidget = TimeMarker(item);
                    break;
                  default:
                    itemWidget = Text("暂不支持此类型消息");
                    break;
                }
              } else {
                itemWidget = Text("暂不支持此类型消息");
              }

              return Dismissible(
                key: ValueKey(item),
                child: Padding(
                    child: GestureDetector(
                      child: itemWidget,
                      onLongPressStart: (details) {
                        print(details.globalPosition);
                        print(details.localPosition);
                        showMenu(
                            context: context,
                            position: RelativeRect.fromLTRB(
                                -details.globalPosition.dx,
                                details.globalPosition.dy,
                                0,
                                0),
                            items: [
                              PopupMenuItem(
                                value: "删除",
                                child: Text("删除"),
                              ),
                              PopupMenuItem(
                                value: "复制",
                                child: Text("复制"),
                              )
                            ]);
                      },
                    ),
                    padding: EdgeInsets.only(top: 10, bottom: 10)),
                onDismissed: (direction) {
                  chatModel.msgList.remove(item);
                },
              );
            });
      }),
    );
  }
}

class SoundRecordingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 200,
        height: 200,
        child: AspectRatio(
          aspectRatio: 1 / 1,
          child: Container(
            decoration: BoxDecoration(
              color: Color(0x88000000),
            ),
          ),
        ));
  }
}

class InputModeTransformation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final model = Provider.of<ChatModel>(context);

    return ExchangeEx(
        child1: Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(
                color: Color(0xffbdbdbd),
                width: 1.0,
              ),
            ),
            alignment: Alignment.centerLeft,
            child: ObservableBridge(
              data: [model.inputText],
              childBuilder: (context) {
                return EditableText(
                    style: TextStyle(color: Color(0xff000000)),
                    cursorColor: Color(0xff246786),
                    backgroundCursorColor: Color(0xff457832),
                    focusNode: FocusNode(),
                    maxLines: 5,
                    minLines: 1,
                    textAlign: TextAlign.start,
                    controller:
                        TextEditingController(text: model.inputText.value),
                    onChanged: (text) {
                      model.inputText.setValue(text);
                    });
              },
            )),
        child2: GestureDetector(
            onLongPressStart: (details) async {
              model.recording.setValue(!model.recording.value);
              model.recordUri = await model.flutterSound.startRecorder(null);
              print('startRecorder: ${model.recordUri}');
              model.recorderSubscription =
                  model.flutterSound.onRecorderStateChanged.listen((e) {
                model.duration = e.currentPosition.toInt();
                print(e.currentPosition.toInt());
              });
            },
            onLongPressEnd: (details) async {
              String result = await model.flutterSound.stopRecorder();
              print('stopRecorder: $result');
              if (model.recorderSubscription != null) {
                model.recorderSubscription.cancel();
                model.recorderSubscription = null;
              }
              if (model.recordUri == null || model.recordUri.length <= 0) {
                return;
              }
              model.msgList.add(
                  Message(2, url: model.recordUri, duration: model.duration));
              model.recordUri = null;
              model.duration = 0;
              model.recording.setValue(!model.recording.value);
            },
            child: RaisedButton(
              child: Text("按住 说话"),
              onPressed: () {},
            )),
        status: model.inputMode);
  }
}

class ControlPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final model = Provider.of<ChatModel>(context);

    return Container(
      padding: EdgeInsets.only(left: 16, right: 16),
      child: Row(
        children: <Widget>[
          IconButton(
            padding: EdgeInsets.all(0),
            icon: Icon(Icons.keyboard_voice),
            onPressed: () {
              model.inputMode.setValue(!model.inputMode.value);
            },
          ),
          Expanded(child: InputModeTransformation()),
          IconButton(
            padding: EdgeInsets.all(0),
            icon: Icon(Icons.insert_emoticon),
            onPressed: () {},
          ),
          IconButton(
              padding: EdgeInsets.all(0),
              icon: Icon(Icons.add),
              onPressed: () {
                model.panelVisible.setValue(!model.panelVisible.value);
              }),
          Consumer<ChatModel>(builder: (context, chatModel, child) {
            return RaisedButton(
              child: Text(
                "发 送",
                style: TextStyle(color: Color(0xffffffff)),
              ),
              color: Color(0xFF0D47A1),
              onPressed: () {
                FocusScope.of(context).requestFocus();
                chatModel.msgList.add(Marker(0, DateTime.now().toString()));
                print("send ${model.inputText.value}");
                chatModel.msgList.add(Message(0, text: model.inputText.value));
                model.inputText.setValue("");
              },
            );
          })
        ],
      ),
    );
  }
}

class TimeMarker extends StatelessWidget {
  const TimeMarker(this.marker);

  final Marker marker;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        color: Color(0x22aaaaaa),
        padding: EdgeInsets.all(10),
        child: Text(
          marker.text,
          style: TextStyle(fontSize: 10),
        ),
      ),
    );
  }
}

class ImageMessage extends StatelessWidget {
  const ImageMessage(this.message);

  final Message message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Image.network(
          "http://b-ssl.duitang.com/uploads/item/201811/04/20181104074412_wcelx.jpg",
          width: 28,
          height: 28,
        ),
        Container(
          margin: EdgeInsets.only(left: 16),
          padding: EdgeInsets.all(10),
          child: PhotoHero(
            width: 100,
            photo: message.file.path,
            onTap: () {
              Navigator.of(context).push(PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      PhotoPreviewPage(message.file.path),
                  opaque: false));
            },
          ),
        )
      ],
    );
  }
}

class SoundMessage extends StatelessWidget {
  SoundMessage(this.message);

  FlutterSound flutterSound = FlutterSound();

  final Message message;

  @override
  Widget build(BuildContext context) {
    final radio = min(max(message.duration.toInt() / (60 * 1000), 0.3), 1);
    return Row(
      children: <Widget>[
        Image.network(
          "http://b-ssl.duitang.com/uploads/item/201811/04/20181104074412_wcelx.jpg",
          width: 28,
          height: 28,
        ),
        Expanded(
            child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: radio,
          child: Container(
              margin: EdgeInsets.only(left: 16),
              child: RaisedButton(
                color: Color(0xffffffff),
                child: Text(
                  "${message.duration.toInt() ~/ 1000}'",
                  textAlign: TextAlign.start,
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  flutterSound.startPlayer(message.url);
                },
              )),
        ))
      ],
    );
  }
}

class TextMessage extends StatelessWidget {
  const TextMessage(this.message);

  final Message message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Image.network(
          "http://b-ssl.duitang.com/uploads/item/201811/04/20181104074412_wcelx.jpg",
          width: 28,
          height: 28,
        ),
        Container(
          constraints: BoxConstraints(minWidth: 40, maxWidth: 200),
          margin: EdgeInsets.only(left: 16),
          padding: EdgeInsets.all(10),
          color: Color(0xffffffff),
          child: Text(
            message.text,
            softWrap: true,
            style: TextStyle(fontSize: 16),
          ),
        )
      ],
    );
  }
}

class ToolkitPanel extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ToolkitPanelState();
  }
}

class ToolkitPanelState extends State {
  @override
  Widget build(BuildContext context) {
    return Container(
        color: Color(0xfff1f1f1),
        height: 200,
        child: PageView(
            children: <Widget>[ToolkitPage(), ToolkitPage(), ToolkitPage()]));
  }
}

class ToolkitPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ToolkitPageState();
  }
}

class ToolkitPageState extends State {
  Future sendImageMessage(BuildContext context, ImageSource source) async {
    var image = await ImagePicker.pickImage(source: source);
    if (image != null) {
      Provider.of<ChatModel>(context).msgList.add(Message(1, file: image));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
                child: Center(
                    child: Column(
              children: <Widget>[
                IconButton(
                    icon: Icon(Icons.image),
                    onPressed: () {
                      sendImageMessage(context, ImageSource.gallery);
                    }),
                Text("相册")
              ],
            ))),
            Expanded(
                child: Center(
                    child: Column(
              children: <Widget>[
                IconButton(
                    icon: Icon(Icons.camera),
                    onPressed: () {
                      sendImageMessage(context, ImageSource.camera);
                    }),
                Text("拍摄")
              ],
            ))),
            Expanded(
                child: Center(
                    child: Column(
              children: <Widget>[
                IconButton(icon: Icon(Icons.attach_file), onPressed: () {}),
                Text("文件")
              ],
            ))),
          ],
        )),
        Expanded(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
                child: Center(
                    child: Column(
              children: <Widget>[
                IconButton(
                    icon: Icon(Icons.account_balance_wallet),
                    onPressed: () {
                      Navigator.of(context).push(PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            MomentsPage(),
                      ));
                    }),
                Text("红包")
              ],
            ))),
          ],
        ))
      ],
    );
  }
}
