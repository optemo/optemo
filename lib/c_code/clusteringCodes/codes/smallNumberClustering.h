void smallNumberClustering(int conFeatureN, int boolFeatureN, int clusterN, string* conFeatureNames, string* boolFeatureNames, 
					sql::ResultSet *res, sql::ResultSet *res2, sql::Statement *stmt, string productName, int version, string region){
	
   string command, command2;
	string capProductName = productName;
	capProductName[0] = capProductName[0] - 32;
	ostringstream vstream;
	ostringstream lstream;
	vstream << version;
	lstream << 1;
	double value;
	ostringstream idStream;
	ostringstream pstream;
	ostringstream ustr;
	ostringstream sizestr;
	ostringstream cidstr;
	pstream << 0; 
	sizestr << 1;
	
	
	while (res->next()){
		
		idStream << res->getInt("id");
		command = "INSERT INTO ";
		command += productName;
		command += "_clusters (version, region, layer, parent_id, cluster_size,cached_utility, price_min, price";
		for (int i=1; i<conFeatureN; i++){
			command += "_max, ";
			command += conFeatureNames[i];
			command += "_min, ";
			command += conFeatureNames[i];
		}
		
		command += "_max, brand";
		for (int f=0; f<boolFeatureN; f++){
			command += ", ";
			command += boolFeatureNames[f];
		}
		command += ") values (";
		
		command += vstream.str();
		command += ", '";
		command += region;
		command += "', ";
		
		command += lstream.str();
		command += ", ";
		command += pstream.str();
		command += ", ";
		command += sizestr.str();
		command += ", ";
	   //utility
	   command2 = "SELECT ";
	   command2 += conFeatureNames[0];
 
	   for (int f=1; f<conFeatureN; f++){
	    command2 += ", ";   
	   	command2 += conFeatureNames[f]; 
	
	   }	
	   command2 += " from factors where (product_type= \'";
	   
	   command2 += capProductName;
	   command2 += "\' and product_id=";
	   command2 += idStream.str();
	   command2 += ");";

	   res2 = stmt->executeQuery(command2);
		
	   int utility = 0.0;
	   if (res2->rowsCount()>0){
	   	res2->next();
	   	for (int f=0; f<conFeatureN; f++){
	   		utility += res2->getDouble(conFeatureNames[f]);
	   	}	
	   }
	   
	   ustr << utility;
	   command +=  ustr.str();
	  
	  
	for (int f=0; f<conFeatureN; f++){ // min and max are the same
		command += ", "	;
		value = res->getDouble(conFeatureNames[f]);
		
		ostringstream vstream;
		vstream << value;
		command +=vstream.str();
		command += ",";
		command += vstream.str();
	}	
	for (int f=0; f<boolFeatureN; f++){ // min and max are the same
		command += ", "	;
		value = res->getDouble(boolFeatureNames[f]);
		
		ostringstream vstream;
		vstream << value;
		command +=vstream.str();
	}
		
	command += ", '";

	command += res->getString("brand");
	
	command += "');"; 

	
	stmt->execute(command);	
    
	//NODES
	command2 = "SELECT last_insert_id();"; // from clusters;"
	res2 = stmt->executeQuery(command2);
		res2->next();
	cidstr << res2->getInt("last_insert_id()");
	
	
	command = "INSERT INTO ";
	command += productName;
	command += "_nodes (version, region, cluster_id, utility, product_id, price";
	for (int i=1; i<conFeatureN; i++){
		command += ", ";
		command += conFeatureNames[i];
	}
	
	command += ", brand";
	for (int f=0; f<boolFeatureN; f++){
		command += ", ";
		command += boolFeatureNames[f];
	}
	command += ") values (";
	
	command += vstream.str();
	command += ", '";
	command += region;
	command += "', ";
	command += cidstr.str();
	command += ", ";
	
   //utility
   command2 = "SELECT ";
   command2 += conFeatureNames[0];
   
   for (int f=1; f<conFeatureN; f++){
   	command2 += ", ";
   	command2 += conFeatureNames[f]; 
   }	
   command2 += " from factors where (product_type= \'";
   
   command2 += capProductName;
   command2 += "\' and product_id=";
   command2 += idStream.str();
   command2 += ");";
   
   res2 = stmt->executeQuery(command2);
   utility = 0.0;
   if (res2->rowsCount()>0){
   	res2->next();
   	for (int f=0; f<conFeatureN; f++){
   		utility += res2->getDouble(conFeatureNames[f]);
   	}	
   }
   
   ustr << utility;
   command +=  ustr.str();
   command += ", ";
   command += idStream.str();  
   
for (int f=0; f<conFeatureN; f++){ 
	command += ", "	;
	value = res->getDouble(conFeatureNames[f]);
	ostringstream vstream;
	vstream << value;
	command +=vstream.str();
}	
for (int f=0; f<boolFeatureN; f++){ // min and max are the same
	command += ", "	;
	value = res->getDouble(boolFeatureNames[f]);
	
	ostringstream vstream;
	vstream << value;
	command +=vstream.str();

}	
command += ", '";
command += res->getString("brand");
command += "');";	
	stmt->execute(command);		
	}
	
	
}	
	
