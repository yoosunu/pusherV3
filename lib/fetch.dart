// ignore_for_file: avoid_print, non_constant_identifier_names

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;

class INotification {
  int code;
  String tag;
  String title;
  String link;
  String writer;
  String etc;
  DateTime created_at;

  INotification({
    required this.code,
    required this.tag,
    required this.title,
    required this.link,
    required this.writer,
    required this.etc,
    required this.created_at,
  });

  factory INotification.fromJson(Map<String, dynamic> json) {
    return INotification(
      code: json['code'] ?? 0,
      tag: json['tag'] ?? '',
      title: json['title'] ?? '',
      link: json['link'] ?? '',
      writer: json['writer'] ?? '',
      etc: json['etc'] ?? '',
      created_at: DateTime.parse(json['created_at']),
    );
  }
}

class INotificationBG {
  int code;
  String tag;
  String title;
  String link;
  String writer;
  String etc;

  INotificationBG({
    required this.code,
    required this.tag,
    required this.title,
    required this.link,
    required this.writer,
    required this.etc,
  });

  factory INotificationBG.fromJson(Map<String, dynamic> json) {
    return INotificationBG(
      code: json['code'] ?? 0,
      tag: json['tag'] ?? '',
      title: json['title'] ?? '',
      link: json['link'] ?? '',
      writer: json['writer'] ?? '',
      etc: json['etc'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'tag': tag,
      'title': title,
      'link': link,
      'writer': writer,
      'etc': etc,
    };
  }
}

Future<List<INotificationBG>> fetchInfosBG(String url) async {
  List<INotificationBG> fetchedData = [];

  try {
    // Fetch HTML content
    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      Uint8List bodyBytes = response.bodyBytes;
      String decodedBody = utf8.decode(bodyBytes, allowMalformed: true);
      var document = html.parse(decodedBody);

      // Find rows with class "tr-normal"
      var trs = document.getElementsByClassName('tr-normal');
      for (var tr in trs) {
        // code
        var brdNum = tr.querySelector('.brd-num');
        var codeText = brdNum?.text.trim() ?? '';
        var code = int.tryParse(codeText) ?? 0;

        // tag
        var tagType = tr.querySelector('.tag-type-01');
        var tag = tagType?.text.trim() ?? '';

        // title
        var titleHtml = tr.querySelector('.title');
        var title = titleHtml?.text.trim() ?? '';

        // link
        var onclickValue = titleHtml?.attributes['onclick'];
        String link = '';
        if (onclickValue != null) {
          var startIndex = onclickValue.indexOf("'") + 1;
          var endIndex = onclickValue.indexOf("'", startIndex);
          var extractedValue = onclickValue.substring(startIndex, endIndex);
          link =
              "https://www.jbnu.ac.kr/web/Board/$extractedValue/detailView.do?pageIndex=1&menu=2377";
        }

        // writer
        var brdWriter = tr.querySelector('.brd-writer');
        var writer = brdWriter?.text.trim() ?? '';

        // etc
        var etcList = tr.querySelector('.etc-list li');
        var etc = etcList?.text.trim() ?? '';

        fetchedData.add(
          INotificationBG(
            code: code,
            tag: tag,
            title: title,
            link: link,
            writer: writer,
            etc: etc,
          ),
        );
        // print(fetchedData.last.code);
      }
    } else {
      print('Failed to load URL: $url');
    }
  } catch (e) {
    print('Error fetching data at fetchInfosBG: $e');
  }

  return fetchedData;
}
