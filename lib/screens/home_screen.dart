// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_downloader/image_downloader.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:open_ai_gpt/api/api_service.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:text_to_speech/text_to_speech.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _queryController = TextEditingController();
  final SpeechToText speechToTextInstance = SpeechToText();
  String recordedAudioString = "";
  bool isLoading = false;
  String modeOpenAI = "chat";
  String imageUrlFromOpenAI = "";
  String answerTextFromOpenAI = "";
  bool speakFRIDAY = true;
  final TextToSpeech textToSpeechInstance = TextToSpeech();

  void initializeSpeechToText() async {
    await speechToTextInstance.initialize();

    setState(() {});
  }

  void startListeningNow() async {
    FocusScope.of(context).unfocus();

    await speechToTextInstance.listen(onResult: onSpeechToTextResult);

    setState(() {});
  }

  void onSpeechToTextResult(SpeechRecognitionResult recognitionResult) {
    recordedAudioString = recognitionResult.recognizedWords;

    speechToTextInstance.isListening
        ? null
        : sendRequestToOpenAI(recordedAudioString);

    print("Speech Result:");
    print(recordedAudioString);
  }

  Future<void> sendRequestToOpenAI(String userInput) async {
    stopListeningNow();

    setState(() {
      isLoading = true;
    });

    //send the request to openAI using our APIService
    await APIService().requestOpenAI(userInput, modeOpenAI, 2000).then((value) {
      setState(() {
        isLoading = false;
      });

      if (value.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Api Key you are/were using expired or it is not working anymore.",
            ),
          ),
        );
      }

      _queryController.clear();

      final responseAvailable = jsonDecode(value.body);

      if (modeOpenAI == "chat") {
        print("bbbbbbbbbbbbbbbbbbbbbb${responseAvailable}");
        setState(() {
          answerTextFromOpenAI = utf8.decode(
              responseAvailable["choices"][0]["text"].toString().codeUnits);
          print("ChatGPT Chatbot: ");
          print(answerTextFromOpenAI);
        });
        if (speakFRIDAY == true) {
          textToSpeechInstance.speak(answerTextFromOpenAI);
        }
      } else {
        //image generation
        setState(() {
          imageUrlFromOpenAI = responseAvailable["data"][0]["url"];

          print("Generated Dale E Image Url: ");
          print(imageUrlFromOpenAI);
        });
      }
    }).catchError((errorMessage) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error: $errorMessage",
          ),
        ),
      );
    });
  }

  void stopListeningNow() async {
    await speechToTextInstance.stop();

    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    initializeSpeechToText();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          "assets/images/logo.png",
          width: 120,
        ),
        flexibleSpace: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [
                      Colors.purpleAccent.shade100,
                      Colors.purple,
                    ],
                    begin: const FractionalOffset(0.0, 0.0),
                    end: const FractionalOffset(1.0, 0.0),
                    stops: const [0.0, 1.0],
                    tileMode: TileMode.clamp))),
        titleSpacing: 12,
        elevation: 0,
        actions: [
          //chat
          Padding(
            padding: const EdgeInsets.only(right: 4, top: 4),
            child: InkWell(
              onTap: () {
                setState(() {
                  modeOpenAI = "chat";
                });
              },
              child: Icon(
                Icons.chat,
                size: 40,
                color: modeOpenAI == "chat" ? Colors.white : Colors.grey,
              ),
            ),
          ),

          //image
          Padding(
            padding: const EdgeInsets.only(right: 8, left: 4),
            child: InkWell(
              onTap: () {
                setState(() {
                  modeOpenAI = "image";
                });
              },
              child: Icon(
                Icons.image,
                size: 40,
                color: modeOpenAI == "image" ? Colors.white : Colors.grey,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 20,
                ),
                GestureDetector(
                  onLongPress: () {
                    startListeningNow();
                  },
                  onLongPressDown: (_) {
                    stopListeningNow();
                  },
                  onTap: () {
                    speechToTextInstance.isListening
                        ? stopListeningNow()
                        : startListeningNow();
                  },
                  child: speechToTextInstance.isListening
                      ? Center(
                          child: LoadingAnimationWidget.beat(
                            size: 200,
                            color: speechToTextInstance.isListening
                                ? Colors.deepPurple
                                : isLoading
                                    ? Colors.deepPurple[400]!
                                    : Colors.deepPurple[200]!,
                          ),
                        )
                      : Image.asset(
                          "assets/images/assistant_icon.png",
                          width: 200,
                          height: 200,
                        ),
                ),
                const SizedBox(
                  height: 50,
                ),
                SizedBox(
                  height: 50,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _queryController,
                          decoration: const InputDecoration(
                            labelText: "How can I help you?",
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.purple,
                                width: 2.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      InkWell(
                        onTap: () {
                          if (_queryController.text.isNotEmpty) {
                            sendRequestToOpenAI(
                                _queryController.text.toString());
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.fastLinearToSlowEaseIn,
                          height: 62,
                          width: 62,
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(10),
                            shape: BoxShape.rectangle,
                          ),
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 24,
                ),

                //display result
                modeOpenAI == "chat"
                    ? SelectableText(
                        answerTextFromOpenAI,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : modeOpenAI == "image" && imageUrlFromOpenAI.isNotEmpty
                        ? Column(
                            //image
                            children: [
                              Image.network(
                                imageUrlFromOpenAI,
                              ),
                              const SizedBox(
                                height: 14,
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  String? imageStatus =
                                      await ImageDownloader.downloadImage(
                                          imageUrlFromOpenAI);

                                  if (imageStatus != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            "Image downloaded Successfully."),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                ),
                                child: const Text(
                                  "Download this Image",
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink()
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () {
          if (!isLoading) {
            setState(() {
              speakFRIDAY = !speakFRIDAY;
            });
          }

          textToSpeechInstance.stop();
        },
        child: speakFRIDAY
            ? Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.asset("assets/images/sound.png"),
              )
            : Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.asset("assets/images/mute.png"),
              ),
      ),
    );
  }
}
