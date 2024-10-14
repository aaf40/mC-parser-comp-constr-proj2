%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tree.h"
#include "strtab.h"

extern int yylineno;

int yyerror(char *s);
int yywarning(char *s);
int yyparse(void);
int yylex(void);
int current_function_type = VOID_TYPE;  // Default to void
int has_return_statement(tree *node);

char* scope = "";
char* oldScope = "";
%}

%union
{
    int value;
    struct treenode *node;
    char *strval;
}


%type <node> program declList decl varDecl funDecl typeSpecifier
%type <node> formalDeclList formalDecl funBody localDeclList
%type <node> statementList statement compoundStmt
%type <node> assignStmt condStmt loopStmt returnStmt
%type <node> var expression relop addExpr addop term mulop factor
%type <node> funcCallExpr argList

%token <strval> ID
%token <value> INTCONST CHARCONST
%token <strval> STRCONST
%token KWD_INT KWD_CHAR KWD_VOID
%token KWD_IF KWD_ELSE KWD_WHILE KWD_RETURN
%token OPER_ADD OPER_SUB OPER_MUL OPER_DIV
%token OPER_LT OPER_LTE OPER_GT OPER_GTE OPER_EQ OPER_NEQ OPER_ASGN
%token LSQ_BRKT RSQ_BRKT LCRLY_BRKT RCRLY_BRKT LPAREN RPAREN
%token COMMA SEMICLN
%token ERROR ILLEGAL_TOKEN

%left OPER_ADD OPER_SUB
%left OPER_MUL OPER_DIV
%nonassoc OPER_LT OPER_LTE OPER_GT OPER_GTE OPER_EQ OPER_NEQ
%nonassoc LOWER_THAN_ELSE
%nonassoc KWD_ELSE

%start program

%%


program         : declList
                {
                    printf("DEBUG: Entering program rule\n");
                    $$ = maketree(PROGRAM, 0);
                    if ($$ == NULL) {
                        printf("ERROR: Failed to create PROGRAM node\n");
                        YYABORT;
                    }
                    printf("DEBUG: Created PROGRAM node\n");
                    
                    if ($1 == NULL) {
                        printf("ERROR: declList is NULL\n");
                        YYABORT;
                    }
                    addChild($$, $1);
                    printf("DEBUG: Added declList as child to PROGRAM node\n");
                    
                    ast = $$;
                    printf("DEBUG: Set ast to PROGRAM node\n");
                    
                    printf("DEBUG: Exiting program rule\n");
                }
                ;

declList        : decl
                {
                    printf("DEBUG: Entering declList rule (single decl)\n");
                    $$ = maketree(DECLLIST, 0);
                    if ($$ == NULL) {
                        printf("ERROR: Failed to create DECLLIST node\n");
                        YYABORT;
                    }
                    printf("DEBUG: Created DECLLIST node\n");
                    
                    if ($1 == NULL) {
                        printf("ERROR: decl is NULL\n");
                        YYABORT;
                    }
                    addChild($$, $1);
                    printf("DEBUG: Added decl as child to DECLLIST node\n");
                    
                    printf("DEBUG: Exiting declList rule (single decl)\n");
                }
                | declList decl
                {
                    printf("DEBUG: Entering declList rule (multiple decl)\n");
                    $$ = $1;
                    if ($$ == NULL) {
                        printf("ERROR: Existing DECLLIST node is NULL\n");
                        YYABORT;
                    }
                    
                    if ($2 == NULL) {
                        printf("ERROR: New decl is NULL\n");
                        YYABORT;
                    }
                    addChild($$, $2);
                    printf("DEBUG: Added new decl as child to existing DECLLIST node\n");
                    
                    printf("DEBUG: Exiting declList rule (multiple decl)\n");
                }
                ;

