#include "tree.h"
#include "parser.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

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

    // Nodes that should not increase indentation
    int noIndentIncrease = (t->nodeKind == COMPOUNDSTMT || 
                            t->nodeKind == LOCALDECLLIST ||
                            t->nodeKind == FORMALDECLLIST);

    // Skip printing for these nodes
    int skipPrinting = (t->nodeKind == COMPOUNDSTMT || 
                        t->nodeKind == LOCALDECLLIST ||
                        t->nodeKind == FORMALDECLLIST);

    // Adjust indentation for statements under statementList
    if (t->parent && t->parent->nodeKind == STATEMENTLIST) {
        level++;
    }

    // Print indentation and node information
    if (!skipPrinting) {
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
                printf("typeSpecifier,");
                switch(t->val) {
                    case KWD_INT: printf("int\n"); break;
                    case KWD_CHAR: printf("char\n"); break;
                    case KWD_VOID: printf("void\n"); break;
                    default: printf("unknown\n");
                }
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
                printf("addop,");
                switch(t->val) {
                    case OPER_ADD: printf("+\n"); break;
                    case OPER_SUB: printf("-\n"); break;
                    default: printf("unknown\n");
                }
                break;
            case MULOP:
                printf("mulop,");
                switch(t->val) {
                    case OPER_MUL: printf("*\n"); break;
                    case OPER_DIV: printf("/\n"); break;
                    default: printf("unknown\n");
                }
                break;
            default:
                printf("%s\n", nodeTypeStrings[t->nodeKind]);
        }
    }

    // Recursively print children
    for (int i = 0; i < t->numChildren; i++) {
        int childLevel = level;
        if (!noIndentIncrease) {
            childLevel++;
        }
        printAst(t->children[i], childLevel);
    }
}
