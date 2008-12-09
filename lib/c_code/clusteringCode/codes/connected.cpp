
// Standard C++ includes
#include <stdlib.h>
#include <iostream>
#include <sstream>
#include <assert.h>
#include <float.h>
#include <math.h>


// Public interface of the MySQL Connector/C++
#include <cppconn/mysql_public_iface.h>
// Connection parameter and sample data
#include "examples.h"

using namespace std;

/**
* Usage example for Driver Manager, Connection, (simple) Statement, ResultSet
*/
int main() {
	// Driver Manager
	sql::mysql::MySQL_Driver *driver;

	// Connection, (simple, not prepared) Statement, Result Set
	sql::Connection	*con;
	sql::Statement	*stmt;
	sql::ResultSet	*res;
    sql::ResultSet	*res2; 
    sql::ResultSet	*res3;
    sql::ResultSet	*res4;   
    sql::ResultSet	*res5;   
    
	/* sql::ResultSet.rowsCount() returns size_t */
	size_t row;
	stringstream sql;
	int i, affected_rows;

//	cout << boolalpha;
	//cout << "Connector/C++ connect basic usage example.." << endl << endl;

	try {
		// Using the Driver to create a connection
		driver = sql::mysql::get_mysql_driver_instance();
		con = driver->connect(EXAMPLE_HOST, EXAMPLE_PORT, EXAMPLE_USER, EXAMPLE_PASS);

		// Creating a "simple" statement - "simple" = not a prepared statement
		stmt = con->createStatement();

		// Create a test table demonstrating the use of sql::Statement.execute()
		stmt->execute("USE " EXAMPLE_DB);
	//	stmt->execute("DROP TABLE IF EXISTS "EXAMPLE_DB);
//		stmt->execute("CREATE TABLE "EXAMPLE_DB"(id INT, label CHAR(1))");
	//	cout << "\tTest table created" << endl;

	//	cout << "\tTest table populated" << endl << endl;


		// Fetching again but using type convertion methods
		res = stmt->executeQuery("SELECT listpriceint FROM cameras"); // ORDER BY id DESC");
		res2 = stmt->executeQuery("SELECT displaysize FROM cameras"); 
		res3 = stmt->executeQuery("SELECT opticalzoom FROM cameras"); 
		res4 = stmt->executeQuery("SELECT maximumresolution FROM cameras"); 
		res5 = stmt->executeQuery("SELECT id FROM cameras");
		
		//listpriceint
	    //displaysize
		//optical zoom
		//maximumresolution
	
		//cout << "\t\tNumber of rows\t";
		double *listpriceA = new double[res->rowsCount()];
		double *displaysizeA = new double[res2->rowsCount()];
		double *opticalzoomA = new double[res3->rowsCount()];
		double *maxResolutionA = new double[res4->rowsCount()]; 
		int *idA = new int[res->rowsCount()];
		
		double *listpriceNA = new double[res->rowsCount()];
		double *displaysizeNA = new double[res2->rowsCount()];
		double *opticalzoomNA = new double[res3->rowsCount()];
		double *maxResolutionNA = new double[res4->rowsCount()];

		
	    row = 0;
		i = 0;
		while (res2->next() && res->next() && res3->next() && res4->next() && res5->next()) {
		//	cout << "\t\tFetching row " << row;
			if (res->getInt("listpriceint")>0 && res2->getDouble("displaysize")>0 && res3->getDouble("opticalzoom")>0 && res4->getDouble("maximumresolution")>0){
			    	
					listpriceA[i] = res->getInt("listpriceint");
				//	cout << "\tlistprice int = " << listpriceA[i]  <<endl;
				    displaysizeA[i] = res2->getInt("displaysize");
					//cout << "\t display size = " << displaysizeA[i]<< endl;
					opticalzoomA[i] = res3->getInt("opticalzoom");
		    	//	cout << "\t optical zoom = " << opticalzoomA[i]<< endl; 
					maxResolutionA[i] = res4->getInt("maximumresolution");
					idA[i] = res5->getInt("id");
					//cout << "\t maxResolution = " << maxResolutionA[i]<< endl; 
					//cout << "\t i is "<<i<<endl;
					//cout<<endl;
					i++;
		}
			row++;
		}
		delete res;
		delete res2;
		delete res3;
		delete res4;

        // int length = listpriceA.size();  // establish size of array
	    double maxP = listpriceA[0];     
		double minP = maxP;
		
	    double maxD = displaysizeA[0];     
	    double minD = maxD;
	    
	    double maxZ = opticalzoomA[0];     
	    double minZ = maxZ;
	
	    double maxR = maxResolutionA[0];     
		double minR = maxR; 
	
	
	
	     for(int j = 0; j<i; j++){
				if(listpriceA[j] > maxP){
	                maxP = listpriceA[j];
	           }
		      if (listpriceA[j] < minP){
				   minP = listpriceA[j];
				}
				
	    	  if(displaysizeA[j] > maxD){
		           maxD = displaysizeA[j];
	            }
		      if (displaysizeA[j] < minD){
				   minD = displaysizeA[j];
				}
	    	  if(opticalzoomA[j] > maxZ){
		           maxZ = opticalzoomA[j];
		        }
			  if (opticalzoomA[j] < minZ){
				   minZ = opticalzoomA[j];
			    }
			  if(maxResolutionA[j] > maxR){
		           maxR = maxResolutionA[j];
		        }
		 	  if (maxResolutionA[j] < minR){
				   minR = maxResolutionA[j];
			    }
  	     }

		//cout <<" max is "<< max<<endl; 
        //cout <<" min is "<< min<<endl; 

		double difP = maxP - minP;
        double difD = maxD - minD;
   		double difZ = maxZ - minZ;
		double difR = maxR - minR;
		
		//cout << "NORMALIZING"<<endl;
		for(int j=0; j<i; j++){
			listpriceNA[j] = ((listpriceA[j] - minP) * 10/ difP) + 1;
			displaysizeNA[j] = ((displaysizeA[j] - minD )* 10 / difD) + 1;
			opticalzoomNA[j] = ((opticalzoomA[j] - minZ ) * 10/ difZ) + 1;	
			maxResolutionNA[j] = ((maxResolutionA[j] - minR ) * 10 / difR) + 1;
		//	cout<<"normalized "<<j<<" price is "<<listpriceNA[j]<< "  zoom is  "<< opticalzoomNA[j]<<endl;
		}	
		
		
		
		
		///Clustering
		//int *k_means(double **data, int n, int m, int k, double t, double **centroids)
	//	double **data = (double**) malloc(sizeof(double*) * 10); //new *double[4];
		double **data = new double*[4];
		for(int j=0; j<4; j++){
			data[j] = new double[i]; 
		}     
		
		data[0] = listpriceNA;
		data[1] = displaysizeNA;
		data[2] = opticalzoomNA;
		data[3] = maxResolutionNA;

        double **data2 = new double*[i];
		for(int j=0; j<i; j++){
			data2[j] = new double[4]; 
		}

		for(int j=0; j<i; j++){
			for(int d=0; d<4; d++){
				data2[j][d] = data[d][j];
			//	cout<<"data[d][j] is  "<< data2[j][d]<< endl;
			}
		}
	
	   // int *centersA = new int[i];
			
	    int *centersA = k_means(data2,i,4, 9, 1e-4, 0); 
		
		for(int j=0; j<i; j++){
		
		    //cout <<"center of "<< idA[j] <<" is  "<<centersA[j] + 1<<endl;
		}
		// Clean up

		delete stmt;
		delete con;

	//	cout << "done!" << endl;
	} catch (sql::mysql::MySQL_DbcException *e) {
		/*
		The MySQL Connector/C++ throws four different exceptions:

		- sql::mysql::MySQL_DbcException (derived from sql::DbcException)
		- sql::DbcMethodNotImplemented (derived from sql::DbcException)
		- sql::DbcInvalidArgument (derived from sql::DbcException)
		- sql::DbcException (derived from std::runtime_error)

		All MySQL Server related errors will be reported by throwing a MySQL_DbcException.
		MySQL_DbcException is the only of the four above mentioned which
		can return a MySQL Server error code through the method int getMySQLErrno().
		*/

	//	cout << endl;
	//	cout << "ERR: MySQL_DbcException in " << __FILE__;
	//	cout << "(" << __FUNCTION__ << ") on line " << __LINE__ << endl;

		// Use what() and getMySQLErrno()
	//	cout << "ERR: " << e->what();
	//	cout << " (MySQL error code: " << e->getMySQLErrno() << " )" << endl;

		delete e;
		return EXIT_FAILURE;

	} catch (sql::DbcException *e) {
		/* Exception is not caused by the MySQL Server */

	//	cout << endl;
	//	cout << "ERR: DbcException in " << __FILE__;
	//	cout << "(" << __FUNCTION__ << ") on line " << __LINE__ << endl;
		// Use what() (derived from std::runtime_error)
	//	cout << "ERR: " << e->what();

		delete e;
		return EXIT_FAILURE;
	}

	
//return EXIT_SUCCESS;
	return 2; 
}

