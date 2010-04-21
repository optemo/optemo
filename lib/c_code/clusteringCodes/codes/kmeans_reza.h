#include <stdlib.h>
#include <time.h>

#define REZA_KMEANS_MAX_ITER 50 //maximum number of EM alternations in the kmeans clustering algorithm

enum InitMethods {INIT_BEGIN, INIT_RANDOM, INIT_KMEANSPP};

template <typename T>
void reza_copy_vec(T *dest, T *src, int n)
{
	for (int i = 0; i < n; i++) dest[i] = src[i];
}

double reza_dist(double x[], double y[], int dim, double weights[])
{
	double res = 0;
	for (int d = 0; d < dim; d++)
		res += weights[d] * pow(x[d] - y[d], 2);
	return res;
}

// uniformly randomly choosing K items from N items
void reza_rand_choose(vector<int> &res, int K, int N)
{
	int i, j, temp;
	
	res.clear();
	for (i = 0; i < N; i++) res.push_back(i);
	for (i = 0; i < K; i++) {
		j = rand() % (N - i) + i; // generates random integer number in [i, N) interval
		temp = res[i]; res[i] = res[j]; res[j] = temp; // swap res[i] and res[j]  
	}
}

// probs can contain 'unnormalized' probabilities
int reza_toss_dice(vector<double> probs)
{
	double z = 0, temp; // normalization constant
	int i;
	
	for (i = 0; i < probs.size(); i++) 	z += probs[i];
	temp = z * ((double)rand() / (RAND_MAX + 1.0));
	for (z = 0, i = 0; i < probs.size(); i++) 
		if ((temp >= z) && (temp < z + probs[i])) return i;
		else z += probs[i];
	for (i = probs.size() - 1; i >= 0; i--)
		if (probs[i] >0) return i;
}

//==================================================================================================
// intelligent initialization
void reza_init_kmeanspp(vector<int> &rindex, int K, double **data, int N, int dim, double *weights)
{  
	int i, j, h;
	vector<double> dist;
	double eps = .000001;
	
	//cout << "kmeanspp k=" << K << "  N=" <<  N << endl;
	//cout << "ii 1" << endl;
	dist.resize(N,0);
	//cout << "ii 2" << endl;
	rindex.clear();
	j = rand() % N; 
	rindex.push_back(j);
	for (h = 0; h < N; h++)
		dist[h] = reza_dist(data[j], data[h], dim, weights) + eps;
	dist[j] = 0;	
	//cout << "ii 3" << endl;	
	for (i = 1; i < K; i++ ) {
		//cout << "ii 4" << endl;
		//for (int kk = 0; kk < dist.size(); kk++)
		//	cout <<dist[kk] << " ";
		//cout << endl;		
		j = reza_toss_dice(dist); 
		rindex.push_back(j); 
		//cout << "ii 5__ j=" << j << endl;
		for (h = 0; h < N; h++) {
		//	cout << "dd 0 _ j=" << j << " h=" << h << endl;
			double temp = reza_dist(data[j], data[h], dim, weights) + eps;
		//	cout << "dd 1" << endl;
			if (temp < dist[h]) dist[h] = temp;
		//	cout << "dd 2" << endl;
		}
		dist[j] = 0;
		//cout << "ii 6" << endl;
	}	
	//cout << "ii 7" << endl;
}

void reza_init_centers(double **centroids, int K, double **data, int dataN, int featN, double *weights, InitMethods method) //INIT_BEGIN, INIT_RANDOM, INIT_KMEANSPP
{
	int i;
	vector<int> rindex;
	
	switch (method) {
	   case INIT_BEGIN:
	      for (i = 0; i < K; i++) rindex.push_back(i); 
		  break;
	   case INIT_RANDOM:       
		  reza_rand_choose(rindex, K, dataN); 
	      break; 
	   case INIT_KMEANSPP:
	      reza_init_kmeanspp(rindex, K, data, dataN, featN, weights);
		  break;	
	}
	for (i = 0; i < K; i++) reza_copy_vec<double>(centroids[i], data[rindex[i]], featN);
} 

