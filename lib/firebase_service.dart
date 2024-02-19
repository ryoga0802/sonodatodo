import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///ユーザーのidをアプリ側に保管しておくProvider
final uidProvider = StateProvider<String>((ref) {
  return '';
});

///Firebaseに保存してあるドキュメントをアプリ側にを保管しておくProvider
final documentsProvider = StateProvider<List>((ref) {
  return [];
});

///Firebaseに保存してあるドキュメントidをアプリ側にを保管しておくProvider
final docIdsProvider = StateProvider<List>((ref) {
  return [];
});

///アカウントを作るための関数
Future<bool> createAccount(String email, String pass, WidgetRef ref) async {
  try {
    ///Firebase側にアカウント作成するようにリクエスト
    final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: pass,
    );

    ///アカウント作成したときにユーザーidのProviderの状態を変えておく
    final notifier = ref.read(uidProvider.notifier);
    notifier.state = result.user!.uid;
    return true;
  }

  /// アカウント作成に失敗した場合のエラー処理
  on FirebaseAuthException catch (e) {
    /// パスワードが弱い場合
    if (e.code == 'weak-password') {
      debugPrint('パスワードが弱いです');
      return false;

      /// メールアドレスが既に使用中の場合
    } else if (e.code == 'email-already-in-use') {
      debugPrint('すでに使用されているメールアドレスです');
      return false;
    }

    /// その他エラー
    else {
      debugPrint('アカウント作成エラー');
      return false;
    }
  } catch (e) {
    debugPrint('$e');
    return false;
  }
}

///ログインするための関数
Future<bool> logIn(String email, String pass, WidgetRef ref) async {
  try {
    ///Firebase側にログインするようにリクエスト
    final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: pass,
    );

    ///ログインしたときにユーザーidのProviderの状態を変えておく
    final notifier = ref.read(uidProvider.notifier);
    notifier.state = result.user!.uid;
    return true;
  }

  /// サインインに失敗した場合のエラー処理
  on FirebaseAuthException catch (e) {
    /// メールアドレスが無効の場合
    if (e.code == 'invalid-email') {
      debugPrint('メールアドレスが無効です');
      return false;
    }

    /// ユーザーが存在しない場合
    else if (e.code == 'user-not-found') {
      debugPrint('ユーザーが存在しません');
      return false;
    }

    /// パスワードが間違っている場合
    else if (e.code == 'wrong-password') {
      debugPrint('パスワードが間違っています');
      return false;
    }

    /// その他エラー
    else {
      debugPrint('サインインエラー');
      return false;
    }
  }
}

///ログアウトするための関数
Future<void> logOut() async {
  try {
    await FirebaseAuth.instance.signOut();
    debugPrint('ログアウト成功');
  } catch (e) {
    debugPrint('データ作成失敗 $e');
    rethrow;
  }
}

///データを読み取る関数
Future getData(WidgetRef ref) async {
  final uid = ref.watch(uidProvider);
  final documentsNotifier = ref.read(documentsProvider.notifier);
  final docIdsNotifier = ref.read(docIdsProvider.notifier);
  try {
    ///保存してあるデータを読み込んでいる
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('todos')
        .get()
        .then((QuerySnapshot snapshot) {
      ///読み込んだドキュメントのデータをProviderに詰め込んでいる
      documentsNotifier.state = [
        for (var doc in snapshot.docs) doc.get('text')
      ];

      ///読み込んだドキュメントidのデータをProviderに詰め込んでいる
      docIdsNotifier.state = [for (var doc in snapshot.docs) doc.id];
    });
    debugPrint('読み取り成功');
  } catch (e) {
    debugPrint('読み取り失敗 $e');
    rethrow;
  }
}

///データを作る関数
Future createData(WidgetRef ref, String text) async {
  final uid = ref.watch(uidProvider);
  try {
    ///データを作成している
    ///データの構造は user/*uid*/todos/*text* **はユーザーごとに異なるデータ
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('todos')
        .add({'text': text});
    debugPrint('データ作成成功');

    ///データを作った後にデータを読み取りProviderを更新している
    await getData(ref);
  } catch (e) {
    debugPrint('データ作成失敗 $e');
    rethrow;
  }
}

///データを削除する関数
Future deleteData(WidgetRef ref, int index) async {
  final uid = ref.watch(uidProvider);
  final docIds = ref.watch(docIdsProvider);
  try {
    ///データを削除している
    ///データの構造は user/*uid*/todos/*text* **はユーザーごとに異なるデータ
    ///*text*はProviderとListViewのindexを同期させてProviderから取得している
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('todos')
        .doc(docIds[index])
        .delete();
    debugPrint('削除成功');

    ///データを削除した後にデータを読み取りProviderを更新している
    await getData(ref);
  } catch (e) {
    debugPrint('削除失敗 $e');
    rethrow;
  }
}
