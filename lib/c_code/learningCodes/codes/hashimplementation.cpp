#include "hashlib.h"
#include "hashimplementation.h"
#include <stdlib.h>
extern int conFeatureN;
int mycmp(void *litem, void *ritem)
{
	hashitemptr left  = (hashitem *)litem;
	hashitemptr right = (hashitem *)ritem;
	int     lvalue, rvalue;

	lvalue = left->product_id;
	rvalue = right->product_id;
	return (lvalue > rvalue) - (lvalue < rvalue);
	// This returns 1, 0, or -1 depending on whether the values are greater, lesser, or equal.
	// This is better than using (lvalue - rvalue) because that can overflow.
}

void *mydupe(void *item)
{
	hashitemptr myitem = (hashitem *)item;
	hashitemptr newitem;
	int i;

	if ((newitem = new hashitem)) {
		newitem->product_id = myitem->product_id;
		newitem->factors = new double[conFeatureN];
		for (i=0; i < conFeatureN; i++)
		{
			newitem->factors[i] = myitem->factors[i];
		}
	}
	else {  /* we ran out of memory, release and fail */
		delete(newitem);
		newitem = NULL;
    }
	return newitem;
}

void myundupe(void *item)
{
	hashitemptr myitem = (hashitem *)item;
	delete(myitem->factors);
	delete(myitem);
}

int hash32shift( int a)
{
   a = (a+0x7ed55d16) + (a<<12);
   a = (a^0xc761c23c) ^ (a>>19);
   a = (a+0x165667b1) + (a<<5);
   a = (a+0xd3a2646c) ^ (a<<9);
   a = (a+0xfd7046c5) + (a<<3);
   a = (a^0xb55a4f09) ^ (a>>16);
   return a;
}

int hash32shiftmult(int key)
{
	int c2=0x27d4eb2d; // a prime or an odd constant
	key = (key ^ 61) ^ (key >> 16);
	key = key + (key << 3);
	key = key ^ (key >> 4);
	key = key * c2;
	key = key ^ (key >> 15);
	return key;
}

unsigned long myhash(void *item)
{
	hashitemptr myitem = (hashitem *)item;
	return hash32shift(myitem->product_id);
}

unsigned long myrehash(void *item)
{
	hashitemptr myitem = (hashitem *)item;
	return hash32shiftmult(myitem->product_id);
}