//==================================================================================================
// kmeans related stuff!
void reza_clip_center(double u[], int con_featsN, int bool_featsN, vector<int> *disc_domains)
{
	for (int base = con_featsN, i = 0; i < disc_domains->size(); i++) {
        double best_v = -1; int best_i = -1;
		for (int d = 0; d < (*disc_domains)[i]; d++) {			
		   if (u[base+d] > best_v) {
			   best_v = u[base+d]; best_i = base+d;
			}
			u[base+d] = 0;   	
		}
		u[best_i] = 1;	base += (*disc_domains)[i];
	}	
}

int reza_find_worse_item(double **dists, int counts[], int labels[], int dataN, int clustersN)
{
	int h, h2;
	double *temp = (double*)calloc(dataN, sizeof(double));
	
	//cout << "find: im in here 1" << endl;
	for (h = 0; h < dataN; h++) 
		temp[h] = dists[h][labels[h]];
	//cout << "find: im in here 2" << endl;	
	for (h = 0; h < dataN; h++) {
		int best_i = 0; double best_v = temp[0]; 
		//cout << "find: im in here 3" << endl;
		for (h2 = 0; h2 < dataN; h2++)
		   if (temp[h2] > best_v) {
			   best_v = temp[h2];	best_i = h2;
		   }
		//cout << "find: im in here 4" << endl;
		if (counts[labels[best_i]] > 1) {
			free(temp);
			return best_i;
		}
		temp[best_i] = -1;
		//cout << "find: im in here 5" << endl;
	}
	printf("\n warning in reza_find_worse_item: could not find a worse item! \n");
	free(temp);
	return 0;
}


void reza_kmeans(double **data, int dataN, int con_featsN, int bool_featsN, int clustersN, double threshold, //input
                  double* weights, int max_iter, bool to_clip, vector<int> *disc_domains,//input 
                  double **centroids, // input and output
                  int labels[], double &error, double errors[]) //output
{
   int h, i, j; /* loop counters, of course :) */
   int *counts = (int*)calloc(clustersN, sizeof(int)); /* size of each cluster */
   double old_error; /* sum of squared euclidean distance */
   double **c1 = (double**)calloc(clustersN, sizeof(double*)); /* temp centroids */
   double **dists = (double**)calloc(dataN, sizeof(double*)); 
   double **c = centroids;

   //cout << "im in here 11" << endl;
   assert(data && clustersN > 0 && clustersN <= dataN && (con_featsN+bool_featsN) > 0 && threshold >= 0); /* for debugging */ 
    //cout << "im in here 21" << endl;
    
    // initialization 
	for (i = 0; i < clustersN; i++)
	   c1[i] = (double*)calloc(con_featsN+bool_featsN, sizeof(double));
    for (h = 0; h < dataN; h++)
       dists[h] = (double*)calloc(clustersN, sizeof(double));

   /****** main loop */
	for (int iter = 0; iter < max_iter; iter++) {
     // initialization ---------------------------------
      for (i = 0; i < clustersN; i++) { 
		 errors[i] = 0; counts[i] = 0;
         for (j = 0; j < (con_featsN+bool_featsN); c1[i][j++] = 0);
      }
      // cout << "im in here 31" << endl;
       //--------------------------------------------------
      // phase 1: assign each point to the nearest cluster
      for (error = 0, h = 0; h < dataN; h++) {
         /* identify the closest cluster */
         double min_distance = DBL_MAX;
         for (i = 0; i < clustersN; i++) {
            dists[h][i] = reza_dist(data[h], c[i], con_featsN + bool_featsN, weights); //ZZZZZZ
			if (dists[h][i] < min_distance) {
               labels[h] = i; min_distance = dists[h][i];
            }
         }
		//cout << h << "_" << labels[h] << " "; //zzz
         /* update size and temp centroid of the destination cluster */
		for (j = 0; j<(con_featsN + bool_featsN) ; j++)  
		   c1[labels[h]][j] += data[h][j];
         counts[labels[h]]++;
         /* update standard error */
		error += min_distance; errors[labels[h]] += min_distance; 
      }
	//cout << endl << DBL_MAX << endl; 
	
        // cout << "im in here 41" << endl;
       //---------------------------------------------------
      // phase 2: update centroids
      for (i = 0; i < clustersN; i++) {  
		 if (counts[i])
	       for (int j = 0; j < (con_featsN+bool_featsN); j++) c[i][j] = c1[i][j] / counts[i];
	      //cout << i << " " << counts[i] << endl;  
      }
	  //cout << "im in here 42" << endl;	   
	  // take care of the empty clusters!
  	  for (i = 0; i <  clustersN; i++) 
		if (counts[i] == 0)  { 
	       // cout << "im in here 421" << endl;
		   int worse_item = reza_find_worse_item((double **)dists, counts, labels, dataN, clustersN);
           //cout << "im in here 422" << endl;
		   // update old cluster info
		   int old_clus = labels[worse_item];		
		   //cout << "im in here 43" << endl;
		   for (j = 0; j < (con_featsN+bool_featsN); j++) 
		   	  c[old_clus][j] = (c[old_clus][j] * counts[old_clus] - data[worse_item][j]) / (counts[old_clus] - 1);
		   //cout << "im in here 44" << endl;	
		   errors[old_clus] -= dists[worse_item][old_clus];
		   error -= dists[worse_item][old_clus]; counts[old_clus] -= 1;
		   // update current cluster info	
		   labels[worse_item] = i; dists[worse_item][i] = 0;
		   counts[i] = 1; errors[i] = 0;
		   //cout << "im in here 45" << endl;
		   for (j = 0; j < (con_featsN+bool_featsN); j++) c[i][j] = data[worse_item][j];
		   //cout << "im in here 46" << endl;		
  	    }
       //cout << "im in here 51" << endl;
      // clipping? if yes, then centers as well as the error(s) sould be updated! 
      if ((disc_domains) && (to_clip == true)) {
		for (i = 0; i < clustersN; i++) {
			errors[i] = 0; reza_clip_center(c[i], con_featsN, bool_featsN, disc_domains);
		}
	    for (h = 0, error = 0; h < dataN; h++) {	  
			double temp = reza_dist(data[h], c[labels[h]], con_featsN + bool_featsN, weights);
		   error += temp; errors[labels[h]] += temp;
        } 
     }
      //cout << "im in here 61" << endl;
      //-------------------------------------------------------
      // termination condition
	//cout << iter << ") objective: " << error << endl;
      if ((iter > 0) && (fabs(error - old_error) < threshold)) break; 
	  old_error = error;
   }

   /****** housekeeping */
   for (i = 0; i < clustersN; i++)  free(c1[i]);
   for (h = 0; h < dataN; h++) free(dists[h]);
   free(counts);
}

