library query;

import 'dart:developer';

import 'package:atlas/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'global.dart';

Future<void> createID(String name) async {
  var db = FirebaseFirestore.instance.collection(
    "ids",
  );

  await db.doc("sequence").update({name: 1});
}

Future<void> incrementID(String name, int ID) async {
  var db = FirebaseFirestore.instance.collection(
    "ids",
  );

  await db.doc("sequence").update({name: ID + 1});
}

Future<int> generateID(String name) async {
  int ID = 0;
  Map<String, dynamic>? sequence;

  var db = FirebaseFirestore.instance.collection(
    "ids",
  );

  await db.doc('sequence').get().then((value) {
    sequence = value.data();

    if (sequence![name] == null) {
      createID(name);
      ID = 1;
    } else {
      ID = sequence![name];
      incrementID(name, ID);
      ID += 1;
    }
  });

  return ID;
}

Future<void> createAccount(
    Map<String, dynamic> accountDetails, String accountType) async {
  var collection =
      accountType == "Doctor" ? "independentDoctor" : accountType.toLowerCase();

  FirebaseAuth.instance
      .createUserWithEmailAndPassword(
          email: accountDetails['email']!,
          password: accountDetails['password']!)
      .then((value) async {
    var uid = FirebaseAuth.instance.currentUser!.uid;

    var db = FirebaseFirestore.instance.collection(
      "${collection}s",
    );

    FirebaseAuth.instance.signOut();

    int ID = await generateID(collection);

    accountDetails['uid'] = uid;
    accountDetails['${collection}ID'] = ID;

    db.add(accountDetails);
  });
}

Future<String> checkAccountType(var email) async {
  String accountType = "anonymous";

  if (email != null) {
    var patientCollection = FirebaseFirestore.instance.collection('patients');
    var clinicCollection = FirebaseFirestore.instance.collection('clinics');
    var doctorCollection =
        FirebaseFirestore.instance.collection('independentDoctors');

    var patientResult =
        await patientCollection.where('email', isEqualTo: email).get();
    var clinicResult =
        await clinicCollection.where('email', isEqualTo: email).get();
    var doctorResult =
        await doctorCollection.where('email', isEqualTo: email).get();

    if (patientResult.size > 0) {
      accountType = 'Patient';
    } else if (clinicResult.size > 0) {
      log(clinicResult.docs.first.data().toString());
      accountType = 'Clinic';
    } else if (doctorResult.size > 0) {
      log(doctorResult.docs.first.data().toString());
      accountType = 'Doctor';
    }
  }

  return accountType;
}

Future<bool> checkSetupStatus() async {
  var uid = FirebaseAuth.instance.currentUser!.uid;
  bool setupStatus = false;

  List accountTypes = ['patients', 'clinics', 'independentDoctors'];

  for (var accountType in accountTypes) {
    await FirebaseFirestore.instance
        .collection(accountType)
        .where("uid", isEqualTo: uid)
        .get()
        .then((value) async {
      if (value.size != 0) {
        await value.docs.first.reference.get().then((value) {
          var accountDetails = value.data();

          setupStatus = accountDetails!['setupDone'];
        });
      }
    });
  }
  print(setupStatus);
  return setupStatus;
}

Future<List<DocumentSnapshot>> getServices() async {
  List<DocumentSnapshot> services = [];

  var servicesCollection = FirebaseFirestore.instance.collection('services');
  await servicesCollection.get().then((snapshot) {
    for (var doc in snapshot.docs) {
      services.add(doc);
    }
  });

  return services;
}

Future<List<dynamic>> getClinicServices() async {
  var uid = FirebaseAuth.instance.currentUser!.uid;
  List<dynamic> services = [];

  var clinicDocRef = FirebaseFirestore.instance.collection('clinic').doc(uid);
  await clinicDocRef.get().then((snapshot) {
    services = snapshot.get('services');
  });

  return services;
}

Future<void> setupAccount(var data, var accountType) async {
  var uid = FirebaseAuth.instance.currentUser!.uid;

  FirebaseFirestore.instance
      .collection("${accountType}s")
      .where("uid", isEqualTo: uid)
      .get()
      .then((value) async {
    var docRef = value.docs.first.reference;

    await docRef.set(
      data,
      SetOptions(merge: true),
    );
  });
}