decl            : varDecl
                {
                    printf("DEBUG: Entering decl rule (varDecl)\n");
                    if ($1 == NULL) {
                        printf("ERROR: varDecl is NULL\n");
                        YYABORT;
                    }
                    $$ = $1;
                    printf("DEBUG: Set decl node to varDecl\n");
                    printf("DEBUG: Exiting decl rule (varDecl)\n");
                }
                | funDecl
                {
                    printf("DEBUG: Entering decl rule (funDecl)\n");
                    if ($1 == NULL) {
                        printf("ERROR: funDecl is NULL\n");
                        YYABORT;
                    }
                    $$ = $1;
                    printf("DEBUG: Set decl node to funDecl\n");
                    printf("DEBUG: Exiting decl rule (funDecl)\n");
                }
                ;

varDecl         : typeSpecifier ID LSQ_BRKT INTCONST RSQ_BRKT SEMICLN
                {
                    printf("DEBUG: Entering varDecl rule (array declaration)\n");
                    $$ = maketree(VARDECL, 0);
                    if ($$ == NULL) {
                        printf("ERROR: Failed to create VARDECL node\n");
                        YYABORT;
                    }
                    printf("DEBUG: Created VARDECL node\n");

                    if ($1 == NULL) {
                        printf("ERROR: typeSpecifier is NULL\n");
                        YYABORT;
                    }
                    addChild($$, $1);
                    printf("DEBUG: Added typeSpecifier as child to VARDECL node\n");

                    tree *arrayDecl = maketree(ARRAYDECL, 0);
                    if (arrayDecl == NULL) {
                        printf("ERROR: Failed to create ARRAYDECL node\n");
                        YYABORT;
                    }
                    printf("DEBUG: Created ARRAYDECL node\n");

                    arrayDecl->strval = $2;
                    printf("DEBUG: Set array name to %s\n", $2);

                    tree *size = maketree(INTEGER, $4);
                    if (size == NULL) {
                        printf("ERROR: Failed to create INTEGER node for array size\n");
                        YYABORT;
                    }
                    printf("DEBUG: Created INTEGER node for array size: %d\n", $4);

                    addChild(arrayDecl, size);
                    printf("DEBUG: Added size as child to ARRAYDECL node\n");

                    addChild($$, arrayDecl);
                    printf("DEBUG: Added ARRAYDECL as child to VARDECL node\n");
                    
                    // Insert into symbol table
                    int data_type = $1->val;
                    printf("DEBUG: Inserting array into symbol table. Name: %s, Scope: %s, Type: %d\n", $2, scope, data_type);
                    if (ST_insert($2, scope, data_type, ARRAY_TYPE) == -1) {
                        yyerror("Symbol table insertion failed");
                        printf("ERROR: Failed to insert array into symbol table\n");
                    } else {
                        printf("DEBUG: Successfully inserted array into symbol table\n");
                    }
                    printf("DEBUG: Exiting varDecl rule (array declaration)\n");
                }
                | typeSpecifier ID SEMICLN
                {
                    printf("DEBUG: Entering varDecl rule (scalar declaration)\n");
                    $$ = maketree(VARDECL, 0);
                    if ($$ == NULL) {
                        printf("ERROR: Failed to create VARDECL node\n");
                        YYABORT;
                    }
                    printf("DEBUG: Created VARDECL node\n");

                    if ($1 == NULL) {
                        printf("ERROR: typeSpecifier is NULL\n");
                        YYABORT;
                    }
                    addChild($$, $1);
                    printf("DEBUG: Added typeSpecifier as child to VARDECL node\n");

                    tree *id = maketree(IDENTIFIER, 0);
                    if (id == NULL) {
                        printf("ERROR: Failed to create IDENTIFIER node\n");
                        YYABORT;
                    }
                    printf("DEBUG: Created IDENTIFIER node\n");

                    id->strval = $2;
                    printf("DEBUG: Set identifier name to %s\n", $2);

                    addChild($$, id);
                    printf("DEBUG: Added IDENTIFIER as child to VARDECL node\n");
                    
                    // Insert into symbol table
                    int data_type = $1->val;
                    printf("DEBUG: Inserting scalar into symbol table. Name: %s, Scope: %s, Type: %d\n", $2, scope, data_type);
                    if (ST_insert($2, scope, data_type, SCALAR_TYPE) == -1) {
                        yyerror("Symbol table insertion failed");
                        printf("ERROR: Failed to insert scalar into symbol table\n");
                    } else {
                        printf("DEBUG: Successfully inserted scalar into symbol table\n");
                    }
                    printf("DEBUG: Exiting varDecl rule (scalar declaration)\n");
                }
                ;

