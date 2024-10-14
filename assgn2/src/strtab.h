#ifndef STRTAB_H
#define STRTAB_H
#define MAXIDS 1000
#define MAX_ID_LENGTH 50
#define MAX_SCOPE_LENGTH 100
#define FUNCTION_TYPE 2

/* These enums are used in the parser.y file when creating nodes in the AST corresponding to the 'typeSpecifier' tokens . */
enum dataType {INT_TYPE, CHAR_TYPE, VOID_TYPE};

/*
These nums are passed as the last argument to ST_insert when inserting information about variable names, array names, and function names into the symbol table */

enum symbolType {SCALAR_TYPE, ARRAY_TYPE, FUNCTION};
#define ERROR_TYPE -1

extern const char* dataTypeStrings[];
extern const char* symbolTypeStrings[];
extern const char* types[];
extern const char* symTypeMod[];

/* This data structure describes each element of the symbol table. */
struct strEntry {
    char* id;
    char* scope;
    int   data_type;
    int   symbol_type;
    int   param_count;    // Number of parameters for functions
    int*  param_types;    // Array of parameter types for functions
};

/* initialize the symbol table */
void ST_init();

/* The symbolTable, which will be implemented as a hash table. */
extern struct strEntry strTable[MAXIDS];

/* id is a lexeme, scope is the scope of the symbol table, data_type is the data type of the lexeme, and symbol_type is one of the elements of symbolType declared in strtab.h. ST_insert should be called from the parser.y file whenever a scalar, array, or function is declared. Note that these types are declared above in symbolType enum. Hint: refer to the production rules varDecl and formalDecl. If you remove left recursion or apply left factoring, you may need to call ST_insert in other places as well. */
int ST_insert(char *id, char *scope, int data_type, int symbol_type);


/* ST_lookup should be called from the parser.y file whenever a reference to variable (id or array) or function call is made. Hint: refer to the production rules VAR and funcCallExpr. */
int ST_lookup(char *id, char *scope);

/* Print the i-th symbol table entry. You may not need this function. */
void output_entry(int i);

unsigned long hash(unsigned char *str);

/* frees the symbol table. */
void ST_free();

#endif
