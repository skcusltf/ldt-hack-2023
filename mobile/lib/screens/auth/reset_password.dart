import 'package:email_validator/email_validator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lodt_hack/styles/ColorResources.dart';
import 'package:google_fonts/google_fonts.dart';


class ResetPassword extends StatefulWidget {
  const ResetPassword({super.key});

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  String email = "";
  final resetPasswordFormKey = GlobalKey<FormState>();

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
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(
              "Восстановить пароль",
              style: GoogleFonts.ptSerif(fontWeight: FontWeight.w100),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                child: Form(
                  autovalidateMode: AutovalidateMode.always,
                  key: resetPasswordFormKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    verticalDirection: VerticalDirection.down,
                    children: [
                      const Text(
                        "Письмо с восстановлением пароля будет отправлено на указанный вами адрес электронной почты",
                        style: TextStyle(
                            fontWeight: FontWeight.w300, fontSize: 16),
                      ),
                      SizedBox(height: 32),
                      textField("Адрес электронной почты", (value) {
                        if (value == null) {
                          return "Введите почту";
                        }

                        if (!EmailValidator.validate(value)) {
                          return "Невалидный формат электронной почты";
                        }

                        return null;
                      }, (text) {
                        email = text;
                      }),
                      SizedBox(height: 32),
                      Container(
                        height: 48,
                        width: double.infinity,
                        child: CupertinoButton(
                          color: ColorResources.accentRed,
                          onPressed: () {
                            if (resetPasswordFormKey.currentState!.validate()) {
                              Navigator.pop(context);
                            }
                          },
                          child: Text("Отправить на почту"),
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
                          child: Text(
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
          ),
        ],
      ),
    );
  }
}