typeSpecifier   : KWD_INT
                {
                    $$ = maketree(TYPESPEC, KWD_INT);
                    $$->val = INT_TYPE;
                }
                | KWD_CHAR
                {
                    $$ = maketree(TYPESPEC, KWD_CHAR);
                    $$->val = CHAR_TYPE;
                }
                | KWD_VOID
                {
                    $$ = maketree(TYPESPEC, KWD_VOID);
                    $$->val = VOID_TYPE;
                }
                ;

funDecl         : typeSpecifier ID LPAREN formalDeclList RPAREN
                {
                    current_function_type = $1->val;  // Set current function type
                    
                    // Create a new scope for the function
                    char* oldScope = scope;
                    scope = strdup($2);  // Use function name as new scope
                }
                funBody
                {
                    $$ = maketree(FUNDECL, 0);
                    tree *funcTypeName = maketree(FUNCTYPENAME, 0);
                    addChild(funcTypeName, $1);
                    tree *id = maketree(IDENTIFIER, 0);
                    id->strval = $2;
                    addChild(funcTypeName, id);
                    addChild($$, funcTypeName);
                    addChild($$, $4);
                    addChild($$, $7);  // funBody

                    // Insert function into symbol table
                    if (ST_insert($2, oldScope, $1->val, FUNCTION_TYPE) == -1) {
                        yyerror("Symbol table insertion failed for function");
                    }

                    // Restore the old scope
                    free(scope);
                    scope = oldScope;
                }
                | typeSpecifier ID LPAREN RPAREN
                {
                    current_function_type = $1->val;  // Set current function type
                    
                    // Create a new scope for the function
                    char* oldScope = scope;
                    scope = strdup($2);  // Use function name as new scope
                }
                funBody
                {
                    $$ = maketree(FUNDECL, 0);
                    tree *funcTypeName = maketree(FUNCTYPENAME, 0);
                    addChild(funcTypeName, $1);
                    tree *id = maketree(IDENTIFIER, 0);
                    id->strval = $2;
                    addChild(funcTypeName, id);
                    addChild($$, funcTypeName);
                    addChild($$, maketree(FORMALDECLLIST, 0));
                    addChild($$, $6);  // funBody

                    // Insert function into symbol table
                    if (ST_insert($2, oldScope, $1->val, FUNCTION_TYPE) == -1) {
                        yyerror("Symbol table insertion failed for function");
                    }

                    // Restore the old scope
                    free(scope);
                    scope = oldScope;
                }
                ;

formalDeclList  : formalDecl
                {
                    $$ = maketree(FORMALDECLLIST, 0);
                    addChild($$, $1);
                }
                | formalDecl COMMA formalDeclList
                {
                    $$ = $3;  // Use the existing FORMALDECLLIST node
                    addChild($$, $1);  // Add the new formalDecl to the beginning of the list
                }
                ;

formalDecl      : typeSpecifier ID
                {
                    $$ = maketree(FORMALDECL, 0);
                    addChild($$, $1);
                    tree *id = maketree(IDENTIFIER, 0);
                    id->strval = $2;
                    addChild($$, id);

                    // Insert parameter into symbol table
                    if (ST_insert($2, scope, $1->val, SCALAR_TYPE) == -1) {
                        yyerror("Symbol table insertion failed for parameter");
                    }
                }
                | typeSpecifier ID LSQ_BRKT RSQ_BRKT
                {
                    $$ = maketree(FORMALDECL, 0);
                    addChild($$, $1);
                    tree *arrayDecl = maketree(ARRAYDECL, 0);
                    arrayDecl->strval = $2;
                    addChild($$, arrayDecl);

                    // Insert array parameter into symbol table
                    if (ST_insert($2, scope, $1->val, ARRAY_TYPE) == -1) {
                        yyerror("Symbol table insertion failed for array parameter");
                    }
                }
                ;
