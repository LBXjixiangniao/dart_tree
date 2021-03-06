part of 'dart_tree.dart';

enum _NodeColor { Black, Red }

/// RedBlack树节点
/**
 * 二叉树节点的平衡因子A的被定义为高度差（右子树高度-左子树高度）
 * 如果二叉搜索树所有节点的平衡因子在{-1,0,1}范围内，则称为RedBlack树
 * 如果节点平衡因子 < 0，被称为“左重”；如果节点平衡因子 > 0，被称为“右重”；如果节点平衡因子 == 0， 有时简称为“平衡”
 */
class _RedBlackTreeNode<K, Node extends _RedBlackTreeNode<K, Node>> extends _BinaryTreeNode<K, Node> {
  ///平衡因子，新节点没有子树，所以平衡因子为0
  _NodeColor color;
  _RedBlackTreeNode(K key) : super(key);

  _RedBlackTreeNode<K, Node> copy() {
    return _RedBlackTreeNode<K, Node>(key);
  }

  Node get grandparent => parent?.parent;

  ///兄弟姊妹
  Node get sibling {
    if (parent == null) return null;
    if (this == parent.left) {
      return parent.right;
    }
    return parent.left;
  }

  Node get uncle => parent?.sibling;

  @override
  String get debugString {
    if (color == _NodeColor.Black) {
      return '${key}b';
    } else if (color == _NodeColor.Red) {
      return '${key}r';
    } else {
      return key.toString();
    }
  }
}

/// 基于RedBlack树实现的Set的节点
class _RedBlackTreeSetNode<K> extends _RedBlackTreeNode<K, _RedBlackTreeSetNode<K>> {
  _RedBlackTreeSetNode(K key) : super(key);
  _RedBlackTreeSetNode<K> copy() {
    return _RedBlackTreeSetNode<K>(key);
  }
}

/// 基于RedBlack树实现的Map的节点
/// 一个包含value值的_RedBlackTreeNode
class _RedBlackTreeMapNode<K, V> extends _RedBlackTreeNode<K, _RedBlackTreeMapNode<K, V>> {
  V value;
  _RedBlackTreeMapNode(K key, this.value) : super(key);

  _RedBlackTreeMapNode<K, V> copy() {
    return _RedBlackTreeMapNode<K, V>(key, value);
  }

  @override
  void replaceWith(_RedBlackTreeMapNode<K, V> node) {
    super.replaceWith(node);
    value = node?.value;
  }
}

/// RedBlack树实现
abstract class _RedBlackTree<K, Node extends _RedBlackTreeNode<K, Node>> {
  // RedBlack树根节点
  Node get _root;
  set _root(Node newValue);

  /// RedBlack书中元素个数
  int _count = 0;

  /// 每次增删都会加1，用来识别并发修改
  int _modificationCount = 0;

  /// 用于比较
  Comparator<K> get _compare;

  /// 判断是否key有效
  _Predicate get _validKey;

  ///是否调试模式
  ///调试模式下增、删后会打印出整个RedBlack树，且搜索的时候会打印出查找路径
  bool debug = false;
  ValueChanged<String> debugPrintMethod;
  void debugPrint(String str) {
    if(debugPrintMethod != null) {
      debugPrintMethod.call(str);
    }
    else {
      print(str);
    }
  }

  ///单次左旋
  /**
   *  p
   *   \
   *    n
   *   /  \
   * t1     nnew
   *       /  \
   *      t2  t3
   *     
   *     p
   *      \
   *       nnew
   *      /   \
   *     n     t3
   *   /  \   
   * t1   t2
   *       
   */
  void _rotateLeft(Node n) {
    if (n == null || n.right == null) return;
    assert(() {
      if (debug) debugPrint('RotateLeft:${n.key.toString()}\n');
      return true;
    }());
    Node nnew = n.right;
    Node p = n.parent;
    assert(nnew != null); // Since the leaves of a red-black tree are empty,
    // they cannot become internal nodes.
    n.right = nnew.left;
    nnew.left = n;
    n.parent = nnew;
    // Handle other child/parent pointers.
    if (n.right != null) {
      n.right.parent = n;
    }

    // Initially n could be the root.
    if (p != null) {
      if (n == p.left) {
        p.left = nnew;
      } else if (n == p.right) {
        p.right = nnew;
      }
    }
    nnew.parent = p;
  }

  ///单次右旋
  /**
   * 
   *      p
   *       \
   *        n
   *      /   \
   *     nnew  t3
   *   /  \   
   * t1   t2
   * 
   *   p
   *    \
   *    nnew
   *   /   \
   * t1     n
   *       /  \
   *      t2  t3
   *       
   */
  void _rotateRight(Node n) {
    if (n == null || n.left == null) return;
    assert(() {
      if (debug) debugPrint('RotateRight:${n.key.toString()}\n');
      return true;
    }());
    Node nnew = n.left;
    Node p = n.parent;
    assert(nnew != null); // Since the leaves of a red-black tree are empty,
    // they cannot become internal nodes.

    n.left = nnew.right;
    nnew.right = n;
    n.parent = nnew;

    // Handle other child/parent pointers.
    if (n.left != null) {
      n.left.parent = n;
    }

    // Initially n could be the root.
    if (p != null) {
      if (n == p.left) {
        p.left = nnew;
      } else if (n == p.right) {
        p.right = nnew;
      }
    }
    nnew.parent = p;
  }

