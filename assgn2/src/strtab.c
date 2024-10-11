#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include "strtab.h"


/* Provided is a hash function that you may call to get an integer back. */
unsigned long hash(unsigned char *str)
{
    unsigned long hash = 5381;
    int c;

    while (c = *str++)
        hash = ((hash << 5) + hash) + c; /* hash * 33 + c */

    return hash;
}

int ST_insert(char *id, char *scope, int data_type, int symbol_type){
    // TODO: Concatenate the scope and id and use that to create the hash key

    // TODO: Use ST_lookup to check if the id is already in the symbol table. If yes, ST_lookup will return an index that is not -1. if index != -1, that means the variable is already in the hashtable. Hence, no need to insert that variable again. However, if index == -1, then use linear probing to find an empty spot and insert there. Then return that index.

    return index;
}

int ST_lookup(char *id, char *scope) {
    // TODO: Concatenate the scope and id and use that to create the hash key


    // TODO: Use the hash value to check if the index position has the "id". If not, keep looking for id until you find an empty spot. If you find "id", return that index. If you arrive at an empty spot, that means "id" is not there. Then return -1. 

    return index;
}

void output_entry(int i){
    printf("%d: %s ", i, types[strTable[i].data_type]);
    printf("%s:%s%s\n", strTable[i].scope, strTable[i].id, symTypeMod[strTable[i].symbol_type]);
}

