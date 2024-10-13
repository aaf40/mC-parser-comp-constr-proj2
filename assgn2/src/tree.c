#include "tree.h"
#include "parser.h"
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
    "FUNCTYPENAME", "NODE_KWD_INT", "NODE_KWD_CHAR"
};

tree *maketree(nodeKind kind, int value) {
    tree *node = (tree *)malloc(sizeof(tree));
    if (node == NULL) {
        fprintf(stderr, "ERROR: Memory allocation failed for node\n");
        exit(1);
    }
    node->nodeKind = kind;
    node->val = value;
    node->numChildren = 0;
    node->parent = NULL;
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
    if (parent->numChildren < MAXCHILDREN) {
        parent->children[parent->numChildren] = child;
        parent->numChildren++;
        child->parent = parent;
    } else {
        // Handle error: too many children
        fprintf(stderr, "Error: Too many children for node\n");
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
                printf("  Name: %s\n", t->strval);
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
            printf("Program\n");
            break;
        case DECLLIST:
            printf("DeclList\n");
            break;
        case FUNDECL:
            printf("FunDecl\n");
            break;
        case TYPESPEC:
            printf("TypeSpec: ");
            switch(t->val) {
                case KWD_INT: printf("int\n"); break;
                case KWD_CHAR: printf("char\n"); break;
                case KWD_VOID: printf("void\n"); break;
                default: printf("unknown (%d)\n", t->val);
            }
            break;
        case IDENTIFIER:
            printf("Identifier: %s\n", t->strval);
            break;
        case VARDECL:
            printf("VarDecl\n");
            break;
        case FORMALDECLLIST:
            printf("FormalDeclList\n");
            break;
        case FORMALDECL:
            printf("FormalDecl\n");
            break;
        case LOCALDECLLIST:
            printf("LocalDeclList\n");
            break;
        case STATEMENTLIST:
            printf("StatementList\n");
            break;
        case COMPOUNDSTMT:
            printf("CompoundStmt\n");
            break;
        case EXPRESSION:
            printf("Expression\n");
            break;
        case ADDEXPR:
            printf("AddExpr\n");
            break;
        case TERM:
            printf("Term\n");
            break;
        case FACTOR:
            printf("Factor\n");
            break;
        case INTEGER:
            printf("Integer: %d\n", t->val);
            break;
        case VAR:
            printf("Var\n");
            break;
        case STATEMENT:
            printf("Statement\n");
            break;
        case CONDSTMT:
            printf("CondStmt\n");
            break;
        case LOOPSTMT:
            printf("LoopStmt\n");
            break;
        case RETURNSTMT:
            printf("ReturnStmt\n");
            break;
        case ASSIGNSTMT:
            printf("AssignStmt\n");
            break;
        case ADDOP:
            printf("AddOp: ");
            switch(t->val) {
                case OPER_ADD: printf("+\n"); break;
                case OPER_SUB: printf("-\n"); break;
                default: printf("unknown (%d)\n", t->val);
            }
            break;
        case MULOP:
            printf("MulOp: ");
            switch(t->val) {
                case OPER_MUL: printf("*\n"); break;
                case OPER_DIV: printf("/\n"); break;
                default: printf("unknown (%d)\n", t->val);
            }
            break;
        case RELOP:
            printf("RelOp: ");
            switch(t->val) {
                case OPER_LT: printf("<\n"); break;
                case OPER_LTE: printf("<=\n"); break;
                case OPER_GT: printf(">\n"); break;
                case OPER_GTE: printf(">=\n"); break;
                case OPER_EQ: printf("==\n"); break;
                case OPER_NEQ: printf("!=\n"); break;
                default: printf("unknown (%d)\n", t->val);
            }
            break;
        case CHAR:
            printf("Char: %c\n", (char)t->val);
            break;
        default:
            printf("Unknown node type: %s (%d)\n", nodeTypeStrings[t->nodeKind], t->nodeKind);
    }

    for (int i = 0; i < t->numChildren; i++) {
        printAst(t->children[i], level + 1);
    }
}