funBody         : LCRLY_BRKT localDeclList statementList RCRLY_BRKT
                {
                    $$ = maketree(FUNBODY, 0);
                    addChild($$, $2);  // localDeclList
                    addChild($$, $3);  // statementList

                    // Check if there's a return statement for non-void functions
                    if (current_function_type != VOID_TYPE) {
                        // This is a simple check. You might want to implement a more
                        // sophisticated analysis to ensure all code paths return a value.
                        if (!has_return_statement($3)) {
                            yyerror("Function must return a value");
                        }
                    }

                    current_function_type = VOID_TYPE;  // Reset to default
                }
                ;

localDeclList   : /* empty */
                {
                    $$ = maketree(LOCALDECLLIST, 0);
                }
                | varDecl localDeclList
                {
                    $$ = $2;  // Use the existing LOCALDECLLIST node
                    addChild($$, $1);  // Add the new varDecl to the beginning of the list
                }
                ;

statementList   : /* empty */
                {
                    $$ = NULL;
                }
                | statement statementList
                {
                    if ($2 == NULL) {
                        $$ = maketree(STATEMENTLIST, 0);
                        addChild($$, $1);
                    } else {
                        $$ = $2;
                        addChild($$, $1);
                    }
                }
                ;

statement       : compoundStmt
                {
                    $$ = maketree(STATEMENT, 0);
                    addChild($$, $1);
                }
                | assignStmt
                {
                    $$ = maketree(STATEMENT, 0);
                    addChild($$, $1);
                }
                | condStmt
                {
                    $$ = maketree(STATEMENT, 0);
                    addChild($$, $1);
                }
                | loopStmt
                {
                    $$ = maketree(STATEMENT, 0);
                    addChild($$, $1);
                }
                | returnStmt
                {
                    $$ = maketree(STATEMENT, 0);
                    addChild($$, $1);
                }
                | expression SEMICLN
                {
                    $$ = maketree(STATEMENT, 0);
                    addChild($$, $1);
                }
                ;

compoundStmt    : LCRLY_BRKT statementList RCRLY_BRKT
                {
                    $$ = maketree(COMPOUNDSTMT, 0);
                    addChild($$, $2);  // Add statementList as a child
                }
                ;

assignStmt      : var OPER_ASGN expression SEMICLN
                {
                    $$ = maketree(ASSIGNSTMT, 0);
                    addChild($$, $1);
                    addChild($$, $3);

                    // Check if the variable exists in the symbol table
                    if (ST_lookup($1->strval, scope) == -1) {
                        yyerror("Undefined variable");
                    }
                    // Type checking could be done here if needed
                }
                | expression SEMICLN
                {
                    $$ = maketree(ASSIGNSTMT, 0);
                    addChild($$, $1);
                }
                ;

condStmt        : KWD_IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
                {
                    $$ = maketree(CONDSTMT, 0);
                    addChild($$, $3);  // expression
                    addChild($$, $5);  // statement

                    // Check if the expression evaluates to a boolean
                    if ($3->val != INT_TYPE) {
                        yyerror("Condition in if statement must be of type int");
                    }
                }
                | KWD_IF LPAREN expression RPAREN statement KWD_ELSE statement
                {
                    $$ = maketree(CONDSTMT, 0);
                    addChild($$, $3);  // expression
                    addChild($$, $5);  // if statement
                    addChild($$, $7);  // else statement

                    // Check if the expression evaluates to a boolean
                    if ($3->val != INT_TYPE) {
                        yyerror("Condition in if-else statement must be of type int");
                    }
                }
                ;

