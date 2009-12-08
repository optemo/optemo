/* Copyright (C) 2004, International Business Machines Corporation 
   and others.  All Rights Reserved.

   This sample program is designed to illustrate programming 
   techniques using CoinLP, has not been thoroughly tested
   and comes without any warranty whatsoever.

   You may copy, modify and distribute this sample program without 
   any restrictions whatsoever and without any payment to anyone.
*/

/* This shows how to provide a simple picture of a matrix.
   The default matrix will print Hello World
*/

#include "ClpSimplex.hpp"
#include "CoinModel.hpp"
#include "CoinHelperFunctions.hpp"
#include "CoinTime.hpp"
#include <iomanip>
#include <cassert>


int main (int argc, const char *argv[])
{
 CoinModel build;	
 int iRow;
int numberRows = model.numberRows();
  const double * rowLower = model.rowLower();
  const double * rowUpper = model.rowUpper();
  int numberColumns = model.numberColumns();
  const double * columnLower = model.columnLower();
  const double * columnUpper = model.columnUpper();
  const double * columnObjective = model.objective();
  for (iRow=0;iRow<numberRows;iRow++) {
    build.setRowBounds(iRow,rowLower[iRow],rowUpper[iRow]);
    // optional name
    build.setRowName(iRow,model.rowName(iRow).c_str());
  }
  // Column bounds and objective
  int iColumn;
  for (iColumn=0;iColumn<numberColumns;iColumn++) {
    build.setColumnLower(iColumn,columnLower[iColumn]);
    build.setColumnUpper(iColumn,columnUpper[iColumn]);
    build.setObjective(iColumn,columnObjective[iColumn]);
    // optional name
    build.setColumnName(iColumn,model.columnName(iColumn).c_str());
  }
  // Adds elements one by one by row (backwards by row)
  for (iRow=numberRows-1;iRow>=0;iRow--) {
    int start = rowStart[iRow];
    for (int j=start;j<start+rowLength[iRow];j++) 
      build(iRow,column[j],element[j]);
  }	

 ClpSimplex model2;
  model2.loadProblem(build);
model2.dual();	
// ClpSimplex  model;
// int status;
// // Keep names
// if (argc<2) {
//   status=model.readMps("o",true);
// } else {
//   status=model.readMps(argv[1],true);
// }
// if (status)
//   exit(10);
//
// int numberColumns = model.numberColumns();
// int numberRows = model.numberRows();
// 
// if (numberColumns>80||numberRows>80) {
//   printf("model too large\n");
//   exit(11);
// }
// printf("This prints x wherever a non-zero elemnt exists in matrix\n\n\n");
//
// char x[81];
//
// int iRow;
// // get row copy
// CoinPackedMatrix rowCopy = *model.matrix();
// rowCopy.reverseOrdering();
// const int * column = rowCopy.getIndices();
// const int * rowLength = rowCopy.getVectorLengths();
// const CoinBigIndex * rowStart = rowCopy.getVectorStarts();
// 
// x[numberColumns]='\0';
// for (iRow=0;iRow<numberRows;iRow++) {
//   memset(x,' ',numberColumns);
//   for (int k=rowStart[iRow];k<rowStart[iRow]+rowLength[iRow];k++) {
//     int iColumn = column[k];
//     x[iColumn]='x';
//   }
//   printf("%s\n",x);
// }
// printf("\n\n");
  return 0;
}    
