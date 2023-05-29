import 'dart:developer';

class Doctor{
  String name = "";
  List specializations = [];
  Map<String, bool> availableDays = {
    "Monday": false,
    "Tuesday": false,
    "Wednesday": false,
    "Thursday": false,
    "Friday": false,
    "Saturday": false,
    "Sunday": false
  };
  List<Map<String, dynamic>> serviceHours = [];

  Doctor(this.name, this.specializations, this.availableDays, this.serviceHours);

  printDetails(){
    log("Name: $name\nSpecializations: $specializations\nAvailable Days: $availableDays\nService Hours: $serviceHours");
  }
}