import 'dart:math';
import 'dart:async';
import 'package:WHOFlutter/api/question_data.dart';
import 'package:WHOFlutter/components/page_scaffold/page_scaffold.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:html/dom.dart' as dom;

typedef QuestionIndexDataSource = Future<List<QuestionItem>> Function(
    BuildContext);

/// A Data driven series of questions and answers using HTML fragments.
class QuestionIndexPage extends StatefulWidget {
  final String title;
  final QuestionIndexDataSource dataSource;

  const QuestionIndexPage(
      {Key key, @required this.title, @required this.dataSource})
      : super(key: key);

  @override
  _QuestionIndexPageState createState() => _QuestionIndexPageState();
}

class _QuestionIndexPageState extends State<QuestionIndexPage> {
  List<QuestionItem> _questions;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    // Note: this depends on the build context for the locale and hence is not
    // Note: available at the usual initState() time.
    await _loadQuestionData();
  }

  Future _loadQuestionData() async {
    // Fetch the question data.
    if (_questions != null) {
      return;
    }
    _questions = await widget.dataSource(context);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildPage());
  }

  Widget _buildPage() {
    final scrollController = ScrollController();
    List items = (_questions ?? [])
        .map((questionData) => QuestionTile(
              questionItem: questionData,
              scrollController: scrollController
            ))
        .toList();

    return PageScaffold(
      context,
      body: [
        items.isNotEmpty
            ? SliverList(
                delegate: SliverChildListDelegate(items),
              )
            : SliverToBoxAdapter(
                child: Padding(
                padding: const EdgeInsets.all(48.0),
                child: CupertinoActivityIndicator(),
              ))
      ],
      title: widget.title,
      scrollController: scrollController,
    );
  }
}

class QuestionTile extends StatefulWidget {
  const QuestionTile({
    @required this.questionItem,
    this.scrollController
  });

  final QuestionItem questionItem;
  final ScrollController scrollController;

  @override
  _QuestionTileState createState() => _QuestionTileState();
}

class _QuestionTileState extends State<QuestionTile>
    with TickerProviderStateMixin {
  AnimationController rotationController;

  Color titleColor;


  @override
  void initState() {
    super.initState();
    rotationController = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
        lowerBound: 0,
        upperBound: pi / 4);

    titleColor = Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(children: <Widget>[
        Divider(
          height: 1,
        ),
        ExpansionTile(
          onExpansionChanged: (expanded) {
            if (expanded) {
              rotationController.forward();
              setState(() {
                titleColor = Color(0xff1A458E);
              });
              // Timer to wait for ExpansionTile to fully expand
              Timer(Duration(milliseconds: 500), () {
                final RenderBox renderBox = this.context.findRenderObject();
                final offset = renderBox.localToGlobal(Offset.zero);
                double statusBarHeight = MediaQuery.of(context).padding.top;
                widget.scrollController.animateTo(
                  widget.scrollController.offset + offset.dy - statusBarHeight,
                  duration: Duration(milliseconds: 500),
                  curve: Curves.ease
                );
              });
            } else {
              rotationController.reverse();
              setState(() {
                titleColor = Colors.black;
              });
            }
          },
          key: PageStorageKey<String>(widget.questionItem.title),
          trailing: AnimatedBuilder(
            animation: rotationController,
            child: Icon(Icons.add_circle_outline, color: titleColor),
            builder: (context, child) {
              return Transform.rotate(
                angle: rotationController.value,
                child: child,
              );
            },
          ),
          title: Html(
            data: widget.questionItem.title,
            defaultTextStyle: TextStyle(fontSize: 16 * MediaQuery.of(context).textScaleFactor, color: this.titleColor, fontWeight: FontWeight.bold),

          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 32, bottom: 32),
              child: html(widget.questionItem.body),
            )
          ],
        )
      ]),
    );
  }

  // flutter_html supports a subset of html: https://pub.dev/packages/flutter_html
  Widget html(String html) {
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;

    return Html(
      data: html,
      defaultTextStyle: TextStyle(fontSize: 16 * textScaleFactor),
      linkStyle: const TextStyle(
        color: Colors.deepPurple,
      ),
      onLinkTap: (url) {
        launch(url, forceSafariVC: false);
      },
      onImageTap: (src) {},
      // This is our css :)
      customTextStyle: (dom.Node node, TextStyle baseStyle) {
        if (node is dom.Element) {
          switch (node.localName) {
            case "h2":
              return baseStyle.merge(TextStyle(
                  fontSize: 20,
                  color: Color(0xff26354E),
                  fontWeight: FontWeight.w500));
          }
        }
        return baseStyle.merge(
            TextStyle(color: Color(0xff26354E), fontWeight: FontWeight.w500));
      },
    );
  }
}
