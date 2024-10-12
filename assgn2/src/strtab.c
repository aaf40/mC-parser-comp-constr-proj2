#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "strtab.h"

#define MAXIDS 1000
#define MAX_ID_LENGTH 50
#define MAX_SCOPE_LENGTH 100

struct strEntry strTable[MAXIDS];

const char* dataTypeStrings[] = {"int", "char", "void"};
const char* symbolTypeStrings[] = {"", "[]", "()"};
const char* types[] = {"int", "char", "void"};
const char* symTypeMod[] = {"", "[]", "()"};

/* Provided is a hash function that you may call to get an integer back. */
unsigned long hash(unsigned char *str)
{
    unsigned long hash = 5381;
    int c;

    while (c = *str++)
        hash = ((hash << 5) + hash) + c; /* hash * 33 + c */

    return hash;
}

void ST_init() {
    for (int i = 0; i < MAXIDS; i++) {
        strTable[i].id = NULL;
        strTable[i].scope = NULL;
    }
}

int ST_insert(char *id, char *scope, int data_type, int symbol_type) {
    char key[MAX_ID_LENGTH + MAX_SCOPE_LENGTH];
    snprintf(key, sizeof(key), "%s_%s", scope, id);
    
    unsigned long index = hash((unsigned char*)key) % MAXIDS;
    int start_index = index;

    do {
        if (strTable[index].id == NULL) {
            strTable[index].id = malloc(strlen(id) + 1);
            if (strTable[index].id == NULL) {
                fprintf(stderr, "Memory allocation failed for id\n");
                return -1;
            }
            strcpy(strTable[index].id, id);

            strTable[index].scope = malloc(strlen(scope) + 1);
            if (strTable[index].scope == NULL) {
                fprintf(stderr, "Memory allocation failed for scope\n");
                free(strTable[index].id);
                return -1;
            }
            strcpy(strTable[index].scope, scope);

            strTable[index].data_type = data_type;
            strTable[index].symbol_type = symbol_type;
            return index;
        }
        if (strcmp(strTable[index].id, id) == 0 && 
            strcmp(strTable[index].scope, scope) == 0) {
            return index;  // Identifier already exists
        }
        index = (index + 1) % MAXIDS;
    } while (index != start_index);

    return -1;  // Table is full
}

int ST_lookup(char *id, char *scope) {
    char key[MAX_ID_LENGTH + MAX_SCOPE_LENGTH];
    snprintf(key, sizeof(key), "%s_%s", scope, id);
    
    unsigned long index = hash((unsigned char*)key) % MAXIDS;
    int start_index = index;

    do {
        if (strTable[index].id == NULL) {
            return -1;  // Identifier not found
        }
        if (strcmp(strTable[index].id, id) == 0 && 
            strcmp(strTable[index].scope, scope) == 0) {
            return index;  // Found the identifier
        }
        index = (index + 1) % MAXIDS;
    } while (index != start_index);

    return -1;  // Identifier not found
}

void output_entry(int i) {
    if (i >= 0 && i < MAXIDS && strTable[i].id != NULL) {
        printf("%d: %s ", i, types[strTable[i].data_type]);
        printf("%s:%s%s\n", strTable[i].scope, strTable[i].id, symTypeMod[strTable[i].symbol_type]);
    } else {
        printf("Invalid entry or empty slot at index %d\n", i);
    }
}

void ST_free() {
    for (int i = 0; i < MAXIDS; i++) {
        free(strTable[i].id);
        free(strTable[i].scope);
    }
}
