/* Copyright (C) 2007-2008 Sun Microsystems

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; version 2 of the License.

   There are special exceptions to the terms and conditions of the GPL 
   as it is applied to this software. View the full text of the 
   exception in file EXCEPTIONS-CONNECTOR-C++ in the directory of this 
   software distribution.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#ifndef _EXAMPLES_H
#define	_EXAMPLES_H

// Portable __FUNCTION__
#ifndef __FUNCTION__
 #ifdef __func__
   #define __FUNCTION__ __func__
 #else
   #define __FUNCTION__ "(function n/a)"
 #endif
#endif

#ifndef __LINE__
  #define __LINE__ "(line number n/a)"
#endif 




int find(int *idA, int value, int size){
	int ind = -1;
	for(int i=0; i<size; i++){
		if (idA[i] == value){
			ind = i;
			return ind;
		}
	}
	return ind;  
}

int findVec(vector<string> tokens, string value)
{
	int ind = -1;
	for (int i=0; i<tokens.size(); i++){
		if (tokens.at(i) == value){
			ind = i;
			return ind;
		}
	}
	return ind;
}

int *k_means(double **data, int n, int m, int k, double t, double **centroids)
{
   /* output cluster label for each data point */
   int *labels = (int*)calloc(n, sizeof(int));

   int h, i, j; /* loop counters, of course :) */
   int *counts = (int*)calloc(k, sizeof(int)); /* size of each cluster */
   double old_error, error = DBL_MAX; /* sum of squared euclidean distance */
   double **c = centroids ? centroids : (double**)calloc(k, sizeof(double*));
   double **c1 = (double**)calloc(k, sizeof(double*)); /* temp centroids */

   assert(data && k > 0 && k <= n && m > 0 && t >= 0); /* for debugging */

   /****
   ** initialization */

   for (h = i = 0; i < k; h += n / k, i++) {
      c1[i] = (double*)calloc(m, sizeof(double));
      if (!centroids) {
         c[i] = (double*)calloc(m, sizeof(double));
      }
      /* pick k points as initial centroids */
      for (j = m; j-- > 0; c[i][j] = data[h][j]);
   }

   /****
   ** main loop */

   do {
      /* save error from last step */
      old_error = error, error = 0;

      /* clear old counts and temp centroids */
      for (i = 0; i < k; counts[i++] = 0) {
         for (j = 0; j < m; c1[i][j++] = 0);
      }

      for (h = 0; h < n; h++) {
         /* identify the closest cluster */
         double min_distance = DBL_MAX;
         for (i = 0; i < k; i++) {
            double distance = 0;
            for (j = m; j-- > 0; distance += pow(data[h][j] - c[i][j], 2));
            if (distance < min_distance) {
               labels[h] = i;
               min_distance = distance;
            }
         }
         /* update size and temp centroid of the destination cluster */
         for (j = m; j-- > 0; c1[labels[h]][j] += data[h][j]);
         counts[labels[h]]++;
         /* update standard error */
         error += min_distance;
      }

      for (i = 0; i < k; i++) { /* update all centroids */
         for (j = 0; j < m; j++) {
            c[i][j] = counts[i] ? c1[i][j] / counts[i] : c1[i][j];
         }
      }

   } while (fabs(error - old_error) > t);

   /****
   ** housekeeping */

   for (i = 0; i < k; i++) {
      if (!centroids) {
         free(c[i]);
      }
      free(c1[i]);
   }

   if (!centroids) {
      free(c);
   }
   free(c1);

   free(counts);

   return labels;
}


#endif	/* _EXAMPLES_H */

