
//  this function chooses the best K in the range [1,max_k] to cluster the given data set
// it does this by selecting the k which minimizes (W_k / W_{k+1} - 1) * (N-k-1)
// where N is the number of given data points and W_k is the total error (distrtion) when the number of clusters is k
int hartigan_qmeasure(double **data, int N, int con_featsN, int bool_featsN, int max_k, InitMethods method, int restart_num,  
						                  double *weights, bool to_clip, vector<int> *disc_domains,//input 
//						                  double **centroids, // output, we assume that the space is 'already' reserved (in the caller) for this variable!
										int best_labels[]) //output and the function retirns best_k
{
	int best_k, old_labels[N], labels[N];
	double error, old_error, best_val, errors[max_k+1];
	double **centroid;

	//cout << "im here 1" << endl;
    if (N <= 0) {
		cout << "error in hartigan_qmeasure: it is called with zero points!" << endl;
		exit(0);
    }
    cout << "im here 2" << endl;
    if (N==1) {
		best_labels[0] = 0;
		return 1;
    }
    if (N==2) {
		best_labels[0] = 0;
		best_labels[1] = 1;
		return 2;
    }
     //cout << "im here 3" << endl;
    // reserving memory ...
	centroid = new double* [1+max_k];		
	for(int kk=0; kk < (1+max_k); kk++)
   		centroid[kk]=new double[con_featsN + bool_featsN];
   	//cout << "im here 4" << endl;
    // the min loop
	int init_val = 1;
	if (N > max_k) init_val = 2;
	for (int k = init_val; (k <= (1+max_k)) && (k <= N); k++) {
	   	reza_kmeans_multiple_start(data, N, con_featsN, bool_featsN, k, method, 
	                               restart_num, weights, to_clip, disc_domains,//input 
								   centroid, labels, error, errors);  //output														
		// for debugging
		//if (k > init_val) 
		//ß	cout << " the value of hartigan mesure for " << k-1 << " is " << (old_error/error - 1) * (N - k) << endl;			
		// taking care of the Hartigan qmeasure ...
		if (k == (1 + init_val)) {
			best_val = (old_error/error - 1) * (N - k);
			reza_copy_vec<int>(best_labels, old_labels, N);
			best_k = k-1;
		} 
		if (error == 0) break;
		if ( (k > (1 + init_val)) && (((old_error/error - 1) * (N - k)) < best_val)) {
			best_val = (old_error/error - 1) * (N - k);
			reza_copy_vec<int>(best_labels, old_labels, N);
			best_k = k-1;
		}
		if ( (k > init_val) && (best_val < 10) ) break;
		old_error = error; reza_copy_vec<int>(old_labels, labels, N);
	//	cout << "wow 3" << endl;
	}
	//cout << "im here 5" << endl;	
	// freeing up the memory ...
	for (int kk = 0; kk < (1 + max_k); kk++) free(centroid[kk]);
	//cout << "im here 6" << endl;
	// for debugging
	//int max = 0;
	//for (int k = 0; k < N; k++)
	//	if (best_labels[k] > max) max = best_labels[k];
	//cout << "the best val is " << best_val << " and the best k is " << best_k << " and the max k is " << max << " the first k is " << endl;	
	return best_k;
}										

//===================================================================
void get_mean_var(double **data, int size, int con_feats, vector<double> &mean, vector<double> &var) 
{
	mean.clear(); var.clear();
	for (int j = 0; j < con_feats; j++) {
		mean.push_back(0); var.push_back(0);
	}
	for (int h = 0; h < size; h++) 
		for (int j = 0; j < con_feats; j++) {
			mean[j] += data[h][j]; var[j] += data[h][j] * data[h][j];
	    }
	for (int j = 0; j < con_feats; j++) {
		mean[j] = mean[j] / size;
        var[j] = sqrt(var[j]/size - mean[j] * mean[j]);
	}	
}

void standarize_data(double **data, int size, int con_feats, int bool_feats, vector<double> &mean, vector<double> &var, double **dataN) 
{
	for (int h = 0; h < size; h++) {
		for (int j = 0; j < con_feats; j++)
			dataN[h][j] = (data[h][j] - mean[j]) / var[j];
		for (int j = 0; j < bool_feats; j++)
			dataN[h][con_feats + j] = data[h][con_feats + j];	
	}
}

//outlier detection is done just based on the continous features
// the distance between each point and the center is calculated, 
// then the points are put into H bins based on their distances to the center
// those bins whose density is less than eps are removed
void identify_outliers( vector<int> & index, double **temp_dataN, double **data, int N, int conFeatureN, int H, double meps)
{
	double errors[N], bins[H], mean[conFeatureN]; 
	double max_err, min_err;
	int data_bin[N];

	for (int i = 0; i < N; i++) {
		errors[i] = 0;
		//cout << " " << i << ")  ";
		for (int j = 0; j < conFeatureN; j++) {
			errors[i] += data[i][j] * data[i][j];
		//	cout << data[i][j] << " ";
    }
		//cout << " ___" << errors[i] << endl;//zzzz	
		if (i > 0) {
			if (min_err > errors[i]) min_err = errors[i];
			if (max_err < errors[i]) max_err = errors[i];
		} else {
			min_err = errors[i];
			max_err = errors[i];
		}
	}
	//cout << "max " << max_err << " min " << min_err << endl; //zz
	for (int h = 0; h < H; h++) 
	    bins[h] = 0;
	double delta = (max_err - min_err) / H;	
	for (int i = 0; i < N; i++) {
		if (errors[i] == max_err) 
		   data_bin[i] = H-1; 
		else 
		   data_bin[i] = (int)((errors[i] - min_err) / delta);
		   bins[data_bin[i]] += 1.0;	
	}
	//for (int h = 0; h < H; h++)
	//	cout << " bin " << h << "_" << bins[h] << endl;
	index.clear();
	for (int i = 0; i < N; i++)
		//cout << i << " " << data_bin[i] << " " << bins[data_bin[i]] << " " << bins[data_bin[i]]/N << " " << meps << endl;
		if ((bins[data_bin[i]]/N) > meps) { //this point is NOT an outlier bin
			index.push_back(i);
			temp_dataN[index.size()-1] = data[i];
		} 
}

