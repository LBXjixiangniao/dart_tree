# dart_tree

实现AVL树和红黑树

## Getting Started

AVL树相关类有AVLTreeSet、AVLTreeMap，AVLTreeSet操作类似Set，AVLTreeMap操作类似Map。

红黑树相关类有RedBlackTreeSet、RedBlackTreeMap，RedBlackTreeSet操作类似Set，RedBlackTreeMap操作类似Map。

如果设置treeInstance.debug为true，则添加、删除查找元素的时候会将查找路径和树的结构打印出来，如下所示：

```
///红黑树示例
///数字后的b代表节点颜色是黑色，r表示红色
Insert:1678**********************************

InserCase2

->1301->1916
TreeStructure:

              1301b
            /        \
           /          \
        1205b        1916b
       /            /      \
    511r         1678r    1973r
End Insert:1678**********************************
```

```
///AVL树示例
///-表示左重，平衡因子是-1；+表示右重，平衡因子是+1；没符号表示左右子树等高，平衡因子是0
Insert:437**********************************

RebalanceForInsert:437
RotateRight:966,687

->1419->319->966->687
TreeStructure:

                     1419-
               /                \
              /                  \
             /                    \
            /                      \
         319                      1845+
       /      \                          \
      /        \                          \
    104+       687                       1966
         \    /    \
        184 437    966
End Insert:437**********************************


```
