import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:dart_tree/dart_tree.dart';

void main() {
  test('adds one to input values', () {
    // AVLTreeSet<int> tree = AVLTreeSet<int>();
    RedBlackTreeSet<int> tree = RedBlackTreeSet<int>();
    tree.debug = true;
    Set<int> values = {};
    Random random = Random();

    ///增
    List.generate(130, (index) {
      int value = random.nextInt(2000);
      values.add(value);
      tree.add(value);
      if (values.length != tree.length || !tree.check()) {
        print('失败1:********************************************');
        print(values.toString());
        exit(0);
      }
    });

    Set<int> treeSet = tree.toSet();
    if(treeSet.length != values.length || !treeSet.containsAll(values)) {
      print('失败2:********************************************');
        print(values.toString());
        exit(0);
    }

    print('添加顺序：****************************');
    print(values.toString());

    ///删
    List.generate(values.length, (index) {
      int value = values.randomItem;
      tree.remove(value);
      values.remove(value);
      if (values.length != tree.length || !tree.check()) {
        print('失败3:********************************************');
        print(values.toString());
        exit(0);
      }
    });
  });
}

extension IterableExtension<E> on Iterable<E> {
  bool get isNotNullAndEmpty {
    if (this == null) {
      return false;
    } else {
      return this.isNotEmpty;
    }
  }

  E get firstOrNull => isNotNullAndEmpty ? first : null;

  int get notNulllength => this == null ? 0 : length;

  E get randomItem {
    if (isNotNullAndEmpty) {
      if (length == 1) return last;
      return elementAt(Random().nextInt(length));
    }
    return null;
  }
}