//==================================================================================================
// purterbation of the initial point. this function is on top of the 'reza_kmean' above and wraps it. 
// it's supposed to enhance the solution found
// this is an implementation of the method proposed by the following paper:
// "Refining Initial Points for K-Means Clustering", by P.S. Bradley and Usama Fayyad

// N is the size of the 'data' and M is the size of the 'sub_sample'
// this sampling 'with' replacement
void reza_sub_sampling(double **data, int N, int dim, int M, double **sub_sample)
{
	for (int h = 0; h < M; h++) 
	   reza_copy_vec<double>(sub_sample[h], data[rand() % N], dim);
}

// sub_samples_num : is the numbr of sub samples! this parameter controls how many times we wish to purturb the initial parameters.
// sub_samples_size : is the number of points in each sub sample!
void reza_kmeans_refinement(double **data, int N, int con_featsN, int bool_featsN, int K, InitMethods method, int sub_sample_num, int sub_sample_size, 
                  double* weights,  bool to_clip, vector<int> *disc_domains,//input 
                  double **centroids, // output, we assume that the space is 'already' reserved (in the caller) for this variable!
                  int labels[], double &error, double errors[]) //output
{
	double **sub_sample;
	double **cm, **tcm; // cluster means for sub samples
	int *tlabels = (int *) calloc(sub_sample_size, sizeof(int));
	int *ttlabels = (int *) calloc(K*sub_sample_num, sizeof(int));
	double best_error;
	int best_sample;
	
	srand ( time(NULL) );
	//allocating memory
    sub_sample = (double**)calloc(sub_sample_size, sizeof(double*));
	for (int h = 0; h < sub_sample_size; h++)
		sub_sample[h] = (double *) calloc(con_featsN + bool_featsN, sizeof(double));
	tcm = (double**) calloc(K, sizeof(double *));
	for (int k = 0; k < K; k++)
		tcm[k] = (double*) calloc(con_featsN + bool_featsN, sizeof(double));
	cm = (double**) calloc(K*sub_sample_num, sizeof(double *));
	for (int k = 0; k < (K*sub_sample_num); k++)
		cm[k] = (double*) calloc(con_featsN + bool_featsN, sizeof(double));		
    
	// main loop
	for (int j = 0; j < sub_sample_num; j++) {
		reza_sub_sampling(data, N,con_featsN + bool_featsN, sub_sample_size, sub_sample);
		reza_init_centers(tcm, K, sub_sample, sub_sample_size, con_featsN + bool_featsN, weights, method);
    	reza_kmeans(sub_sample, sub_sample_size, con_featsN, bool_featsN, K, DBL_MIN, weights, REZA_KMEANS_MAX_ITER, to_clip,  disc_domains, tcm, tlabels, error, errors);
		for (int k = 0; k < K; k++)
			reza_copy_vec<double>(cm[j * K + k], tcm[k], con_featsN + bool_featsN);	       	
	}	
	for (int j = 0; j < sub_sample_num; j++) {
		for (int k = 0; k < K; k++)
			reza_copy_vec<double>(tcm[k], cm[j * K + k], con_featsN + bool_featsN);
		reza_kmeans(cm, sub_sample_num*K, con_featsN, bool_featsN, K, DBL_MIN, weights, REZA_KMEANS_MAX_ITER, to_clip,  disc_domains, tcm, ttlabels, error, errors);	
        if ((j == 0) || (error < best_error)) {
			best_sample = j; best_error = error;
			for (int k = 0; k < K; k++)
				reza_copy_vec<double>(centroids[k], tcm[k], con_featsN + bool_featsN );
        } 
	}
	
	// the final call to reza_kmeans with the best intial point found so far to prepare the output results!
	reza_kmeans(data, N, con_featsN, bool_featsN, K, DBL_MIN, weights, REZA_KMEANS_MAX_ITER, to_clip,  disc_domains, centroids, labels, error, errors);

   // releasing memory ...
	for (int h = 0; h < sub_sample_size; h++)  free(sub_sample[h]);
	for (int k = 0; k < K; k++) free(tcm[k]);
	for (int k = 0; k < (K*sub_sample_num); k++) free(cm[k]);
	free(tlabels); free(ttlabels);  
}


