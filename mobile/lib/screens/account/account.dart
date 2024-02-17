import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lodt_hack/clients/ApiClient.dart';
import 'package:lodt_hack/providers/LocalStorageProvider.dart';
import 'package:lodt_hack/screens/account/edit_account.dart';
import 'package:lodt_hack/screens/info.dart';
import 'package:lodt_hack/utils/parser.dart';
import 'package:lodt_hack/utils/widgets.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import '../../generated/google/protobuf/empty.pb.dart';
import '../../models/User.dart';
import '../../models/consultation/Consultation.dart';
import '../../styles/ColorResources.dart';
import '../auth/auth.dart';
import '../auth/login.dart';
import 'package:grpc/grpc.dart';
import 'package:url_launcher/url_launcher.dart';

class Account extends StatefulWidget {
  const Account({super.key});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  User user = User();
  String? token;

  void fetchData() {
    storageProvider.getUser().then(
          (value) => setState(
            () {
              user = value!;
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

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Вы уверены, что хотите выйти из аккаунта?"),
          content: Text("Это повлечет за собой очистку локальных данных"),
          actions: [
            TextButton(
              child:
                  const Text("Продолжить", style: TextStyle(color: Colors.red)),
              onPressed: () {
                storageProvider.clearData();
                Navigator.pushAndRemoveUntil(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => Auth(),
                  ),
                  (r) => false,
                );
              },
            ),
            TextButton(
              child: Text("Отмена"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ],
        );
      },
    );
  }

  void deleteAccount() {
    showDialog(
      context: context,
      builder: (BuildContext builder) {
        return AlertDialog(
          title: Text("Вы уверены, что хотите удалить аккаунт?"),
          content: Text("Эту операцию невозможно будет отменить"),
          actions: [
            TextButton(
              child:
                  const Text("Продолжить", style: TextStyle(color: Colors.red)),
              onPressed: () async {
                await apiClient
                    .deleteBusinessUser(
                      Empty(),
                      options: CallOptions(
                        metadata: {'Authorization': 'Bearer $token'},
                      ),
                    )
                    .then(
                      (p0) => {
                        storageProvider.clearData(),
                        Navigator.pushAndRemoveUntil(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => Auth(),
                            ),
                            (r) => false)
                      },
                    );
              },
            ),
            TextButton(
              child: Text("Отмена"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget accountSettingsCard(String text, IconData icon, Function onTap) {
      return Material(
        color: CupertinoColors.systemGrey6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          onTap: () => onTap(),
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(icon, size: 20),
                      SizedBox(width: 16),
                      Text(text, style: GoogleFonts.inter(fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget accountCard(String type, String? text) {
      return Material(
        color: CupertinoColors.systemGrey6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: const TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  isBlank(text) ? "—" : text!,
                  style: GoogleFonts.inter(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    void showSettings() {
      showCupertinoModalBottomSheet(
        context: context,
        builder: (context) => Scaffold(
          persistentFooterAlignment: AlignmentDirectional.center,
          body: Container(
            child: Stack(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16),
                      Text(
                        "Параметры",
                        style: GoogleFonts.ptSerif(fontSize: 32),
                      ),
                      const SizedBox(height: 32),
                      accountSettingsCard(
                        "Журнал о контроле",
                        Icons.list_alt_rounded,
                        () {
                          launchUrl(
                            Uri.parse(
                              'https://knd.mos.ru/news/categories/article',
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      accountSettingsCard(
                        "Настройки уведомлений",
                        Icons.notifications_outlined,
                        () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => Info(
                                title: 'Уведомления',
                                description:
                                    '',
                                externalLink: '',
                                subtitle:
                                    'Удобно управляйте уведомлениями приложения',
                                buttonLabel: 'Подтвердить',
                                customBody: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "Все уведомления",
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        CupertinoSwitch(
                                          value: true,
                                          onChanged: (v) {},
                                          activeColor: ColorResources.accentRed,
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 32),
                                    Text(
                                      "Консультации",
                                      style: GoogleFonts.ptSerif(fontSize: 24),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "За час до консультации",
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        CupertinoSwitch(
                                          value: true,
                                          onChanged: (v) {},
                                          activeColor: ColorResources.accentRed,
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "За 15 минут до консультации",
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        CupertinoSwitch(
                                          value: true,
                                          onChanged: (v) {},
                                          activeColor: ColorResources.accentRed,
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 32),
                                    Text(
                                      "События",
                                      style: GoogleFonts.ptSerif(fontSize: 24),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "Сообщения в чате",
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        CupertinoSwitch(
                                          value: true,
                                          onChanged: (v) {},
                                          activeColor: ColorResources.accentRed,
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 32),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      accountSettingsCard(
                        "Сообщить об ошибке",
                        Icons.bug_report_outlined,
                        () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => Info(
                                title: 'Сообщить об ошибке',
                                description:
                                    'В данный момент функция находится в стадии разработки',
                                externalLink: '',
                                subtitle:
                                    'Это поможет разработчикам сделать приложение еще удобнее и стабильнее',
                                buttonLabel: 'Отправить',
                                customBody: input("Текст ошибки"),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      accountSettingsCard(
                        "Помощь и поддержка",
                        Icons.support,
                        () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => Info(
                                title: 'Помощь и поддержка',
                                description:
                                    'В данный момент функция находится в стадии разработки',
                                externalLink: '',
                                subtitle:
                                    'При возникновении проблем обратитесь в службу помощи и поддержки приложения',
                                buttonLabel: 'Отправить',
                                customBody: input("Обращение в поддержку"),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      accountSettingsCard(
                        "О приложении",
                        CupertinoIcons.info_circle,
                        () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => const Info(
                                title: 'О приложении',
                                description:
                                    'Трек "Мобильное приложение для прохождения предпринимателями проверок контрольных органов" в рамках хакатона Leaders of Digital Transformation',
                                externalLink:
                                    'https://github.com/skcusltf/ldt-hack-2023',
                                subtitle: 'Проект разработан командой skcusltf',
                                buttonLabel: 'Ссылка на репозиторий',
                                customBody: null,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: CupertinoButton(
                          color: CupertinoColors.systemGrey5,
                          onPressed: () {
                            logout();
                          },
                          child: const Text("Выйти из аккаунта",
                              style: TextStyle(color: Colors.black)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (user!.userType != 'Инспектор')
                        SizedBox(
                          height: 48,
                          width: double.infinity,
                          child: CupertinoButton(
                            color: Colors.red,
                            onPressed: () {
                              deleteAccount();
                            },
                            child: const Text("Удалить аккаунт",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CupertinoButton(
                      padding: EdgeInsets.all(0),
                      borderRadius: BorderRadius.circular(64),
                      color: CupertinoColors.systemGrey5,
                      onPressed: () => Navigator.of(context).popUntil(
                        (route) => route.settings.name == '/',
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: CupertinoColors.darkBackgroundGray,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: CupertinoPageScaffold(
        child: CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: Text(
                "Профиль",
                style: GoogleFonts.ptSerif(fontWeight: FontWeight.w100),
              ),
              trailing: Material(
                child: IconButton(
                  icon: const Icon(CupertinoIcons.settings_solid),
                  onPressed: () {
                    showSettings();
                  },
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  verticalDirection: VerticalDirection.down,
                  children: [
                    if (user.isBusiness())
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (_) => EditAccount(initialUser: user!),
                            ),
                          ).then((value) => fetchData());
                        },
                        child: Text("Редактировать данные"),
                        style: ButtonStyle(
                          foregroundColor: MaterialStateProperty.all(
                              ColorResources.accentRed),
                          overlayColor: MaterialStateProperty.all(
                            ColorResources.accentRed.withOpacity(0.1),
                          ),
                        ),
                      ),
                    if (user!.isBusiness()) SizedBox(height: 16),
                    if (user!.isBusiness())
                      accountCard("Название бизнеса", user?.businessName),
                    SizedBox(height: 16),
                    accountCard("Род деятельности",
                        user?.userType ?? "Предприниматель"),
                    SizedBox(height: 32),
                    Text(
                      "Контактные данные",
                      style: GoogleFonts.ptSerif(fontSize: 24),
                    ),
                    if (user!.isBusiness()) SizedBox(height: 8),
                    if (user!.isBusiness()) accountCard("Телефон", user?.phone),
                    SizedBox(height: 8),
                    accountCard("Адрес электронной почты", user?.email),
                    SizedBox(height: 32),
                    Text(
                      "Основные данные",
                      style: GoogleFonts.ptSerif(fontSize: 24),
                    ),
                    SizedBox(height: 8),
                    accountCard("Фамилия", user?.lastName),
                    SizedBox(height: 8),
                    accountCard("Имя", user?.firstName),
                    if (user!.isBusiness())
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        verticalDirection: VerticalDirection.down,
                        children: [
                          SizedBox(height: 8),
                          accountCard("Отчество", user?.patronymic),
                          SizedBox(height: 8),
                          accountCard("ИНН", user?.inn),
                          SizedBox(height: 8),
                          accountCard("СНИЛС", user?.snils),
                          SizedBox(height: 8),
                          accountCard("Пол", user?.sex),
                          SizedBox(height: 8),
                          accountCard("Дата рождения", user?.birthDate),
                          SizedBox(height: 8),
                          accountCard("Место рождения", user?.birthPlace),
                          SizedBox(height: 32),
                          Text(
                            "Паспортные данные",
                            style: GoogleFonts.ptSerif(fontSize: 24),
                          ),
                          SizedBox(height: 8),
                          accountCard("Серия", user?.passport?.series),
                          SizedBox(height: 8),
                          accountCard("Номер", user?.passport?.number),
                          SizedBox(height: 8),
                          accountCard("Дата выдачи", user?.passport?.date),
                          SizedBox(height: 8),
                          accountCard("Кем выдан", user?.passport?.place),
                          SizedBox(height: 8),
                          accountCard("Адрес регистрации",
                              user?.passport?.registration),
                        ],
                      ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