loopStmt        : KWD_WHILE LPAREN expression RPAREN statement
                {
                    $$ = maketree(LOOPSTMT, 0);
                    addChild($$, $3);  // expression
                    addChild($$, $5);  // statement

                    // Check if the expression evaluates to a boolean (int in C-)
                    if ($3->val != INT_TYPE) {
                        yyerror("Condition in while statement must be of type int");
                    }
                }
                ;

returnStmt      : KWD_RETURN SEMICLN
                {
                    $$ = maketree(RETURNSTMT, 0);
                    
                    // Check if the function is declared to return void
                    if (current_function_type != VOID_TYPE) {
                        yyerror("Function must return a value");
                    }
                }
                | KWD_RETURN expression SEMICLN
                {
                    $$ = maketree(RETURNSTMT, 0);
                    addChild($$, $2);  // expression
                    
                    // Check if the return type matches the function's declared return type
                    if ($2->val != current_function_type) {
                        yyerror("Return type does not match function return type");
                    }
                }
                ;

var             : ID
                {
                    $$ = maketree(VAR, 0);
                    tree *id = maketree(IDENTIFIER, 0);
                    id->strval = strdup($1);
                    addChild($$, id);

                    // Look up the variable in the symbol table
                    int index = ST_lookup($1, scope);
                    if (index == -1) {
                        yyerror("Undefined variable");
                        $$->val = ERROR_TYPE;
                    } else {
                        // Store the variable's type in the AST node
                        $$->val = strTable[index].data_type;
                        $$->symbol_type = strTable[index].symbol_type;
                    }
                }
                | ID LSQ_BRKT addExpr RSQ_BRKT
                {
                    $$ = maketree(VAR, 0);
                    tree *arrayAccess = maketree(ARRAYDECL, 0);
                    arrayAccess->strval = strdup($1);
                    addChild(arrayAccess, $3);  // addExpr
                    addChild($$, arrayAccess);

                    // Look up the array in the symbol table
                    int index = ST_lookup($1, scope);
                    if (index == -1) {
                        yyerror("Undefined array");
                        $$->val = ERROR_TYPE;
                    } else if (strTable[index].symbol_type != ARRAY_TYPE) {
                        yyerror("Variable is not an array");
                        $$->val = ERROR_TYPE;
                    } else {
                        // Store the array's element type in the AST node
                        $$->val = strTable[index].data_type;
                        $$->symbol_type = SCALAR_TYPE;  // Array access results in a scalar
                    }

                    // Check if the index expression is of integer type
                    if ($3->val != INT_TYPE) {
                        yyerror("Array index must be an integer");
                        $$->val = ERROR_TYPE;
                    }
                }
                ;

expression      : addExpr
                {
                    $$ = maketree(EXPRESSION, 0);
                    addChild($$, $1);
                    $$->val = $1->val;  // Propagate the type
                }
                | expression relop addExpr
                {
                    $$ = maketree(EXPRESSION, 0);
                    addChild($$, $1);
                    addChild($$, $2);
                    addChild($$, $3);

                    // Type checking
                    if ($1->val != INT_TYPE || $3->val != INT_TYPE) {
                        yyerror("Type mismatch: relational operations require integer operands");
                        $$->val = ERROR_TYPE;
                    } else {
                        $$->val = INT_TYPE;  // Result of relational operation is always int (boolean)
                    }
                }
                ;

relop           : OPER_LTE
                {
                    $$ = maketree(RELOP, OPER_LTE);
                    $$->val = OPER_LTE;
                    $$->strval = strdup("<=");
                }
                | OPER_LT
                {
                    $$ = maketree(RELOP, OPER_LT);
                    $$->val = OPER_LT;
                    $$->strval = strdup("<");
                }
                | OPER_GT
                {
                    $$ = maketree(RELOP, OPER_GT);
                    $$->val = OPER_GT;
                    $$->strval = strdup(">");
                }
                | OPER_GTE
                {
                    $$ = maketree(RELOP, OPER_GTE);
                    $$->val = OPER_GTE;
                    $$->strval = strdup(">=");
                }
                | OPER_EQ
                {
                    $$ = maketree(RELOP, OPER_EQ);
                    $$->val = OPER_EQ;
                    $$->strval = strdup("==");
                }
                | OPER_NEQ
                {
                    $$ = maketree(RELOP, OPER_NEQ);
                    $$->val = OPER_NEQ;
                    $$->strval = strdup("!=");
                }
                ;

