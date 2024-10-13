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

char* scope = "";
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
                    tree* progNode = maketree(PROGRAM, 0);
                    addChild(progNode, $1);
                    ast = progNode;
                    $$ = progNode;
                }
                ;

declList        : decl
                {
                    tree* declListNode = maketree(DECLLIST, 0);
                    addChild(declListNode, $1);
                    $$ = declListNode;
                }
                | declList decl
                {
                    $$ = $1;
                    addChild($$, $2);
                }
                ;

decl            : varDecl
                | funDecl
                ;

varDecl         : typeSpecifier ID SEMICLN
                {
                    $$ = maketree(VARDECL, 0);
                    addChild($$, $1);
                    addChild($$, maketree(IDENTIFIER, 0));
                    $$->children[1]->strval = $2;
                    ST_insert($2, scope, $1->val, SCALAR);
                }
                | typeSpecifier ID LSQ_BRKT INTCONST RSQ_BRKT SEMICLN
                {
                    $$ = maketree(VARDECL, 0);
                    addChild($$, $1);
                    addChild($$, maketree(ARRAYDECL, 0));
                    $$->children[1]->strval = $2;
                    addChild($$->children[1], maketree(INTEGER, $4));
                    ST_insert($2, scope, $1->val, ARRAY);
                }
                ;

typeSpecifier   : KWD_INT
                {
                    $$ = maketree(TYPESPEC, KWD_INT);
                }
                | KWD_CHAR
                {
                    $$ = maketree(TYPESPEC, KWD_CHAR);
                }
                | KWD_VOID
                {
                    $$ = maketree(TYPESPEC, KWD_VOID);
                }
                ;

funDecl         : typeSpecifier ID LPAREN formalDeclList RPAREN funBody
                {
                    $$ = maketree(FUNDECL, 0);
                    addChild($$, $1);
                    addChild($$, maketree(IDENTIFIER, 0));
                    $$->children[1]->strval = $2;
                    addChild($$, $4);
                    addChild($$, $6);
                    scope = $2;
                    ST_insert($2, "", $1->val, FUNCTION);
                    scope = "";
                }
                | typeSpecifier ID LPAREN RPAREN funBody
                {
                    $$ = maketree(FUNDECL, 0);
                    addChild($$, $1);
                    addChild($$, maketree(IDENTIFIER, 0));
                    $$->children[1]->strval = $2;
                    addChild($$, maketree(FORMALDECLLIST, 0));
                    addChild($$, $5);
                    scope = $2;
                    ST_insert($2, "", $1->val, FUNCTION);
                    scope = "";
                }
                ;

formalDeclList  : formalDecl
                {
                    $$ = maketree(FORMALDECLLIST, 0);
                    addChild($$, $1);
                }
                | formalDecl COMMA formalDeclList
                {
                    $$ = maketree(FORMALDECLLIST, 0);
                    addChild($$, $1);
                    addChild($$, $3);
                }
                ;

formalDecl      : typeSpecifier ID
                {
                    $$ = maketree(FORMALDECL, 0);
                    addChild($$, $1);
                    addChild($$, maketree(IDENTIFIER, 0));
                    $$->children[1]->strval = $2;
                    ST_insert($2, scope, $1->val, SCALAR);
                }
                | typeSpecifier ID LSQ_BRKT RSQ_BRKT
                {
                    $$ = maketree(FORMALDECL, 0);
                    addChild($$, $1);
                    addChild($$, maketree(ARRAYDECL, 0));
                    $$->children[1]->strval = $2;
                    ST_insert($2, scope, $1->val, ARRAY);
                }
                ;

funBody         : LCRLY_BRKT localDeclList statementList RCRLY_BRKT
                {
                    $$ = maketree(FUNBODY, 0);
                    addChild($$, $2);
                    addChild($$, $3);
                }
                ;

localDeclList   : /* empty */
                {
                    $$ = maketree(LOCALDECLLIST, 0);
                }
                | varDecl localDeclList
                {
                    $$ = maketree(LOCALDECLLIST, 0);
                    addChild($$, $1);
                    addChild($$, $2);
                }
                ;

statementList   : /* empty */
                {
                    $$ = maketree(STATEMENTLIST, 0);
                }
                | statement statementList
                {
                    $$ = maketree(STATEMENTLIST, 0);
                    addChild($$, $1);
                    addChild($$, $2);
                }
                ;

statement       : compoundStmt
                | assignStmt
                | condStmt
                | loopStmt
                | returnStmt
                ;

compoundStmt    : LCRLY_BRKT statementList RCRLY_BRKT
                {
                    $$ = maketree(COMPOUNDSTMT, 0);
                    addChild($$, $2);
                }
                ;

assignStmt      : var OPER_ASGN expression SEMICLN
                {
                    $$ = maketree(ASSIGNSTMT, 0);
                    addChild($$, $1);
                    addChild($$, $3);
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
                    addChild($$, $3);
                    addChild($$, $5);
                }
                | KWD_IF LPAREN expression RPAREN statement KWD_ELSE statement
                {
                    $$ = maketree(CONDSTMT, 0);
                    addChild($$, $3);
                    addChild($$, $5);
                    addChild($$, $7);
                }
                ;

