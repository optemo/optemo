
// Standard C++ includes
#include <stdlib.h>
#include <fstream>
#include <iostream>
#include <sstream>
#include <assert.h>
#include <float.h>
#include <math.h>
#include <vector>
#include <string>
#include <algorithm>
using namespace std;


// Public interface of the MySQL Connector/C++
#include <cppconn/mysql_public_iface.h>
// Connection parameter and sample data
#include "examples.h"

using namespace std;

/**
* Usage example for Driver Manager, Connection, (simple) Statement, ResultSet
*/
int main(int argc, char** argv) {
	

	stringstream sql;
	int size , affected_rows, sized;
	int clusterN = 9; 
	int conFeatureN = 4;
	int catFeatureN = 1;
	int boolFeatureN = 0;
	int varNamesN = 12;
	int featureN = conFeatureN + catFeatureN + boolFeatureN;    
	int range = 2;
    int inputID = 8;
	int layer = 2;
	int session_id = 1; 
	double difMin; 
	double difMax;
	ostringstream session_idStream;
	ostringstream layerStream;
	layerStream<<layer;
	
	string nodeString;
	
	char** indicatorNames = new char* [4];
	indicatorNames[0] = "Price";
	indicatorNames[1] = "Display Size";
	indicatorNames[2] = "Optical Zoom";
	indicatorNames[3] = "Megapixels";
		
	string *varNames = new string[varNamesN];	
	string *catFeatureNames = new string[catFeatureN];
	string *boolFeatureNames = new string [boolFeatureN];
	string *conFeatureNames = new string[conFeatureN];
	double **conFeatureRange = new double* [conFeatureN];
	
	catFeatureNames[0] = "brand";
	
	conFeatureNames[0]="listpriceint";
	conFeatureNames[1]="displaysize";  
    conFeatureNames[2]="opticalzoom";
    conFeatureNames[3]="maximumresolution";
    
	double *average = new double[conFeatureN]; 
	for (int j=0; j<conFeatureN; j++){
		average[j] = 0.0;
	}


  	bool *conFilteredFeatures = new bool[conFeatureN];   
	bool *catFilteredFeatures = new bool[catFeatureN];
	bool *boolFilteredFeatures = new bool[boolFeatureN];

	
	for (int f=0; f<conFeatureN; f++){
		conFilteredFeatures[f] = 0;
		conFeatureRange[f] = new double[range]; 
	} 

	for (int f=0; f<catFeatureN; f++){
	    catFilteredFeatures[f] = 0;
	}

    for (int f=0; f<boolFeatureN; f++){
		boolFilteredFeatures[f] = 0;
	}

	string argu = argv[1];
	int ind, endit, startit, lengthit;
	string var;

	varNames[0] = "layer";
	varNames[1] = "camid";
	varNames[2] = "brand";
	varNames[3] = "price_min";
	varNames[4] = "price_max";
	varNames[5] = "displaysize_min";
	varNames[6] = "displaysize_max";
	varNames[7] = "opticalzoom_min";
	varNames[8] = "opticalzoom_max";
	varNames[9] = "maximumresolution_min";
	varNames[10] = "maximumresolution_max";
	varNames[11] = "session_id";	
   
	string brand = "";
	for (int j=0; j<varNamesN; j++){
		var = varNames[j];
		ind = argu.find(var, 0);
		endit = argu.find("\n", ind);
		startit = ind + var.length() + 2;
		lengthit = endit - startit;
		if(lengthit > 0){
			if (var=="brand"){
					brand = (argu.substr(startit, lengthit)).c_str();
					if (brand != "All Brands"){
						catFilteredFeatures[0] = 1;
					}
		
		   }
		   else if(var == "layer"){
		        	layer = atoi((argu.substr(startit, lengthit)).c_str());
				//	cout<<"seeing layer"<<endl;
	    	}
		   else if(var == "camid"){
			//cout<<"seeing id  is  "<<endl;
			    	inputID = atoi((argu.substr(startit, lengthit)).c_str());
				//	cout<<inputID<<endl;
		    }
		   else if(var == "price_min"){
					conFeatureRange[0][0] = atof((argu.substr(startit, lengthit)).c_str()) * 100;
		        	conFilteredFeatures[0] = 1;
	    	}
		   else if(var == "price_max"){
			
			conFeatureRange[0][1] = atof((argu.substr(startit, lengthit)).c_str()) ;
					
					conFeatureRange[0][1] = conFeatureRange[0][1]* 100;
			    	conFilteredFeatures[0] = 1;
		    }
		   else if(var == "displaysize_min"){
				    conFeatureRange[1][0] = atof((argu.substr(startit, lengthit)).c_str());
				    conFilteredFeatures[1] = 1;
		    }
		   else if(var == "displaysize_max"){
			    	conFeatureRange[1][1] = atof((argu.substr(startit, lengthit)).c_str());
			    	conFilteredFeatures[1] = 1;
		    }
		   else if(var == "opticalzoom_min"){
			    	conFeatureRange[2][0] = atof((argu.substr(startit, lengthit)).c_str());
			    	conFilteredFeatures[2] = 1;
		    }
		   else if(var == "opticalzoom_max"){
				    conFeatureRange[2][1] = atof((argu.substr(startit, lengthit)).c_str());
				    conFilteredFeatures[2] = 1;
			}
		   else if (var == "maximumresolution_min"){
					conFeatureRange[3][0] = atof((argu.substr(startit, lengthit)).c_str());
			   		conFilteredFeatures[3] = 1;
		    }	
		   else if (var == "maximumresolution_max"){
				    conFeatureRange[3][1] = atof((argu.substr(startit, lengthit)).c_str());
				   	conFilteredFeatures[3] = 1;
					
			}
		   else if (var == "session_id"){
					session_id = atoi((argu.substr(startit, lengthit)).c_str());
		} 	
				 
	    }
		
		else{      //if lengthit = 0
		//	cout<<"Error, you didn't specify a value for "<<var<<endl;
			}
		//layer = atoi((argu.substr(startit, lengthit)).c_str());
	}

// Driver Manager

   	sql::mysql::MySQL_Driver *driver;

	// Connection, (simple, not prepared) Statement, Result Set
	sql::Connection	*con;
	sql::Statement	*stmt;
	sql::Statement  *stmt1;
	sql::Statement  *stmt2;
	
	sql::ResultSet	*res;
    sql::ResultSet	*resClus;
		string line;
		string buf; 
		vector<string> tokens;
		ifstream myfile;
		int i=0;
	   myfile.open("/optemo/site/config/database.yml"); 
	   if (myfile.is_open()){
		while (! myfile.eof()){
			getline (myfile,line);
			stringstream ss(line);
			while(ss>>buf){
				tokens.push_back(buf);
				i++;	}
		}
	    myfile.close();
       }
	   else{
			cout<<"Can't open file "<<myfile<<endl;
	}

	string databaseString = tokens.at(findVec(tokens, "database:") + 1);
	string usernameString = tokens.at(findVec(tokens, "username:") + 1);
	string passwordString = tokens.at(findVec(tokens, "password:") + 1);
	string hostString = tokens.at(findVec(tokens, "host:") + 1);

	    #define EXAMPLE_PORT "3306"       
	 	#define EXAMPLE_DB  "optemo_development"
		#define EXAMPLE_HOST hostString    
		#define EXAMPLE_USER usernameString 
	    #define EXAMPLE_PASS passwordString 

		
	if (layer == 1){

			try {
				// Using the Driver to create a connection
				driver = sql::mysql::get_mysql_driver_instance();
				con = driver->connect(EXAMPLE_HOST, EXAMPLE_PORT, EXAMPLE_USER, EXAMPLE_PASS);
				// Creating a "simple" statement - "simple" = not a prepared statement
				stmt = con->createStatement();
				stmt1 = con->createStatement();
				stmt2 = con->createStatement();

				// Create a test table demonstrating the use of sql::Statement.execute()
				stmt->execute("USE "  EXAMPLE_DB);
			//	stmt1->execute("USE "  EXAMPLE_DB);
			//	stmt2->execute("USE "  EXAMPLE_DB);

				// Fetching again but using type convertion methods
			//	res = stmt->executeQuery("SELECT listpriceint FROM cameras"); // ORDER BY id DESC");
			   res = stmt->executeQuery("SELECT * FROM cameras"); 
			
	     		sized = res->rowsCount();
				double **data = new double*[sized];
		    	for(int j=0; j<sized; j++){
						data[j] = new double[conFeatureN]; 
				}
				string *brands = new string [sized];
				int *idA = new int[sized];	
			
				size = 0;
				bool include = true;
				double listprice = 0.0;
				double saleprice = 0.0;
				double price = 0.0;
		
				 
		//cout<<"conFeatureRange[0][0] is "<<conFeatureRange[0][0]<<"  and conFeatureRange[0][1] is  "<<conFeatureRange[0][1];
	
				
				while (res->next()) // && res1->next() && res2->next() && res3->next() & res4->next() & res5->next()) {
				{
				
					listprice =  res->getDouble("listpriceint");
				 if(res->getDouble("salepriceint")!=NULL ) {	
					
				    saleprice = res->getDouble("salepriceint");
				}
						
				   price = min(listprice, saleprice);
				
					
				 if (
			// (price>0.0 && res1->getDouble("displaysize")!=NULL && res2->getDouble("opticalzoom")!=NULL && res3->getDouble("maximumresolution")!=NULL && res5->getString("brand")!="")&& 
		     (!conFilteredFeatures[0]  || ((price>=(conFilteredFeatures[0]*conFeatureRange[0][0])) && (price<=(conFilteredFeatures[0]*conFeatureRange[0][1])))) &&  
			  (!conFilteredFeatures[1]  ||((res->getDouble(conFeatureNames[1])>=(conFilteredFeatures[1]*conFeatureRange[1][0])) && (res->getDouble(conFeatureNames[1])<=(conFilteredFeatures[1]*conFeatureRange[1][1])))) && 
			  (!conFilteredFeatures[2]  ||((res->getDouble(conFeatureNames[2])>=(conFilteredFeatures[2]*conFeatureRange[2][0])) && (res->getDouble(conFeatureNames[2])<=(conFilteredFeatures[2]*conFeatureRange[2][1])))) && 
	     	 (!conFilteredFeatures[3]  ||((res->getDouble(conFeatureNames[3])>=(conFilteredFeatures[3]*conFeatureRange[3][0])) && (res->getDouble(conFeatureNames[3])<=(conFilteredFeatures[3]*conFeatureRange[3][1])))) &&
			 
			(!catFilteredFeatures[0]  ||((res->getString("brand")==brand))) 
				)	
				{              
			
							data[size][0] = price;
						    data[size][1] = res->getDouble("displaysize");
							data[size][2] = res->getDouble("opticalzoom");
							data[size][3] = res->getDouble("maximumresolution");
							idA[size] = res->getInt("id"); 
							brands[size] = res->getString("brand");
								
							for (int f=0; f<conFeatureN; f++){
							average[f] += data[size][f];
					}
					size++;							
				}
			
			}
		
		
		
		
//////////////////////		
	  
	   int **indicators = new int* [conFeatureN];
	   for (int j=0; j<conFeatureN; j++){
			average[j] = average[j]/size;
			indicators[j] = new int[size];
		}
	  
		double tresh;
	
	
	 	double *dif = new double[conFeatureN];
	    
	    double **dataN = new double*[size];
	    for(int j=0; j<size; j++){
				dataN[j] = new double[conFeatureN]; 
		}     
	
		
		for(int f=0; f<conFeatureN; f++){	
  	          conFeatureRange[f][1] = data[0][f]; 
              conFeatureRange[f][0] = data[0][f]; 
        }
 
	   
	
		for (int f=0; f<conFeatureN; f++){
	      for(int j = 0; j<size; j++){
				if(data[j][f] > conFeatureRange[f][1]){
	                conFeatureRange[f][1] = data[j][f];
	           }
		       if (data[j][f] < conFeatureRange[f][0]){
				   conFeatureRange[f][0] = data[j][f];
			   }
			}
		//	cout<< "Min of "<<f<<" is "<< 	conFeatureRange[f][0]<<endl;
		}	
				
		
		for (int f=0; f<conFeatureN; f++){
			difMin = average[f] - conFeatureRange[f][0];
			difMax = conFeatureRange[f][1] - average[f];
			tresh = min(difMax, difMin) / 2;
			for (int j=0; j<size; j++){
				if (data[j][f] > (average[f] + tresh)){    // high 
			   		indicators[f][j] = 1;
			    }
			    else if(data[j][f] < (average[f] - tresh)){ // low
			   		indicators[f][j] = -1;
				}  
				else{  //average
					indicators[f][j] = 0;
				}
			}		
		}
	
		for (int f=0; f<conFeatureN; f++){
			dif[f] = conFeatureRange[f][1] - conFeatureRange[f][0];
		}
	
		for (int f=0; f<conFeatureN; f++){
		   for(int j=0; j<size; j++){
			if (dif[f] == 0){
				dataN[j][f] = 0;
			}
			else{
		    	dataN[j][f] = (((data[j][f] - conFeatureRange[f][0])/ dif[f]) * 2 ) - 1;
		   	}
	}
	   }
        
   //  delete data;
  
     double** centroids = new double* [clusterN];
    	for(int j=0; j<clusterN; j++){
    		centroids[j]=new double[conFeatureN];
   	}
    
    
       int *centersA = k_means(dataN,size,conFeatureN, clusterN, 1e-4, centroids); 
      	
    
    		double** dist = new double* [size];
 
     		for(int j=0; j<size; j++){
    			dist[j] = new double[clusterN]; 
    		}
  
			double distan;
          for (int j=0; j<size; j++){
    			for (int c=0; c<clusterN; c++){
    				for (int f=0; f<conFeatureN; f++){
						distan = dist[j][c] + ((centroids[c][f] - dataN[j][f])*(centroids[c][f] - dataN[j][f]) );	 
    				    dist[j][c] = distan;	   
    				}  
   			}	 
    	}
			
		
							////////////////////////////////  Change clusteredData to vector 
  	int **clusteredData = new int* [clusterN];


 		for (int j=0; j<clusterN; j++){
 			clusteredData[j] = new int[size];	
 		}

 		for (int c=0; c<clusterN; c++){
 			clusteredData[c][0] = 0;
 		}	
 		int *ts = new int[clusterN];
 		for(int j=0; j<clusterN; j++){
 			ts[j] = 0;
 		}
 		for (int j=0; j<size; j++){
 		    ts[centersA[j]] = ts[centersA[j]]++;			
 			clusteredData[centersA[j]][ts[centersA[j]]] = idA[j];
 			clusteredData[centersA[j]][0]++;
 		}
 		

   //	for (int c=0; c<clusterN; c++){
   //		for(int j=0; j<size; j++){
   //			cout<<"clusteredData[c][j] is  "<<clusteredData[c][j]<<endl;
   //		}
   //	}   
 	  
         int *medians = new int [clusterN];
 		
 		double minDist;
 		for(int c =0; c<clusterN; c++){
 			minDist = dist[0][c];
 			medians[c] = clusteredData[c][1];
			if (clusteredData[c][0] == 0){   /////////////LOSER, FIX IT!!
   			medians[c] = clusteredData[c+1][2];
		//	cout<<"loser c is "<<c<<endl;
			
			   			}
 			for(int j=2; j<clusteredData[c][0]; j++){
 				if(minDist > dist[j-1][c]){
 					minDist = dist[j-1][c];
 					medians[c] = clusteredData[c][j];
 				}
 			}
			
 		}
//Generating the output string 

		string out = "--- !map:HashWithIndifferentAccess \n";
		
		conFeatureRange[0][0] = conFeatureRange[0][0] / 100;
		conFeatureRange[0][1] = conFeatureRange[0][1] / 100;
		for (int j=0; j<(conFeatureN*2); j++){
			out.append(varNames[j+3]);
			out.append(": ");
			if ((j%2) == 0){  // j is even for mins
				std::ostringstream oss;
				oss<<conFeatureRange[j/2][0];
		     	out.append(oss.str());
			}
			else{
				std::ostringstream oss;
				oss<<conFeatureRange[j/2][1];
		     	out.append(oss.str());
				}
			out.append("\n");
		}
		out.append("ids: \n");
		
        for(int c=0; c<clusterN; c++){
		       out.append("- ");
	           std::ostringstream oss; 		  
			   oss<<medians[c];
			   out.append(oss.str()); 
			   out.append("\n");
		} 
		///////////////>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
		out.append("chosen: \n");
		for(int c=0; c<clusterN; c++){		  
			   out.append("- {");
			   out.append("id: ");
			   std::ostringstream oss2; 		  
			   oss2<<medians[c];
			   out.append(oss2.str()); 
			   

			for (int f=0; f<4; f++){
				out.append(", ");
				out.append(indicatorNames[f]);
				out.append(": ");
			    std::ostringstream oss; 
				oss<<indicators[f][find(idA, medians[c], size)];
				out.append(oss.str());
				
			}
			out.append("}\n");
		}
		
		
//
		cout<<out<<endl;

	
	session_idStream<<session_id;
	for (int c=0; c<clusterN; c++){
		ostringstream nodeStream;
		ostringstream clusterStream;
		ostringstream clusterSizeStream;
		clusterStream<<c;
		string command = "INSERT INTO clusters (session_id, layer, cluser_num) values (";
		command += session_idStream.str();
		command += ", ";
		command += layerStream.str();
		command += ", ";
		command += clusterStream.str();
		command +=")";
		stmt->execute(command);
	
		for(int j=0; j<clusteredData[c][0]+1; j++){
			nodeStream<<clusteredData[c][j];
			nodeStream<<" ";
		}
		
		clusterSizeStream<<clusteredData[c][0];
		command = "UPDATE clusters set cluster_size=";
		command += clusterSizeStream.str();
		command += " WHERE session_id=";
		command += session_idStream.str();
		command += " AND cluser_num=";
		command += clusterStream.str();
		stmt->execute(command);
		
		nodeString = "\"";
		nodeString += nodeStream.str();
		nodeString += "\")";
		command = "UPDATE clusters set nodes=(";
		command += nodeString;
		
		command += " WHERE session_id=";
		command += session_idStream.str();
		command += " AND layer=";
		command += layerStream.str();
		command += " AND cluser_num=";
		command += clusterStream.str();
		
		stmt->execute(command); 
	
	}	
            

	// Clean up

 	delete stmt;
 	delete con;
    delete data;
    delete dataN;
 	delete clusteredData; 
 	delete medians;
 	delete dist;

 	} catch (sql::mysql::MySQL_DbcException *e) {

		delete e;
		return EXIT_FAILURE;

	} catch (sql::DbcException *e) {
		/* Exception is not caused by the MySQL Server */

		delete e;
		return EXIT_FAILURE;
	}



}////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


else if(layer >1){
	
	clusterN = clusterN - layer + 2;
	
		try {
			// Using the Driver to create a connection
			driver = sql::mysql::get_mysql_driver_instance();
			con = driver->connect(EXAMPLE_HOST, EXAMPLE_PORT, EXAMPLE_USER, EXAMPLE_PASS);
			// Creating a "simple" statement - "simple" = not a prepared statement
			stmt = con->createStatement();

			// Create a test table demonstrating the use of sql::Statement.execute()
			stmt->execute("USE "  EXAMPLE_DB);
		    res = stmt->executeQuery("SELECT * FROM cameras");

   //string fileName = "tmp/cachedFiles/saveClustered";	 
   //std::ostringstream layerS;
   //layerS<<layer-1;
   //fileName.append(layerS.str());

int minDist;
  
 	int session_id = 1;
		ostringstream session_idStream;
		session_idStream<<session_id;

string command = "SELECT * from clusters where session_id=";
command += session_idStream.str();
resClus = stmt->executeQuery(command);


////loading data

// int **oldClusteredData = new int* [clusterN];
// for (int j=0; j<clusterN; j++){
// 			oldClusteredData[j] = new int[size];	
//}
int* idA;
int ClusterSize;
string nodeToken;
int pos;
int id;
int clusterSize;
int pickedCluster;
bool stop = false;


for (int c=0; c<clusterN; c++){
  if(resClus->next()){
	
	
	nodeString = resClus->getString("nodes");
	
	//parse nodeString
	pos = nodeString.find(" ");
	nodeToken = nodeString.substr(0, pos);
	clusterSize = atoi(nodeToken.c_str());
//	oldClusteredData[c][0] = clusterSize;

//	delete idA;
	idA = new int [clusterSize];
	
	for (int j=0; j<clusterSize; j++){
		nodeString = nodeString.substr(pos+1);
		pos = nodeString.find(" ");
		nodeToken = nodeString.substr(0, pos);
		id = atoi(nodeToken.c_str());
		
//		oldClusteredData[c][j+1] = id;
		if (!stop){
			
			idA[j] = id;
		}
	} 		
	if (find(idA, id , clusterSize) >-1){
		
		stop = true;
		pickedCluster = c;
		c = clusterN;
	}
	
}
}






 //int *oldCentersA = new int[size];

// loadFile(fileName, oldData, oldClusteredData, oldCentersA, oldBrands, oldIdA);
//for (int j=0; j<size; j++){
//	<<"oldBrand is "<<oldBrands[j]<<endl;
//}

 if (inputID > 2200){
 	cout<<"THE ID NUMBER IS TOO LARGE"<<endl;
 	return 0;
  }


 //removing the inputID from the rest of data   

int size = 0;

// oldClusteredData[pickedCluster][find(oldClusteredData[pickedCluster], inputID, oldClusteredData[pickedCluster][0])] = oldClusteredData[pickedCluster][clusterSize];
// oldClusteredData[pickedCluster][0]--;

idA[find(idA, id, clusterSize)] = idA[clusterSize]; 

 clusterSize--;


double **data = new double*[clusterSize];
 for(int j=0; j<clusterSize; j++){
	 	data[j] = new double[conFeatureN]; 
  }	
 
string *brands = new string [clusterSize]; 
int saleprice, price, listprice;
// filtering the data
string dataBrand;
bool include = true;

for (int j=0; j<clusterSize; j++){

	command = "SELECT * from cameras where id=";
	ostringstream idStream;
	idStream<<idA[j];
	command += idStream.str();
	
	resClus = stmt->executeQuery(command);
	if (resClus->next()){
	dataBrand = resClus->getString("brand");
	
	saleprice = 0.0;

	if(resClus->getDouble("salepriceint")!=NULL ) {	
    	saleprice = resClus->getDouble("salepriceint");
	}
		
	listprice = resClus->getDouble("listpriceint");
	
	price = min(listprice, saleprice);
//	cout<<"BEFORE"<<endl;
//	cout<<"brand is  "<<brand<<"and dataBrand is  "<<dataBrand<<endl;
    if(
       (!conFilteredFeatures[0]  || ((price>=(conFilteredFeatures[0]*conFeatureRange[0][0])) && (price<=(conFilteredFeatures[0]*conFeatureRange[0][1])))) &&  
       (!conFilteredFeatures[1]  ||((resClus->getDouble(conFeatureNames[1])>=(conFilteredFeatures[1]*conFeatureRange[1][0])) && (resClus->getDouble(conFeatureNames[1])<=(conFilteredFeatures[1]*conFeatureRange[1][1])))) && 
	   (!conFilteredFeatures[2]  ||((resClus->getDouble(conFeatureNames[2])>=(conFilteredFeatures[2]*conFeatureRange[2][0])) && (resClus->getDouble(conFeatureNames[2])<=(conFilteredFeatures[2]*conFeatureRange[2][1])))) && 
	   (!conFilteredFeatures[3]  ||((resClus->getDouble(conFeatureNames[3])>=(conFilteredFeatures[3]*conFeatureRange[3][0])) && (resClus->getDouble(conFeatureNames[3])<=(conFilteredFeatures[3]*conFeatureRange[3][1])))) &&
	   ( !catFilteredFeatures[0] || brand == dataBrand ))
	{	 
		
		data[size][0] = price;
		data[size][1] = resClus->getDouble("displaysize");
		data[size][2] = resClus->getDouble("opticalzoom");
		data[size][3] = resClus->getDouble("maximumresolution"); 
		brands[size] = dataBrand; 
		
		
		for (int j=0; j<conFeatureN; j++){
					average[j] += data[size][j];
			}
		size++;	
	}
}
}

int **indicators = new int* [conFeatureN];
for (int j=0; j<conFeatureN; j++){
	average[j] = average[j]/size;
	indicators[j] = new int[size];
		}
	  
double tresh;


// normalizing of the data
 
 double **dataN = new double* [size];
  	
 for(int j=0; j<size; j++){
	 	dataN[j] = new double[conFeatureN]; 
  }     
  
 for(int f=0; f<conFeatureN; f++){	
        conFeatureRange[f][1] = data[0][f]; 
        conFeatureRange[f][0] = data[0][f]; 
  }

	double *dif = new double[conFeatureN];


	for (int f=0; f<conFeatureN; f++){
       for(int j = 0; j<size; j++){
			if(data[j][f] > conFeatureRange[f][1]){
               conFeatureRange[f][1] = data[j][f];
         }
	       if (data[j][f] < conFeatureRange[f][0]){
			   conFeatureRange[f][0] = data[j][f];
		   }
		}
	}	
	
	
	for (int f=0; f<conFeatureN; f++){
	
		difMin = average[f] - conFeatureRange[f][0];
		difMax = conFeatureRange[f][1] - average[f];
		tresh = min(difMax, difMin) / 2;
	
		for (int j=0; j<size; j++){
			if (data[j][f] > (average[f] + tresh)){    // high 
		   		indicators[f][j] = 1;
		    }
		    else if(data[j][f] < (average[f] - tresh)){ // low
		   		indicators[f][j] = -1;
			}  
			else{  //average
				indicators[f][j] = 0;
			}
		}		
	}

	for (int f=0; f<conFeatureN; f++){
		dif[f] = conFeatureRange[f][1] - conFeatureRange[f][0];
	}

	for (int f=0; f<conFeatureN; f++){
	   for(int j=0; j<size; j++){
		if (dif[f] == 0){
			dataN[j][f] = -1;	
		}
	    else{
		dataN[j][f] = (((data[j][f] - conFeatureRange[f][0])/ dif[f]) * 2 ) -1;
   	}
}
 }
  
clusterN--;

  double** centroids = new double* [clusterN];
  for(int j=0; j<clusterN; j++){
   	centroids[j]=new double[conFeatureN];
  }
 

  double** dist = new double* [size];
  	
  for(int j=0; j<size; j++){
  	dist[j] = new double[clusterN]; 
  }
  

 
 int *centersA = k_means(dataN,size, conFeatureN, clusterN, 1e-4, centroids); 


  for (int j=0; j<size; j++){
 	for (int c=0; c<clusterN; c++){
  		for (int f=0; f<conFeatureN; f++){
  			dist[j][c] = dist[j][c] + ((centroids[c][f] - dataN[j][f])*(centroids[c][f] - dataN[j][f]));	
      
  		}  
  	}	 
  }
  
   	int **clusteredData = new int* [clusterN];


  	for (int j=0; j<clusterN; j++){
  		clusteredData[j] = new int[size];	
  	}

  	for (int c=0; c<clusterN; c++){
  		clusteredData[c][0] = 0;
  	}	
  	int *ts = new int[clusterN];
  	for(int j=0; j<clusterN; j++){
  		ts[j] = 0;
  	}
  	for (int j=0; j<size; j++){
  	
  	    ts[centersA[j]] = ts[centersA[j]]++;	
  		clusteredData[centersA[j]][ts[centersA[j]]] = idA[j];//oldClusteredData[pickedCluster][j+1];
		clusteredData[centersA[j]][0]++;
  	}
 
   	int *medians = new int [clusterN];
   	for(int c =0; c<clusterN; c++){
   		minDist = dist[0][c];
   		medians[c] = clusteredData[c][1];
   			if (clusteredData[c][0] == 0){   /////////////LOSER, FIX IT!!
			
				medians[c] = idA[c]; //oldClusteredData[pickedCluster][c];
   			}
		
   	  		for(int j=2; j<clusteredData[c][0]; j++){
   		 		if(minDist > dist[j-1][c]){
    					minDist = dist[j-1][c];
   					medians[c] = clusteredData[c][j];		   
   		     	}
   		   	}
	
   		 }
   


		 string nodeString;

		for (int c=0; c<clusterN; c++){
			ostringstream nodeStream;
			ostringstream clusterStream;
			ostringstream clusterSizeStream;
			clusterStream<<c;
			string command = "INSERT INTO clusters (session_id, layer, cluser_num) values (";
			command += session_idStream.str();
			command += ", ";
			command += layerStream.str();
			command += ", ";
			command += clusterStream.str();
			command +=")";
			stmt->execute(command);

			for(int j=0; j<clusteredData[c][0]+1; j++){
				nodeStream<<clusteredData[c][j];
				nodeStream<<" ";
			}

			clusterSizeStream<<clusteredData[c][0];
			command = "UPDATE clusters set cluster_size=";
			command += clusterSizeStream.str();
			command += " WHERE session_id=";
			command += session_idStream.str();
			command += " AND cluser_num=";
			command += clusterStream.str();
			stmt->execute(command);

			nodeString = "\"";
			nodeString += nodeStream.str();
			nodeString += "\")";
			command = "UPDATE clusters set nodes=(";
			command += nodeString;

			command += " WHERE session_id=";
			command += session_idStream.str();
			command += " AND layer=";
			command += layerStream.str();
			command += " AND cluser_num=";
			command += clusterStream.str();

			stmt->execute(command); 

		}	
	 
		// Clean up

	    delete data;
	    delete dataN;
	 	delete clusteredData; 
	 	delete dist;
	

	

		string out = "--- !map:HashWithIndifferentAccess \n";
		
		conFeatureRange[0][0] = conFeatureRange[0][0] / 100;
		conFeatureRange[0][1] = conFeatureRange[0][1] / 100;
		for (int j=0; j<(conFeatureN*2); j++){
			out.append(varNames[j+3]);
			out.append(": ");
			if ((j%2) == 0){  // j is even for mins
				std::ostringstream oss;
				oss<<conFeatureRange[j/2][0];
		     	out.append(oss.str());
			}
			else{
				std::ostringstream oss;
				oss<<conFeatureRange[j/2][1];
		     	out.append(oss.str());
				}
			out.append("\n");
		}
		out.append("ids: \n");
        for(int c=0; c<clusterN; c++){
		       out.append("- ");
	           std::ostringstream oss; 		  
			   oss<<medians[c];
			   out.append(oss.str()); 
			   out.append("\n");
		} 
		out.append("chosen: \n");
	
		for(int c=0; c<clusterN; c++){		  
		   out.append("- {");
		   out.append("id: ");
		   std::ostringstream oss2; 		  
		   oss2<<medians[c];
		   out.append(oss2.str());
		   
		   for (int f=0; f<4; f++){
				out.append(", ");
				out.append(indicatorNames[f]);
				out.append(": ");
				std::ostringstream oss; 
				oss<<indicators[f][find(idA, medians[c], clusterSize)];
				out.append(oss.str());
			
			}
		   	out.append("}\n");
	    }

//
		cout<<out<<endl;
 }
catch(sql::mysql::MySQL_DbcException *e) {

		delete e;
		return EXIT_FAILURE;

	} catch (sql::DbcException *e) {
		/* Exception is not caused by the MySQL Server */

		delete e;
		return EXIT_FAILURE;
	}

}

return 1; //EXIT_SUCCESS;
}