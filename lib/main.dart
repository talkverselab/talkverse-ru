import 'package:flutter/material.dart';

import 'embed.dart';

/// 단독 앱(러시아어 유니버스). 초기화·화면은 embed.dart — 통합 앱(Talkverse)도 같은 두 함수를 쓴다.
void main() async {
  await embedInit(standalone: true);
  runApp(embedApp());
}
