import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';

import '../auth/login_screen.dart';

class OnboardingScreen extends StatelessWidget {
   OnboardingScreen({super.key});

  final introKey = GlobalKey<IntroductionScreenState>();

  @override
  Widget build(BuildContext context) {
    final pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700
      ),
      bodyTextStyle: TextStyle(fontSize: 19),
      bodyPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
      pageColor: Colors.white,
      imagePadding: EdgeInsets.zero,
      contentMargin: EdgeInsets.symmetric(vertical: 40)
    );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
      ),
      body: IntroductionScreen(
        key: introKey,
        pages: [
          PageViewModel(
            title: "Save lives",
            body: 'Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney',
            image: Center(child: Image.asset('assets/images/save_lives.png'),),
            decoration: pageDecoration,
          ),
          PageViewModel(
            title: "Secure",
            body: 'Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney',
            image: Center(child: Image.asset('assets/images/secure.png'),),
            decoration: pageDecoration,
          ),
          PageViewModel(
            title: "Easy to Use",
            body: 'Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney',
            image: Center(child: Image.asset('assets/images/easy.png'),),
            decoration: pageDecoration,
            footer: Padding(
              padding: const EdgeInsets.only(left: 15,right: 15, top: 40),
              child: ElevatedButton(
                  onPressed: (){
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen(),));
                  },
                  child: Text("Let's Start!", style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.fromHeight(60),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  )

                ),
              ),
            ),
          ),
        ],
        onDone: () {
          //lo que queremos que pase cuando termine el onboarding
        },
        onSkip: () {
          //Navegamos al LoginScreen
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen(),));
        },
        done: Text("Done"),
        next: Text("Next"),
        skip: Text("Skip"),
        back: Text("Back"),
        showDoneButton: false,
        showNextButton: true,
        showSkipButton: true,
        showBackButton: false,

        skipStyle: TextButton.styleFrom(foregroundColor: Colors.grey),
        //doneStyle: TextButton.styleFrom(foregroundColor: Colors.red),
        nextStyle: TextButton.styleFrom(foregroundColor: Theme.of(context).primaryColor),
        backStyle: TextButton.styleFrom(foregroundColor: Theme.of(context).primaryColor),
        dotsDecorator: DotsDecorator(
          size: Size.square(10),
          activeSize: Size(20, 10),
          activeColor: Theme.of(context).primaryColor,
          color: Colors.black26,
          spacing: EdgeInsets.symmetric(horizontal: 3),
          activeShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25)
          )
        ),
      ),
    );
  }
}