  void _insert(Node n, {Node root, _ReplaceCheck<Node> replaceIfExist}) {
    if (n == null) return;
    _DebugString searchPath = _DebugString();
    assert(() {
      if (debug) debugPrint('Insert:${n.key}**********************************\n');
      return true;
    }());
    // Insert new Node into the current tree.
    bool add = true;
    _insertRecurse(
      n,
      root: root ?? _root,
      replaceIfExist: (oldValue, newValue) {
        add = false;
        return replaceIfExist?.call(oldValue, newValue) ?? false;
      },
      searchPath: searchPath,
    );

    ///如果add为true，则树结构发生了变化
    if (add) {
      // Repair the tree in case any of the red-black properties have been violated.
      _insertRepairTree(n);

      // Find the new root to return.
      _resetRoot(n);
    }
    _modificationCount++;
    assert(() {
      if (debug) debugPrint(searchPath.value);
      return true;
    }());
    assert(() {
      if (debug) debugPrint('TreeStructure:${treeStructureString()}');
      return true;
    }());
    assert(() {
      if (debug) debugPrint('End Insert:${n.key}**********************************\n');
      return true;
    }());
  }

  void _insertRecurse(Node n, {Node root, _ReplaceCheck<Node> replaceIfExist, _DebugString searchPath}) {
    assert(n != null);
    assert(() {
      if (debug && root != null) searchPath.value += '->${root.key}';
      return true;
    }());
    // Recursively descend the tree until a leaf is found.
    if (root != null) {
      int com = _compare(n.key, root.key);
      if (com == 0) {
        if (replaceIfExist?.call(root, n) == true) {
          ///用node替换parent
          _replaceNode(root, n);
          return;
        }
      } else if (com < 0) {
        if (root.left != null) {
          _insertRecurse(
            n,
            root: root.left,
            replaceIfExist: replaceIfExist,
            searchPath: searchPath,
          );
          return;
        } else {
          root.left = n;
          _count++;
        }
      } else {
        // n.key >= root.key
        if (root.right != null) {
          _insertRecurse(
            n,
            root: root.right,
            replaceIfExist: replaceIfExist,
            searchPath: searchPath,
          );
          return;
        } else {
          root.right = n;
          _count++;
        }
      }
    } else {
      _count++;
    }

    // Insert new Node n.
    n.parent = root;
    n.left = null;
    n.right = null;
    n.color = _NodeColor.Red;
  }

  void _insertRepairTree(Node n) {
    if (n == null) return;
    if (n.parent == null) {
      _insertCase1(n);
    } else if (n.parent.color == _NodeColor.Black) {
      _insertCase2(n);
    } else if (n.uncle != null && n.uncle.color == _NodeColor.Red) {
      _insertCase3(n);
    } else {
      _insertCase4(n);
    }
  }

  ///n是_root，要设置为黑色
  void _insertCase1(Node n) {
    assert(n != null);
    assert(() {
      if (debug) debugPrint('InserCase1\n');
      return true;
    }());
    n.color = _NodeColor.Black;
  }

  ///n的父节点是黑色，则插入红色的n不违反红黑树性质
  void _insertCase2(Node n) {
    // Do nothing since tree is still valid.
    assert(() {
      if (debug) debugPrint('InserCase2\n');
      return true;
    }());
    return;
  }

  ///n的parent和uncle都是红色
  ///将grandparent设置为红色，parent和uncle设置为黑色
  ///此时grandparent就类似是新插入的红色节点，需要重新平衡
  /**
   *            G(B)
   *          /   \
   *        P(R)    U(R)
   *       /  \    /  \
   *     N(R) t3  t4  t5
   *     /  \
   *    t1   t2
   * 
   *           G(R)
   *          /   \
   *        P(B)    U(B)
   *       /  \    /  \
   *     N(R) t3  t4  t5
   *     /  \
   *    t1   t2
   */
  void _insertCase3(Node n) {
    assert(n != null);
    assert(() {
      if (debug) debugPrint('InserCase3\n');
      return true;
    }());
    n.parent.color = _NodeColor.Black;
    n.uncle.color = _NodeColor.Black;
    n.grandparent?.color = _NodeColor.Red;
    _insertRepairTree(n.grandparent);
  }

  ///n是红色，n的parent是红色，n的uncle是黑色
  ///_insertCase4是将N、P、G弄成一条直线的形式，以使用_insertCase4Step2
  /**
   *        G
   *      /   \
   *     P(R)   U
   *   /  \    /  \
   * t1  N(R) t4   t5
   *     /  \
   *    t2   t3
   * 
   *            G
   *          /   \
   *        N(R)    U
   *       /  \    /  \
   *     P(R) t3  t4  t5
   *     /  \
   *    t1   t2
   */
  void _insertCase4(Node n) {
    assert(n != null);
    assert(() {
      if (debug) debugPrint('InserCase4\n');
      return true;
    }());
    Node p = n.parent;
    Node g = n.grandparent;

    if (n == p?.right && p == g?.left) {
      _rotateLeft(p);
      n = n.left;
    } else if (n == p?.left && p == g?.right) {
      _rotateRight(p);
      n = n.right;
    }

    _insertCase4Step2(n);
  }

/**
 
   *           G(B)
   *          /   \
   *        P(R)    U(B)
   *       /  \    /  \
   *     N(R) t3  t4  t5
   *     /  \
   *    t1   t2
   *         
   *       P(B)
   *      /   \
   *     N(R)  G(R)
   *   /  \    /  \
   * t1   t2   t3 U(B) 
   *              /  \
   *             t4   t5
   * 
   *
 */
  void _insertCase4Step2(Node n) {
    assert(n != null);
    assert(() {
      if (debug) debugPrint('InserCase4Step2\n');
      return true;
    }());
    Node p = n.parent;
    Node g = n.grandparent;

    if (n == p?.left) {
      _rotateRight(g);
    } else {
      _rotateLeft(g);
    }
    p?.color = _NodeColor.Black;
    g?.color = _NodeColor.Red;
  }

