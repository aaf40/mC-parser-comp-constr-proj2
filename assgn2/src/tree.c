#include "tree.h"
#include "parser.h"  // This will include the NodeKind enum definition
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tree.h"
#include "parser.h"

tree *ast = NULL;
// TODO: implement printAst(tree *root, int nestLevel) addChild
// TODO: implement addChild(tree *parent, tree *child)

// Node type strings
const char* nodeTypeStrings[] = {
    "PROGRAM", "DECLLIST", "DECL", "VARDECL", "TYPESPEC", "FUNDECL",
    "FORMALDECLLIST", "FORMALDECL", "FUNBODY", "LOCALDECLLIST",
    "STATEMENTLIST", "STATEMENT", "COMPOUNDSTMT", "ASSIGNSTMT",
    "CONDSTMT", "LOOPSTMT", "RETURNSTMT", "EXPRESSION", "RELOP",
    "ADDEXPR", "ADDOP", "TERM", "MULOP", "FACTOR", "FUNCCALLEXPR",
    "ARGLIST", "INTEGER", "IDENTIFIER", "VAR", "ARRAYDECL", "CHAR",
    "FUNCTYPENAME", "NODE_KWD_INT", "NODE_KWD_CHAR"
};

tree *maketree(nodeKind kind) {
    tree *node = (tree *)malloc(sizeof(tree));
    node->nodeKind = kind;
    node->numChildren = 0;
    node->parent = NULL;
    // Initialize other fields as necessary
    return node;
}

void addChild(tree *parent, tree *child) {
    if (parent->numChildren < MAXCHILDREN) {
        parent->children[parent->numChildren] = child;
        parent->numChildren++;
        child->parent = parent;
    } else {
        // Handle error: too many children
        fprintf(stderr, "Error: Too many children for node\n");
    }
}

void printAst(tree *root, int nestLevel) {
    if (root == NULL) return;

    // Print indentation
    for (int i = 0; i < nestLevel; i++) {
        printf("  ");
    }

    // Print node information
    printf("Node Type: %s\n", nodeTypeStrings[root->nodeKind]);

    // Print additional node information based on node type
    switch (root->nodeKind) {
        case IDENTIFIER:
        case VAR:
            printf("  Name: %s\n", root->strval);
            break;
        case INTEGER:
            printf("  Value: %d\n", root->val);
            break;
        case CHAR:
            printf("  Value: '%c'\n", root->val);
            break;
        case TYPESPEC:
            printf("  Type: %s\n", root->val == NODE_KWD_INT ? "int" : 
                                   root->val == NODE_KWD_CHAR ? "char" : "void");
            break;
        // Add more cases for other node types as needed
    }

    // Print number of children
    printf("  Children: %d\n", root->numChildren);

    // Recursively print children
    for (int i = 0; i < root->numChildren; i++) {
        printAst(root->children[i], nestLevel + 1);
    }
}