addExpr         : term
                {
                    $$ = maketree(ADDEXPR, 0);
                    addChild($$, $1);
                    $$->val = $1->val;  // Propagate the type from term
                }
                | addExpr addop term
                {
                    $$ = maketree(ADDEXPR, 0);
                    addChild($$, $1);
                    addChild($$, $2);
                    addChild($$, $3);

                    // Type checking
                    if ($1->val != INT_TYPE || $3->val != INT_TYPE) {
                        yyerror("Type mismatch: additive operations require integer operands");
                        $$->val = ERROR_TYPE;
                    } else {
                        $$->val = INT_TYPE;
                    }

                    // Store the operation type
                    $$->op = $2->op;
                }
                ;

addop           : OPER_ADD
                {
                    $$ = maketree(ADDOP, OPER_ADD);
                    $$->val = OPER_ADD;
                    $$->strval = strdup("+");
                    $$->op = OPER_ADD;
                }
                | OPER_SUB
                {
                    $$ = maketree(ADDOP, OPER_SUB);
                    $$->val = OPER_SUB;
                    $$->strval = strdup("-");
                    $$->op = OPER_SUB;
                }
                ;

term            : factor
                {
                    $$ = maketree(TERM, 0);
                    addChild($$, $1);
                    $$->val = $1->val;  // Propagate the type from factor
                }
                | term mulop factor
                {
                    $$ = maketree(TERM, 0);
                    addChild($$, $1);
                    addChild($$, $2);
                    addChild($$, $3);

                    // Type checking
                    if ($1->val != INT_TYPE || $3->val != INT_TYPE) {
                        yyerror("Type mismatch: multiplicative operations require integer operands");
                        $$->val = ERROR_TYPE;
                    } else {
                        $$->val = INT_TYPE;
                    }

                    // Store the operation type
                    $$->op = $2->op;
                }
                ;

mulop           : OPER_MUL
                {
                    $$ = maketree(MULOP, OPER_MUL);
                    $$->val = OPER_MUL;
                    $$->op = OPER_MUL;
                    $$->strval = strdup("*");
                }
                | OPER_DIV
                {
                    $$ = maketree(MULOP, OPER_DIV);
                    $$->val = OPER_DIV;
                    $$->op = OPER_DIV;
                    $$->strval = strdup("/");
                }
                ;

factor          : LPAREN expression RPAREN
                {
                    $$ = maketree(FACTOR, 0);
                    addChild($$, $2);
                    $$->val = $2->val;  // Propagate the type from expression
                }
                | var
                {
                    $$ = maketree(FACTOR, 0);
                    addChild($$, $1);
                    $$->val = $1->val;  // Propagate the type from var
                }
                | funcCallExpr
                {
                    $$ = maketree(FACTOR, 0);
                    addChild($$, $1);
                    $$->val = $1->val;  // Propagate the type from function call
                }
                | INTCONST
                {
                    $$ = maketree(FACTOR, 0);
                    tree *intNode = maketree(INTEGER, $1);
                    intNode->val = INT_TYPE;
                    addChild($$, intNode);
                    $$->val = INT_TYPE;
                }
                | CHARCONST
                {
                    $$ = maketree(FACTOR, 0);
                    tree *charNode = maketree(CHAR, $1);
                    charNode->val = CHAR_TYPE;
                    addChild($$, charNode);
                    $$->val = CHAR_TYPE;
                }
                | STRCONST
                {
                    $$ = maketree(FACTOR, 0);
                    tree *str = maketree(STRING, 0);
                    str->strval = strdup($1);
                    str->val = CHAR_TYPE;  // Treat string as char*
                    addChild($$, str);
                    $$->val = CHAR_TYPE;
                }
                ;

