#include<tree.h>
#include<strtab.h>
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include "tree.h"

tree *ast = NULL;
// TODO: implement printAst(tree *root, int nestLevel) addChild
// TODO: implement addChild(tree *parent, tree *child)

tree *maketree(int kind) {
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
    printf("Node Kind: %d\n", root->nodeKind);

    // Recursively print children
    for (int i = 0; i < root->numChildren; i++) {
        printAst(root->children[i], nestLevel + 1);
    }
}