  ///删除
  ///key: 需要删除的节点的key值
  ///root：指定查找的根结点，如果root不为null，则会从root开始查找key删除node
  Node _delete(K key, {Node root}) {
    String searchPath = 'SearchPath:';
    assert(() {
      if (debug) debugPrint('Delete:$key**********************************\n');
      return true;
    }());

    if (_root == null || key == null)
      return null;
    else {
      var compare = _compare;
      int comp;

      Node remove(Node parent) {
        if (parent == null) return null;
        assert(() {
          if (debug) searchPath += '->${parent.key}';
          return true;
        }());
        comp = compare(key, parent.key);
        if (comp == 0) {
          if (parent.left != null && parent.right != null) {
            Node min = _findMin(root: parent.right);
            _deleteOneChild(min);
            _replaceNode(parent, min);
          } else {
            _deleteOneChild(parent);
          }
          _count--;
          _modificationCount++;
          return parent;
        } else if (comp < 0) {
          return remove(parent.left);
        } else {
          return remove(parent.right);
        }
      }

      Node deletedNode = remove(root ?? _root);
      assert(() {
        if (debug) debugPrint(searchPath);
        return true;
      }());
      assert(() {
        if (debug) debugPrint('TreeStructure:${treeStructureString()}');
        return true;
      }());
      assert(() {
        if (debug) debugPrint('End Delete:$key**********************************\n');
        return true;
      }());
      return deletedNode?.copy();
    }
  }

  ///用newNode代替oldNode，newNode的parent、left、right都是从oldNode来
  void _replaceNode(Node oldNode, Node newNode) {
    assert(() {
      if (debug) debugPrint('Replace ${oldNode.key.toString()} with ${newNode.key.toString()}\n');
      return true;
    }());
    if (oldNode == null) return;
    oldNode.replaceWith(newNode);
  }

  ///child是n的子节点，child没有兄弟姐妹
  ///用child代替n在n.parent中的位置
  void _replaceNodeInParent(Node n, Node child) {
    if (n == null) return null;

    child?.parent = n.parent;
    if (n == _root) {
      _root = child;
      _root.color = _NodeColor.Black;
      return;
    }

    if (n == n.parent?.left) {
      n.parent?.left = child;
    } else {
      n.parent?.right = child;
    }
  }

  //删除最多只有一个子节点的节点
  void _deleteOneChild(Node n) {
    assert(() {
        if (debug) debugPrint('DeleteOneChild:${n.key}**********************************\n');
        return true;
      }());
    // Precondition: n has at most one non-leaf child.
    Node child = (n.right == null) ? n.left : n.right;
    bool isLeaf = child == null;

    if (isLeaf) {
      //如果child是null，则表面其是叶子节点，所以此处添加一个空值的叶子结点以便于做树的平衡操作
      child ??= n.copy()..color = _NodeColor.Black;
    }
    _replaceNodeInParent(n, child);
    if (n.color == _NodeColor.Black) {
      if (child?.color == _NodeColor.Red) {
        child.color = _NodeColor.Black;
      } else {
        _deleteCase1(child);
      }
    }
    n.parent = null;
    n.left = null;
    n.right = null;

    _resetRoot(child);
    if (isLeaf) {
      //删除叶子节点
      if (child.parent == null) {
        _root = null;
      } else if (child == child.parent.left) {
        child.parent.left = null;
      } else if (child == child.parent.right) {
        child.parent.right = null;
      }
      child = null;
    }
  }

  ///删除了n.parent（黑色节点），且n是黑色
  ///n一定有非子叶兄弟
  ///n是新的根节点，且是黑色的，不做处理
  void _deleteCase1(Node n) {
    if (n?.parent != null) {
      _deleteCase2(n);
    } else {
      assert(() {
        if (debug) debugPrint('DeleteCase1:${n.key}\n');
        return true;
      }());
    }
  }

