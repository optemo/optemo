class Distribution 
require 'inline'

@@dist = []
  
 def getDist(feat)
   @@dist[feat] unless dist.empty?
 end     

 def self.distribution_r(products)
     ind = Session.current.continuous["filter"].index(feat)
       num_buckets = 21;
       st = []
       mins = []
       maxes = []
       Session.current.continuous["filter"].each{|f| st << ContSpec.cachemany(products, f)}
       specs = st.transpose
       Session.current.continuous["filter"].each{|f| mins << ContSpec.allMinMax(f)[0]}
       Session.current.continuous["filter"].each{|f| maxes << ContSpec.allMinMax(f)[1]} 
       return [[],[]] if maxes[ind].nil? || mins[ind].nil?
       $d = Distribution.new unless $d
       sf = specs.flatten 
       res = $d.distribution_c(sf, specs.size, specs.first.size, num_buckets, mins, maxes) #unless $res
       Session.current.continuous["filter"].each_with_index{|f, i|  t = ind*(2+num_buckets); @@dist[f] = [[res[t], res[t+1]], round2Decim(normalize(res[(t+2)...(i+1)*(2+num_buckets)]))]}
  end
  
  
  
  
 def distribution_r(products)
    num_buckets = 21;
    st = []
    mins = []
    maxes = []
    Session.current.continuous["filter"].each{|f| st << ContSpec.cachemany(products, f)}
    specs = st.transpose
    Session.current.continuous["filter"].each{|f| mins << ContSpec.allMinMax(f)[0]}
    Session.current.continuous["filter"].each{|f| maxes << ContSpec.allMinMax(f)[1]} 
    if maxes[ind].nil? || mins[ind].nil?
      @@dist = [] 
    else  
      $d = Distribution.new unless $d
      sf = specs.flatten 
      @@dist = $d.distribution_c(sf, specs.size, specs.first.size, num_buckets, mins, maxes)
    end  
 end  


  inline :C do |builder|
    builder.c "
    #include <math.h> 
    
       static VALUE distribution_c(VALUE _data, VALUE num_products, VALUE num_features, VALUE num_buckets, VALUE _dataMins, VALUE _dataMaxes){
         VALUE* data_a = RARRAY_PTR(_data);
         VALUE* dataMins_a = RARRAY_PTR(_dataMins);
         VALUE* dataMaxes_a = RARRAY_PTR(_dataMaxes);

         int n = NUM2INT(num_products);
         int d = NUM2INT(num_features);
         int k = NUM2INT(num_buckets);  

         VALUE result_ary = rb_ary_new2((2*d)+(k*d));

         int i,j, ind;
         double curr_min, curr_max, stepsize;
         double offset = 0.000001;
         int** dist = malloc(sizeof(int*)*d);
         double* dataMins = malloc(sizeof(double)*d);
         double* dataMaxes = malloc(sizeof(double)*d);
         double* mins = malloc(sizeof(double)*d);
         double* maxes = malloc(sizeof(double)*d);
         double** data = malloc(sizeof(double*)*n);
         for (i=0; i<n; i++) data[i] = malloc(sizeof(double)*d);    
         for (j=0; j<d; j++) {
           dist[j] = malloc(sizeof(int)*k);
           for (i=0; i<k; i++) dist[j][i] = 0;  
         }  
         for (i=0; i<n; i++){
           for (j=0; j<d; j++) {   
              data[i][j]= NUM2DBL(data_a[i*d+j]);}}
              
          for (j=0; j<d; j++){
             dataMins[j] = NUM2DBL(dataMins_a[j]);
             dataMaxes[j] = NUM2DBL(dataMaxes_a[j]);
          } 
               
         
         for (j=0; j<d; j++){
           curr_min = dataMaxes[j];
           curr_max = dataMins[j];
           stepsize =  (dataMaxes[j] - dataMins[j])/k + offset;
           for (i=0; i<n; i++){ 
               if (curr_min > data[i][j]){
                 curr_min = data[i][j];
               }
               if (curr_max < data[i][j]){
                 curr_max = data[i][j];
               }
              ind = (data[i][j] - dataMins[j])/stepsize;
               if (ind < k) dist[j][ind] ++;    
             }
           mins[j] = curr_min;
           maxes[j] = curr_max;       
         }
         ////normalizing & round 2 decimal  
          for (j=0; j<d; j++) {
             for (i=0; i<k; i++) dist[j][i]=round(dist[j][i]*1000)/(maxes[j]*1000); 
         }
         
         
         ///storing in result_ary
         ind = 0;
         for (j=0; j<d; j++) {
           rb_ary_store(result_ary, ind,  DBL2NUM(mins[j]));
           ind++;
           rb_ary_store(result_ary, ind,  DBL2NUM(maxes[j]));
           ind++;
           for (i=0; i<k; i++){
              rb_ary_store(result_ary, ind, INT2NUM(dist[j][i]));
              ind++;
           }   
         }        
         
         return result_ary;
       }"
    end
   
end 