string queryClusters(string productName, string region, int version, int layer){
		
	string command = "";
	ostringstream vs;
	vs << version;
	ostringstream layerStream;
	layerStream << layer; 
	command += layerStream.str();
	command = "SELECT * FROM clusters WHERE (product_type=\'" + productName + "_" +  region + "\' AND version="+ vs.str()+" AND layer="+ 
				layerStream.str() + ");";
	return command;			
}