  ///由于N是黑色，且刚删了一个黑色，所以N的兄弟子树至少有两个黑色节点，所以SL和SR不是叶子节点
  ///N一定有父亲
/**
 *         P(B)
   *      /   \
   *     N(B)  S(R)
   *   /  \    /   \
   * t1   t2  SL(B) SR(B) 
   *              
   *           S(B)
   *          /   \
   *        P(R)   SR(B)
   *       /  \    
   *     N(B) SL(B) 
   *     /  \
   *    t1   t2
 */
  void _deleteCase2(Node n) {
    Node s = n.sibling;

    if (s.color == _NodeColor.Red) {
      assert(() {
        if (debug) debugPrint('DeleteCase2:${n.key}\n');
        return true;
      }());
      n.parent.color = _NodeColor.Red;
      s.color = _NodeColor.Black;
      if (n == n.parent.left) {
        _rotateLeft(n.parent);
      } else {
        _rotateRight(n.parent);
      }
    }
    _deleteCase3(n);
  }

/**
 *         P(B)
   *      /   \
   *     N(B)  S(B)
   *   /  \    /    \
   * t1   t2  t3(B) t4(B)
   * 
   *       P(B)
   *      /   \
   *     N(B)  S(R)
   *   /  \    /    \
   * t1   t2  t3(B) t4(B) 
 */
  void _deleteCase3(Node n) {
    Node s = n.sibling;

    if ((n.parent.color == _NodeColor.Black) &&
        (s.color == _NodeColor.Black) &&
        (s.left == null || s.left.color == _NodeColor.Black) &&
        (s.right == null || s.right.color == _NodeColor.Black)) {
      assert(() {
        if (debug) debugPrint('DeleteCase3:${n.key}\n');
        return true;
      }());
      s.color = _NodeColor.Red;
      _deleteCase1(n.parent);
    } else {
      _deleteCase4(n);
    }
  }

/**
 *         P(R)
   *      /   \
   *    N(B)  S(B)
   *   /  \    /   \
   * t1   t2  SL(B) SR(B) 
   * 
   *       P(B)
   *      /   \
   *    N(B)  S(R)
   *   /  \    /   \
   * t1   t2  SL(B) SR(B) 
 */
  void _deleteCase4(Node n) {
    Node s = n.sibling;

    if ((n.parent.color == _NodeColor.Red) &&
        (s.color == _NodeColor.Black) &&
        (s.left == null || s.left.color == _NodeColor.Black) &&
        (s.right == null || s.right.color == _NodeColor.Black)) {
      assert(() {
        if (debug) debugPrint('DeleteCase4:${n.key}\n');
        return true;
      }());
      s.color = _NodeColor.Red;
      n.parent.color = _NodeColor.Black;
    } else {
      _deleteCase5(n);
    }
  }

/**
 *         S(B)
   *      /   \
   *    SL(R)  t1(B)
   *   /  \    
   * (B)  (B) 
   * 
   *       SL(B)
   *      /   \
   *    (B)  S(R)
   *        /   \
   *      (B)    t1(B) 
   *             
 */
  void _deleteCase5(Node n) {
    Node s = n.sibling;

    // This if statement is trivial, due to case 2 (even though case 2 changed
    // the sibling to a sibling's child, the sibling's child can't be red, since
    // no red parent can have a red child).
    if (s.color == _NodeColor.Black) {
      assert(() {
        if (debug) debugPrint('DeleteCase5:${n.key}\n');
        return true;
      }());
      // The following statements just force the red to be on the left of the
      // left of the parent, or right of the right, so case six will rotate
      // correctly.
      if ((n == n.parent.left) && (s.right == null || s.right.color == _NodeColor.Black) && (s.left?.color == _NodeColor.Red)) {
        // This last test is trivial too due to cases 2-4.
        s.color = _NodeColor.Red;
        s.left.color = _NodeColor.Black;
        _rotateRight(s);
      } else if ((n == n.parent.right) &&
          (s.left == null || s.left.color == _NodeColor.Black) &&
          (s.right?.color == _NodeColor.Red)) {
        // This last test is trivial too due to cases 2-4.
        s.color = _NodeColor.Red;
        s.right?.color = _NodeColor.Black;
        _rotateLeft(s);
      }
    }
    _deleteCase6(n);
  }

/**
 *         P(B/R)
   *      /   \
   *    N(B)  S(B)
   *         /   \
   *       (B)    SR(R) 
   *             /   \
   *            t1   t2
   * 
   * S的颜色是P之前的颜色
   *           S(B/R)
   *          /   \
   *        P(B)    SR(B)
   *       /  \    /  \
   *     N(B) (B)  t1  t2
   *
 */
  void _deleteCase6(Node n) {
    assert(() {
      if (debug) debugPrint('DeleteCase6:${n.key}\n');
      return true;
    }());
    Node s = n.sibling;

    s.color = n.parent.color;
    n.parent.color = _NodeColor.Black;

    if (n == n.parent.left) {
      s.right.color = _NodeColor.Black;
      _rotateLeft(n.parent);
    } else {
      s.left.color = _NodeColor.Black;
      _rotateRight(n.parent);
    }
  }

  ///往上遍历重新设置_root
  void _resetRoot(Node node) {
    // Find the new root to return.
    while (node?.parent != null) {
      node = node.parent;
    }
    _root = node;
  }

  ///查找node.key == key的node
  ///root：指定查找的根结点，如果root不为null，则会从root开始查找
  Node _search(K key, {Node root}) {
    String searchPath = 'SearchPath:';
    assert(() {
      if (debug) debugPrint('Search:**********************************\n');
      return true;
    }());
    if (_root == null || key == null)
      return null;
    else {
      var compare = _compare;
      int comp;
      int initialModificationCount = _modificationCount;
      Node searchRecursively(Node parent) {
        if (parent == null) return null;
        assert(() {
          if (debug) searchPath += '->${parent.key}';
          return true;
        }());
        if (initialModificationCount != _modificationCount) {
          throw ConcurrentModificationError(this);
        }
        comp = compare(key, parent.key);
        if (comp == 0) {
          return parent;
        } else if (comp < 0) {
          return searchRecursively(parent.left);
        } else {
          return searchRecursively(parent.right);
        }
      }

      Node resultNode = searchRecursively(root ?? _root);
      assert(() {
        if (debug) debugPrint(searchPath);
        return true;
      }());
      return resultNode;
    }
  }

  ///查找最小值
  ///root：指定查找的根结点，如果root不为null，则会从root开始查找
  Node _findMin({Node root}) {
    Node minNode = root ?? _root;
    if (minNode == null) return minNode;
    while (minNode.left != null) {
      minNode = minNode.left;
    }
    return minNode;
  }

  ///查找最大值
  ///root：指定查找的根结点，如果root不为null，则会从root开始查找
  Node _findMax({Node root}) {
    Node minNode = root ?? _root;
    if (minNode == null) return minNode;
    while (minNode.right != null) {
      minNode = minNode.right;
    }
    return minNode;
  }

  Node get _first {
    return _findMin();
  }

  Node get _last {
    return _findMax();
  }