Future<List<Map<String, dynamic>>> getClinicInformation() async {
  List<Map<String, dynamic>> clinicsInformation = [];
  var clinicCollection =
      await FirebaseFirestore.instance.collection('clinics').get();
  var clinicDocuments = clinicCollection.docs;

  for (var doc in clinicDocuments) {
    var clinicInformation = doc.data();
    if (clinicInformation['setupDone'] == true) {
      clinicInformation['requestDetail'] = await getData('verificationRequests',
          id: clinicInformation['verificationRequestID']);
      clinicInformation['accountType'] = "clinic";
      clinicsInformation.add(clinicInformation);
    }
  }

  return clinicsInformation;
}

Future<List<Map<String, dynamic>>> getDoctorInformation() async {
  List<Map<String, dynamic>> doctorsInformation = [];
  var doctorCollection =
      await FirebaseFirestore.instance.collection('independentDoctors').get();
  var doctorDocuments = doctorCollection.docs;

  for (var doc in doctorDocuments) {
    var doctorInformation = doc.data();
    if (doctorInformation['setupDone'] == true) {
      doctorInformation['requestDetail'] = await getData('verificationRequests',
          id: doctorInformation['verificationRequestID']);
      doctorInformation['accountType'] = "independentDoctor";
      doctorsInformation.add(doctorInformation);
    }
  }

  return doctorsInformation;
}

Future<List<int>> addDoctors(
    List<Map<String, dynamic>> doctors, var clinicID) async {
  int doctorID = 0;

  List<int> doctorsID = [];
  var doctorsCollection = FirebaseFirestore.instance.collection('doctors');
  for (var doctor in doctors) {
    doctorID = await generateID("doctor");
    doctor['doctorID'] = doctorID;
    doctor['clinicID'] = clinicID;
    await doctorsCollection.add(doctor).then((value) {
      doctorsID.add(doctor['doctorID']);
    });
  }

  return doctorsID;
}

Future<void> addAppointment(
    Map<String, dynamic> appointmentDetails, String appointmentType) async {
  var appointmentsCollection =
      FirebaseFirestore.instance.collection("${appointmentType}Appointments");

  int appointmentID = await generateID("${appointmentType}Appointment");
  appointmentDetails['${appointmentType}AppointmentID'] = appointmentID;
  appointmentsCollection.add(appointmentDetails);
}

Future<dynamic> getData(String collection, {var uid, var id, var field}) async {
  var collectionRef = FirebaseFirestore.instance.collection(collection);
  QuerySnapshot<Map<String, dynamic>> snapshot;

  if (uid != null) {
    snapshot = await collectionRef.where("uid", isEqualTo: uid).get();
  } else if (id != null) {
    snapshot = await collectionRef
        .where("${collection.substring(0, collection.length - 1)}ID",
            isEqualTo: id)
        .get();
  } else {
    snapshot = await collectionRef.get();
  }

  if (uid == null && id == null) {
    List<Map<String, dynamic>> documents = [];

    for (var doc in snapshot.docs) {
      documents.add(doc.data());
    }

    return documents;
  }

  var docRef = await snapshot.docs.first.reference.get();

  if (field == null) {
    var data = docRef.data();
    return data;
  } else {
    return await docRef.data()!['$field'];
  }
}

Future<void> updateData(String collection, var data, {var id, var uid}) async {
  if (id != null) {
    FirebaseFirestore.instance
        .collection(collection)
        .where("${collection.substring(0, collection.length - 1)}ID",
            isEqualTo: id)
        .get()
        .then((value) {
      value.docs.first.reference.set(data, SetOptions(merge: true));
    });
  } else {
    FirebaseFirestore.instance
        .collection(collection)
        .where("uid", isEqualTo: uid)
        .get()
        .then((value) {
      value.docs.first.reference.set(data, SetOptions(merge: true));
    });
  }
}

Future<void> deleteData(String collection, var id) async {
  var db = FirebaseFirestore.instance;
  var documents = await db
      .collection(collection)
      .where("${collection.substring(0, collection.length - 1)}ID",
          isEqualTo: id)
      .get();

  var docRef = documents.docs.first.reference.path;

  await db.doc(docRef).delete();
}

