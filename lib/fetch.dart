import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;

class INotification {
  final int code;
  final String tag;
  final String title;
  final String link;
  final String writer;
  final String etc;
  final DateTime created_at;

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

Future<List<INotification>> fetchInfosBG(String url) async {
  final List<INotification> fetchedData = [];

  try {
    // Fetch HTML content
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final document = html.parse(response.body);

      // Find rows with class "tr-normal"
      final trs = document.getElementsByClassName('tr-normal');
      for (var tr in trs) {
        // code
        final brdNum = tr.querySelector('.brd-num');
        final codeText = brdNum?.text.trim() ?? '';
        final code = int.tryParse(codeText) ?? 0;

        // tag
        final tagType = tr.querySelector('.tag-type-01');
        final tag = tagType?.text.trim() ?? '';

        // title
        final titleHtml = tr.querySelector('.title');
        final title = titleHtml?.text.trim() ?? '';

        // link
        final onclickValue = titleHtml?.attributes['onclick'];
        String link = '';
        if (onclickValue != null) {
          final startIndex = onclickValue.indexOf("'") + 1;
          final endIndex = onclickValue.indexOf("'", startIndex);
          final extractedValue = onclickValue.substring(startIndex, endIndex);
          link =
              "https://www.jbnu.ac.kr/web/Board/$extractedValue/detailView.do?pageIndex=1&menu=2377";
        }

        // writer
        final brdWriter = tr.querySelector('.brd-writer');
        final writer = brdWriter?.text.trim() ?? '';

        // etc
        final etcList = tr.querySelector('.etc-list li');
        final etc = etcList?.text.trim() ?? '';

        // createdAt
        DateTime? lastFetchTime;
        lastFetchTime = DateTime.now();
        final DateTime formattedDate =
            DateFormat('yyyy-MM-dd').format(lastFetchTime) as DateTime;

        fetchedData.add(
          INotification(
            code: code,
            tag: tag,
            title: title,
            link: link,
            writer: writer,
            etc: etc,
            created_at: formattedDate,
          ),
        );
      }
    } else {
      print('Failed to load URL: $url');
    }
  } catch (e) {
    print('Error fetching data: $e');
  }

  print(fetchedData);
  return fetchedData;
}



// Future<void> postDataBG() async {
//   final List<String> urls = [
//     'https://www.jbnu.ac.kr/web/news/notice/sub01.do?pageIndex=1&menu=2377',
//     'https://www.jbnu.ac.kr/web/news/notice/sub01.do?pageIndex=2&menu=2377',
//     'https://www.jbnu.ac.kr/web/news/notice/sub01.do?pageIndex=3&menu=2377',
//   ];

//   List<Notification> scrappedDataBG = [];
//   final results = await Future.wait(urls.map(fetchInfosBG));

//   // Combine results from all URLs
//   for (var result in results) {
//     scrappedDataBG.addAll(result);
//   }

//   // Debug: Print scrapped data
//   for (var data in scrappedDataBG) {
//     print('Code: ${data.code}, Title: ${data.title}, Link: ${data.link}');
//   }
// }