  /// Get the last node in the tree that is strictly smaller than [key]. Returns
  /// `null` if no key was not found.
  Node _lastBefore(K key) {
    if (key == null) throw ArgumentError(key);
    if (_root == null) return null;
    var compare = _compare;
    int comp;
    int initialModificationCount = _modificationCount;
    Node resultNode;
    void searchRecursively(Node parent) {
      if (parent == null) return;
      if (initialModificationCount != _modificationCount) {
        throw ConcurrentModificationError(this);
      }
      comp = compare(key, parent.key);
      if (comp == 0) {
        return;
      } else if (comp < 0) {
        return searchRecursively(parent.left);
      } else {
        resultNode = parent;
        return searchRecursively(parent.right);
      }
    }

    searchRecursively(_root);
    return resultNode;
  }

  /// Get the first node in the tree that is strictly larger than [key]. Returns
  /// `null` if no key was not found.
  Node _firstAfter(K key) {
    if (key == null) throw ArgumentError(key);
    if (_root == null) return null;
    var compare = _compare;
    int comp;
    int initialModificationCount = _modificationCount;
    Node resultNode;
    void searchRecursively(Node parent) {
      if (parent == null) return;
      if (initialModificationCount != _modificationCount) {
        throw ConcurrentModificationError(this);
      }
      comp = compare(key, parent.key);
      if (comp == 0) {
        return;
      } else if (comp < 0) {
        resultNode = parent;
        return searchRecursively(parent.left);
      } else {
        return searchRecursively(parent.right);
      }
    }

    searchRecursively(_root);
    return resultNode;
  }

  void _clear() {
    _root = null;
    _count = 0;
    _modificationCount++;
  }

  String treeStructureString() {
    return _BinaryTreePrinter.treeStructureString(_root);
  }

  @visibleForTesting
  bool check() {
    ///返回子黑色节点数量，如果node.left.key < node.key < node.right.key 且 node.lefty与node.right黑色节点数量不相等立则返回null
    int checkNode(Node node) {
      if (node == null) {
        return 0;
      } else {
        ///满足二叉搜索树规则
        bool result = true;
        Node left = node.left;
        Node right = node.right;
        if (left != null && _compare(left.key, node.key) >= 0) {
          result = false;
        }

        if (result && right != null && _compare(right.key, node.key) <= 0) {
          result = false;
        }

        if (result) {
          ///如果节点为红色，则其两个子节点均为黑色
          if (node.color == _NodeColor.Red) {
            if (node.left?.color == _NodeColor.Red || node.right?.color == _NodeColor.Red) return null;
          }
          else if(node.color != _NodeColor.Black) {
            ///每个节点是红色或黑色
            return null;
          }

          ///从给定节点到其任何后代NIL节点的每条路径都经过相同数量的黑色节点。
          int leftBlackNodeNumber = checkNode(node.left);
          if (leftBlackNodeNumber == null) return null;
          int rightBlacktNodeNumber = checkNode(node.right);
          if (rightBlacktNodeNumber == null) return null;
          if (leftBlackNodeNumber != rightBlacktNodeNumber) return null;

          return leftBlackNodeNumber + (node.color == _NodeColor.Black ? 1 : 0);
        } else {
          return null;
        }
      }
    }

    ///根是黑色的
    return (_root == null || _root.color == _NodeColor.Black) && checkNode(_root) != null;
  }
}

/// A [Map] of objects that can be ordered relative to each other.
///
/// The map is based on a RedBlack tree. It allows most operations
/// in amortized logarithmic time.
///
/// Keys of the map are compared using the `compare` function passed in
/// the constructor, both for ordering and for equality.
/// If the map contains only the key `a`, then `map.containsKey(b)`
/// will return `true` if and only if `compare(a, b) == 0`,
/// and the value of `a == b` is not even checked.
/// If the compare function is omitted, the objects are assumed to be
/// [Comparable], and are compared using their [Comparable.compareTo] method.
/// Non-comparable objects (including `null`) will not work as keys
/// in that case.
///
/// To allow calling [operator []], [remove] or [containsKey] with objects
/// that are not supported by the `compare` function, an extra `isValidKey`
/// predicate function can be supplied. This function is tested before
/// using the `compare` function on an argument value that may not be a [K]
/// value. If omitted, the `isValidKey` function defaults to testing if the
/// value is a [K].
class RedBlackTreeMap<K, V> extends _RedBlackTree<K, _RedBlackTreeMapNode<K, V>> with MapMixin<K, V> {
  _RedBlackTreeMapNode<K, V> _root;

  Comparator<K> _compare;
  _Predicate _validKey;

  RedBlackTreeMap([int Function(K key1, K key2) compare, bool Function(dynamic potentialKey) isValidKey])
      : _compare = compare ?? _defaultCompare<K>(),
        _validKey = isValidKey ?? ((dynamic v) => v is K);

  /// Creates a [RedBlackTreeMap] that contains all key/value pairs of [other].
  ///
  /// The keys must all be instances of [K] and the values of [V].
  /// The [other] map itself can have any type.
  factory RedBlackTreeMap.from(Map<dynamic, dynamic> other,
      [int Function(K key1, K key2) compare, bool Function(dynamic potentialKey) isValidKey]) {
    if (other is Map<K, V>) {
      return RedBlackTreeMap<K, V>.of(other, compare, isValidKey);
    }
    RedBlackTreeMap<K, V> result = RedBlackTreeMap<K, V>(compare, isValidKey);
    other.forEach((dynamic k, dynamic v) {
      result[k] = v;
    });
    return result;
  }

  /// Creates a [RedBlackTreeMap] that contains all key/value pairs of [other].
  factory RedBlackTreeMap.of(Map<K, V> other,
          [int Function(K key1, K key2) compare, bool Function(dynamic potentialKey) isValidKey]) =>
      RedBlackTreeMap<K, V>(compare, isValidKey)..addAll(other);

