import 'package:email_validator/email_validator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lodt_hack/clients/ApiClient.dart';
import 'package:lodt_hack/generated/app.pb.dart';
import 'package:lodt_hack/styles/ColorResources.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:grpc/grpc.dart';
import 'package:lodt_hack/utils/parser.dart';

import '../../models/User.dart';
import '../../providers/LocalStorageProvider.dart';

class EditAccount extends StatefulWidget {
  const EditAccount({super.key, required this.initialUser});

  final User initialUser;

  @override
  State<EditAccount> createState() => _EditAccountState();
}

class _EditAccountState extends State<EditAccount> {
  final registerFormKey = GlobalKey<FormState>();

  late User user = widget.initialUser;
  late String? token;
  late bool isMale = widget.initialUser.sex == "Мужской";

  final passport = Passport();

  @override
  void initState() {
    super.initState();
    storageProvider.getUser().then(
          (value) => setState(
            () {
              user = value!;
              print(user.toJson());
            },
          ),
        );
    storageProvider.getToken().then(
          (value) => setState(
            () {
              token = value!;
            },
          ),
        );
  }

  Future<void> updateUser() async {
    try {
      await apiClient.updateBusinessUser(
        UpdateBusinessUserRequest(
          user: BusinessUser(
            firstName: user.firstName,
            patronymicName: user.patronymic,
            lastName: user.lastName,
            sex: PersonSex.PERSON_SEX_MALE,
            birthDate:
                user.birthDate != null ? dateFromString(user.birthDate!) : null,
            businessName: user.businessName,
            phoneNumber: user.phone,
          ),
        ),
        options: CallOptions(
          metadata: {'Authorization': 'Bearer ${token!}'},
        ),
      );

      setState(() {
        storageProvider.saveUser(user);
        Navigator.pop(context);
      });
    } on GrpcError catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Ошибка редактирования профиля"),
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

  Widget textField(String label, String? initialValue,
      String? Function(String?)? validator, Function(String)? onChanged,
      [bool? obscureText, TextInputFormatter? inputFormatter]) {
    return TextFormField(
      initialValue: initialValue,
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
    return Scaffold(
      body: CupertinoPageScaffold(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: Text(
                "Редактирование",
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
                      textField(
                        "Название бизнеса",
                        user.businessName,
                        (value) {
                          if (value == null || value.isEmpty) {
                            return "Название бизнеса не должно быть пустым";
                          }

                          return null;
                        },
                        (text) {
                          user.businessName = text;
                        },
                      ),
                      SizedBox(height: 32),
                      Text(
                        "Контактные данные",
                        style: GoogleFonts.ptSerif(fontSize: 24),
                      ),
                      SizedBox(height: 8),
                      textField(
                        "Телефон",
                        user.phone,
                        (value) {
                          if (value == null || value.isEmpty) {
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
                      // SizedBox(height: 8),
                      // textField(
                      //   "Адрес электронной почты",
                      //   user.email,
                      //   (value) {
                      //     if (value == null || value.isEmpty) {
                      //       return "Адрес электронной почты не должен быть пустым";
                      //     }
                      //
                      //     if (!EmailValidator.validate(value)) {
                      //       return "Неверный формат электронной почты";
                      //     }
                      //
                      //     return null;
                      //   },
                      //   (text) {
                      //     user.email = text;
                      //   },
                      // ),
                      // SizedBox(height: 8),
                      // textField(
                      //   "Пароль",
                      //   user.password,
                      //   (value) {
                      //     if (value == null || value.isEmpty) {
                      //       return "Пароль не должен быть пустым";
                      //     }
                      //
                      //     if (value.length < 6) {
                      //       return "Пароль должен быть не менее 6 символов в длину";
                      //     }
                      //
                      //     return null;
                      //   },
                      //   (text) {
                      //     user.password = text;
                      //   },
                      //   true,
                      // ),
                      SizedBox(height: 32),
                      Text(
                        "Основные данные",
                        style: GoogleFonts.ptSerif(fontSize: 24),
                      ),
                      SizedBox(height: 8),
                      textField(
                        "Фамилия",
                        user.lastName,
                        (value) {
                          if (value == null || value.isEmpty) {
                            return "Фамилия не должна быть пустой";
                          }

                          return null;
                        },
                        (text) {
                          user.lastName = text;
                        },
                      ),
                      SizedBox(height: 8),
                      textField(
                        "Имя",
                        user.firstName,
                        (value) {
                          if (value == null || value.isEmpty) {
                            return "Имя не должно быть пустым";
                          }

                          return null;
                        },
                        (text) {
                          user.firstName = text;
                        },
                      ),
                      SizedBox(height: 8),
                      textField(
                        "Отчество",
                        user.patronymic,
                        (value) {
                          if (value == null || value.isEmpty) {
                            return "Отчество не должно быть пустым";
                          }

                          return null;
                        },
                        (text) {
                          user.patronymic = text;
                        },
                      ),
                      SizedBox(height: 8),
                      textField("ИНН", user.inn, (value) {
                        return null;
                      }, (text) {
                        user.inn = text;
                      }, false, MaskedInputFormatter("0000000000")),
                      SizedBox(height: 8),
                      textField("СНИЛС", user.snils, (value) {
                        return null;
                      }, (text) {
                        user.snils = text;
                      }, false, MaskedInputFormatter("000-000-000-00")),
                      SizedBox(height: 8),
                      genderSelection(),
                      SizedBox(height: 8),
                      textField(
                        "Дата рождения",
                        user.birthDate,
                        (value) {
                          if (value == null || value.isEmpty) {
                            return "Место рождения не должна быть пустой";
                          }

                          return null;
                        },
                        (text) {
                          user.birthDate = text;
                        },
                        false,
                        MaskedInputFormatter("00.00.0000"),
                      ),
                      SizedBox(height: 8),
                      textField(
                        "Место рождения",
                        user.birthPlace,
                        (value) {
                          return null;
                        },
                        (text) {
                          user.birthPlace = text;
                        },
                      ),
                      SizedBox(height: 32),
                      Text(
                        "Паспортные данные",
                        style: GoogleFonts.ptSerif(fontSize: 24),
                      ),
                      SizedBox(height: 8),
                      textField("Серия", user.passport?.series, (value) {
                        return null;
                      }, (text) {
                        user.passport ??= Passport();
                        user.passport!.series = text;
                      }, false, MaskedInputFormatter("0000")),
                      SizedBox(height: 8),
                      textField("Номер", user.passport?.number, (value) {
                        return null;
                      }, (text) {
                        user.passport ??= Passport();
                        user.passport!.number = text;
                      }, false, MaskedInputFormatter("000000")),
                      SizedBox(height: 8),
                      textField(
                        "Дата выдачи",
                        user.passport?.date,
                        (value) {
                          return null;
                        },
                        (text) {
                          user.passport ??= Passport();
                          user.passport!.date = text;
                        },
                        false,
                        MaskedInputFormatter("00.00.0000"),
                      ),
                      SizedBox(height: 8),
                      textField(
                        "Кем выдан",
                        user.passport?.place,
                        (value) {
                          return null;
                        },
                        (text) {
                          user.passport ??= Passport();
                          user.passport!.place = text;
                        },
                      ),
                      SizedBox(height: 8),
                      textField(
                        "Адрес регистрации",
                        user.passport?.registration,
                        (value) {
                          return null;
                        },
                        (text) {
                          user.passport ??= Passport();
                          user.passport!.registration = text;
                        },
                      ),
                      SizedBox(height: 32),
                      Container(
                        height: 48,
                        width: double.infinity,
                        child: CupertinoButton(
                          color: ColorResources.accentRed,
                          onPressed: () async {
                            if (registerFormKey.currentState!.validate()) {
                              updateUser();
                            }
                          },
                          child: Text("Применить изменения"),
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        height: 48,
                        width: double.infinity,
                        child: CupertinoButton(
                          color: ColorResources.accentPink,
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Отменить",
                            style: TextStyle(
                              color: ColorResources.accentRed,
                            ),
                          ),
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
      ),
    );
  }
}
