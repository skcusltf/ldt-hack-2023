import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lodt_hack/clients/ApiClient.dart';
import 'package:lodt_hack/main.dart';
import 'package:lodt_hack/screens/auth/reset_password.dart';
import 'package:lodt_hack/styles/ColorResources.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:email_validator/email_validator.dart';
import 'package:grpc/grpc.dart';

import '../../generated/app.pbgrpc.dart';
import '../../generated/google/protobuf/empty.pb.dart';
import '../../models/User.dart';
import '../../providers/LocalStorageProvider.dart';
import '../../utils/parser.dart';

class Login extends StatefulWidget {
  final Function onChangeFlow;

  const Login({super.key, required this.onChangeFlow});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool isBusiness = true;
  final loginFormKey = GlobalKey<FormState>();

  String email = "";
  String password = "";

  Future<void> loginUser() async {
    try {
      final response = await apiClient.createSession(
        CreateSessionRequest(
          sessionUser: isBusiness
              ? CreateSessionRequest_SessionUser.SESSION_USER_BUSINESS
              : CreateSessionRequest_SessionUser.SESSION_USER_AUTHORITY,
          email: email,
          password: password,
        ),
      );

      final token = response.token;
      storageProvider.saveToken(token);

      final userResponse = await apiClient.getSessionUser(
        Empty(),
        options: CallOptions(metadata: {'Authorization': 'Bearer $token'}),
      );

      User user = isBusiness
          ? User.fromBusinessUser(userResponse.business)
          : User.fromAuthorityUser(userResponse.authority);
      user.email = email;
      user.password = password;
      user.userType = isBusiness ? "Предприниматель" : "Инспектор";

      storageProvider.saveUser(user);

      setState(() {
        Navigator.pushAndRemoveUntil(
          context,
          CupertinoPageRoute(builder: (context) => MyApp()),
          (r) => false,
        );
      });
    } on GrpcError catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Ошибка входа"),
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

  Widget textField(String label, String? Function(String?)? validator,
      Function(String)? onChanged,
      [bool? obscureText]) {
    return TextFormField(
      cursorColor: Colors.black,
      validator: validator,
      onChanged: onChanged,
      obscureText: obscureText ?? false,
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              Form(
                autovalidateMode: AutovalidateMode.always,
                key: loginFormKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  verticalDirection: VerticalDirection.down,
                  children: [
                    SizedBox(height: 16),
                    Text(
                      "Вход в аккаунт",
                      style: GoogleFonts.ptSerif(fontSize: 32),
                    ),
                    SizedBox(height: 8),
                    const Text(
                      "Для входа в аккаунт выберите полномочие и авторизуйтесь",
                      style:
                          TextStyle(fontWeight: FontWeight.w300, fontSize: 16),
                    ),
                    Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CupertinoButton(
                          color: isBusiness
                              ? ColorResources.accentRed
                              : CupertinoColors.secondarySystemFill,
                          onPressed: () {
                            setState(() {
                              isBusiness = true;
                            });
                          },
                          child: Text(
                            "Бизнес",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: isBusiness
                                  ? ColorResources.white
                                  : ColorResources.darkGrey,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        CupertinoButton(
                          padding: EdgeInsets.symmetric(horizontal: 48),
                          color: isBusiness
                              ? CupertinoColors.secondarySystemFill
                              : ColorResources.accentRed,
                          onPressed: () {
                            setState(() {
                              isBusiness = false;
                            });
                          },
                          child: Text(
                            "Инспектор",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: isBusiness
                                  ? ColorResources.darkGrey
                                  : ColorResources.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32),
                    textField("Адрес электронной почты", (value) {
                      if (isBlank(value)) {
                        return "Введите почту";
                      }

                      if (!EmailValidator.validate(value!)) {
                        return "Невалидный формат электронной почты";
                      }

                      return null;
                    }, (text) {
                      email = text;
                    }),
                    SizedBox(height: 8),
                    textField("Пароль", (value) {
                      if (isBlank(value)) {
                        return "Введите пароль";
                      }

                      return null;
                    }, (text) {
                      password = text;
                    }, true),
                    Spacer(),
                    SizedBox(height: 96),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  isBusiness
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Нет аккаунта?"),
                            SizedBox(
                              height: 24,
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    widget.onChangeFlow();
                                  });
                                },
                                child: Text("Создать"),
                                style: ButtonStyle(
                                  padding: MaterialStateProperty.all(
                                      EdgeInsets.all(4)),
                                  foregroundColor: MaterialStateProperty.all(
                                      ColorResources.accentRed),
                                  overlayColor: MaterialStateProperty.all(
                                    ColorResources.accentRed.withOpacity(0.1),
                                  ),
                                ),
                              ),
                            )
                          ],
                        )
                      : SizedBox(height: 0),
                  SizedBox(height: 8),
                  isBusiness
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Забыли пароль?"),
                            SizedBox(
                              height: 24,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) => ResetPassword(),
                                    ),
                                  );
                                },
                                child: Text("Восстановить"),
                                style: ButtonStyle(
                                  padding: MaterialStateProperty.all(
                                      EdgeInsets.all(4)),
                                  foregroundColor: MaterialStateProperty.all(
                                      ColorResources.accentRed),
                                  overlayColor: MaterialStateProperty.all(
                                    ColorResources.accentRed.withOpacity(0.1),
                                  ),
                                ),
                              ),
                            )
                          ],
                        )
                      : SizedBox(height: 0),
                  SizedBox(height: 12),
                  Container(
                    height: 48,
                    width: double.infinity,
                    child: CupertinoButton(
                      color: ColorResources.accentRed,
                      onPressed: () async {
                        if (loginFormKey.currentState!.validate()) {
                          loginUser();
                        }
                      },
                      child: Text("Войти"),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
