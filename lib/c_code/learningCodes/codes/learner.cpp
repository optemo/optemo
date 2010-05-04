/* Preference Learner, (c) Optemo 2010
*/

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
#include <map>
#include <utility>

using namespace std;
#include "ClpSimplex.hpp"
#include </usr/local/include/mysql-connector-c++/driver/mysql_public_iface.h>
#include "formulate.h"

// This is hard-coded for the 4 camera features.
int conFeatureN = 4;

/* There are some modifications to the original learner present so that at the moment, this program
 * just analyses best buy data from the mysql instance on Zev's computer. */

int main (int argc, const char *argv[])
{
    stringstream sql;
	sql::Driver *driver = get_driver_instance();
  	sql::Connection	*con;
	sql::Statement	*stmt;
	sql::ResultSet	*resPref;
	string productName = "Camera";
	// This hash is between optemo_session and a linked list of "browse similar" preference results.
	map <int, preference*> browse_similar_results;
    
	/*
    if (argc<3){
   		cout<<"Err - Enter product type and optemo_session id"<<endl;
        cout << "Example: " << argv[0] << " Printer 328"<<endl;
		return 0;
   	} else {
		productName = argv[1];
   		session = atoi(argv[2]);
    }
    */
	int conFeatureN = 4;
	string* conFeatureNames = new string[conFeatureN];
	
	string databaseName = "prefpwk";
	string tableName = "piwik_log_preferences";
    #define PORT "3306"
	#define DB   databaseName
	#define HOST "optemo"
	#define USER "remoteaccess"
    #define PASS "pre78fs"
	
	try {
		// Using the Driver to create a connection
//	    std::auto_ptr< sql::Connection > con(driver->connect(HOST, USER, PASS)); // No port specified?
	    con = driver->connect("localhost", "root", "zev");
		stmt = con->createStatement();
		string command = "USE ";
		command += databaseName;
		stmt->execute(command);

        delete stmt;
        stmt = con->createStatement();

        command = "SELECT * FROM `piwik_log_link_visit_action` lva, piwik_log_preferences p WHERE lva.idaction = 35 AND p.idvisit = lva.idvisit AND product_picked IS NOT NULL AND product_ignored IS NOT NULL GROUP BY product_picked, product_ignored, optemo_session, servertime ORDER BY optemo_session";
        cout <<"Command executing now is: " << command << endl;
        resPref = stmt->executeQuery(command);
        delete stmt;
        // now put it into a hash based on optemo_session
        preference * list;
        int product_picked, product_ignored, optemo_session;
        while (resPref->next())
        {
            preference *preference_list = new preference;
            preference_list->next = 0;
            product_picked = resPref->getInt("product_picked");
            product_ignored = resPref->getInt("product_ignored");
            optemo_session = resPref->getInt("optemo_session");
            preference_list->product_picked = product_picked;
            preference_list->product_ignored = product_ignored;
            if (browse_similar_results.find(optemo_session) == browse_similar_results.end())
            {
                browse_similar_results[optemo_session] = preference_list;
            }
            else {
                list = browse_similar_results[optemo_session];
                while (list->next)
                {
                    list = list->next;
                }
                // Now we have the last element
                list->next = preference_list;
            }
            // Then don't free anything.
        }
        // At this point, the structure should be:
        // { session => (struct => struct => struct), session => (struct, struct, struct) }
        map <int, preference*>::iterator itr;
        cout << "Session ID => []"<<endl;
        for(itr = browse_similar_results.begin();itr!=browse_similar_results.end();itr++)
        {
            // cout << itr->first << " => [";
            list = itr->second;
            while (list)
            {
                // cout << "[" << list->product_picked << ", " << list->product_ignored << "] ";
                list = list->next;
            }
            // cout << "]" << endl;
        }
		stmt = con->createStatement();
        cout << "Ready to use optemo_bestbuy: " << endl;
        stmt->execute("USE optemo_bestbuy");

		conFeatureNames[0] = "maximumresolution";
		conFeatureNames[1] = "displaysize";
		conFeatureNames[2] = "opticalzoom";
		conFeatureNames[3] = "price";
		formulate(stmt, productName, conFeatureNames, browse_similar_results);

        delete stmt;
    } catch (sql::SQLException &e) {
        cout << "# ERR: " << e.what();
        cout << " (MySQL error code: " << e.getErrorCode();
        cout << ", SQLState: " << e.getSQLState() << " )" << endl;
        return EXIT_FAILURE;
    }
    return 0;
}