class Distribution 
require 'inline'

  def computeDist
       dist = {}
       num_buckets = 21;
       st = []
       mins = []
       maxes = []
       Session.current.continuous["filter"].each{|f| st << ContSpec.by_feat(f)}
       specs = st.transpose
       Session.current.continuous["filter"].each{|f| mins << ContSpec.allMinMax(f)[0]}
       Session.current.continuous["filter"].each{|f| maxes << ContSpec.allMinMax(f)[1]}
       res = distribution_c(specs.flatten, specs.size, specs.first.size, num_buckets, mins, maxes) #unless $res
       Session.current.continuous["filter"].each_with_index do |f, i|   
         t = i*(2+num_buckets) 
         dist[f] = [[res[t], res[t+1]], res[(t+2)...(i+1)*(2+num_buckets)]]
       end
       dist
  end

  inline :C do |builder|
    builder.c "
    #include <math.h> 
    
       static VALUE distribution_c(VALUE _data, VALUE num_products, VALUE num_features, VALUE num_buckets, VALUE _dataMins, VALUE _dataMaxes){
         
         //initializing the 
         VALUE* data_a = RARRAY_PTR(_data);
         VALUE* dataMins_a = RARRAY_PTR(_dataMins);
         VALUE* dataMaxes_a = RARRAY_PTR(_dataMaxes);

         int n = NUM2INT(num_products);
         int d = NUM2INT(num_features);
         int k = NUM2INT(num_buckets);  

         VALUE result_ary = rb_ary_new2((2*d)+(k*d));

         int i,j, ind;
         double curr_min, curr_max, stepsize, offset;
         offset = 0.000001;
         double** dist = malloc(sizeof(double*)*d);
         double* dataMins = malloc(sizeof(double)*d);
         double* dataMaxes = malloc(sizeof(double)*d);
         double* mins = malloc(sizeof(double)*d);
         double* maxes = malloc(sizeof(double)*d);
         double** data = malloc(sizeof(double*)*n);
         double *distMaxes = (double*)calloc(d, sizeof(double));
         for (i=0; i<n; i++) data[i] = malloc(sizeof(double)*d);    
         for (j=0; j<d; j++) {
           dist[j] = malloc(sizeof(double)*k);
           for (i=0; i<k; i++) dist[j][i] = 0.0;  
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
               if (curr_min > data[i][j])curr_min = data[i][j];
               if (curr_max < data[i][j])curr_max = data[i][j];
               ind = (data[i][j] - dataMins[j])/stepsize;
               if (ind < k) dist[j][ind]++;    
           }
           mins[j] = curr_min;
           maxes[j] = curr_max;       
         }
         
         
         for (j=0; j<d; j++) 
             for (i=0; i<k; i++) 
                if (dist[j][i]>distMaxes[j]) distMaxes[j]=dist[j][i];     
                  
        ////normalizing & round 2 decimal  
         for (j=0; j<d; j++) 
            for (i=0; i<k; i++) 
              if (distMaxes!=0) dist[j][i]=round(dist[j][i]*1000/distMaxes[j])/1000;       
         
         ///storing in result_ary
         ind = 0;
         for (j=0; j<d; j++) {
           rb_ary_store(result_ary, ind,  DBL2NUM(mins[j]));
           ind++;
           rb_ary_store(result_ary, ind,  DBL2NUM(maxes[j]));
           ind++;
           for (i=0; i<k; i++){
              rb_ary_store(result_ary, ind, DBL2NUM(dist[j][i]));
              ind++;
           }   
         }        
         
         return result_ary;
       }"
    end
  
  def normalize(a)
    total = a.max
    if total==0 
      a  
    else    
      a.map{|i| i.to_f/total}
    end  
  end

  def round2Decim(a)
    a.map{|n| (n*1000).round.to_f/1000}
  end  
    
  def distribution_r(feat) 
       dist = Array.new(21,0)
       min = ContSpec.allMinMax(feat)[0]
       max = ContSpec.allMinMax(feat)[1]
       return [[],[]] if max.nil? || min.nil?
       current_dataset_minimum = max
       current_dataset_maximum = min
       stepsize = (max-min) / dist.length + 0.000001 #Offset prevents overflow of 10 into dist array
       specs = ContSpec.cachemany(products, feat)
       specs.each do |s|
         current_dataset_minimum = s if s < current_dataset_minimum
         current_dataset_maximum = s if s > current_dataset_maximum
         i = ((s - min) / stepsize).to_i
         dist[i] += 1 if i < dist.length
       end  
       [[current_dataset_minimum, current_dataset_maximum], round2Decim(normalize(dist))] 
  end  

end    
    
    
    
    
    
    
    
    
    
    
    
    
    