Future<int> addVerificationRequest(
    Map<String, dynamic> verificationRequest) async {
  int verificationRequestID = 0;

  var verificationRequestCollection =
      FirebaseFirestore.instance.collection('verificationRequests');

  verificationRequestID = await generateID("verificationRequest");
  verificationRequest['verificationRequestID'] = verificationRequestID;

  await verificationRequestCollection.add(verificationRequest);

  return verificationRequestID;
}

Future<Map<String, dynamic>> checkDuplicateAppointment(
    var patientID, var pickedDate, var appointmentType) async {
  var appointmentCollection =
      FirebaseFirestore.instance.collection('${appointmentType}Appointments');
  var appointmentRef = await appointmentCollection
      .where('patientID', isEqualTo: patientID)
      .where('status', whereIn: ['pending', 'accepted']).get();

  for (var doc in appointmentRef.docs) {
    if (pickedDate.toString().split(' ')[0] ==
        doc.data()['date'].split(' ')[0]) {
      var appointmentDetails = doc.data();
      appointmentDetails['ID'] = doc.id;
      return appointmentDetails;
    }
  }

  return {};
}

Future<dynamic> getTakenSlots(
    {required var id, required var accountType}) async {
  List<DateTime> takenSlots = [];
  var appointmentsCollection =
      FirebaseFirestore.instance.collection('${accountType}Appointments');
  var docRef = await appointmentsCollection
      .where('${accountType}ID', isEqualTo: id)
      .where('status', isEqualTo: 'accepted')
      .get();

  for (var doc in docRef.docs) {
    takenSlots.add(DateTime.parse(doc.data()['date']));
  }

  return takenSlots;
}

Future<int> addNotification(
    {var scheduleDate = "", required uid, title, body}) async {
  int notificationID = 0;

  notificationID = await generateID("notification");

  Map<String, dynamic> notificationDetails = {
    "notificationID": notificationID,
    "uid": uid,
    "title": title,
    "body": body,
    "dismissed": false,
    "date": DateTime.now().toString(),
    "scheduleDate": scheduleDate
  };

  var notificationsCollection =
      FirebaseFirestore.instance.collection('notifications');
  await notificationsCollection.add(notificationDetails);

  return notificationID;
}

Future<List<Map<String, dynamic>>> getPatientTokens(
    {required accountType}) async {
  List<Map<String, dynamic>> patientsData = [];
  var appointmentCollection =
      FirebaseFirestore.instance.collection('${accountType}Appointments');
  var appointmentRef = await appointmentCollection
      .where('${accountType}ID', isEqualTo: uid)
      .where('status', isEqualTo: 'accepted')
      .get();

  for (var doc in appointmentRef.docs) {
    if (DateTime.now().toString().split(' ')[0] ==
            doc.data()['date'].split(' ')[0] &&
        DateTime.parse(doc.data()['date']).isAfter(DateTime.now())) {
      var appointmentDetails = doc.data();
      appointmentDetails['ID'] = doc.id;
      var patientDetails =
          await getData('patients', id: appointmentDetails['patientID']);

      patientsData.add(patientDetails);
    }
  }

  return patientsData;
}

Future<bool> checkDoctorActiveAppointment({required doctorID}) async {
  bool hasActiveAppointment;

  var db = FirebaseFirestore.instance;
  var clinicAppointmentCollections = await db
      .collection('clinicAppointments')
      .where("doctorID", isEqualTo: doctorID)
      .get();

  hasActiveAppointment = clinicAppointmentCollections.size >= 1;

  return hasActiveAppointment;
}

Future<bool> checkDateWithAppointment(
    {required ID, required accountType, required day}) async {
  bool dayHasAppointment = false;

  var db = FirebaseFirestore.instance;
  var appointmentCollections = await db
      .collection('${accountType}Appointments')
      .where("${accountType}ID", isEqualTo: ID)
      .get();

  for (var doc in appointmentCollections.docs) {
    var data = doc.data();
    var date = DateTime.parse(data['date']);

    if (day == formatWeekday(date.weekday) &&
        (data['status'] != "cancelled" && data['status'] != "dismissed" && data['status'] != "done")) {
      print(data);
      dayHasAppointment = true;
      break;
    }
  }

  return dayHasAppointment;
}
