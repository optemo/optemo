//preProcessing.h
#include <map>
#include "preProcessing/preClustering.h"
#include "preProcessing/parseInput.h"
#include "preProcessing/generateOutput.h"

//preClustering sets variables appropriately based to generate clusters and node tables for each product

string preClustering(string* varNames, map<const string, int>productNames, string productName, string* conFeatureNames, string* catFeatureNames, string* boolFeatureNames, string* indicatorNames);


// parseInput takes the string passed by the ruby code, parse it and store the values for appropriate variables

int parseInput(string* varNames, map<const string, int>productNames, string productName, string argument, string* brands, bool* catFilteredFeatures, bool* conFilteredFeatures, 
	bool* boolFilteredFeatures, double** filteredRange, int varNamesN, string* conFeatureNames, string* catFeatureNames, string* indicatorNames);


// generate output generated the string in yml format for ruby

string generateOutput(string* indicatorNames, string* conFeatureNames, int conFeatureN, int productN, double** conFeatureRange, string* varNames, int repW, int* reps, bool reped, 
	int* clusterIDs, int** childrenIDs, int* childrenCount, int* mergedClusterIDs, int* clusterCounts, int** indicators, double** bucketCount, int bucketDiv);