funcCallExpr    : ID LPAREN argList RPAREN
                {
                    $$ = maketree(FUNCCALLEXPR, 0);
                    tree *id = maketree(IDENTIFIER, 0);
                    id->strval = strdup($1);
                    addChild($$, id);
                    addChild($$, $3);  // argList

                    // Look up the function in the symbol table
                    int index = ST_lookup($1, scope);
                    if (index == -1) {
                        yyerror("Undefined function");
                        $$->val = ERROR_TYPE;
                    } else if (strTable[index].symbol_type != FUNCTION_TYPE) {
                        yyerror("Identifier is not a function");
                        $$->val = ERROR_TYPE;
                    } else {
                        $$->val = strTable[index].data_type;  // Set return type
                        
                        // Check argument types against function declaration
                        // This assumes you've added a field to strEntry to store parameter types
                        if (strTable[index].param_count != $3->val) {
                            yyerror("Incorrect number of arguments");
                            $$->val = ERROR_TYPE;
                        } else {
                            for (int i = 0; i < $3->val; i++) {
                                if (strTable[index].param_types[i] != $3->arg_types[i]) {
                                    yyerror("Argument type mismatch");
                                    $$->val = ERROR_TYPE;
                                    break;
                                }
                            }
                        }
                    }
                }
                | ID LPAREN RPAREN
                {
                    $$ = maketree(FUNCCALLEXPR, 0);
                    tree *id = maketree(IDENTIFIER, 0);
                    id->strval = strdup($1);
                    addChild($$, id);
                    addChild($$, maketree(ARGLIST, 0));  // empty argList

                    // Look up the function in the symbol table
                    int index = ST_lookup($1, scope);
                    if (index == -1) {
                        yyerror("Undefined function");
                        $$->val = ERROR_TYPE;
                    } else if (strTable[index].symbol_type != FUNCTION_TYPE) {
                        yyerror("Identifier is not a function");
                        $$->val = ERROR_TYPE;
                    } else {
                        $$->val = strTable[index].data_type;  // Set return type
                        
                        // Check if function accepts no arguments
                        if (strTable[index].param_count != 0) {
                            yyerror("Function called with no arguments, but expects arguments");
                            $$->val = ERROR_TYPE;
                        }
                    }
                }
                ;

argList         : expression
                {
                    $$ = maketree(ARGLIST, 0);
                    addChild($$, $1);
                    $$->val = 1;  // Count of arguments
                    
                    // Create an array to store argument types
                    $$->arg_types = malloc(sizeof(int));
                    if ($$->arg_types == NULL) {
                        yyerror("Memory allocation failed for argument types");
                        YYABORT;
                    }
                    $$->arg_types[0] = $1->val;
                }
                | argList COMMA expression
                {
                    $$ = $1;  // Use the existing ARGLIST node
                    addChild($$, $3);  // Add the new expression to it
                    $$->val++;  // Increment argument count
                    
                    // Reallocate memory for the new argument type
                    int *new_arg_types = realloc($$->arg_types, $$->val * sizeof(int));
                    if (new_arg_types == NULL) {
                        yyerror("Memory reallocation failed for argument types");
                        YYABORT;
                    }
                    $$->arg_types = new_arg_types;
                    $$->arg_types[$$->val - 1] = $3->val;
                }
                ;



%%


int yywarning(char * msg){
    printf("warning: line %d: %s\n", yylineno, msg);
    return 0;
}

int yyerror(char * msg){
    printf("error: line %d: %s\n", yylineno, msg);
    return 0;
}

int has_return_statement(tree *node) {
    if (node == NULL) return 0;
    
    if (node->nodeKind == RETURNSTMT) {
        return 1;
    }
    
    for (int i = 0; i < node->numChildren; i++) {
        if (has_return_statement(node->children[i])) {
            return 1;
        }
    }
    
    return 0;
}