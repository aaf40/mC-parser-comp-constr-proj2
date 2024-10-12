%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
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

%left OPER_ADD OPER_SUB
%left OPER_MUL OPER_DIV
%nonassoc OPER_LT OPER_LTE OPER_GT OPER_GTE OPER_EQ OPER_NEQ
%nonassoc LOWER_THAN_ELSE
%nonassoc KWD_ELSE

/*Add token declarations below. The type <value> indicates that the associated token will be of a value type such as integer, float etc., and <strval> indicates that the associated token will be of string type.*/
%token <strval> ID
%token <value> INTCONST
%token KWD_INT KWD_CHAR KWD_VOID
%token KWD_IF KWD_ELSE KWD_WHILE KWD_RETURN
%token OPER_ADD OPER_SUB OPER_MUL OPER_DIV
%token OPER_LT OPER_LTE OPER_GT OPER_GTE OPER_EQ OPER_NEQ OPER_ASGN
%token LSQ_BRKT RSQ_BRKT LCRLY_BRKT RCRLY_BRKT LPAREN RPAREN
%token COMMA SEMICLN
%token <value> CHARCONST
%token ERROR ILLEGAL_TOKEN
/* TODO: Add the rest of the tokens below.*/



/* TODO: Declate non-terminal symbols as of type node. Provided below is one example. node is defined as 'struct treenode *node' in the above union data structure. This declaration indicates to parser that these non-terminal variables will be implemented using a 'treenode *' type data structure. Hence, the circles you draw when drawing a parse tree, the following lines are telling yacc that these will eventually become circles in an AST. This is one of the connections between the AST you draw by hand and how yacc implements code to concretize that. We provide with two examples: program and declList from the grammar. Make sure to add the rest.  */

%type <node> program declList decl varDecl funDecl typeSpec compoundStmt
%type <node> formalDeclList formalDecl localDeclList
%type <node> statementList statement assignStmt condStmt loopStmt returnStmt
%type <node> expression addExpr mulExpr factor relop addop mulop
%type <node> funcCallExpr argList var
%type <node> integer




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

varDecl         : typeSpec ID SEMICLN
                {
                    $$ = maketree(VARDECL);
                    addChild($$, $1);  // typeSpec
                    addChild($$, maketree(IDENTIFIER));
                    $$->children[1]->strval = $2;
                    // TODO: Insert variable into symbol table
                    // ST_insert($2, scope, ...);
                }
                | typeSpec ID LSQ_BRKT INTCONST RSQ_BRKT SEMICLN
                {
                    $$ = maketree(VARDECL);
                    addChild($$, $1);  // typeSpec
                    addChild($$, maketree(IDENTIFIER));
                    $$->children[1]->strval = $2;
                    addChild($$->children[1], maketree(INTEGER));
                    $$->children[1]->children[0]->val = $4;  // array size
                    // TODO: Insert array into symbol table
                    // ST_insert($2, scope, ...);
                }
                ;

funDecl : typeSpec ID LPAREN formalDeclList RPAREN compoundStmt
        {
            $$ = maketree(FUNDECL);
            addChild($$, $1);  // typeSpec
            addChild($$, maketree(IDENTIFIER));
            $$->children[1]->strval = $2;  // ID
            addChild($$, $4);  // formalDeclList
            addChild($$, $6);  // compoundStmt
            
            // Update scope for symbol table
            scope = $2;
            // TODO: Insert function into symbol table
            // ST_insert($2, "", FUNCTION, ...);
            
            scope = "";  // Reset to global scope after function
        }
        | typeSpec ID LPAREN RPAREN compoundStmt
        {
            $$ = maketree(FUNDECL);
            addChild($$, $1);  // typeSpec
            addChild($$, maketree(IDENTIFIER));
            $$->children[1]->strval = $2;  // ID
            addChild($$, maketree(FORMALDECLLIST));  // empty formal decl list
            addChild($$, $5);  // compoundStmt
            
            // Update scope for symbol table
            scope = $2;
            // TODO: Insert function into symbol table
            // ST_insert($2, "", FUNCTION, ...);
            
            scope = "";  // Reset to global scope after function
        }
        ;

formalDeclList : formalDecl
                {
                    $$ = maketree(FORMALDECLLIST);
                    addChild($$, $1);
                }
                | formalDeclList COMMA formalDecl
                {
                    $$ = $1;
                    addChild($$, $3);
                }
                ;

formalDecl : typeSpec ID
           {
               $$ = maketree(FORMALDECL);
               addChild($$, $1);
               addChild($$, maketree(IDENTIFIER));
               $$->children[1]->strval = $2;
               // TODO: Insert parameter into symbol table
               // ST_insert($2, scope, ...);
           }
           | typeSpec ID LSQ_BRKT RSQ_BRKT
           {
               $$ = maketree(FORMALDECL);
               addChild($$, $1);
               addChild($$, maketree(ARRAYDECL));
               $$->children[1]->strval = $2;
               // TODO: Insert array parameter into symbol table
               // ST_insert($2, scope, ...);
           }
           ;

compoundStmt : LCRLY_BRKT localDeclList statementList RCRLY_BRKT
             {
                 $$ = maketree(COMPOUNDSTMT);
                 addChild($$, $2);  // localDeclList
                 addChild($$, $3);  // statementList
             }
             ;

localDeclList : /* empty */
              {
                  $$ = maketree(LOCALDECLLIST);
              }
              | localDeclList varDecl
              {
                  $$ = $1;
                  addChild($$, $2);
              }
              ;

statementList : /* empty */
              {
                  $$ = maketree(STATEMENTLIST);
              }
              | statementList statement
              {
                  $$ = $1;
                  addChild($$, $2);
              }
              ;

