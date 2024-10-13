#include "tree.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h" 

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
    "FUNCTYPENAME", "NODE_KWD_INT", "NODE_KWD_CHAR", "STRING"
};

tree *maketree(nodeKind kind, int value) {
    /*printf("DEBUG: Creating tree node of kind %d\n", kind);*/
    tree *node = (tree *)malloc(sizeof(tree));
    if (node == NULL) {
        fprintf(stderr, "ERROR: Memory allocation failed for node\n");
        exit(1);
    }
    node->nodeKind = kind;
    node->val = value;
    node->numChildren = 0;
    node->parent = NULL;
    /*printf("DEBUG: Finished creating tree node of kind %d\n", kind);*/    
    return node;
}

tree* makeTreeNode(nodeKind kind, int value) {
    tree* node = (tree*)malloc(sizeof(tree));
    node->nodeKind = kind;
    node->val = value;
    // ... other initialization ...
    return node;
}

void addChild(tree *parent, tree *child) {
    if (parent == NULL) {
        printf("ERROR: Attempting to add child to NULL parent\n");
        return;
    }
    if (child == NULL) {
        printf("WARNING: Attempting to add NULL child to parent of kind %d\n", parent->nodeKind);
        return;
    }
    if (parent->numChildren < MAXCHILDREN) {
        parent->children[parent->numChildren] = child;
        parent->numChildren++;
        child->parent = parent;
    } else {
        fprintf(stderr, "Error: Too many children for node of kind %d\n", parent->nodeKind);
    }
}

void printAstDebug(tree *t, int nestLevel) {
    if (t == NULL) {
        printf("DEBUG: Encountered NULL node at nest level %d\n", nestLevel);
        return;
    }
    
    printf("DEBUG: Printing node of type %d at nest level %d\n", t->nodeKind, nestLevel);
    fflush(stdout);
    
    // Print node-specific information
    switch(t->nodeKind) {
        case IDENTIFIER:
            if (t->strval != NULL) {
                printf("  Name, %s\n", t->strval);
            } else {
                printf("  WARNING: NULL identifier name\n");
            }
            break;
        case TYPESPEC:
            printf("  Type: %d\n", t->val);
            break;
        // Add cases for other node types as needed
        default:
            printf("  Children: %d\n", t->numChildren);
    }
    
    // Print children
    for (int i = 0; i < t->numChildren; i++) {
        if (t->children[i] != NULL) {
            printf("DEBUG: About to print child %d of %d for node type %d\n", i+1, t->numChildren, t->nodeKind);
            fflush(stdout);
            printAst(t->children[i], nestLevel + 1);
        } else {
            printf("WARNING: Child %d of %d is NULL for node type %d\n", i+1, t->numChildren, t->nodeKind);
        }
    }
    
    printf("DEBUG: Finished printing node of type %d at nest level %d\n", t->nodeKind, nestLevel);
    fflush(stdout);
}

void freeAst(tree *t) {
    if (t == NULL) return;
    /*printf("DEBUG: Freeing node of type %d\n", t->nodeKind);
    fflush(stdout);*/
    for (int i = 0; i < t->numChildren; i++) {
        freeAst(t->children[i]);
    }
    free(t);
}

void printIndent(int level) {
    for (int i = 0; i < level; i++) {
        printf("  ");
    }
}

void printAst(tree *t, int level) {
    if (t == NULL) return;
    
    printIndent(level);
    
    switch(t->nodeKind) {
        case PROGRAM:
            printf("program\n");
            break;
        case DECLLIST:
            printf("declList\n");
            break;
        case DECL:
            printf("decl\n");
            break;
        case FUNDECL:
            printf("funDecl\n");
            break;
        case FUNCTYPENAME:
            printf("funcTypeName\n");
            break;
        case TYPESPEC:
            printf("typeSpecifier,%s\n", t->val == KWD_INT ? "int" : (t->val == KWD_CHAR ? "char" : "void"));
            break;
        case IDENTIFIER:
            printf("identifier,%s\n", t->strval);
            break;
        case FUNBODY:
            printf("funBody\n");
            break;
        case STATEMENTLIST:
            printf("statementList\n");
            break;
        case STATEMENT:
            printf("statement\n");
            break;
        case ASSIGNSTMT:
            printf("assignStmt\n");
            break;
        case EXPRESSION:
            printf("expression\n");
            break;
        case ADDEXPR:
            printf("addExpr\n");
            break;
        case TERM:
            printf("term\n");
            break;
        case FACTOR:
            printf("factor\n");
            break;
        case INTEGER:
            printf("integer,%d\n", t->val);
            break;
        case ADDOP:
            printf("addop,%c\n", t->val == OPER_ADD ? '+' : '-');
            break;
        default:
            printf("%s\n", nodeTypeStrings[t->nodeKind]);
    }
    
    for (int i = 0; i < t->numChildren; i++) {
        if (t->children[i]->nodeKind != FORMALDECLLIST && t->children[i]->nodeKind != LOCALDECLLIST) {
            printAst(t->children[i], level + 1);
        }
    }
}
