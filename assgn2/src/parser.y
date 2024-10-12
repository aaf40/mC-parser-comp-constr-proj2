%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tree.h"
#include "strtab.h"
#include "parser.h"

extern int yylineno;

int get_token(void);
#define yylex get_token
int yyerror(char *s);
int yywarning(char *s);



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

%type <node> program declList decl varDecl funDecl typeSpec
%type <node> formalDeclList formalDecl localDeclList
%type <node> statementList statement compoundStmt
%type <node> returnStmt expression
%type <node> var
%type <node> factor
%type <node> assignStmt condStmt loopStmt
%type <node> addExpr mulExpr relop addop mulop
%type <node> funcCallExpr argList
%type <node> integer

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

%start program

%%
/* TODO: Your grammar and semantic actions go here. We provide with two example productions and their associated code for adding non-terminals to the AST.*/

program         : { /*printf("DEBUG: Entering program rule\n"); fflush(stdout); */ }
                  declList
                 {
                    /*printf("DEBUG: Reducing program\n");*/
                    tree* progNode = maketree(PROGRAM, 0);
                    addChild(progNode, $2);  // Note: changed $1 to $2
                    ast = progNode;
                    $$ = progNode;
                 }
                ;

declList        : { /*printf("DEBUG: Entering declList rule\n"); fflush(stdout); */ }
                  decl
                 {
                    tree* declListNode = maketree(DECLLIST, 0);
                    addChild(declListNode, $2);  // Note: changed $1 to $2
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

varDecl         : typeSpec ID SEMICLN
                {
                    /*printf("DEBUG: Reducing varDecl: %s\n", $2);*/
                    $$ = maketree(VARDECL, 0);
                    addChild($$, $1);  // typeSpec
                    addChild($$, maketree(IDENTIFIER, 0));
                    $$->children[1]->strval = $2;
                    int dataType = $1->val;
                    /*printf("DEBUG: Inserting variable %s with type %d\n", $2, dataType);*/
                    ST_insert($2, scope, dataType, SCALAR);
                }
                | typeSpec ID LSQ_BRKT INTCONST RSQ_BRKT SEMICLN
                {
                    $$ = maketree(VARDECL, 0);
                    addChild($$, $1);  // typeSpec
                    addChild($$, maketree(IDENTIFIER, 0));
                    $$->children[1]->strval = $2;
                    addChild($$->children[1], maketree(INTEGER, $4));
                    $$->children[1]->children[0]->val = $4;  // array size
                    int dataType = $1->val;  // Assuming typeSpec sets this value
                    ST_insert($2, scope, dataType, ARRAY);
                }
                ;

funDecl : typeSpec ID LPAREN formalDeclList RPAREN compoundStmt
        {
            $$ = maketree(DECL, 0);
            tree *funDeclNode = maketree(FUNDECL, 0);
            addChild($$, funDeclNode);
            
            tree *funcTypeName = maketree(FUNCTYPENAME, 0);
            addChild(funDeclNode, funcTypeName);
            addChild(funcTypeName, $1);  // typeSpec
            addChild(funcTypeName, maketree(IDENTIFIER, 0));
            funcTypeName->children[1]->strval = $2;  // ID
            
            addChild(funDeclNode, $4);  // formalDeclList
            
            tree *funBody = maketree(FUNBODY, 0);
            addChild(funDeclNode, funBody);
            addChild(funBody, $6);  // compoundStmt
            
            scope = $2;
            ST_insert($2, "", $1->val, FUNCTION);
            scope = "";  // Reset to global scope after function
        }
        | typeSpec ID LPAREN RPAREN compoundStmt
        {
            $$ = maketree(FUNDECL, 0);
            tree *funcTypeName = maketree(FUNCTYPENAME, 0);
            addChild(funcTypeName, $1);  // typeSpec
            addChild(funcTypeName, maketree(IDENTIFIER, 0));
            funcTypeName->children[1]->strval = $2;  // ID
            addChild($$, funcTypeName);
            addChild($$, maketree(FORMALDECLLIST, 0));  // empty formal decl list
            tree *funBody = maketree(FUNBODY, 0);
            addChild(funBody, $5);  // compoundStmt
            addChild($$, funBody);
            
            // Update scope for symbol table
            scope = $2;
            ST_insert($2, "", $1->val, FUNCTION);
            
            scope = "";  // Reset to global scope after function
        }
        ;

formalDeclList : formalDecl
                {
                    $$ = maketree(FORMALDECLLIST, 0);
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
               $$ = maketree(FORMALDECL, 0);
               addChild($$, $1);
               addChild($$, maketree(IDENTIFIER, 0));
               $$->children[1]->strval = $2;
               ST_insert($2, scope, $1->val, SCALAR);
           }
           | typeSpec ID LSQ_BRKT RSQ_BRKT
           {
               $$ = maketree(FORMALDECL, 0);
               addChild($$, $1);
               addChild($$, maketree(ARRAYDECL, 0));
               $$->children[1]->strval = $2;
               ST_insert($2, scope, $1->val, ARRAY);
           }
           ;

compoundStmt : LCRLY_BRKT localDeclList statementList RCRLY_BRKT
             {
                 $$ = maketree(COMPOUNDSTMT, 0);
                 addChild($$, $2);  // localDeclList
                 addChild($$, $3);  // statementList
             }
             ;

localDeclList : /* empty */
              {
                  $$ = maketree(LOCALDECLLIST, 0);
              }
              | localDeclList varDecl
              {
                  $$ = $1;
                  addChild($$, $2);
              }
              ;

statementList : statement
              {
                  $$ = maketree(STATEMENTLIST, 0);
                  addChild($$, $1);
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
              $$ = maketree(STATEMENT, 0);
              addChild($$, maketree(ASSIGNSTMT, 0));
              addChild($$->children[0], $1);
          }
          ;
assignStmt : var OPER_ASGN expression SEMICLN
           {
               $$ = maketree(ASSIGNSTMT, 0);
               addChild($$, $1);  // var
               tree *exprNode = maketree(EXPRESSION, 0);
               addChild(exprNode, $3);  // Wrap the existing expression
               addChild($$, exprNode);  // Add the EXPRESSION node to ASSIGNSTMT
               printf("DEBUG: Created ASSIGNSTMT with %d children\n", $$->numChildren);
               printf("DEBUG: Second child of ASSIGNSTMT is of type %d\n", $$->children[1]->nodeKind);
           }
           ;

var : ID
    {
        /*printf("DEBUG: Processing var: %s\n", $1);*/
        $$ = maketree(VAR, 0);
        addChild($$, maketree(IDENTIFIER, 0));
        $$->children[0]->strval = $1;
        if (ST_lookup($1, scope) == -1) {
            /*printf("DEBUG: Variable %s not found in symbol table\n", $1);*/
            char error_msg[100];
            snprintf(error_msg, sizeof(error_msg), "Undeclared variable: %s", $1);
            yyerror(error_msg);
        } else {
            /*printf("DEBUG: Variable %s found in symbol table\n", $1);*/
        }
    }
    | ID LSQ_BRKT expression RSQ_BRKT
    {
        $$ = maketree(VAR, 0);
        addChild($$, maketree(ARRAYDECL, 0));
        $$->children[0]->strval = $1;
        addChild($$->children[0], $3);  // array index expression
        if (ST_lookup($1, scope) == -1) {
            char error_msg[100];
            snprintf(error_msg, sizeof(error_msg), "Undeclared array: %s", $1);
            yyerror(error_msg);
        }
    }
    ;

expression : addExpr
           {
               $$ = maketree(EXPRESSION, 0);
               addChild($$, $1);
           }
           | expression relop addExpr
           {
               $$ = maketree(EXPRESSION, 0);
               addChild($$, $1);
               addChild($$, $2);
               addChild($$, $3);
           }
           ;

condStmt : KWD_IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
         {
             $$ = maketree(CONDSTMT, 0);
             addChild($$, $3);  // condition
             addChild($$, $5);  // if-body
             addChild($$, NULL);  // no else-body
         }
         | KWD_IF LPAREN expression RPAREN statement KWD_ELSE statement
         {
             $$ = maketree(CONDSTMT, 0);
             addChild($$, $3);  // condition
             addChild($$, $5);  // if-body
             addChild($$, $7);  // else-body
         }
         ;

returnStmt : KWD_RETURN SEMICLN
           {
               $$ = maketree(RETURNSTMT, 0);
               addChild($$, NULL);  // void return
           }
           | KWD_RETURN expression SEMICLN
           {
               $$ = maketree(RETURNSTMT, 0);
               addChild($$, $2);  // return with value
           }
           ;

relop : OPER_LT
      {
          $$ = maketree(RELOP, OPER_LT);
      }
      | OPER_LTE
      {
          $$ = maketree(RELOP, OPER_LTE);
      }
      | OPER_GT
      {
          $$ = maketree(RELOP, 0);
          $$->opType = GT;
      }
      | OPER_GTE
      {
          $$ = maketree(RELOP, 0);
          $$->opType = GTE;
      }
      | OPER_EQ
      {
          $$ = maketree(RELOP, 0);
          $$->opType = EQ;
      }
      | OPER_NEQ
      {
          $$ = maketree(RELOP, 0);
          $$->opType = NEQ;
      }
      ;

addExpr : mulExpr
        {
            $$ = maketree(ADDEXPR, 0);
            addChild($$, $1);
        }
        | addExpr addop mulExpr
        {
            $$ = maketree(ADDEXPR, 0);
            addChild($$, $1);
            addChild($$, $2);
            addChild($$, $3);
        }
        ;

addop : OPER_ADD
      {
          $$ = maketree(ADDOP, OPER_ADD);
      }
      | OPER_SUB
      {
          $$ = maketree(ADDOP, OPER_SUB);
      }
      ;

mulExpr : factor
        {
            $$ = maketree(TERM, 0);
            addChild($$, $1);
        }
        | mulExpr mulop factor
        {
            tree *newTerm = maketree(TERM, 0);
            addChild(newTerm, $1);
            addChild(newTerm, $2);
            addChild(newTerm, $3);
            $$ = newTerm;
        }
        ;

mulop : OPER_MUL
      {
          $$ = maketree(MULOP, OPER_MUL);
      }
      | OPER_DIV
      {
          $$ = maketree(MULOP, OPER_DIV);
      }
      ;

factor : var
       {
           $$ = maketree(FACTOR, 0);
           addChild($$, $1);
       }
       | integer
       {
           $$ = maketree(FACTOR, 0);
           addChild($$, $1);
       }
       | LPAREN expression RPAREN
       {
           $$ = maketree(FACTOR, 0);
           addChild($$, $2);
       }
       | funcCallExpr
       {
           $$ = maketree(FACTOR, 0);
           addChild($$, $1);
       }
       ;

integer : INTCONST
        {
            $$ = maketree(INTEGER, $1);
        }
        ;

funcCallExpr : ID LPAREN argList RPAREN
             {
                 $$ = maketree(FUNCCALLEXPR, 0);
                 addChild($$, maketree(IDENTIFIER, 0));
                 $$->children[0]->strval = $1;
                 addChild($$, $3);  // argList
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
                 addChild($$, maketree(ARGLIST, 0));  // empty argList
                 if (ST_lookup($1, "") == -1) {
                     char error_msg[100];
                     snprintf(error_msg, sizeof(error_msg), "Undeclared function: %s", $1);
                     yywarning(error_msg);
                 }
             }
             ;

argList : expression
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

typeSpec : KWD_INT
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

loopStmt : KWD_WHILE LPAREN expression RPAREN statement
         {
             $$ = maketree(LOOPSTMT, 0);
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
