import 'package:http/http.dart' as http;
import 'dart:convert';

sendPushNotification(var token, var title, var body, var notificationID) async {
  var headers = {
    'Content-Type': 'application/json',
    'Authorization':
        'key=AAAAEEUE2F8:APA91bHqmhLJPupvDcFyjw7QDb6iAw7Av4-h9ikbt_Zn8f6nGehPC3D6L8fv82YZ5HZY1C6N0o6TXu3KrawI72Z5UJ_wWDzcE75uRT_rIqZsG-0AnbmBXjE9236PP8IPDNuwxcFfHCQR'
  };
  var request =
      http.Request('POST', Uri.parse('https://fcm.googleapis.com/fcm/send'));
  request.body = json.encode({
    "to": token,
    "mutable_content": true,
    "priority": "high",
    "notification": {
      "title": title,
      "body": body
    },
    "data": {
      "content": {
        "id": 1,
        "channelKey": "alerts",
        "displayOnForeground": true,
        "notificationLayout": "BigText",
        "showWhen": true,
        "autoDismissible": true,
        "privacy": "Private",
        "sound": true,
        "payload": {"notificationID": "$notificationID"},
        "isScheduled": true,

      },
      "actionButtons": [
        {
          "key": "DISMISS",
          "label": "Dismiss",
          "actionType": "DismissAction",
          "isDangerousOption": true,
          "autoDismissible": true
        }
      ],
    }
  });
  request.headers.addAll(headers);

  http.StreamedResponse response = await request.send();

  if (response.statusCode == 200) {
    print(await response.stream.bytesToString());
  } else {
    print(response.reasonPhrase);
  }
}
