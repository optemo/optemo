// Include the Ruby headers and goodies
#include "ruby.h"
#include <math.h> 

//// Defining a space for information and references about the module to be stored internally
VALUE Distribution= Qnil;
//
//// Prototype for the initialization method - Ruby calls this, not you
void Init_distribution();
//
//// Prototype for our method 'test1' - methods are prefixed by 'method_' here
VALUE method_test(VALUE self);

static VALUE distribution_c(VALUE _data, VALUE num_products, VALUE num_features, VALUE num_buckets, VALUE _dataMins, VALUE _dataMaxes);

//
//// The initialization method for this module
void Init_mynewtest() {
	MyTest = rb_define_module("MyNewTest");
	rb_define_method(MyTest, "test2", method_test2, 0);	
	rb_define_method(MyTest, "distribution_c", distribution_c, 6);
}
//
//// Our 'test1' method.. it simply returns a value of '10' for now.
VALUE method_test2(VALUE self) {
	int x = 10000000000000000000000000;
	return INT2NUM(x);
}




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
   }