//  however, a very simple way to refine kmeans is by multiple restart!
void reza_kmeans_multiple_start(double **data, int N, int con_featsN, int bool_featsN, int K, InitMethods method, int restart_num,  
						                  double *weights, bool to_clip, vector<int> *disc_domains,//input 
						                  double **centroids, // output, we assume that the space is 'already' reserved (in the caller) for this variable!
										int labels[], double &error, double errors[])  //output
{
	double **tcm; // cluster means for sub samples
	double terror, terrors[K];
	int tlabels[N];
    
	srand ( time(NULL) );
	//allocating memory
	tcm = (double**) calloc(K, sizeof(double *));
	for (int k = 0; k < K; k++)
		tcm[k] = (double*) calloc(con_featsN + bool_featsN, sizeof(double));
    //cout << "wow 0" << endl;
	// main loop
	for (int j = 0; j < restart_num; j++) {
		//cout << "wow 1" << endl;
		//cout << "multiple k=" << K << "  N=" <<  N << endl; 
		reza_init_centers(tcm, K, data, N, con_featsN + bool_featsN, weights, method);
		//cout << "wow 2" << endl;
		reza_kmeans(data, N, con_featsN, bool_featsN, K, DBL_MIN, weights, REZA_KMEANS_MAX_ITER, to_clip,  disc_domains, tcm, tlabels, terror, terrors);	
        //cout << "wow 3" << endl;
        if ((j == 0) || (terror < error)) {
			error = terror;
			for (int k = 0; k < K; k++) {
				errors[k] = terrors[k];
				reza_copy_vec<double>(centroids[k], tcm[k], con_featsN + bool_featsN );
			}
			for (int h = 0; h < N; h++) 
			   labels[h] = tlabels[h];
        } 
        //cout << "wow 4" << endl;
	}
   // releasing memory ...
	for (int k = 0; k < K; k++) free(tcm[k]);
	//cout << "wow 5" << endl;
}
