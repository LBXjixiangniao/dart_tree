import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:dart_tree/dart_tree.dart';

const int CirculateTime = 1000;
const int Length = 300;
const bool Debug = false;
void main() {
  test('Test Red-Black Set Tree', () {
    List.generate(CirculateTime, (index) {
      RedBlackTreeSet<int> tree = RedBlackTreeSet<int>();
      tree.debug = Debug;
      Set<int> values = {};
      Random random = Random();

      ///增
      List.generate(Length, (index) {
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
      if (treeSet.length != values.length || !treeSet.containsAll(values)) {
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
  });

  test('Test Red-Black Map Tree', () {
    List.generate(CirculateTime, (index) {
      RedBlackTreeMap<int, String> tree = RedBlackTreeMap<int, String>();
      tree.debug = Debug;
      Map<int, String> values = {};
      Random random = Random();

      ///增
      List.generate(Length, (index) {
        int value = random.nextInt(2000);
        values[value] = 'value:$value';
        tree[value] = 'value:$value';
        if (values.length != tree.length || !tree.check()) {
          print('失败1:********************************************');
          print(values.toString());
          exit(0);
        }
      });

      values.forEach((key, value) {
        if (tree[key] != value) {
          print('失败2：****************************');
          print(values.toString());
        }
      });

      print('添加顺序：****************************');
      print(values.toString());

      List<int> keys = tree.keys.toList();
      if (keys.length != values.length) {
        print('失败3：****************************');
      } else {
        ///查
        keys.forEach((key) {
          if(tree[key] != values[key]) {
            print('失败4：****************************');
          }
        });

        ///改
        keys.forEach((element) {
          values[element] = 'newValue';
          tree[element] = 'newValue';
        });
        if (values.length == tree.length && values.length == keys.length) {
          ///查
          tree.forEach((key, value) {
            if (value != 'newValue') {
              print('失败5：****************************');
            }
          });
        } else {
          print('失败6：****************************');
        }
      }

      ///删
      List.generate(values.length, (index) {
        int key = keys.randomItem;
        tree.remove(key);
        values.remove(key);
        if (values.length != tree.length || !tree.check()) {
          print('失败7:********************************************');
          print(values.toString());
          exit(0);
        }
      });
    });
  });

  test('Test Avl Tree', () {
    List.generate(CirculateTime, (index) {
      AVLTreeSet<int> tree = AVLTreeSet<int>();
      tree.debug = Debug;
      Set<int> values = {};
      Random random = Random();

      ///增
      List.generate(Length, (index) {
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
      if (treeSet.length != values.length || !treeSet.containsAll(values)) {
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
  });

  test('Test Avl Map Tree', () {
    List.generate(CirculateTime, (index) {
      AVLTreeMap<int, String> tree = AVLTreeMap<int, String>();
      tree.debug = Debug;
      Map<int, String> values = {};
      Random random = Random();

      ///增
      List.generate(Length, (index) {
        int value = random.nextInt(2000);
        values[value] = 'value:$value';
        tree[value] = 'value:$value';
        if (values.length != tree.length || !tree.check()) {
          print('失败1:********************************************');
          print(values.toString());
          exit(0);
        }
      });

      values.forEach((key, value) {
        if (tree[key] != value) {
          print('失败2：****************************');
          print(values.toString());
        }
      });

      print('添加顺序：****************************');
      print(values.toString());

      List<int> keys = tree.keys.toList();
      if (keys.length != values.length) {
        print('失败3：****************************');
      } else {
        ///查
        keys.forEach((key) {
          if(tree[key] != values[key]) {
            print('失败4：****************************');
          }
        });

        ///改
        keys.forEach((element) {
          values[element] = 'newValue';
          tree[element] = 'newValue';
        });
        if (values.length == tree.length && values.length == keys.length) {
          ///查
          tree.forEach((key, value) {
            if (value != 'newValue') {
              print('失败5：****************************');
            }
          });
        } else {
          print('失败6：****************************');
        }
      }

      ///删
      List.generate(values.length, (index) {
        int key = keys.randomItem;
        tree.remove(key);
        values.remove(key);
        if (values.length != tree.length || !tree.check()) {
          print('失败7:********************************************');
          print(values.toString());
          exit(0);
        }
      });
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
