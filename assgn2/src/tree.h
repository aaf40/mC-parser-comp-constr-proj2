#ifndef TREE_H
#define TREE_H

#define MAXCHILDREN 12

// Forward declare the NodeKind enum
typedef enum nodeKind {
    PROGRAM, DECLLIST, DECL, VARDECL, TYPESPEC, FUNDECL, FORMALDECLLIST, FORMALDECL, FUNBODY,
    LOCALDECLLIST, STATEMENTLIST, STATEMENT, COMPOUNDSTMT, ASSIGNSTMT, CONDSTMT, LOOPSTMT,
    RETURNSTMT, EXPRESSION, RELOP, ADDEXPR, ADDOP, TERM, MULOP, FACTOR, FUNCCALLEXPR,
    ARGLIST, INTEGER, IDENTIFIER, VAR, ARRAYDECL, CHAR, FUNCTYPENAME, 
    EXPRSTMT, STRING
} nodeKind;

typedef struct treenode tree;

/* tree node - you may need to add more fields or change this file however you see fit. */
struct treenode {
      nodeKind nodeKind;
      int numChildren;
      int val;
      char *strval;
      // Remove or comment out the opType field if it's not needed
      // int opType;
      tree *parent;
      tree *children[MAXCHILDREN];
};

extern tree *ast; /* pointer to AST root */

/* builds sub tree with zero children  */
tree *maketree(nodeKind kind, int value);

/* builds sub tree with leaf node. Leaf nodes typically hold a value. */
tree *maketreeWithVal(nodeKind kind, int val);

/* assigns the subtree rooted at 'child' as a child of the subtree rooted at 'parent'. Also assigns the 'parent' node as the 'child->parent'. */
void addChild(tree *parent, tree *child);

/* prints the ast recursively starting from the root of the ast with debug statements. */
void printAstDebug(tree *root, int nestLevel);

/* frees the ast recursively starting from the root of the ast. */
void freeAst(tree *t);

/* prints the indent for the ast recursively starting from the root of the ast. */
void printIndent(int level);

/* prints the ast recursively starting from the root of the ast. */
void printAst(tree *root, int nestLevel);


#endif