  /// Creates a [RedBlackTreeMap] where the keys and values are computed from the
  /// [iterable].
  ///
  /// For each element of the [iterable] this constructor computes a key/value
  /// pair, by applying [key] and [value] respectively.
  ///
  /// The keys of the key/value pairs do not need to be unique. The last
  /// occurrence of a key will simply overwrite any previous value.
  ///
  /// If no functions are specified for [key] and [value] the default is to
  /// use the iterable value itself.
  factory RedBlackTreeMap.fromIterable(Iterable iterable,
      {K Function(dynamic element) key,
      V Function(dynamic element) value,
      int Function(K key1, K key2) compare,
      bool Function(dynamic potentialKey) isValidKey}) {
    RedBlackTreeMap<K, V> map = RedBlackTreeMap<K, V>(compare, isValidKey);
    _CustomMapBase.fillMapWithMappedIterable(map, iterable, key, value);
    return map;
  }

  /// Creates a [RedBlackTreeMap] associating the given [keys] to [values].
  ///
  /// This constructor iterates over [keys] and [values] and maps each element
  /// of [keys] to the corresponding element of [values].
  ///
  /// If [keys] contains the same object multiple times, the last occurrence
  /// overwrites the previous value.
  ///
  /// It is an error if the two [Iterable]s don't have the same length.
  factory RedBlackTreeMap.fromIterables(Iterable<K> keys, Iterable<V> values,
      [int Function(K key1, K key2) compare, bool Function(dynamic potentialKey) isValidKey]) {
    RedBlackTreeMap<K, V> map = RedBlackTreeMap<K, V>(compare, isValidKey);
    _CustomMapBase.fillMapWithIterables(map, keys, values);
    return map;
  }

  V operator [](Object key) {
    if (!_validKey(key)) return null;
    return _search(key)?.value;
  }

  V remove(Object key) {
    if (!_validKey(key)) return null;
    return _delete(key)?.value;
  }

  void operator []=(K key, V value) {
    if (key == null) throw ArgumentError(key);
    _RedBlackTreeMapNode<K, V> node = _RedBlackTreeMapNode<K, V>(key, value);
    _insert(node, replaceIfExist: (_, __) => true);
  }

  V putIfAbsent(K key, V ifAbsent()) {
    if (key == null) throw ArgumentError(key);
    _RedBlackTreeMapNode<K, V> node = _RedBlackTreeMapNode<K, V>(key, null);
    bool absent = true;
    _insert(
      node,
      replaceIfExist: (oldValue, newValue) {
        ///存在对应的key
        absent = false;
        node.value = oldValue.value;
        return false;
      },
    );
    if (absent) {
      int modificationCount = _modificationCount;
      node.value = ifAbsent();
      if (modificationCount != _modificationCount) {
        throw ConcurrentModificationError(this);
      }
    }
    return node.value;
  }

  void addAll(Map<K, V> other) {
    other.forEach((K key, V value) {
      this[key] = value;
    });
  }

  bool get isEmpty {
    return (_root == null);
  }

  bool get isNotEmpty => !isEmpty;

  void forEach(void f(K key, V value)) {
    Iterator<_RedBlackTreeMapNode<K, V>> nodes = _RedBlackTreeNodeIterator<K, _RedBlackTreeMapNode<K, V>>(this);
    while (nodes.moveNext()) {
      _RedBlackTreeMapNode<K, V> node = nodes.current;
      f(node.key, node.value);
    }
  }

  int get length {
    return _count;
  }

  void clear() {
    _clear();
  }

  bool containsKey(Object key) {
    return _validKey(key) && _search(key) != null;
  }

  bool containsValue(Object value) {
    int initialModificationCount = _modificationCount;
    bool visit(_RedBlackTreeMapNode<K, V> node) {
      while (node != null) {
        if (node.value == value) return true;
        if (initialModificationCount != _modificationCount) {
          throw ConcurrentModificationError(this);
        }
        if (node.right != null && visit(node.right)) {
          return true;
        }
        node = node.left;
      }
      return false;
    }

    return visit(_root);
  }

  Iterable<K> get keys => _RedBlackTreeKeyIterable<K, _RedBlackTreeMapNode<K, V>>(this);

  Iterable<V> get values => _RedBlackTreeValueIterable<K, V>(this);

  /// Get the first key in the map. Returns `null` if the map is empty.
  K firstKey() {
    if (_root == null) return null;
    return _first.key;
  }

  /// Get the last key in the map. Returns `null` if the map is empty.
  K lastKey() {
    if (_root == null) return null;
    return _last.key;
  }

  /// Get the last key in the map that is strictly smaller than [key]. Returns
  /// `null` if no key was not found.
  K lastKeyBefore(K key) {
    return _lastBefore(key)?.key;
  }

  /// Get the first key in the map that is strictly larger than [key]. Returns
  /// `null` if no key was not found.
  K firstKeyAfter(K key) {
    return _firstAfter(key)?.key;
  }
}

abstract class _RedBlackTreeIterator<K, Node extends _RedBlackTreeNode<K, Node>, T> implements Iterator<T> {
  final _RedBlackTree<K, Node> _tree;

  /// Worklist of nodes to visit.
  ///
  /// These nodes have been passed over on the way down in a
  /// depth-first left-to-right traversal. Visiting each node,
  /// and their right subtrees will visit the remainder of
  /// the nodes of a full traversal.
  ///
  /// Only valid as long as the original tree isn't reordered.
  final List<Node> _workList = [];

  /// Original modification counter of [_tree].
  ///
  /// Incremented on [_tree] when a key is added or removed.
  /// If it changes, iteration is aborted.
  ///
  /// Not final because some iterators may modify the tree knowingly,
  /// and they update the modification count in that case.
  int _modificationCount;

  /// Current node.
  Node _currentNode;

