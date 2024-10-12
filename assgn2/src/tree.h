#ifndef TREE_H
#define TREE_H

#define MAXCHILDREN 12

#include "parser.h"

// Forward declare the NodeKind enum
typedef enum nodeKind nodeKind;

typedef struct treenode tree;

/* tree node - you may need to add more fields or change this file however you see fit. */
struct treenode {
      nodeKind nodeKind;
      int numChildren;
      int val;
      char *strval;
      int opType;
      tree *parent;
      tree *children[MAXCHILDREN];
};

extern tree *ast; /* pointer to AST root */

/* builds sub tree with zero children  */
tree *maketree(nodeKind kind);

/* builds sub tree with leaf node. Leaf nodes typically hold a value. */
tree *maketreeWithVal(nodeKind kind, int val);

/* assigns the subtree rooted at 'child' as a child of the subtree rooted at 'parent'. Also assigns the 'parent' node as the 'child->parent'. */
void addChild(tree *parent, tree *child);

/* prints the ast recursively starting from the root of the ast. */
void printAst(tree *root, int nestLevel);

#endif