statement : assignStmt
          | condStmt
          | loopStmt
          | returnStmt
          | compoundStmt
          | expression SEMICLN
          {
              $$ = maketree(STATEMENT);
              addChild($$, $1);
          }
          ;
assignStmt : var OPER_ASGN expression SEMICLN
           {
               $$ = maketree(ASSIGNSTMT);
               addChild($$, $1);  // var
               addChild($$, $3);  // expression
           }
           ;

var : ID
    {
        $$ = maketree(VAR);
        addChild($$, maketree(IDENTIFIER));
        $$->children[0]->strval = $1;
        // TODO: Check if variable is in symbol table
        // if (!ST_lookup($1, scope)) yyerror("Undeclared variable");
    }
    | ID LSQ_BRKT expression RSQ_BRKT
    {
        $$ = maketree(VAR);
        addChild($$, maketree(ARRAYDECL));
        $$->children[0]->strval = $1;
        addChild($$->children[0], $3);  // array index expression
        // TODO: Check if array is in symbol table
        // if (!ST_lookup($1, scope)) yyerror("Undeclared array");
    }
    ;

expression : addExpr
           | expression relop addExpr
           {
               $$ = maketree(EXPRESSION);
               addChild($$, $1);
               addChild($$, $2);
               addChild($$, $3);
           }
           ;

condStmt : KWD_IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
         {
             $$ = maketree(CONDSTMT);
             addChild($$, $3);  // condition
             addChild($$, $5);  // if-body
             addChild($$, NULL);  // no else-body
         }
         | KWD_IF LPAREN expression RPAREN statement KWD_ELSE statement
         {
             $$ = maketree(CONDSTMT);
             addChild($$, $3);  // condition
             addChild($$, $5);  // if-body
             addChild($$, $7);  // else-body
         }
         ;

returnStmt : KWD_RETURN SEMICLN
           {
               $$ = maketree(RETURNSTMT);
               addChild($$, NULL);  // void return
           }
           | KWD_RETURN expression SEMICLN
           {
               $$ = maketree(RETURNSTMT);
               addChild($$, $2);  // return with value
           }
           ;

relop : OPER_LT
      {
          $$ = maketree(RELOP);
          $$->opType = LT;
      }
      | OPER_LTE
      {
          $$ = maketree(RELOP);
          $$->opType = LTE;
      }
      | OPER_GT
      {
          $$ = maketree(RELOP);
          $$->opType = GT;
      }
      | OPER_GTE
      {
          $$ = maketree(RELOP);
          $$->opType = GTE;
      }
      | OPER_EQ
      {
          $$ = maketree(RELOP);
          $$->opType = EQ;
      }
      | OPER_NEQ
      {
          $$ = maketree(RELOP);
          $$->opType = NEQ;
      }
      ;

addExpr : mulExpr
        | addExpr addop mulExpr
        {
            $$ = maketree(ADDEXPR);
            addChild($$, $1);
            addChild($$, $2);
            addChild($$, $3);
        }
        ;

addop : OPER_ADD
      {
          $$ = maketree(ADDOP);
          $$->opType = ADD;
      }
      | OPER_SUB
      {
          $$ = maketree(ADDOP);
          $$->opType = SUB;
      }
      ;

mulExpr : factor
        | mulExpr mulop factor
        {
            $$ = maketree(TERM);
            addChild($$, $1);
            addChild($$, $2);
            addChild($$, $3);
        }
        ;

mulop : OPER_MUL
      {
          $$ = maketree(MULOP);
          $$->opType = MUL;
      }
      | OPER_DIV
      {
          $$ = maketree(MULOP);
          $$->opType = DIV;
      }
      ;

factor : LPAREN expression RPAREN
       {
           $$ = $2;  // We don't need a separate node for parentheses
       }
       | var
       | funcCallExpr
       | integer
       | CHARCONST
       {
           $$ = maketree(CHAR);
           $$->val = $1;
       }
       ;

integer : INTCONST
        {
            $$ = maketree(INTEGER);
            $$->val = $1;
        }
        ;

funcCallExpr : ID LPAREN argList RPAREN
             {
                 $$ = maketree(FUNCCALLEXPR);
                 addChild($$, maketree(IDENTIFIER));
                 $$->children[0]->strval = $1;
                 addChild($$, $3);  // argList
                 // TODO: Check if function is in symbol table
                 // if (!ST_lookup($1, "")) yyerror("Undeclared function");
             }
             | ID LPAREN RPAREN
             {
                 $$ = maketree(FUNCCALLEXPR);
                 addChild($$, maketree(IDENTIFIER));
                 $$->children[0]->strval = $1;
                 addChild($$, maketree(ARGLIST));  // empty argList
                 // TODO: Check if function is in symbol table
                 // if (!ST_lookup($1, "")) yyerror("Undeclared function");
             }
             ;

argList : expression
        {
            $$ = maketree(ARGLIST);
            addChild($$, $1);
        }
        | argList COMMA expression
        {
            $$ = $1;
            addChild($$, $3);
        }
        ;

typeSpec : KWD_INT
         {
             $$ = maketree(TYPESPEC);
             $$->val = KWD_INT;
         }
         | KWD_CHAR
         {
             $$ = maketree(TYPESPEC);
             $$->val = KWD_CHAR;
         }
         | KWD_VOID
         {
             $$ = maketree(TYPESPEC);
             $$->val = KWD_VOID;
         }
         ;

loopStmt : KWD_WHILE LPAREN expression RPAREN statement
         {
             $$ = maketree(LOOPSTMT);
             addChild($$, $3);  // condition
             addChild($$, $5);  // loop body
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
