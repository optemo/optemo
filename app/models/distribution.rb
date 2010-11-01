class Distribution 
require 'inline'

inline :C do |builder|
  builder.c "
     static VALUE distribution_c(VALUE _data, VALUE num_products, VALUE num_features, VALUE num_buckets, VALUE _dataMins, VALUE _dataMaxes){
       VALUE* data_a = RARRARY_PTR(_data);
       VALUE* dataMins_a = RARRAY_PTR(_dataMins_a);
       VALUE* dataMaxes_a = RARRAY_PTR(_dataMaxes_a);
       
       int n = NUM2INT num_products;
       int d = NUM2INT num_features;
       int k = NUM2INT(num_buckets);  
       
       VALUE result_ary = rb_ary_new2((2*d)+(k*d));
       
       int i,j. step_size, ind;
       double offset = 0.000001;
       int** dist = malloc(sizeof(int*)*d);
       double* mins = malloc(sizeof(double)*d);
       double* maxes = malloc(sizeof(double)*d);
       double** data = malloc(sizeof(double*)*nn);
       for (i=0; i<n; i++) data[i] = malloc(sizeof(double)*dd);    
       for (j=0; j<d; j++) {
         dist[j] = malloc(sizeof(int)*k);
         for (i=0; i<k; i++) dist[j][k] = 0;  
       }  
       for (i=0; i<nn; i++){
         for (j=0; j<dd; j++) {   
            data[i][j]= NUM2DBL(data_a[i*dd+j]);}}
       
       for (j=0; j<d; j++){
         curr_min = NUM2DBL(dataMaxes_a[j]);
         curr_max = NUM2DBL(dataMins_a[j]);
         stepsize =  (curr_min - curr_max)/k + offset;
         for (i=0; i<n; i++){ 
             if (curr_min > data[i][j]){
               curr_min = data[i][j];
             }
             if (curr_max < data[i][j]){
               curr_max = data[i][j];
             }
             ind = (data[i][j] - curr_min)/stepsize;
             if (ind >= k){
               dist[j][ind] += 1;
             } 
           }
           
         mins[j] = curr_min;
         maxes[j] = curr_max;       
       }
       ind = 0;
       for (j=0; j<d; j++) {
         rb_ary_store(result_arr, ind,  DBL2NUM(curr_min[j]));
         ind++;
         rb_ary_store(result_arr, ind,  DBL2NUM(curr_max[j]));
         ind++;
         for (i=0; i<k; i++){
            rb_ary_store(result_arr, ind, INT2NUM(dist[j][i]));
            ind++;
         }   
       }        
       return result_arr;
     }"
    end 
    def self.distribution
       num_buckets = 21;
       st = []
       mins = []
       maxes = []
       Session.current.continuous["filter"].each{|f| st << ContSpec.cachemany(p_ids, f)}
       specs = st.transpose
       Session.current.continuous["filter"].each{|f| mins << ContSpec.allMinMax(feat)[0]}
       Session.current.continuous["filter"].each{|f| maxes << ContSpec.allMinMax(feat)[1]}
       distribution_c(specs.flatten, specs.size, specs.first.size, num_buckets, mins, maxes)
    end
end 