//formulate.h
#include <iostream> 
//#include <string>
#include "CoinPackedMatrix.hpp" 
#include "CoinPackedVector.hpp" 
#include <../../../cppconn/mysql_public_iface.h>
#include "ClpSimplex.hpp"
using namespace std;

void formulate(sql::Statement *stmt, sql::ResultSet *resPref, sql::ResultSet *resFactor, ClpSimplex model, string productName, string* conFeatureNames, int conFeatureN){
	
	string command;
	//alpha is -1 * the upper bound on the the number of violated constraints
	double alpha = -2;
	int pickedId, ignoredId, constN;
	double* factor = new double [conFeatureN];
	double utility;
	while (resPref->next()){
			
		//	cout<<"count is "<<resPref->rowsCount()<<endl;
		pickedId = resPref->getDouble("product_picked");
	
		command ="select * from factors where product_type=\'";
		command += productName;
		command += "\' and product_id=";
		ostringstream ppIdS;
		ppIdS << pickedId;
		command += ppIdS.str();
		command += ";";
	//	
		resFactor = stmt->executeQuery(command);
		
		for (int i=0; i<conFeatureN; i++){
			resFactor->next();
			factor[i] = resFactor->getDouble(conFeatureNames[i]);
		}	
		
		ignoredId = resPref->getDouble("product_ignored");
		command ="select * from optemo_bestbuy.factors where product_type=\'";
		command += productName;
		command += "\' and product_id=";
		ostringstream ipIdS;
		ipIdS << ignoredId;
		command += ipIdS.str();
		command += ";";
		cout<<"command is "<<command<< endl;
		resFactor = stmt->executeQuery(command);
		cout<<"count is "<<resFactor->rowsCount()<<endl;
		for (int i=0; i<conFeatureN; i++){
				cout<<"HERE"<<endl;
		    resFactor->next();
				
		
			factor[i] = factor[i] - resFactor->getDouble(conFeatureNames[i]);
	
		}	
			
	}	
	
	
		//factor vector is the coeffiecient vector for the constraints
		//the lower bound is 0 and the upper bound is maximum utility, i.e. 1
		
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
			col_ub[i] = 1;
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
			row_ub[i] = -1 * 1000;
			row_lb[i] = 0;
			matrix->appendRow(row1);
		}
		
		model.loadProblem(*matrix, col_lb, col_ub, objective, row_lb, row_ub);
			
	
}