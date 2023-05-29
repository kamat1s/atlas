import 'package:geolocator/geolocator.dart';

Future<Position> determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.

  return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);
}

convertTime(int time) {
  int convertedTime = time > 12
      ? time - 12
      : time == 0
          ? time += 12
          : time;

  return convertedTime;
}

formatTime(int time) {
  String formattedTime = time < 10 ? "0$time" : "$time";

  return formattedTime;
}

formatMonth(int month) {
  Map<int, String> months = {
    1: "January",
    2: "February",
    3: "March",
    4: "April",
    5: "May",
    6: "June",
    7: "July",
    8: "August",
    9: "September",
    10: "October",
    11: "November",
    12: "December"
  };

  return months[month];
}

formatWeekday(int weekday) {
  Map<int, String> weekdays = {
    1: "Monday",
    2: "Tuesday",
    3: "Wednesday",
    4: "Thursday",
    5: "Friday",
    6: "Saturday",
    7: "Sunday"
  };

  return weekdays[weekday];
}

getMeridiem(int hour) {
  if (hour >= 12) {
    return "pm";
  } else {
    return "am";
  }
}

getDaysInMonth(int year, int month) {
  if (month == DateTime.february) {
    final bool isLeapYear =
        (year % 4 == 0) && (year % 100 != 0) || (year % 400 == 0);
    return isLeapYear ? 29 : 28;
  }
  const List<int> daysInMonth = <int>[
    31,
    -1,
    31,
    30,
    31,
    30,
    31,
    31,
    30,
    31,
    30,
    31
  ];
  return daysInMonth[month - 1];
}

formatPhoneNumber(String phoneNumber) {
  String formattedNumber = phoneNumber;

  if (phoneNumber.length >= 5) {
    formattedNumber =
        "${phoneNumber.substring(0, 4)} ${phoneNumber.substring(4, phoneNumber.length)}";
  }
  if (phoneNumber.length >= 8) {
    formattedNumber =
        "${phoneNumber.substring(0, 4)} ${phoneNumber.substring(4, 7)} ${phoneNumber.substring(7, phoneNumber.length)}";
  }

  return formattedNumber;
}

formatLandline(String landline) {
  String formattedLandline = landline;

  if (landline.length >= 4) {
    formattedLandline =
        "${landline.substring(0, 3)} ${landline.substring(3, landline.length)}";
  }

  return formattedLandline;
}