loopStmt        : KWD_WHILE LPAREN expression RPAREN statement
                {
                    $$ = maketree(LOOPSTMT, 0);
                    addChild($$, $3);
                    addChild($$, $5);
                }
                ;

returnStmt      : KWD_RETURN SEMICLN
                {
                    $$ = maketree(RETURNSTMT, 0);
                }
                | KWD_RETURN expression SEMICLN
                {
                    $$ = maketree(RETURNSTMT, 0);
                    addChild($$, $2);
                }
                ;

var             : ID
                {
                    $$ = maketree(VAR, 0);
                    addChild($$, maketree(IDENTIFIER, 0));
                    $$->children[0]->strval = $1;
                    if (ST_lookup($1, scope) == -1) {
                        char error_msg[100];
                        snprintf(error_msg, sizeof(error_msg), "Undeclared variable: %s", $1);
                        yyerror(error_msg);
                    }
                }
                | ID LSQ_BRKT addExpr RSQ_BRKT
                {
                    $$ = maketree(VAR, 0);
                    addChild($$, maketree(ARRAYDECL, 0));
                    $$->children[0]->strval = $1;
                    addChild($$->children[0], $3);
                    if (ST_lookup($1, scope) == -1) {
                        char error_msg[100];
                        snprintf(error_msg, sizeof(error_msg), "Undeclared array: %s", $1);
                        yyerror(error_msg);
                    }
                }
                ;

expression      : addExpr
                | expression relop addExpr
                {
                    $$ = maketree(EXPRESSION, 0);
                    addChild($$, $1);
                    addChild($$, $2);
                    addChild($$, $3);
                }
                ;

relop           : OPER_LTE
                {
                    $$ = maketree(RELOP, OPER_LTE);
                }
                | OPER_LT
                {
                    $$ = maketree(RELOP, OPER_LT);
                }
                | OPER_GT
                {
                    $$ = maketree(RELOP, OPER_GT);
                }
                | OPER_GTE
                {
                    $$ = maketree(RELOP, OPER_GTE);
                }
                | OPER_EQ
                {
                    $$ = maketree(RELOP, OPER_EQ);
                }
                | OPER_NEQ
                {
                    $$ = maketree(RELOP, OPER_NEQ);
                }
                ;

addExpr         : term
                | addExpr addop term
                {
                    $$ = maketree(ADDEXPR, 0);
                    addChild($$, $1);
                    addChild($$, $2);
                    addChild($$, $3);
                }
                ;

addop           : OPER_ADD
                {
                    $$ = maketree(ADDOP, OPER_ADD);
                }
                | OPER_SUB
                {
                    $$ = maketree(ADDOP, OPER_SUB);
                }
                ;

term            : factor
                | term mulop factor
                {
                    $$ = maketree(TERM, 0);
                    addChild($$, $1);
                    addChild($$, $2);
                    addChild($$, $3);
                }
                ;

mulop           : OPER_MUL
                {
                    $$ = maketree(MULOP, OPER_MUL);
                }
                | OPER_DIV
                {
                    $$ = maketree(MULOP, OPER_DIV);
                }
                ;

factor          : LPAREN expression RPAREN
                {
                    $$ = $2;
                }
                | var
                | funcCallExpr
                | INTCONST
                {
                    $$ = maketree(INTEGER, $1);
                }
                | CHARCONST
                {
                    $$ = maketree(CHAR, $1);
                }
                | STRCONST
                {
                    $$ = maketree(STRING, 0);
                    $$->strval = $1;
                }
                ;

funcCallExpr    : ID LPAREN argList RPAREN
                {
                    $$ = maketree(FUNCCALLEXPR, 0);
                    addChild($$, maketree(IDENTIFIER, 0));
                    $$->children[0]->strval = $1;
                    addChild($$, $3);
                    if (ST_lookup($1, "") == -1) {
                        char error_msg[100];
                        snprintf(error_msg, sizeof(error_msg), "Undeclared function: %s", $1);
                        yywarning(error_msg);
                    }
                }
                | ID LPAREN RPAREN
                {
                    $$ = maketree(FUNCCALLEXPR, 0);
                    addChild($$, maketree(IDENTIFIER, 0));
                    $$->children[0]->strval = $1;
                    addChild($$, maketree(ARGLIST, 0));
                    if (ST_lookup($1, "") == -1) {
                        char error_msg[100];
                        snprintf(error_msg, sizeof(error_msg), "Undeclared function: %s", $1);
                        yywarning(error_msg);
                    }
                }
                ;

argList         : expression
                {
                    $$ = maketree(ARGLIST, 0);
                    addChild($$, $1);
                }
                | argList COMMA expression
                {
                    $$ = $1;
                    addChild($$, $3);
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