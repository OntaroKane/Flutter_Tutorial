import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nfc_manager/nfc_manager.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Name App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          // Color(0xFF00FF00 Color.fromRGBO(0, 255, 0, 1.0)
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();

  void getNext(){
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>[];
  var  nfcCommands = <Object>[];


  void toggleFavorite(){
    if(favorites.contains(current)){
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }
}

// ...

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch(selectedIndex){
      case 0:
        page = ReadNFC();
      case 1:
        page = WriteNFC();
      case 2:
        page = CodeNFC();
      default:
        throw UnimplementedError('No widget for $selectedIndex');
    }

    return LayoutBuilder(
      builder: (context,constraints) {
        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  extended: constraints.maxWidth >= 600,
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(Icons.barcode_reader),
                      label: Text('Read from Tag'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.wysiwyg),
                      label: Text('Write to Tag'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.code),
                      label: Text('Commands'),
                    ),
                  ],
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: page,
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}

class ReadNFC extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    var readFromNfcTag = "";

    void readNfcTag() {
      NfcManager.instance.startSession(onDiscovered: (NfcTag badge) async {
        var ndef = Ndef.from(badge);

        if (ndef != null && ndef.cachedMessage != null) {
          String tempRecord = "";
          for (var record in ndef.cachedMessage!.records) {
            tempRecord =
            "$tempRecord ${String.fromCharCodes(record.payload.sublist(record.payload[0] + 1))}";
          }

            readFromNfcTag = tempRecord;

        }
        if (ndef != null) {
          var chipId = ndef.additionalData['identifier']
              .map((e) => e.toRadixString(16).padLeft(2, '0'))
              .join(':');
        }

        NfcManager.instance.stopSession();
      });
    }

    if(appState.nfcCommands.isEmpty){
      return Center(
        child: Text('Scan a NFC tag!'),
      );
    }

    return FutureBuilder(
        future: NfcManager.instance.isAvailable(),
        builder: (context,snapshot) {
          if(snapshot.data!){
            return const Center(
                child: Text('NFC not available')
            );
          }else{
            return Center(
              child: TextField(
                decoration: InputDecoration(
                    enabled: false,
                    border: const OutlineInputBorder(),
                    hintText: readFromNfcTag,
                    hintMaxLines: 10),
              )
            );
      }}
    );
  }
}

class WriteNFC extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if(appState.nfcCommands.isEmpty){
      return Center(
        child: Text('Write to a NFC tag!'),
      );
    }

    return ListView(
      children: [
        Padding(
            padding: const EdgeInsets.all(20),
            child: Text('NFC Tag ID: ${appState.nfcCommands}')
        ),
        Padding(
            padding: const EdgeInsets.all(20),
            child: Text('NFC Tag Data: ${appState.nfcCommands}')
        )
      ],
    );
  }
}

class CodeNFC extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if(appState.nfcCommands.isEmpty){
      return Center(
        child: Text('Execute Commands on Tags!'),
      );
    }

    return ListView(
      children: [
        Padding(
            padding: const EdgeInsets.all(20),
            child: Text('NFC Tag ID: ${appState.nfcCommands}')
        ),
        Padding(
            padding: const EdgeInsets.all(20),
            child: Text('NFC Tag Data: ${appState.nfcCommands}')
        )
      ],
    );
  }
}

class FavoritesPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if(appState.favorites.isEmpty){
      return Center(
        child: Text('No favorites added!'),
      );
    }

    return ListView(
      children: [
        Padding(
          padding:const EdgeInsets.all(20),
          child: Text('You have''${appState.favorites.length} favorites:')
        ),
        for(var pair in appState.favorites)
          ListTile(
            leading: Icon(Icons.favorite),
            title: Text(pair.asLowerCase),
          ),
      ],
    );
  }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BigCard(pair: pair),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ...


class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),

        child: Text(
            pair.asLowerCase,
            style: style,
            semanticsLabel: "${pair.first} ${pair.second}"),
      ),
    );
  }
}