import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart' as lottie;
import 'package:horizontal_card_pager/horizontal_card_pager.dart';
import 'package:horizontal_card_pager/card_item.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:ndialog/ndialog.dart';
import 'package:road_supervisor/generated/codegen_loader.g.dart';
import 'package:easy_localization/easy_localization.dart';

class AboutWidget extends StatefulWidget {
  AboutWidget({Key? key}) : super(key: key);

  @override
  _AboutWidgetState createState() => _AboutWidgetState();
}

class _AboutWidgetState extends State<AboutWidget> {
  int i = 0;
  @override
  void initState() {
    super.initState();
  }

  String name = "Semeh Chriha";
  @override
  Widget build(BuildContext context) {
    List<String> names = [
      "Fehmi Denguir",
      "Semeh Chriha",
      "Mohamed Habib Faouel"
    ];
    changeText(int i) {
      setState(() {
        name = names[i].toString();
      });
    }

    List<CardItem> items = [
      ImageCarditem(
          image: Image.asset(
        "assets/images/Profile0.jpg",
      )),
      ImageCarditem(
          image: Image.asset(
        "assets/images/Profile1.jpg",
      )),
      ImageCarditem(
          image: Image.asset(
        "assets/images/Profile2.jpg",
      )),
    ];

    return Scaffold(
        backgroundColor: Colors.grey.shade200,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: TextLiquidFill(
                  text: LocaleKeys.OurTeam.tr(),
                  waveColor: Colors.blueAccent,
                  boxBackgroundColor: Theme.of(context).colorScheme.surface,
                  textStyle: TextStyle(
                    fontSize: 30.0,
                    fontWeight: FontWeight.bold,
                  ),
                  boxHeight: 100.0,
                ),
              ),
              Container(
                width: MediaQuery.of(context).size.width,
                height: 250,
                child: lottie.Lottie.asset(
                  "assets/lottie/38281-team.json",
                  animate: true,
                  repeat: true,
                  reverse: true,
                  alignment: Alignment.center,
                ),
                padding: const EdgeInsets.only(bottom: 50),
              ),
              Container(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Text(
                    '$name',
                    style: TextStyle(
                      shadows: <Shadow>[
                        Shadow(
                          offset: Offset(1.0, 1.0),
                          blurRadius: .5,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                        Shadow(
                          offset: Offset(1, 1.0),
                          blurRadius: .5,
                          color: Color.fromARGB(125, 0, 0, 255),
                        ),
                      ],
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  )),
              HorizontalCardPager(
                onPageChanged: (page) {
                  print("page : $page");
                  changeText(page.toInt());
                },
                onSelectedItem: (page) {
                  showPic(page.toInt());
                },
                items: items,
                initialPage: 1,
              ),
            ],
          ),
        ));
  }

  Future<void> showPic(int i) async {
    await NAlertDialog(
      dialogStyle: DialogStyle(titleDivider: true),
      title: Text(
        "$name",
        textAlign: TextAlign.center,
      ),
      content: Container(
        height: 450,
        child: Column(
          children: [
            Image.asset(
              "assets/images/Profile$i.jpg",
            )
          ],
        ),
      ),
    ).show(context, transitionType: DialogTransitionType.Bubble);
  }
}
