#ifndef PARSER_H
#define PARSER_H

int yyparse(void);
int yylex(void);
int yyerror(char *s);

/* nodeTypes refer to different types of internal and external nodes that can be part of the abstract syntax tree.*/
typedef enum nodeKind {
    PROGRAM, DECLLIST, DECL, VARDECL, TYPESPEC, FUNDECL, FORMALDECLLIST, FORMALDECL, FUNBODY,
    LOCALDECLLIST, STATEMENTLIST, STATEMENT, COMPOUNDSTMT, ASSIGNSTMT, CONDSTMT, LOOPSTMT,
    RETURNSTMT, EXPRESSION, RELOP, ADDEXPR, ADDOP, TERM, MULOP, FACTOR, FUNCCALLEXPR,
    ARGLIST, INTEGER, IDENTIFIER, VAR, ARRAYDECL, CHAR, FUNCTYPENAME, 
    NODE_KWD_INT, NODE_KWD_CHAR
} nodeKind;

#endif // PARSER_H
