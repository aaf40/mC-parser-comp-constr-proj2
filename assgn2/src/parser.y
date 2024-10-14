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
                    $$ = maketree(PROGRAM, 0);
                    addChild($$, $1);
                    ast = $$;
                }
                ;

declList        : decl
                {
                    $$ = maketree(DECLLIST, 0);
                    addChild($$, $1);
                }
                | declList decl
                {
                    $$ = $1;
                    addChild($$, $2);
                }
                ;

decl            : varDecl
                {
                    $$ = $1;
                }
                | funDecl
                {
                    $$ = $1;
                }
                ;

varDecl         : typeSpecifier ID SEMICLN
                {
                    $$ = maketree(VARDECL, 0);
                    addChild($$, $1);
                    tree *id = maketree(IDENTIFIER, 0);
                    id->strval = $2;
                    addChild($$, id);
                }
                | typeSpecifier ID LSQ_BRKT INTCONST RSQ_BRKT SEMICLN
                {
                    $$ = maketree(VARDECL, 0);
                    addChild($$, $1);
                    tree *arrayDecl = maketree(ARRAYDECL, 0);
                    arrayDecl->strval = $2;
                    tree *size = maketree(INTEGER, $4);
                    addChild(arrayDecl, size);
                    addChild($$, arrayDecl);
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
                    tree *funcTypeName = maketree(FUNCTYPENAME, 0);
                    addChild(funcTypeName, $1);
                    tree *id = maketree(IDENTIFIER, 0);
                    id->strval = $2;
                    addChild(funcTypeName, id);
                    addChild($$, funcTypeName);
                    addChild($$, $4);
                    addChild($$, $6);
                }
                | typeSpecifier ID LPAREN RPAREN funBody
                {
                    $$ = maketree(FUNDECL, 0);
                    tree *funcTypeName = maketree(FUNCTYPENAME, 0);
                    addChild(funcTypeName, $1);
                    tree *id = maketree(IDENTIFIER, 0);
                    id->strval = $2;
                    addChild(funcTypeName, id);
                    addChild($$, funcTypeName);
                    addChild($$, maketree(FORMALDECLLIST, 0));
                    addChild($$, $5);
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
                    tree *id = maketree(IDENTIFIER, 0);
                    id->strval = $2;
                    addChild($$, id);
                }
                | typeSpecifier ID LSQ_BRKT RSQ_BRKT
                {
                    $$ = maketree(FORMALDECL, 0);
                    addChild($$, $1);
                    tree *arrayDecl = maketree(ARRAYDECL, 0);
                    arrayDecl->strval = $2;
                    addChild($$, arrayDecl);
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
                    $$ = NULL;
                }
                | statement statementList
                {
                    $$ = maketree(STATEMENTLIST, 0);
                    addChild($$, $1);  // Add the new statement
                    if ($2 != NULL) {
                        addChild($$, $2);  // Add the rest of the statementList if it exists
                    }
                }
                ;

statement       : compoundStmt
                {
                    $$ = $1;
                }
                | assignStmt
                {
                    $$ = $1;
                }
                | condStmt
                {
                    $$ = $1;
                }
                | loopStmt
                {
                    $$ = $1;
                }
                | returnStmt
                {
                    $$ = $1;
                }
                ;

compoundStmt    : LCRLY_BRKT statementList RCRLY_BRKT
                {
                    $$ = $2;
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
                    addChild($$, $3);  // expression
                    addChild($$, $5);  // statement
                }
                | KWD_IF LPAREN expression RPAREN statement KWD_ELSE statement
                {
                    $$ = maketree(CONDSTMT, 0);
                    addChild($$, $3);  // expression
                    addChild($$, $5);  // if statement
                    addChild($$, $7);  // else statement
                }
                ;

loopStmt        : KWD_WHILE LPAREN expression RPAREN statement
                {
                    $$ = maketree(LOOPSTMT, 0);
                    addChild($$, $3);  // expression
                    addChild($$, $5);  // statement
                }
                ;

returnStmt      : KWD_RETURN SEMICLN
                {
                    $$ = maketree(RETURNSTMT, 0);
                }
                | KWD_RETURN expression SEMICLN
                {
                    $$ = maketree(RETURNSTMT, 0);
                    addChild($$, $2);  // expression
                }
                ;

var             : ID
                {
                    $$ = maketree(VAR, 0);
                    tree *id = maketree(IDENTIFIER, 0);
                    id->strval = $1;
                    addChild($$, id);
                }
                | ID LSQ_BRKT addExpr RSQ_BRKT
                {
                    $$ = maketree(VAR, 0);
                    tree *arrayAccess = maketree(ARRAYDECL, 0);
                    arrayAccess->strval = $1;
                    addChild(arrayAccess, $3);  // addExpr
                    addChild($$, arrayAccess);
                }
                ;

expression      : addExpr
                {
                    $$ = maketree(EXPRESSION, 0);
                    addChild($$, $1);
                }
                | expression relop addExpr
                {
                    $$ = maketree(EXPRESSION, 0);
                    addChild($$, $1);  // left expression
                    addChild($$, $2);  // relop
                    addChild($$, $3);  // right addExpr
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
                {
                    $$ = maketree(ADDEXPR, 0);
                    addChild($$, $1);
                }
                | addExpr addop term
                {
                    tree *newExpr = maketree(ADDEXPR, 0);
                    addChild(newExpr, $1);  // left addExpr
                    addChild(newExpr, $2);  // addop
                    addChild(newExpr, $3);  // right term
                    $$ = newExpr;
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
                {
                    $$ = maketree(TERM, 0);
                    addChild($$, $1);
                }
                | term mulop factor
                {
                    tree *newTerm = maketree(TERM, 0);
                    addChild(newTerm, $1);  // left term
                    addChild(newTerm, $2);  // mulop
                    addChild(newTerm, $3);  // right factor
                    $$ = newTerm;
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
                    $$ = $2;  // Just pass up the expression node
                }
                | var
                {
                    $$ = $1;
                }
                | funcCallExpr
                {
                    $$ = $1;
                }
                | INTCONST
                {
                    $$ = maketree(FACTOR, 0);
                    addChild($$, maketree(INTEGER, $1));
                }
                | CHARCONST
                {
                    $$ = maketree(FACTOR, 0);
                    addChild($$, maketree(CHAR, $1));
                }
                | STRCONST
                {
                    $$ = maketree(FACTOR, 0);
                    tree *strNode = maketree(STRING, 0);
                    strNode->strval = $1;
                    addChild($$, strNode);
                }
                ;

funcCallExpr    : ID LPAREN argList RPAREN
                {
                    $$ = maketree(FUNCCALLEXPR, 0);
                    tree *id = maketree(IDENTIFIER, 0);
                    id->strval = $1;
                    addChild($$, id);
                    addChild($$, $3);  // argList
                }
                | ID LPAREN RPAREN
                {
                    $$ = maketree(FUNCCALLEXPR, 0);
                    tree *id = maketree(IDENTIFIER, 0);
                    id->strval = $1;
                    addChild($$, id);
                    addChild($$, maketree(ARGLIST, 0));  // empty argList
                }
                ;

argList         : expression
                {
                    $$ = maketree(ARGLIST, 0);
                    addChild($$, $1);
                }
                | argList COMMA expression
                {
                    $$ = $1;  // Use the existing ARGLIST node
                    addChild($$, $3);  // Add the new expression to it
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
