#ifndef hashlibimplementation_h
#define hashlibimplementation_h

/* This goes into the hash; ie., product_id is the index, pointing to this structure: */
typedef struct hashitem {
	int product_id; /* This is the key */
	double * factors; /* These are the associated factors */
} hashitem, *hashitemptr;

/* The following functions implement the loose ends of hashlib.h. */
/* Comparison between two hash keys */
int mycmp(void *litem, void *ritem);
/* Duplication of items in storage */
void *mydupe(void *item);
/* Freeing the memory for deleting an object */
void myundupe(void *item);
/* Two hash functions using 32 bit keys; the implementations and the skeletons */
int hash32shift(int key);
int hash32shiftmult(int key);
unsigned long myhash(void *item);
unsigned long myrehash(void *item);
#endif
