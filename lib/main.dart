// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_todo_list/firebase_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo',
      home: LogInPage(),
    );
  }
}

///ConsumerWidgetに変えておく
class LogInPage extends ConsumerWidget {
  const LogInPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mailcontroller = TextEditingController();
    final passcontroller = TextEditingController();
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(100),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  label: Text('Email'),
                  icon: Icon(Icons.mail),
                ),
                controller: mailcontroller,
              ),
              TextField(
                decoration: const InputDecoration(
                  label: Text('Password'),
                  icon: Icon(Icons.key),
                ),
                controller: passcontroller,
                obscureText: true,
              ),
              Container(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton(
                    onPressed: () async {
                      if (await logIn(
                          mailcontroller.text, passcontroller.text, ref)) {
                        debugPrint('ログイン成功');

                        ///ログイン成功したタイミングでProviderのデータを更新しておく
                        await getData(ref);

                        ///画面遷移するコード
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ListPage()),
                        );
                      } else {
                        debugPrint('ログイン失敗');
                      }
                    },
                    child: Container(
                      alignment: Alignment.center,
                      width: 150,
                      child: const Text('LOGIN'),
                    )),
              ),
              Container(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton(
                  onPressed: () async {
                    if (await createAccount(
                        mailcontroller.text, passcontroller.text, ref)) {
                      debugPrint('アカウント作成成功');

                      ///画面遷移するコード
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ListPage()),
                      );
                    } else {
                      debugPrint('アカウント作成失敗');
                    }
                  },
                  child: Container(
                    alignment: Alignment.center,
                    width: 150,
                    child: const Text('CREATE ACCOUNT'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

///ConsumerWidgetに変えておく
class ListPage extends ConsumerWidget {
  const ListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ///Providerの値が入っているdocs変数を定義する
    final docs = ref.watch(documentsProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ///ボタンをクリックしたらDialogを出す
          showDialog(
              context: context,
              builder: (_) {
                return const ListAddDialog();
              });
        },
        tooltip: 'リスト追加',
        child: const Icon(Icons.add),
      ),
      body: Center(
        child: Column(
          children: [
            Container(
                height: 300,
                width: 300,
                margin: const EdgeInsets.only(bottom: 30),
                child: ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Card(
                        child: ListTile(
                          title: SizedBox(
                            height: 50,
                            child: Center(child: Text(docs[index])),
                          ),
                          onTap: () {
                            ///リストをクリックしたらデータを削除する
                            ///クリックしたデータはindexに入っている
                            deleteData(ref, index);
                          },
                        ),
                      );
                    })),
            ElevatedButton(
                onPressed: () {
                  ///ログアウトボタンを押したらログアウト処理をしログイン画面に戻る
                  logOut();
                  Navigator.pop(context);
                },
                child: const Text('ログアウト'))
          ],
        ),
      ),
    );
  }
}

///ConsumerWidgetに変えておく
class ListAddDialog extends ConsumerWidget {
  const ListAddDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    return AlertDialog(
      content: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
            ),
            Container(
              margin: const EdgeInsets.only(top: 30),
              child: ElevatedButton(
                onPressed: () async {
                  ///データを保存するボタンでデータを作る
                  await createData(ref, controller.text);

                  ///保存したらDialogを閉じる
                  Navigator.pop(context);
                },
                child: const Text('保存'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
