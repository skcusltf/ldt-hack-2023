import 'package:email_validator/email_validator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lodt_hack/clients/ApiClient.dart';
import 'package:lodt_hack/generated/app.pb.dart';
import 'package:lodt_hack/generated/google/protobuf/timestamp.pb.dart';
import 'package:lodt_hack/main.dart';
import 'package:lodt_hack/providers/LocalStorageProvider.dart';
import 'package:lodt_hack/styles/ColorResources.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:grpc/grpc.dart';
import 'package:lodt_hack/utils/parser.dart';

import '../../models/User.dart';

class Register extends StatefulWidget {
  final Function onChangeFlow;

  const Register({super.key, required this.onChangeFlow});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final registerFormKey = GlobalKey<FormState>();

  final user = User();
  bool isMale = true;

  Future<void> registerUser() async {
    try {
      final response = await apiClient.createBusinessUser(
        CreateBusinessUserRequest(
          email: user.email,
          password: user.password,
          user: BusinessUser(
            firstName: user.firstName,
            patronymicName: user.patronymic,
            lastName: user.lastName,
            sex: user.sex == "Мужской"
                ? PersonSex.PERSON_SEX_MALE
                : PersonSex.PERSON_SEX_FEMALE,
            birthDate: dateFromString(user.birthDate!),
            businessName: user.businessName,
            phoneNumber: user.phone,
          ),
        ),
      );

      storageProvider.saveToken(response.token);
      storageProvider.saveUser(user);

      setState(() {
        Navigator.pushAndRemoveUntil(
          context,
          CupertinoPageRoute(
            builder: (context) => MyApp(),
          ),
          (r) => false,
        );
      });
    } on GrpcError catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Ошибка регистрации"),
            content: Text(e.message ?? "Текст ошибки отсутствует"),
            actions: [
              TextButton(
                child: Text("Продолжить"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        },
      );
    }
  }

  Widget genderSelection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CupertinoButton(
          padding: EdgeInsets.symmetric(horizontal: 48),
          color: isMale
              ? ColorResources.accentRed
              : CupertinoColors.secondarySystemFill,
          onPressed: () {
            setState(() {
              isMale = true;
              user.sex = "Мужской";
            });
          },
          child: Text(
            "Мужчина",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isMale ? ColorResources.white : ColorResources.darkGrey,
            ),
          ),
        ),
        SizedBox(width: 12),
        CupertinoButton(
          padding: EdgeInsets.symmetric(horizontal: 48),
          color: isMale
              ? CupertinoColors.secondarySystemFill
              : ColorResources.accentRed,
          onPressed: () {
            setState(() {
              isMale = false;
              user.sex = "Женский";
            });
          },
          child: Text(
            "Женщина",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isMale ? ColorResources.darkGrey : ColorResources.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget textField(String label, String? Function(String?)? validator,
      Function(String)? onChanged,
      [bool? obscureText, TextInputFormatter? inputFormatter]) {
    return TextFormField(
      cursorColor: Colors.black,
      validator: validator,
      onChanged: onChanged,
      obscureText: obscureText ?? false,
      inputFormatters: [if (inputFormatter != null) inputFormatter],
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(color: Colors.grey),
        fillColor: CupertinoColors.extraLightBackgroundGray,
        filled: true,
        border: OutlineInputBorder(
          borderSide: const BorderSide(width: 0, style: BorderStyle.none),
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(
              "Регистрация",
              style: GoogleFonts.ptSerif(fontWeight: FontWeight.w100),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: registerFormKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  verticalDirection: VerticalDirection.down,
                  children: [
                    const Text(
                      "Заполните данные для создания аккаунта, если вы — бизнес",
                      style:
                          TextStyle(fontWeight: FontWeight.w300, fontSize: 16),
                    ),
                    SizedBox(height: 32),
                    textField("Название бизнеса", (value) {
                      if (isBlank(value)) {
                        return "Название бизнеса не должно быть пустым";
                      }

                      return null;
                    }, (text) {
                      user.businessName = text;
                    }),
                    SizedBox(height: 32),
                    Text(
                      "Контактные данные",
                      style: GoogleFonts.ptSerif(fontSize: 24),
                    ),
                    SizedBox(height: 8),
                    textField(
                      "Телефон",
                      (value) {
                        if (isBlank(value)) {
                          return "Номер телефона не должен быть пустым";
                        }

                        return null;
                      },
                      (text) {
                        user.phone = text;
                      },
                      false,
                      PhoneInputFormatter(),
                    ),
                    SizedBox(height: 8),
                    textField("Адрес электронной почты", (value) {
                      if (isBlank(value)) {
                        return "Адрес электронной почты не должен быть пустым";
                      }

                      if (!EmailValidator.validate(value!)) {
                        return "Неверный формат электронной почты";
                      }

                      return null;
                    }, (text) {
                      user.email = text;
                    }, false),
                    SizedBox(height: 8),
                    textField("Пароль", (value) {
                      if (isBlank(value)) {
                        return "Пароль не должен быть пустым";
                      }

                      if (value!.length < 6) {
                        return "Пароль должен быть не менее 6 символов в длину";
                      }

                      return null;
                    }, (text) {
                      user.password = text;
                    }, true),
                    SizedBox(height: 32),
                    Text(
                      "Основные данные",
                      style: GoogleFonts.ptSerif(fontSize: 24),
                    ),
                    SizedBox(height: 8),
                    textField("Фамилия", (value) {
                      if (isBlank(value)) {
                        return "Фамилия не должна быть пустой";
                      }

                      return null;
                    }, (text) {
                      user.lastName = text;
                    }),
                    SizedBox(height: 8),
                    textField("Имя", (value) {
                      if (isBlank(value)) {
                        return "Имя не должно быть пустым";
                      }

                      return null;
                    }, (text) {
                      user.firstName = text;
                    }),
                    SizedBox(height: 8),
                    textField("Отчество", (value) {
                      if (isBlank(value)) {
                        return "Отчество не должно быть пустым";
                      }

                      return null;
                    }, (text) {
                      user.patronymic = text;
                    }),
                    SizedBox(height: 8),
                    genderSelection(),
                    SizedBox(height: 8),
                    textField("Дата рождения", (value) {
                      if (isBlank(value)) {
                        return "Дата рождения не должна быть пустой";
                      }

                      return null;
                    }, (text) {
                      user.birthDate = text;
                    }, false, MaskedInputFormatter("00.00.0000")),
                    SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Уже есть аккаунт?"),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              widget.onChangeFlow();
                            });
                          },
                          child: Text("Войти"),
                          style: ButtonStyle(
                            foregroundColor: MaterialStateProperty.all(
                                ColorResources.accentRed),
                            overlayColor: MaterialStateProperty.all(
                              ColorResources.accentRed.withOpacity(0.1),
                            ),
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 8),
                    Container(
                      height: 48,
                      width: double.infinity,
                      child: CupertinoButton(
                        color: ColorResources.accentRed,
                        onPressed: () async {
                          if (registerFormKey.currentState!.validate()) {
                            registerUser();
                          }
                        },
                        child: Text("Подтвердить и завершить"),
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
