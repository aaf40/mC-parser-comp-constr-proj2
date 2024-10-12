%{
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include "tree.h"
#include "strtab.h"
#include "parser.h"

extern int yylineno;

int yylex(void);
int yyerror(char *s);

/* nodeTypes refer to different types of internal and external nodes that can be part of the abstract syntax tree.*/
enum nodeTypes {PROGRAM, DECLLIST, DECL, VARDECL, TYPESPEC, FUNDECL,
                FORMALDECLLIST, FORMALDECL, FUNBODY, LOCALDECLLIST,
                STATEMENTLIST, STATEMENT, COMPOUNDSTMT, ASSIGNSTMT,
                CONDSTMT, LOOPSTMT, RETURNSTMT, EXPRESSION, RELOP,
                ADDEXPR, ADDOP, TERM, MULOP, FACTOR, FUNCCALLEXPR,
                ARGLIST, INTEGER, IDENTIFIER, VAR, ARRAYDECL, CHAR,
                FUNCTYPENAME};

enum opType {ADD, SUB, MUL, DIV, LT, LTE, EQ, GTE, GT, NEQ};

/* NOTE: mC has two kinds of scopes for variables : local and global. Variables declared outside any
function are considered globals, whereas variables (and parameters) declared inside a function foo are local to foo. You should update the scope variable whenever you are inside a production that matches function definition (funDecl production). The rationale is that you are entering that function, so all variables, arrays, and other functions should be within this scope. You should pass this variable whenever you are calling the ST_insert or ST_lookup functions. This variable should be updated to scope = "" to indicate global scope whenever funDecl finishes. Treat these hints as helpful directions only. You may implement all of the functions as you like and not adhere to my instructions. As long as the directory structure is correct and the file names are correct, we are okay with it. */
char* scope = "";
%}

/* the union describes the fields available in the yylval variable */
%union
{
    int value;
    struct treenode *node;
    char *strval;
}

/*Add token declarations below. The type <value> indicates that the associated token will be of a value type such as integer, float etc., and <strval> indicates that the associated token will be of string type.*/
%token <strval> ID
%token <value> INTCONST
%token KWD_INT KWD_CHAR KWD_VOID
%token KWD_IF KWD_ELSE KWD_WHILE KWD_RETURN
%token OPER_ADD OPER_SUB OPER_MUL OPER_DIV
%token OPER_LT OPER_LTE OPER_GT OPER_GTE OPER_EQ OPER_NEQ OPER_ASGN
%token LSQ_BRKT RSQ_BRKT LCRLY_BRKT RCRLY_BRKT LPAREN RPAREN
%token COMMA SEMICLN
%token CHARCONST
%token ERROR ILLEGAL_TOKEN
/* TODO: Add the rest of the tokens below.*/


/* TODO: Declate non-terminal symbols as of type node. Provided below is one example. node is defined as 'struct treenode *node' in the above union data structure. This declaration indicates to parser that these non-terminal variables will be implemented using a 'treenode *' type data structure. Hence, the circles you draw when drawing a parse tree, the following lines are telling yacc that these will eventually become circles in an AST. This is one of the connections between the AST you draw by hand and how yacc implements code to concretize that. We provide with two examples: program and declList from the grammar. Make sure to add the rest.  */

%type <node> program declList decl varDecl funDecl typeSpec compoundStmt






%start program

%%
/* TODO: Your grammar and semantic actions go here. We provide with two example productions and their associated code for adding non-terminals to the AST.*/

program         : declList
                 {
                    tree* progNode = maketree(PROGRAM);
                    addChild(progNode, $1);
                    ast = progNode;
                 }
                ;

declList        : decl
                 {
                    tree* declListNode = maketree(DECLLIST);
                    addChild(declListNode, $1);
                    $$ = declListNode;
                 }
                | declList decl
                 {
                    tree* declListNode = maketree(DECLLIST);
                    addChild(declListNode, $1);
                    addChild(declListNode, $2);
                    $$ = declListNode;
                 }
                ;
decl            : varDecl
                | funDecl
                ;
varDecl         : typeSpec ID ';'
                {
                    // TODO: Implement AST node creation for varDecl
                    $$ = maketree(VARDECL);
                    // Add children as needed
                }
                ;

funDecl         : typeSpec ID '(' /* parameters */ ')' compoundStmt
                {
                    // TODO: Implement AST node creation for funDecl
                    $$ = maketree(FUNDECL);
                    // Add children as needed
                }
                ;

typeSpec        : KWD_INT
                  {
                    $$ = maketree(TYPESPEC);
                    // TODO: Set the type of typeSpec node to INT
                  }
                | KWD_CHAR
                  {
                    $$ = maketree(TYPESPEC);
                    // TODO: Set the type of typeSpec node to CHAR
                  }
                | KWD_VOID
                  {
                    $$ = maketree(TYPESPEC);
                    // TODO: Set the type of typeSpec node to VOID
                  }
                ;

compoundStmt    : '{' /* statements */ '}'
                {
                    // TODO: Implement AST node creation for compoundStmt
                    $$ = maketree(COMPOUNDSTMT);
                    // Add children as needed
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
