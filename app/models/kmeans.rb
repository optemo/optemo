class Kmeans
require 'inline'

inline :C do |builder|
  builder.c "
      
  static VALUE kmeans_c(VALUE _points, VALUE n, VALUE d, VALUE cluster_n){
    VALUE* points_a = RARRAY_PTR(_points);
    int nn = NUM2INT(n);
    int dd = NUM2INT(d);
    int k = NUM2INT(cluster_n);
    double DBL_MAX = 10000000.0;
    double t = 0.0001;
    
    VALUE labels_r = rb_ary_new2(nn);
    int i, j, h;
    double** data = malloc(sizeof(double*)*nn);
    double* means = malloc(sizeof(double)*dd);

    for (j=0; j<dd; j++) means[j]=0.0;
    for (i=0; i<nn; i++) data[i] = malloc(sizeof(double)*dd);    
    for (i=0; i<nn; i++){
      for (j=0; j<dd; j++) {   
         data[i][j]= NUM2DBL(points_a[i*dd+j]);
      }
    }
        
    int *counts = (int*)calloc(k, sizeof(int)); //(int*)calloc(k, sizeof(int)); /* size of each cluster */
    double old_error, error = DBL_MAX; /* sum of squared euclidean distance */
    double** centroids = malloc(sizeof(double*)*k);
    for (i=0; i<k; i++) centroids[i]= malloc(sizeof(double)*dd);
    double **c = (double**)calloc(k, sizeof(double*));
    double **c1 = (double**)calloc(k, sizeof(double*)); /* temp centroids */
    int *labels = (int*)calloc(nn, sizeof(int)); 
        
  for (h = i = 0; i < k; h += nn / k, i++) {
     c1[i] = (double*)calloc(dd, sizeof(double));
     c[i] = (double*)calloc(dd, sizeof(double));
     /* pick k points as initial centroids */
     for (j = dd; j-- > 0; c[i][j] = data[h][j]);
  }
  
  /****
  ** main loop */
  
  do {
     /* save error from last step */
     old_error = error, error = 0;
  
     /* clear old counts and temp centroids */
     for (i = 0; i < k; counts[i++] = 0) {
        for (j = 0; j < dd; c1[i][j++] = 0);
     }
  
     for (h = 0; h < nn; h++) {
        /* identify the closest cluster */
        double min_distance = DBL_MAX;
        for (i = 0; i < k; i++) {
           double distance = 0;
           for (j = dd; j-- > 0; distance += (data[h][j] - c[i][j]) * (data[h][j] - c[i][j])) ;
           if (distance < min_distance) {
              labels[h] = i;
              min_distance = distance;
           }
        }
        /* update size and temp centroid of the destination cluster */
        for (j = dd; j-- > 0; c1[labels[h]][j] += data[h][j]);
        counts[labels[h]]++;
        /* update standard error */
        error += min_distance;
     }
  
     for (i = 0; i < k; i++) { /* update all centroids */
        for (j = 0; j < dd; j++) {
           c[i][j] = counts[i] ? c1[i][j] / counts[i] : c1[i][j];
        }
     }
  
  } while (((error - old_error)*(error - old_error)) > t);
  
  for (j=0; j<nn; j++){
      rb_ary_store(labels_r, j, INT2NUM(labels[j]));
  }
  return labels_r;
  }
  "
end


inline do |builder|
  builder.c "
  static VALUE mean_c(VALUE _points, VALUE n, VALUE d){
    VALUE* points_a = RARRAY_PTR(_points);
    int nn = NUM2INT(n);
    int dd = NUM2INT(d);
    VALUE means_r = rb_ary_new2(dd);
    int i, j;
    double** points = malloc(sizeof(double)*(nn));
    double* means = malloc(sizeof(double)*(dd));
    for (j=0; j<dd; j++) means[j]=0.0;
    for (i=0; i<nn; i++) points[i] = malloc(sizeof(double)*(dd));    
    for (i=0; i<nn; i++){
      for (j=0; j<dd; j++) {   
         //points[i*nn+j] 
         points[i][j]= NUM2DBL(points_a[i*dd+j]);
         means[j] += points[i][j];
      }
    }
    for (j=0; j<dd; j++){
        means[j] = means[j]/nn;
        rb_ary_store(means_r, j, DBL2NUM(means[j]));
    }
  return means_r;  
  }"
end
end