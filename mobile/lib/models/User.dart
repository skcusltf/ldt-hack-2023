import 'dart:convert';

import 'package:lodt_hack/generated/app.pb.dart';
import 'package:lodt_hack/utils/parser.dart';

class Passport {
  String? series;
  String? number;
  String? date;
  String? place;
  String? registration;

  Passport([
    this.series,
    this.number,
    this.date,
    this.place,
    this.registration,
  ]);

  Passport.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return;
    }

    series = json['series'];
    number = json['number'];
    date = json['date'];
    place = json['place'];
    registration = json['registration'];
  }

  Map<String, dynamic> toJson() {
    // filter values != null
    return {
      'series': series,
      'number': number,
      'date': date,
      'place': place,
      'registration': registration
    };
  }
}

class User {
  String? firstName;
  String? lastName;
  String? patronymic;
  String? inn;
  String? snils;
  String? sex;
  String? birthDate;
  String? birthPlace;

  String? phone;
  String? email;
  String? password;

  String? businessName;
  Passport? passport;
  String? userType;

  String? authorityName;

  User([
    this.firstName,
    this.lastName,
    this.userType,
    this.patronymic,
    this.passport,
    this.inn,
    this.snils,
    this.sex,
    this.birthDate,
    this.birthPlace,
    this.phone,
    this.email,
    this.password,
    this.businessName,
    this.authorityName,
  ]);

  bool isBusiness() {
    return userType != 'Инспектор';
  }

  User.fromBusinessUser(BusinessUser businessUser) {
    firstName = businessUser.firstName;
    lastName = businessUser.lastName;
    patronymic = businessUser.patronymicName;
    businessName = businessUser.businessName;
    birthDate = stringFromTimestamp(businessUser.birthDate);
    phone = businessUser.phoneNumber;
    sex = businessUser.sex == PersonSex.PERSON_SEX_MALE ? "Мужской" : "Женский";
  }

  User.fromAuthorityUser(AuthorityUser authorityUser) {
    firstName = authorityUser.firstName;
    lastName = authorityUser.lastName;
    patronymic = authorityUser.authorityName;
  }

  User.fromJson(Map<String, dynamic> json) {
    firstName = json['first_name'];
    lastName = json['last_name'];
    userType = json['user_type'];
    patronymic = json['patronymic'];
    businessName = json['business_name'];
    passport = Passport.fromJson(jsonDecode(json['passport']));
    inn = json['inn'];
    snils = json['snils'];
    sex = json['sex'];
    birthDate = json['birth_date'];
    birthPlace = json['birth_place'];
    phone = json['phone'];
    email = json['email'];
    password = json['password'];
    userType = json['user_type'];
    authorityName = json['authority_name'];
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'user_type': userType,
      'patronymic': patronymic,
      'passport': jsonEncode(passport?.toJson()),
      'business_name': businessName,
      'inn': inn,
      'snils': snils,
      'sex': sex,
      'birth_date': birthDate,
      'birth_place': birthPlace,
      'phone': phone,
      'email': email,
      'password': password,
      'authority_name': authorityName,
    };
  }
}