  _RedBlackTreeIterator(_RedBlackTree<K, Node> tree)
      : _tree = tree,
        _modificationCount = tree._modificationCount {
    _findLeftMostDescendent(tree._root);
  }

  T get current {
    var node = _currentNode;
    if (node == null) return null as T;
    return _getValue(node);
  }

  void _findLeftMostDescendent(Node node) {
    while (node != null) {
      _workList.add(node);
      node = node.left;
    }
  }

  bool moveNext() {
    if (_modificationCount != _tree._modificationCount) {
      throw ConcurrentModificationError(_tree);
    }
    // Picks the next element in the worklist as current.
    // Updates the worklist with the left-most path of the current node's
    // right-hand child.
    // If the worklist is no longer valid (after a splay), it is rebuild
    // from scratch.
    if (_workList.isEmpty) {
      _currentNode = null;
      return false;
    }

    _currentNode = _workList.removeLast();
    _findLeftMostDescendent(_currentNode.right);
    return true;
  }

  T _getValue(Node node);
}

class _RedBlackTreeKeyIterable<K, Node extends _RedBlackTreeNode<K, Node>> extends Iterable<K> {
  _RedBlackTree<K, Node> _tree;
  _RedBlackTreeKeyIterable(this._tree);
  int get length => _tree._count;
  bool get isEmpty => _tree._count == 0;
  Iterator<K> get iterator => _RedBlackTreeKeyIterator<K, Node>(_tree);

  Set<K> toSet() {
    RedBlackTreeSet<K> set = RedBlackTreeSet<K>(_tree._compare, _tree._validKey);
    set._count = _tree._count;
    set._root = set._copyNode<Node>(_tree._root);
    return set;
  }
}

class _RedBlackTreeValueIterable<K, V> extends Iterable<V> {
  RedBlackTreeMap<K, V> _map;
  _RedBlackTreeValueIterable(this._map);
  int get length => _map._count;
  bool get isEmpty => _map._count == 0;
  Iterator<V> get iterator => _RedBlackTreeValueIterator<K, V>(_map);
}

class _RedBlackTreeKeyIterator<K, Node extends _RedBlackTreeNode<K, Node>> extends _RedBlackTreeIterator<K, Node, K> {
  _RedBlackTreeKeyIterator(_RedBlackTree<K, Node> map) : super(map);
  K _getValue(Node node) => node.key;
}

class _RedBlackTreeValueIterator<K, V> extends _RedBlackTreeIterator<K, _RedBlackTreeMapNode<K, V>, V> {
  _RedBlackTreeValueIterator(RedBlackTreeMap<K, V> map) : super(map);
  V _getValue(_RedBlackTreeMapNode<K, V> node) => node.value;
}

class _RedBlackTreeNodeIterator<K, Node extends _RedBlackTreeNode<K, Node>>
    extends _RedBlackTreeIterator<K, Node, Node> {
  _RedBlackTreeNodeIterator(_RedBlackTree<K, Node> tree) : super(tree);
  Node _getValue(Node node) => node;
}

/// A [Set] of objects that can be ordered relative to each other.
///
/// The set is based on a self-balancing binary tree. It allows most operations
/// in amortized logarithmic time.
///
/// Elements of the set are compared using the `compare` function passed in
/// the constructor, both for ordering and for equality.
/// If the set contains only an object `a`, then `set.contains(b)`
/// will return `true` if and only if `compare(a, b) == 0`,
/// and the value of `a == b` is not even checked.
/// If the compare function is omitted, the objects are assumed to be
/// [Comparable], and are compared using their [Comparable.compareTo] method.
/// Non-comparable objects (including `null`) will not work as an element
/// in that case.
class RedBlackTreeSet<E> extends _RedBlackTree<E, _RedBlackTreeSetNode<E>> with IterableMixin<E>, SetMixin<E> {
  _RedBlackTreeSetNode<E> _root;

  Comparator<E> _compare;
  _Predicate _validKey;

  /// Create a new [RedBlackTreeSet] with the given compare function.
  ///
  /// If the [compare] function is omitted, it defaults to [Comparable.compare],
  /// and the elements must be comparable.
  ///
  /// A provided `compare` function may not work on all objects. It may not even
  /// work on all `E` instances.
  ///
  /// For operations that add elements to the set, the user is supposed to not
  /// pass in objects that doesn't work with the compare function.
  ///
  /// The methods [contains], [remove], [lookup], [removeAll] or [retainAll]
  /// are typed to accept any object(s), and the [isValidKey] test can used to
  /// filter those objects before handing them to the `compare` function.
  ///
  /// If [isValidKey] is provided, only values satisfying `isValidKey(other)`
  /// are compared using the `compare` method in the methods mentioned above.
  /// If the `isValidKey` function returns false for an object, it is assumed to
  /// not be in the set.
  ///
  /// If omitted, the `isValidKey` function defaults to checking against the
  /// type parameter: `other is E`.
  RedBlackTreeSet([int Function(E key1, E key2) compare, bool Function(dynamic potentialKey) isValidKey])
      : _compare = compare ?? _defaultCompare<E>(),
        _validKey = isValidKey ?? ((dynamic v) => v is E);

  /// Creates a [RedBlackTreeSet] that contains all [elements].
  ///
  /// The set works as if created by `new RedBlackTreeSet<E>(compare, isValidKey)`.
  ///
  /// All the [elements] should be instances of [E] and valid arguments to
  /// [compare].
  /// The `elements` iterable itself may have any element type, so this
  /// constructor can be used to down-cast a `Set`, for example as:
  /// ```dart
  /// Set<SuperType> superSet = ...;
  /// Set<SubType> subSet =
  ///     new RedBlackTreeSet<SubType>.from(superSet.whereType<SubType>());
  /// ```
  factory RedBlackTreeSet.from(Iterable elements,
      [int Function(E key1, E key2) compare, bool Function(dynamic potentialKey) isValidKey]) {
    if (elements is Iterable<E>) {
      return RedBlackTreeSet<E>.of(elements, compare, isValidKey);
    }
    RedBlackTreeSet<E> result = RedBlackTreeSet<E>(compare, isValidKey);
    for (var element in elements) {
      result.add(element as dynamic);
    }
    return result;
  }

