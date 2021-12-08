import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:messenger/helperfunctions/sharedpref_helper.dart';
import 'package:messenger/services/database.dart';
import 'package:random_string/random_string.dart';

class ChatScreen extends StatefulWidget {
  final String chatWithUsername, name;
  ChatScreen(this.chatWithUsername, this.name);
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String chatRoomId, messageId = "";
  Stream messageStream;
  String myName, myProfilePic, myUserName, myEmail;
  TextEditingController messageController = TextEditingController();

  getMyInfoFromSharedPreference() async {
    myName = await SharedPreferenceHelper().getDisplayName();
    myProfilePic = await SharedPreferenceHelper().getUserProfile();
    myUserName = await SharedPreferenceHelper().getUserName();
    myEmail = await SharedPreferenceHelper().getUserEmail();

    chatRoomId = getChatRoomId(widget.chatWithUsername, myUserName);
  }

  getChatRoomId(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "$b\_$a";
    } else {
      return "$a\_$b";
    }
  }

  addMessage(bool sendClicked) {
    if (messageController.text != "") {
      String message = messageController.text;

      var lastMessageTime = DateTime.now();

      Map<String, dynamic> messageMap = {
        "message": message,
        "sender": myUserName,
        "ts": lastMessageTime,
        "imgUrl": myProfilePic,
      };

      //Message Id
      if (messageId == "") {
        messageId = randomAlphaNumeric(12);
      }

      DatabaseMethods()
          .addMessage(chatRoomId, messageId, messageMap)
          .then((value) {
        Map<String, dynamic> lastMessageMap = {
          "lastMessage": message,
          "lastMessageSendTs": lastMessageTime,
          "lastMessageSendBy": myUserName,
        };

        DatabaseMethods().updateLastMessagesend(chatRoomId, lastMessageMap);

        if (sendClicked) {
          messageController.text = ""; // remove the message
          messageId = "";
        }
      });
    }
  }

  Widget messageTile(String message, bool sentByme) {
    return Row(
      mainAxisAlignment:
          sentByme ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
                bottomLeft: sentByme ? Radius.circular(25) : Radius.circular(0),
                bottomRight:
                    sentByme ? Radius.circular(0) : Radius.circular(25),
              ),
              color: Colors.blue,
            ),
            padding: EdgeInsets.all(16),
            child: Text(
              message,
              style: TextStyle(color: Colors.white),
            )),
      ],
    );
  }

  Widget messageList() {
    return StreamBuilder(
      stream: messageStream,
      builder: (context, snapshot) {
        return snapshot.hasData
            ? ListView.builder(
                padding: EdgeInsets.only(bottom: 70, top: 16),
                itemCount: snapshot.data.docs.length,
                reverse: true,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.docs[index];
                  return messageTile(ds["message"], myUserName == ds["sender"]);
                })
            : Center(child: CircularProgressIndicator());
      },
    );
  }

  getMessages() async {
    messageStream = await DatabaseMethods().getMessage(chatRoomId);
    setState(() {});
  }

  doThisOnLaunch() async {
    await getMyInfoFromSharedPreference();
    getMessages();
  }

  @override
  void initState() {
    doThisOnLaunch();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: Container(
        child: Stack(
          children: [
            messageList(),
            Container(
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Colors.blue, width: 1, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                          child: TextField(
                        controller: messageController,
                        onChanged: (value) {
                          addMessage(false);
                        },
                        style: TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Type a message",
                            hintStyle: TextStyle(
                                color: Colors.grey.withOpacity(0.5),
                                fontWeight: FontWeight.w400)),
                      )),
                      GestureDetector(
                        onTap: () {
                          addMessage(true);
                        },
                        child: Icon(
                          Icons.send,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
