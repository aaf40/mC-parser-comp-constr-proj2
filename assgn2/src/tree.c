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
    "program", "decList", "decl", "varDecl", "typeSpecifier", "funDecl",
    "formalDeclList", "formalDecl", "funBody", "localDeclList",
    "statementList", "statement", "compoundStmt", "assignStmt",
    "condStmt", "loopStmt", "returnStmt", "expression", "relop",
    "addExpr", "addop", "term", "mulop", "factor", "funcCallExpr",
    "argList", "integer", "identifier", "var", "arrayDecl", "char",
    "funcTypeName", "string"
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

void freeAst(tree *node) {
    if (node == NULL) return;
    
    for (int i = 0; i < node->numChildren; i++) {
        freeAst(node->children[i]);
    }
    
    if (node->nodeKind == ARGLIST && node->arg_types != NULL) {
        free(node->arg_types);
    }
    
    if (node->strval != NULL) {
        free(node->strval);
    }
    
    free(node);
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
            printf("%s\n", nodeTypeStrings[t->nodeKind]);
            printAst(t->children[0], level + 1);  // Print declList
            break;
        case DECLLIST:
            printf("%s\n", nodeTypeStrings[t->nodeKind]);
            for (int i = 0; i < t->numChildren; i++) {
                printAst(t->children[i], level + 1);
            }
            break;
        case DECL:
            printf("%s\n", nodeTypeStrings[t->nodeKind]);
            for (int i = 0; i < t->numChildren; i++) {
                printAst(t->children[i], level + 1);
            }
            break;
        case FUNDECL:
            printf("%s\n", nodeTypeStrings[t->nodeKind]);
            for (int i = 0; i < t->numChildren; i++) {
                printAst(t->children[i], level + 1);
            }
            break;
        case FUNBODY:
            printf("%s\n", nodeTypeStrings[t->nodeKind]);
            for (int i = 0; i < t->numChildren; i++) {
                if (t->children[i]->nodeKind != LOCALDECLLIST) {
                    printAst(t->children[i], level + 1);
                }
            }
            break;
        case STATEMENTLIST:
            printf("%s\n", nodeTypeStrings[t->nodeKind]);
            for (int i = 0; i < t->numChildren; i++) {
                printAst(t->children[i], level + 1);
            }
            break;
        case STATEMENT:
            printf("%s\n", nodeTypeStrings[t->nodeKind]);
            for (int i = 0; i < t->numChildren; i++) {
                printAst(t->children[i], level + 1);
            }
            break;
        case EXPRESSION:
            printf("%s\n", nodeTypeStrings[t->nodeKind]);
            for (int i = 0; i < t->numChildren; i++) {
                printAst(t->children[i], level + 1);
            }
            break;
        case ADDEXPR:
            printf("%s\n", nodeTypeStrings[t->nodeKind]);
            for (int i = 0; i < t->numChildren; i++) {
                printAst(t->children[i], level + 1);
            }
            break;
        case TERM:
            printf("%s\n", nodeTypeStrings[t->nodeKind]);
            for (int i = 0; i < t->numChildren; i++) {
                printAst(t->children[i], level + 1);
            }
            break;
        case FACTOR:
            printf("%s\n", nodeTypeStrings[t->nodeKind]);
            for (int i = 0; i < t->numChildren; i++) {
                printAst(t->children[i], level + 1);
            }
            break;
        case TYPESPEC:
            printf("%s,%s\n", nodeTypeStrings[t->nodeKind], t->val == KWD_INT ? "int" : (t->val == KWD_CHAR ? "char" : "void"));
            break;
        case IDENTIFIER:
            printf("%s,%s\n", nodeTypeStrings[t->nodeKind], t->strval);
            break;
        case INTEGER:
            printf("%s,%d\n", nodeTypeStrings[t->nodeKind], t->val);
            break;
        case ADDOP:
            printf("%s,%c\n", nodeTypeStrings[t->nodeKind], t->val == OPER_ADD ? '+' : '-');
            break;
        case MULOP:
            printf("%s,%c\n", nodeTypeStrings[t->nodeKind], t->val == OPER_MUL ? '*' : '/');
            break;
        case FUNCCALLEXPR:
            printf("%s\n", nodeTypeStrings[t->nodeKind]);
            for (int i = 0; i < t->numChildren; i++) {
                printAst(t->children[i], level + 1);
            }
            break;
        case ARGLIST:
            printf("%s\n", nodeTypeStrings[t->nodeKind]);
            for (int i = 0; i < t->numChildren; i++) {
                printAst(t->children[i], level + 1);
            }
            break;
        case FORMALDECLLIST:
            printf("%s\n", nodeTypeStrings[t->nodeKind]);
            for (int i = 0; i < t->numChildren; i++) {
                printAst(t->children[i], level + 1);
            }
            break;
        case VARDECL:
            printf("%s\n", nodeTypeStrings[t->nodeKind]);
            for (int i = 0; i < t->numChildren; i++) {
                printAst(t->children[i], level + 1);
            }
            break;
        case FORMALDECL:
            printf("%s\n", nodeTypeStrings[t->nodeKind]);
            for (int i = 0; i < t->numChildren; i++) {
                printAst(t->children[i], level + 1);
            }
            break;
        case COMPOUNDSTMT:
            // Don't print "compoundStmt"
            for (int i = 0; i < t->numChildren; i++) {
                printAst(t->children[i], level);  // Note: we're not increasing the level here
            }
            break;
        case ASSIGNSTMT:
            printf("%s\n", nodeTypeStrings[t->nodeKind]);
            for (int i = 0; i < t->numChildren; i++) {
                printAst(t->children[i], level + 1);
            }
            break;
        case CONDSTMT:
            printf("%s\n", nodeTypeStrings[t->nodeKind]);
            for (int i = 0; i < t->numChildren; i++) {
                printAst(t->children[i], level + 1);
            }
            break;
        case LOOPSTMT:
            printf("%s\n", nodeTypeStrings[t->nodeKind]);
            for (int i = 0; i < t->numChildren; i++) {
                printAst(t->children[i], level + 1);
            }
            break;
        case RETURNSTMT:
            printf("%s\n", nodeTypeStrings[t->nodeKind]);
            for (int i = 0; i < t->numChildren; i++) {
                printAst(t->children[i], level + 1);
            }
            break;
        case VAR:
            printf("%s\n", nodeTypeStrings[t->nodeKind]);
            for (int i = 0; i < t->numChildren; i++) {
                printAst(t->children[i], level + 1);
            }
            break;
        case RELOP:
            printf("%s,%s\n", nodeTypeStrings[t->nodeKind], getRelopString(t->val));
            break;
        default:
            printf("%s\n", nodeTypeStrings[t->nodeKind]);
            for (int i = 0; i < t->numChildren; i++) {
                printAst(t->children[i], level + 1);
            }
    }
}

const char* getRelopString(int val) {
    switch(val) {
        case OPER_LT: return "<";
        case OPER_LTE: return "<=";  // Changed from OPER_LE to OPER_LTE
        case OPER_GT: return ">";
        case OPER_GTE: return ">=";  // Changed from OPER_GE to OPER_GTE
        case OPER_EQ: return "==";
        case OPER_NEQ: return "!=";  // Changed from OPER_NE to OPER_NEQ
        default: return "unknown";
    }
}