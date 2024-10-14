#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tree.h"
#include "strtab.h"
#include "y.tab.h"  // Add this line

int yyparse(void);
extern tree *ast;  // Add this line if it's not already present

int main() {
    yyparse();
    // After parsing is complete and you're done with the AST
    freeAst(ast);
    ST_free();  // Free the symbol table
    return 0;
}
