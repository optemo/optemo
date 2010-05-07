/*
 * void formulate (...) is a helper function to learner.cpp, solving an optimization problem. Optemo 2010
 */

#include <iostream>
#include <iomanip>
#include <sys/time.h>
#include <map>
#include <sstream>
//#include <string>
#include "CoinPackedMatrix.hpp"
#include "CoinPackedVector.hpp"
#include </usr/local/include/mysql-connector-c++/driver/mysql_public_iface.h>
#include "ClpSimplex.hpp"

using namespace std;

extern int conFeatureN;
typedef struct list_el {
   int product_picked;
   int product_ignored;
   struct list_el * next;
} preference;

void formulate(sql::Statement *stmt, string productName, string* conFeatureNames, map <int, preference*> browse_similar_results) {
	string command;
    sql::ResultSet *resFactor;
    map <int, preference*>::iterator itr;
	preference * list;
	double* solutions = new double[conFeatureN];
	//alpha is -1 * the upper bound on the the number of violated constraints
	double alpha = 0.2;
	int pickedId, ignoredId, constN;
// This nexst line allows for up to a hundred browse similar actions per person
    double current_factors[800][conFeatureN];
	int count = 0;
	double fact;
	for(itr = browse_similar_results.begin();itr!=browse_similar_results.end();itr++)
    {
        count = 0;
        list = itr->second;
        cout << "Session " << itr->first << endl;
        while (list)
        {
            pickedId = list->product_picked;
            ignoredId = list->product_ignored;
    		command ="select * from factors where product_type=\'";
    		command += productName;
    		command += "\' and product_id=";
    		ostringstream ppIdS;
    		ppIdS << pickedId;
    		command += ppIdS.str();
    		command += ";";
    		resFactor = stmt->executeQuery(command);
    		if (resFactor->rowsCount()>0){
    			resFactor->next();

        		for (int i=0; i<conFeatureN; i++){
        			current_factors[count][i] = resFactor->getDouble(conFeatureNames[i]);
        		}
            }
            else
            {
                for (int i=0; i<conFeatureN; i++){
                    current_factors[count][i] = 1.0 / (float)conFeatureN; // Put in the default value
                }
            }
    		command ="select * from factors where product_type=\'";
    		command += productName;
    		command += "\' and product_id=";
    		ostringstream ipIdS;
    		ipIdS << ignoredId;
    		command += ipIdS.str();
    		command += ";";
    		resFactor = stmt->executeQuery(command);
    		if (resFactor->rowsCount()>0){
                resFactor->next();
        		for (int i=0; i<conFeatureN; i++){
        			fact = resFactor->getDouble(conFeatureNames[i]);
        			current_factors[count][i] = current_factors[count][i] - fact;
        		}	
        	}
    		else {
        		for (int i=0; i<conFeatureN; i++){
                    current_factors[count][i] = 1.0 / (float)conFeatureN;
        		}	
    		}
    		count++;
            list = list->next;
        }
    // So, now for each set, we need to calculate preferences.
    //factor vector is the coeffiecient vector for the constraints
    //the lower bound is 0 and the upper bound is maximum utility, i.e. 1
    constN = count;
    //constructing the objective function

  	double * objective = new double[constN+1];
  	for (int i=0; i<constN; i++){
  		objective[i] = alpha;
  	}
  	objective[constN] = -1;

  	//constructing the bounds
  	// bounds for preference weights
  	double * col_lb = new double [conFeatureN+constN+1];
  	double * col_ub = new double [conFeatureN+constN+1];
    // These lines are absent altogether from the new solver
//  	for (int i=0; i<conFeatureN; i++){
//  		col_lb[i] = 0; 
//  		col_ub[i] = 1;
//  	}

  	//bounds for slack variables
  	for (int i=conFeatureN; i<conFeatureN+constN; i++){
  		col_lb[i] = 1;
  		col_ub[i] = 100;
  	}

  	// bound for margin
  	col_lb[conFeatureN+constN] = 1;
  	col_ub[conFeatureN+constN] = 100;

  	double* row_lb = new double [constN];
  	double* row_ub = new double [constN];

  	//constructing the constrains matrix
  	CoinPackedMatrix * matrix = new CoinPackedMatrix(false, 0, 0);
  	matrix -> setDimensions(0, constN+conFeatureN);

  	for (int i=0; i<constN; i++){
      	CoinPackedVector row1;
  		for (int f=0; f<conFeatureN; f++){
  			row1.insert(f, current_factors[constN][f]);
  		}	

      	// the coeffient for m and slack
      	row1.insert(conFeatureN, -1);

      	row1.insert(conFeatureN+1, 1);
      	row_lb[i] = 0.0001;
      	row_ub[i] =  1;
      	matrix->appendRow(row1);
  	}

     ClpSimplex model;
     model.loadProblem(*matrix, col_lb, col_ub, objective, row_lb, row_ub);

      //Solve:
      model.dual();
      solutions = model.dualColumnSolution();

      cout<<"Solutions: "<<solutions[0]<<"\0";	
      for (int f=1; f<conFeatureN; f++){
      	cout<<", "<<solutions[f]<<"\0";	
      }
      cout<<endl;   
	}
}
