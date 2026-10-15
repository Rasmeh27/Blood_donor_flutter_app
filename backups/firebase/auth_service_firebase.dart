import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:proyecto_laboratorio_intec/src/repositories/auth_repository.dart';

class AuthServiceFirebase implements AuthRepository {

  //crear las instancias de Firebase para acceder
  //a los metodos
  final FirebaseAuth _auth =  FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  @override
  Future<String> login({required String email, required String password}) async {

    // TODO: implement login
    String res = "Something went wrong";
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return "Success";
    } on FirebaseException catch (error){
      if(error.code == "user-not-found"){
        res = "User not found";
      }else if(error.code == "wrong-password"){
        res = "Wrong password provided for this user";
      }
    }catch(error){
      if(kDebugMode){
        print(error.toString());
      }
    }
    return res;
  }

  @override
  Future<String> register({required String name, required String email, required String password}) async {
    // TODO: implement register
    String res = "Something went wrong";

    try{
      final user = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      res = "Success";
      //debemos guardar el usuario en la Base de Datos
      String? uid = user.user?.uid;
      if(uid != null){
        await _firestore.collection("users").doc(uid).set({
          "uid": uid,
          "name": name,
          "email": email,
          "phone": "",
          "creationDate": FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseException catch(error){
      if(error.code == "weak-password"){
        res  = "The password provided is too weak";
      } else if(error.code == "email-already-in-use"){
        res  = " The account exists for the email provided";
      }
    }catch(error){
      if(kDebugMode){
        print(error.toString());
      }
    }

    return res;
  }

  //Metodo para recuperar la contraseña
Future<void> sendPasswordResetEmail(String email) async{
    try{
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch(error){
      switch(error.code){
        case "invalid-email":
          throw "Email format is not valid";
        case "user-not-found":
          throw "user cannot be found";
        case "too-many-requests":
          throw "too many attemps. Try again later";
        case "network-request-failed":
          throw "connection error. Check internet";
          default:
            throw "Error sending email";
      }
    }
    catch(error){
      throw "Unexpected error: $error";
    }
}


}