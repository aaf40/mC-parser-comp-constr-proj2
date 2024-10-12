#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tree.h"
#include "strtab.h"

int yyparse(void);
extern tree *ast;  // Add this line if it's not already present

int main() {
    /*printf("DEBUG: Starting main function\n");
    fflush(stdout);
    ST_init();  // Initialize the symbol table
    printf("DEBUG: Symbol table initialized\n");
    fflush(stdout);
    printf("DEBUG: About to start parsing\n");
    fflush(stdout);*/
    if (!yyparse()){
        /*printf("DEBUG: Parsing completed. About to print AST.\n");
        fflush(stdout);*/
        if (ast != NULL) {
            /*printf("AST:\n");*/
            printAst(ast, 0);
        } else {
            printf("ERROR: AST is NULL\n");
            fflush(stdout);
        }
        /*printf("DEBUG: AST printing completed. About to free AST.\n");
        fflush(stdout);
        freeAst(ast);
        printf("DEBUG: AST freed. About to free symbol table.\n");
        fflush(stdout);
        ST_free();
        printf("DEBUG: Symbol table freed. Exiting main function.\n");
        fflush(stdout);*/
    } else {
        printf("ERROR: Parsing failed\n");
    }
    /*printf("DEBUG: Exiting main function\n");*/
    return 0;
}
