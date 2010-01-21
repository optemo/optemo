//formulate.h
#include <iostream> 
//#include <string>
#include "CoinPackedMatrix.hpp" 
#include "CoinPackedVector.hpp" 
#include <../../../cppconn/mysql_public_iface.h>
#include "ClpSimplex.hpp"
using namespace std;

void formulate(sql::Statement *stmt, sql::ResultSet *resPref, sql::ResultSet *resFactor, string productName, string* conFeatureNames, int conFeatureN, double* solutions){
	
	string command;
	//alpha is -1 * the upper bound on the the number of violated constraints
	double alpha =0.2;
	int pickedId, ignoredId, constN;
	double* factor = new double [conFeatureN];
	int count = 1;
	double fact;
	while (resPref->next()){
				
		pickedId = resPref->getInt("product_picked");
		command ="select * from factors where product_type=\'";
		command += productName;
		command += "\' and product_id=";
		ostringstream ppIdS;
		ppIdS << pickedId;
		command += ppIdS.str();
		command += ";";

		resFactor = stmt->executeQuery(command);
	
		for (int i=0; i<conFeatureN; i++){
			resFactor->next();
			factor[i] = resFactor->getDouble(conFeatureNames[i]);
		}	
		
		ignoredId = resPref->getInt("product_ignored");
		
		command ="select * from factors where product_type=\'";
		command += productName;
		command += "\' and product_id=";
		ostringstream ipIdS;
		ipIdS << ignoredId;
		command += ipIdS.str();
		command += ";";
		resFactor = stmt->executeQuery(command);
		if (resFactor->rowsCount()>0){
		for (int i=0; i<conFeatureN; i++){
		    resFactor->next();	
			fact = resFactor->getDouble(conFeatureNames[i]);
			factor[i] = factor[i] - fact;
		}	
			count++;
	}
	}
	

		
		//factor vector is the coeffiecient vector for the constraints
		//the lower bound is 0 and the upper bound is maximum utility, i.e. 1
	constN = count;
		//constructing the objective function
	
		double * objective = new double[constN+1];
		for (int i=0; i<constN; i++){
			objective[i] = alpha;
		}
		objective[constN] = 1;
	
		//constructing the bounds
		// bounds for preference weights
		double * col_lb = new double [conFeatureN+constN+1];
		double * col_ub = new double [conFeatureN+constN+1];
		for (int i=0; i<conFeatureN; i++){
			col_lb[i] = 0;
			col_ub[i] = 1;
		}
		
		//bounds for slack variables
		for (int i=conFeatureN; i<conFeatureN+constN; i++){
			col_lb[i] = 0;
			col_ub[i] = 100;
		}
		
		// bound for margin
		col_lb[conFeatureN+constN] = 1;
		col_ub[conFeatureN+constN] = 2;
		
		double* row_lb = new double [constN];
		double* row_ub = new double [constN];
		
		//constructing the constrains matrix
		CoinPackedMatrix * matrix = new CoinPackedMatrix(false, 0, 0);
		matrix -> setDimensions(0, constN+conFeatureN);
	
		for (int i=0; i<constN; i++){
			CoinPackedVector row1;
			for (int f=0; f<conFeatureN; f++){
				row1.insert(f, factor[f]);
			}	
			
			// the coeffient for m and slack
			row1.insert(conFeatureN, -1);
	
			row1.insert(conFeatureN+1, 1);
			row_ub[i] =  1;
			row_lb[i] = 0.01;
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