  /// Creates a [RedBlackTreeSet] from [elements].
  ///
  /// The set works as if created by `new RedBlackTreeSet<E>(compare, isValidKey)`.
  ///
  /// All the [elements] should be valid as arguments to the [compare] function.
  factory RedBlackTreeSet.of(Iterable<E> elements,
          [int Function(E key1, E key2) compare, bool Function(dynamic potentialKey) isValidKey]) =>
      RedBlackTreeSet(compare, isValidKey)..addAll(elements);

  Set<T> _newSet<T>() => RedBlackTreeSet<T>((T a, T b) => _compare(a as E, b as E), _validKey);

  Set<R> cast<R>() => Set.castFrom<E, R>(this, newSet: _newSet);

  // From Iterable.

  Iterator<E> get iterator => _RedBlackTreeKeyIterator<E, _RedBlackTreeSetNode<E>>(this);

  int get length => _count;
  bool get isEmpty => _root == null;
  bool get isNotEmpty => _root != null;

  E get first {
    if (_count == 0) throw _IterableElementError.noElement();
    return _first.key;
  }

  E get last {
    if (_count == 0) throw _IterableElementError.noElement();
    return _last.key;
  }

  E get single {
    if (_count == 0) throw _IterableElementError.noElement();
    if (_count > 1) throw _IterableElementError.tooMany();
    return _root.key;
  }

  // From Set.
  bool contains(Object element) {
    return _validKey(element) && _search(element) != null;
  }

  bool add(E element) {
    _RedBlackTreeSetNode<E> node = _RedBlackTreeSetNode<E>(element);
    bool b = true;
    _insert(node, replaceIfExist: (_, __) {
      b = false;
      return false;
    });
    return b;
  }

  bool remove(Object object) {
    if (!_validKey(object)) return false;
    return _delete(object) != null;
  }

  void addAll(Iterable<E> elements) {
    for (E element in elements) {
      _insert(_RedBlackTreeSetNode<E>(element));
    }
  }

  void removeAll(Iterable<Object> elements) {
    for (Object element in elements) {
      if (_validKey(element)) _delete(element as E);
    }
  }

  void retainAll(Iterable<Object> elements) {
    // Build a set with the same sense of equality as this set.
    RedBlackTreeSet<E> retainSet = RedBlackTreeSet<E>(_compare, _validKey);
    int modificationCount = _modificationCount;
    for (Object object in elements) {
      if (modificationCount != _modificationCount) {
        // The iterator should not have side effects.
        throw ConcurrentModificationError(this);
      }
      // Equivalent to this.contains(object).
      if (_validKey(object) && _search(object) != null) {
        retainSet.add(_root.key);
      }
    }
    // Take over the elements from the retained set, if it differs.
    if (retainSet._count != _count) {
      _root = retainSet._root;
      _count = retainSet._count;
      _modificationCount++;
    }
  }

  E lookup(Object object) {
    if (!_validKey(object)) return null;
    return _search(object)?.key;
  }

  Set<E> intersection(Set<Object> other) {
    Set<E> result = RedBlackTreeSet<E>(_compare, _validKey);
    for (E element in this) {
      if (other.contains(element)) result.add(element);
    }
    return result;
  }

  Set<E> difference(Set<Object> other) {
    Set<E> result = RedBlackTreeSet<E>(_compare, _validKey);
    for (E element in this) {
      if (!other.contains(element)) result.add(element);
    }
    return result;
  }

  Set<E> union(Set<E> other) {
    return _clone()..addAll(other);
  }

  RedBlackTreeSet<E> _clone() {
    var set = RedBlackTreeSet<E>(_compare, _validKey);
    set._count = _count;
    set._root = _copyNode<_RedBlackTreeSetNode<E>>(_root);
    return set;
  }

  // Copies the structure of a RedBlackTree into a new similar structure.
  // Works on _RedBlackTreeMapNode as well, but only copies the keys,
  _RedBlackTreeSetNode<E> _copyNode<Node extends _RedBlackTreeNode<E, Node>>(Node node) {
    if (node == null) return null;
    // Given a source node and a destination node, copy the left
    // and right subtrees of the source node into the destination node.
    // The left subtree is copied recursively, but the right spine
    // of every subtree is copied iteratively.
    void copyChildren(Node node, _RedBlackTreeSetNode<E> dest) {
      Node left;
      Node right;
      do {
        left = node.left;
        right = node.right;
        if (left != null) {
          var newLeft = _RedBlackTreeSetNode<E>(left.key);
          dest.left = newLeft;
          // Recursively copy the left tree.
          copyChildren(left, newLeft);
        }
        if (right != null) {
          var newRight = _RedBlackTreeSetNode<E>(right.key);
          dest.right = newRight;
          // Set node and dest to copy the right tree iteratively.
          node = right;
          dest = newRight;
        }
      } while (right != null);
    }

    var result = _RedBlackTreeSetNode<E>(node.key);
    copyChildren(node, result);
    return result;
  }

  void clear() {
    _clear();
  }

  Set<E> toSet() => _clone();

  String toString() => IterableBase.iterableToFullString(this, '{', '}');
}

class _DebugString {
  String value = 'SearchPath:';
}