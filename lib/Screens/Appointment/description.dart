import 'package:flutter/material.dart';

import '../../styles.dart';

class Description extends StatefulWidget {
  final description;
  const Description({Key? key, this.description}) : super(key: key);

  @override
  State<Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<Description> {
  final descriptionController = TextEditingController();
  String prevDescription = "";

  @override
  void initState() {
    descriptionController.text = widget.description;
    prevDescription = widget.description;
    super.initState();
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColors['accent'],
      body: SafeArea(
        child: Container(
            height: double.maxFinite,
            width: double.maxFinite,
            color: appColors['primary'],
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 74, 10, 10),
                  child: SizedBox(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: descriptionController,
                              keyboardType: TextInputType.multiline,
                              minLines: 1,
                              maxLines: null,
                              decoration: InputDecoration(
                                hintText: "Enter text here...",
                                hintStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: appColors['gray143']),
                                contentPadding: const EdgeInsets.only(left: 10),
                                focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                  color: appColors['gray143']!,
                                )),
                              ),
                              maxLength: 280,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: appColors['white'],
                    boxShadow: [
                      BoxShadow(
                        offset: const Offset(0, 0.5),
                        blurRadius: 4,
                        spreadRadius: 0,
                        color: appColors['black.25']!,
                      ),
                    ],
                  ),
                  height: 54,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 15, 15, 15),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 15),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context, prevDescription);
                            },
                            child: Icon(
                              Icons.close,
                              color: appColors['black'],
                            ),
                          ),
                        ),
                        Text(
                          "Description",
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context, descriptionController.text);
                          },
                          child: Icon(
                            Icons.check,
                            color: appColors['black'],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )),
      ),
    );
  }
}
