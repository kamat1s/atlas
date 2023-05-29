library styles;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Map<String, String?> appFonts = {
  "Inter": GoogleFonts.inter().fontFamily,
  "Montserrat": GoogleFonts.montserratAlternates().fontFamily
};

Map<String, Color> appColors = {
  "primary": const Color.fromRGBO(249, 249, 251, 1),
  "accent": const Color.fromRGBO(196, 44, 44, 1),
  "accentHighlight": const Color.fromRGBO(196, 44, 44, 0.15),
  "white": const Color.fromRGBO(255, 255, 255, 1),
  "black": const Color.fromRGBO(23, 23, 23, 23),
  "black.50": const Color.fromRGBO(0, 0, 0, 0.50),
  "black.25": const Color.fromRGBO(0, 0, 0, 0.25),
  "coolGray": const Color.fromRGBO(236, 238, 240, 1),
  "gray143": const Color.fromRGBO(143, 143, 143, 1),
  "gray145": const Color.fromRGBO(145, 149, 145, 1),
  "gray192": const Color.fromRGBO(192, 192, 192, 1),
  "gray217": const Color.fromRGBO(217, 217, 217, 1),
  "gray231": const Color.fromRGBO(231, 231, 231, 1),
  "dirtyWhite": const Color.fromRGBO(240, 242, 245, 1),
  "pending": const Color.fromRGBO(251, 151, 0, 1),
  "accepted": const Color.fromRGBO(71, 207, 115, 1),
};

TextStyle getTextStyle({
  required String textColor,
  required String fontFamily,
  required int fontWeight,
  required double fontSize,
  textShadow,
  fontStyle = FontStyle.normal,
}) {
  List<FontWeight> fontWeights = [
    FontWeight.w100,
    FontWeight.w200,
    FontWeight.w300,
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w800,
    FontWeight.w900
  ];

  return TextStyle(
    overflow: TextOverflow.ellipsis,
    color: appColors[textColor],
    fontFamily: appFonts[fontFamily],
    fontWeight: fontWeights[fontWeight ~/ 100 - 1],
    fontSize: fontSize,
    shadows: textShadow == null ? [] : [textShadow],
    fontStyle: fontStyle,
  );
}
