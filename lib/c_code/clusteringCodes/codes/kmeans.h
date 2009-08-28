#include "helpers.h"



int find5(int *idA, int value, int size){
		
	int ind = -1;
	for(int i=0; i<size; i++){
		if (idA[i] == value){
			ind = i;
			return ind;
		}
	}
	
	return ind;  
}


int *k_means(double **data, int n, int m, int k, double t, double **centroids)
{
   /* output cluster label for each data point */
   int *labels = new int[n];// (int*)calloc(n, sizeof(int));

   int h, i, j; /* loop counters, of course :) */
   int *counts = new int[k]; //(int*)calloc(k, sizeof(int)); /* size of each cluster */
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


/////////////////////////////////////////////////////////////


int *k_means2(double **data, int n, int m, int k, double t, double **centroids)
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
	old_error = error;
	error = 0;

      /* clear old counts and temp centroids */
      for (i = 0; i < k; counts[i++] = 0) {
         for (j = 0; j < m; c1[i][j++] = 0);
      }

      for (h = 0; h < n; h++) {
         /* identify the closest cluster */
         double min_distance = DBL_MAX;
         for (i = 0; i < k; i++) {
            double distance = 0;
            //for (j = m; j-- > 0; distance += pow(data[h][j] - c[i][j], 2));
			for (j=m; j--; j>0){
			
				if (j==1){
					distance += (1/2) * pow(data[h][j] - c[i][j], 2);
				}
				else if (j==0){
					distance += (2) * pow(data[h][j] - c[i][j], 2);
				}
				else{
					distance += pow(data[h][j] - c[i][j], 2);
				}	
			}	
			
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

//////////////


int *k_means3(double **data, int n, int m, int k, double t, double **centroids, double* weights){
	
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


	bool* assigned = new bool[k];
	for (i=0; i<k; i++){
		assigned[i] = 0;
	}	
   /****
   ** main loop */

   do {
      /* save error from last step */
	old_error = error;
	error = 0;

      /* clear old counts and temp centroids */
      for (i = 0; i < k; counts[i++] = 0) {
         for (j = 0; j < m; c1[i][j++] = 0);
      }

      for (h = 0; h < n; h++) {
         /* identify the closest cluster */
         double min_distance = DBL_MAX;
         for (i = 0; i < k; i++) {
            double distance = 0;
            //for (j = m; j-- > 0; distance += pow(data[h][j] - c[i][j], 2));
			for (j=0; j<m; j++){	
			distance += weights[j] * pow(data[h][j] - c[i][j], 2);	
			}	

			if (distance < min_distance) {
               labels[h] = i;
               min_distance = distance;
            }
         }

         /* update size and temp centroid of the destination cluster */
	
		for (j = 0; j<m ; j++){
	 		c1[labels[h]][j] += data[h][j];
		}
	
         counts[labels[h]]++;
         /* update standard error */
         error += min_distance;
      }
		for (i=0; i<k; i++){
			if (find5(labels, i, n) > -1){
				assigned[i] = 1;
			}
		}	
		
      for (i = 0; i < k; i++) { /* update all centroids */
		if (assigned[i]){
         for (j = 0; j < m; j++) {
            c[i][j] = counts[i] ? c1[i][j] / counts[i] : c1[i][j];
         }
	}
  }

   } while (fabs(error - old_error) > t);
		
		
		for (int i=0; i<k; i++){
			if (find5(labels, i, n) > -1){
				assigned[i] = 1;
			}
			else{
				assigned[i] = 0;
			}
		}

	int preLabel, point =0;
	for (i=0; i<k; i++){
		if (!assigned[i]){
		
			double min_distance = DBL_MAX;
			double distance = 0;
			for (h=0; h<n; h++){
				
				for (j=0; j<m; j++){
					
					if (j==1){
						distance +=  (1/2) * pow(data[h][j] - c[i][j], 2);
					}
					else if (j==0){
						distance += 2 * pow(data[h][j] - c[i][j], 2);
					}
					else{
						distance += pow(data[h][j] - c[i][j], 2);
					}	
				}
				if (distance <min_distance){
				
					if (counts[labels[h]]>1){
						point = h;
						
						preLabel = labels[point];
						min_distance = distance;
					}
				}
			}
 			
			counts[preLabel]--;
			labels[point] = i;
			counts[i] = 1;
			assigned[i] = 1;
		}
	}	
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

int *k_meansInitial(double **data, int n, int m, int k, double t, double **centroids, double* weights, double** initials){
	
	//initials is an array of clusterN*dimension
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
      for (j = m; j-- > 0; c[i][j] = initials[i][j]);
   }
    
	bool* assigned = new bool[k];
	for (i=0; i<k; i++){
		assigned[i] = 0;
	}	
   /****
   ** main loop */

   do {
      /* save error from last step */
	old_error = error;
	error = 0;

      /* clear old counts and temp centroids */
      for (i = 0; i < k; counts[i++] = 0) {
         for (j = 0; j < m; c1[i][j++] = 0);
      }

      for (h = 0; h < n; h++) {
         /* identify the closest cluster */
         double min_distance = DBL_MAX;
         for (i = 0; i < k; i++) {
            double distance = 0;
            //for (j = m; j-- > 0; distance += pow(data[h][j] - c[i][j], 2));
			for (j=0; j<m; j++){
				
			distance += weights[j] * pow(data[h][j] - c[i][j], 2);		
			}	
			if (distance < min_distance) {
               labels[h] = i;
               min_distance = distance;
            }
         }
         /* update size and temp centroid of the destination cluster */
	
		for (j = 0; j<m ; j++){
	 		c1[labels[h]][j] += data[h][j];
		}
	
         counts[labels[h]]++;
         /* update standard error */
         error += min_distance;
      }
		for (i=0; i<k; i++){
			if (find5(labels, i, n) > -1){
				assigned[i] = 1;
			}
		}
	  	
		
      for (i = 0; i < k; i++) { /* update all centroids */
		if (assigned[i]){
         for (j = 0; j < m; j++) {
            c[i][j] = counts[i] ? c1[i][j] / counts[i] : c1[i][j];
         }
	}
  }

   } while (fabs(error - old_error) > t);	
		for (int i=0; i<k; i++){
			if (find5(labels, i, n) > -1){
				assigned[i] = 1;
			}
			else{
				assigned[i] = 0;
			}
		}
	int preLabel, point =0;
	for (i=0; i<k; i++){
		if (!assigned[i]){
		
			double min_distance = DBL_MAX;
			double distance = 0;
			for (h=0; h<n; h++){
				
				for (j=0; j<m; j++){
					
					if (j==1){
						distance +=  (1/2) * pow(data[h][j] - c[i][j], 2);
					}
					else if (j==0){
						distance += 2 * pow(data[h][j] - c[i][j], 2);
					}
					else{
						distance += pow(data[h][j] - c[i][j], 2);
					}	
				}
	
				if (distance <min_distance){
				
					if (counts[labels[h]]>1){
						point = h;
						
						preLabel = labels[point];
						min_distance = distance;
					}				
				}				
			}			
			counts[preLabel]--;
			labels[point] = i;
			counts[i] = 1;
			assigned[i] = 1;
		}
	}	
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


int *k_meansPP(double **data, int n, int m, int k, double t, double **centroids, double* weights){
	
	/* output cluster label for each data point */
   int *labels = (int*)calloc(n, sizeof(int));
   int h, i, j; /* loop counters, of course :) */
   int *counts = (int*)calloc(k, sizeof(int)); /* size of each cluster */
   double old_error, error = DBL_MAX; /* sum of squared euclidean distance */
   double **c = centroids ? centroids : (double**)calloc(k, sizeof(double*));
   double **c1 = (double**)calloc(k, sizeof(double*)); /* temp centroids */
   int p;	
   assert(data && k > 0 && k <= n && m > 0 && t >= 0); /* for debugging */

   int random = rand()%n;
   double * dist = new double [n];	
   int* ids = new int [n]; 
   int * excludeIds;  		
		int* centIds = new int [k];
	/****
   ** initialization */
    
   for (h = i = 0; i < k; h += n / k, i++) {
      c1[i] = (double*)calloc(m, sizeof(double));
      if (!centroids) {
         c[i] = (double*)calloc(m, sizeof(double));
      }
      /* pick k points as initial centroids */
	if (i==0){
		for (j=m; j-- >0; c[0][j] = data[random][j]);
		centIds[i] = random;
	}
	// Distance
	for (int t=0; t<n; t++){
		for (j=0; j<m; j++){
			dist[t] = (data[t][j] - c[i][j]) * (data[t][j] - c[i][j]);
			ids[t] = t;
		}
	}
	if (i>0){
		excludeIds = new int[i-1]; 
	
		for (j=0; j<i-1; j++){
			excludeIds[j] = centIds[j];
		}
		 //sort and pick the largest distance
	
		insertion_sort(dist, ids, n);
		p= 1;
	
   		while (find(excludeIds, ids[n-p], n) >0 )
   		{
   			p++;
   		}	
		centIds[i] = ids[n-p]; 
		for (j=0; j<m; j++){
		
			c[i][j] = data[ids[n-p]][j];
		}
		
		for (j=m; j-- >0; c[0][j] = data[ids[n-1]][j]);
     }
   }

	bool* assigned = new bool[k];
	for (i=0; i<k; i++){
		assigned[i] = 0;
	}	
   /****
   ** main loop */

   do {
      /* save error from last step */
	old_error = error;
	error = 0;

      /* clear old counts and temp centroids */
      for (i = 0; i < k; counts[i++] = 0) {
         for (j = 0; j < m; c1[i][j++] = 0);
      }

      for (h = 0; h < n; h++) {
         /* identify the closest cluster */
         double min_distance = DBL_MAX;
         for (i = 0; i < k; i++) {
            double distance = 0;
            //for (j = m; j-- > 0; distance += pow(data[h][j] - c[i][j], 2));
			for (j=0; j<m; j++){	
			distance += weights[j] * pow(data[h][j] - c[i][j], 2);	
			}	
			if (distance < min_distance) {
               labels[h] = i;
               min_distance = distance;
            }
         }

         /* update size and temp centroid of the destination cluster */
	
		for (j = 0; j<m ; j++){
	 		c1[labels[h]][j] += data[h][j];
		}
	
         counts[labels[h]]++;
         /* update standard error */
         error += min_distance;
      }
		for (i=0; i<k; i++){
			if (find5(labels, i, n) > -1){
				assigned[i] = 1;
			}
		}	
		
      for (i = 0; i < k; i++) { /* update all centroids */
		if (assigned[i]){
         for (j = 0; j < m; j++) {
            c[i][j] = counts[i] ? c1[i][j] / counts[i] : c1[i][j];
         }
	}
  }

   } while (fabs(error - old_error) > t);
		
		
		for (int i=0; i<k; i++){
			if (find5(labels, i, n) > -1){
				assigned[i] = 1;
			}
			else{
				assigned[i] = 0;
			}
		}

	int preLabel, point =0;
	for (i=0; i<k; i++){
		if (!assigned[i]){
		
			double min_distance = DBL_MAX;
			double distance = 0;
			for (h=0; h<n; h++){
				
				for (j=0; j<m; j++){
					
					if (j==1){
						distance +=  (1/2) * pow(data[h][j] - c[i][j], 2);
					}
					else if (j==0){
						distance += 2 * pow(data[h][j] - c[i][j], 2);
					}
					else{
						distance += pow(data[h][j] - c[i][j], 2);
					}	
				}
				if (distance <min_distance){
				
					if (counts[labels[h]]>1){
						point = h;
						
						preLabel = labels[point];
						min_distance = distance;
					}
				}
			}
 			
			counts[preLabel]--;
			labels[point] = i;
			counts[i] = 1;
			assigned[i] = 1;
		}
	}	
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



































