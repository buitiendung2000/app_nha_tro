// // ignore_for_file: avoid_function_literals_in_foreach_calls

// import 'dart:developer';
 
// import 'package:flutter/material.dart';
// import 'package:page_transition/page_transition.dart';
 
// import 'package:tinh_tien_dien_nuoc_phong_tro/constants/constants.dart';
// import 'package:tinh_tien_dien_nuoc_phong_tro/model/userModel.dart';
// import 'package:tinh_tien_dien_nuoc_phong_tro/view/signinLogicScreen/signLogicScreen.dart';
 
 
 

// class UserDataCRUDServices {
//   static registerUser(UserModel data, BuildContext context) async {
//     try {
//       await firestore
//           .collection('User')
//           .doc(auth.currentUser!.uid)
//           .set(data.toMap())
//           .whenComplete(() {
//         Navigator.pushAndRemoveUntil(
//             context,
//             PageTransition(
//                 child: const SignInLogicScreen(),
//                 type: PageTransitionType.rightToLeft),
//             (route) => false);
//       });
//     } catch (e) {
//       log(e.toString());
//       throw Exception(e);
//     }
//   }

  
// }