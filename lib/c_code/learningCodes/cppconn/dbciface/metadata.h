/* Copyright (C) 2007-2008 Sun Microsystems

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; version 2 of the License.

   There are special exceptions to the terms and conditions of the GPL 
   as it is applied to this software. View the full text of the 
   exception in file EXCEPTIONS-CONNECTOR-C++ in the directory of this 
   software distribution.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#ifndef _METADATA_H_
#define _METADATA_H_

#include <string>

namespace sql
{

class ResultSet;

class DatabaseMetaData
{
public:
	enum
	{
		attributeNoNulls,
		attributeNullable,
		attributeNullableUnknown
	};
	enum
	{
		bestRowTemporary = 0,
		bestRowTransaction = 1,
		bestRowSession = 2
	};
	enum
	{
		bestRowUnknown = 0,
		bestRowPseudo = 1,
		bestRowNotPseudo = 2
	};
	enum
	{
		columnNoNulls,
		columnNullable,
		columnNullableUnknown
	};
	enum
	{
		importedKeyCascade,
		importedKeyInitiallyDeferred,
		importedKeyInitiallyImmediate,
		importedKeyNoAction,
		importedKeyNotDeferrable,
		importedKeyRestrict,
		importedKeySetDefault,
		importedKeySetNull
	};
	enum
	{
		procedureColumnIn,
		procedureColumnInOut,
		procedureColumnOut,
		procedureColumnResult,
		procedureColumnReturn,
		procedureColumnUnknown,
		procedureNoNulls,
		procedureNoResult,
		procedureNullable,
		procedureNullableUnknown,
		procedureResultUnknown,
		procedureReturnsResult
	};
	enum
	{
		sqlStateSQL99,
		sqlStateXOpen
	};
	enum
	{
		tableIndexClustered,
		tableIndexHashed,
		tableIndexOther,
		tableIndexStatistic
	};
	enum
	{
		versionColumnUnknown = 0,
		versionColumnNotPseudo = 1,
		versionColumnPseudo = 2
	};
	enum
	{
		typeNoNulls = 0,
		typeNullable = 1,
		typeNullableUnknown = 2
	};
	enum
	{
		typePredNone = 0,
		typePredChar = 1,
		typePredBasic= 2,
		typeSearchable = 3
	};

	virtual ~DatabaseMetaData() {}

	virtual	bool allProceduresAreCallable() const = 0;

	virtual	bool allTablesAreSelectable() const = 0;

	virtual	bool dataDefinitionCausesTransactionCommit() const = 0;

	virtual	bool dataDefinitionIgnoredInTransactions() const = 0;

	virtual	bool deletesAreDetected(int type) const = 0;

	virtual	bool doesMaxRowSizeIncludeBlobs() const = 0;

	virtual	ResultSet * getAttributes(std::string& catalog, std::string& schemaPattern, std::string& typeNamePattern, std::string& attributeNamePattern) const = 0;

	virtual	ResultSet * getBestRowIdentifier(std::string& catalog, std::string& schema, std::string& table, int scope, bool nullable) const = 0;

	virtual	ResultSet * getCatalogs() const = 0;

	virtual	const std::string& getCatalogSeparator() const = 0;

	virtual	const std::string& getCatalogTerm() const = 0;

	virtual	ResultSet * getColumns(std::string& catalog, std::string& schemaPattern, std::string& tableNamePattern, std::string& columnNamePattern) const = 0;

	virtual	Connection * getConnection() const = 0;

	virtual	int getDatabaseMajorVersion() const = 0;

	virtual	int getDatabaseMinorVersion() const = 0;

	virtual	const std::string& getDatabaseProductName() const = 0;

	virtual	const std::string& getDatabaseProductVersion() const = 0;

	virtual	int getDefaultTransactionIsolation() const = 0;

	virtual	int getDriverMajorVersion() const = 0;

	virtual	int getDriverMinorVersion() const = 0;

	virtual	const std::string& getDriverName() const = 0;

	virtual	std::string getDriverVersion() const = 0;

	virtual	const std::string& getExtraNameCharacters() const = 0;

	virtual	const std::string& getIdentifierQuoteString() const = 0;

	virtual	ResultSet * getImportedKeys(std::string& catalog, std::string& schema, std::string& table) const = 0;

	virtual	ResultSet * getIndexInfo(std::string& catalog, std::string& schema, std::string& table, bool unique, bool approximate) const = 0;

	virtual	int getCDBCMajorVersion() const = 0;

	virtual	int getCDBCMinorVersion() const = 0;

	virtual	int getMaxBinaryLiteralLength() const = 0;

	virtual	int getMaxCatalogNameLength() const = 0;

	virtual	int getMaxCharLiteralLength() const = 0;

	virtual	int getMaxColumnNameLength() const = 0;

	virtual	int getMaxColumnsInGroupBy() const = 0;

	virtual	int getMaxColumnsInIndex() const = 0;

	virtual	int getMaxColumnsInOrderBy() const = 0;

	virtual	int getMaxColumnsInSelect() const = 0;

	virtual	int getMaxColumnsInTable() const = 0;

	virtual	int getMaxConnections() const = 0;

	virtual	int getMaxCursorNameLength() const = 0;

	virtual	int getMaxIndexLength() const = 0;

	virtual	int getMaxProcedureNameLength() const = 0;

	virtual	int getMaxRowSize() const = 0;

	virtual	int getMaxSchemaNameLength() const = 0;

	virtual	int getMaxStatementLength() const = 0;

	virtual	int getMaxStatements() const = 0;

	virtual	int getMaxTableNameLength() const = 0;

	virtual	int getMaxTablesInSelect() const = 0;

	virtual	int getMaxUserNameLength() const = 0;

	virtual	std::string getNumericFunctions() const = 0;

	virtual	ResultSet * getPrimaryKeys(std::string& catalog, std::string& schema, std::string& table) const = 0;

	virtual	ResultSet * getProcedures(std::string& catalog, std::string& schemaPattern, std::string& procedureNamePattern) const = 0;

	virtual	const std::string& getProcedureTerm() const = 0;

	virtual	int getResultSetHoldability() const = 0;

	virtual	ResultSet * getSchemas() const = 0;

	virtual	const std::string& getSchemaTerm() const = 0;

	virtual	const std::string& getSearchStringEscape() const = 0;

	virtual	const std::string& getSQLKeywords() const = 0;

	virtual	int getSQLStateType() const = 0;

	virtual const std::string& getStringFunctions() const = 0;

	virtual	ResultSet * getSuperTables(std::string& catalog, std::string& schemaPattern, std::string& tableNamePattern) const = 0;

	virtual	ResultSet * getSuperTypes(std::string& catalog, std::string& schemaPattern, std::string& typeNamePattern) const = 0;

	virtual	const std::string& getSystemFunctions() const = 0;

	virtual	ResultSet * getTablePrivileges(std::string& catalog, std::string& schemaPattern, std::string& tableNamePattern) const = 0;

	virtual	ResultSet * getTables(std::string& catalog, std::string& schemaPattern, std::string& tableNamePattern, std::list<std::string> &types) const = 0;

	virtual	ResultSet * getTableTypes() const = 0;

	virtual	const std::string& getTimeDateFunctions() const = 0;

	virtual	ResultSet * getTypeInfo() const = 0;

	virtual	ResultSet * getUDTs(std::string& catalog, std::string& schemaPattern, std::string& typeNamePattern, std::list<int> &types) const = 0;

	virtual std::string getUserName() const = 0;

	virtual ResultSet * getVersionColumns(std::string& catalog, std::string& schema, std::string& table) const = 0;

	virtual bool insertsAreDetected(int type) const = 0;

	virtual bool isCatalogAtStart() const = 0;

	virtual bool isReadOnly() const = 0;

	virtual bool nullPlusNonNullIsNull() const = 0;

	virtual bool nullsAreSortedAtEnd() const = 0;

	virtual bool nullsAreSortedAtStart() const = 0;

	virtual bool nullsAreSortedHigh() const = 0;

	virtual bool nullsAreSortedLow() const = 0;

	virtual bool othersDeletesAreVisible(int type) const = 0;

	virtual bool othersInsertsAreVisible(int type) const = 0;

	virtual bool othersUpdatesAreVisible(int type) const = 0;

	virtual bool ownDeletesAreVisible(int type) const = 0;

	virtual bool ownInsertsAreVisible(int type) const = 0;

	virtual bool ownUpdatesAreVisible(int type) const = 0;

	virtual bool storesLowerCaseIdentifiers() const = 0;

	virtual bool storesLowerCaseQuotedIdentifiers() const = 0;

	virtual bool storesMixedCaseIdentifiers() const = 0;

	virtual bool storesMixedCaseQuotedIdentifiers() const = 0;

	virtual bool storesUpperCaseIdentifiers() const = 0;

	virtual bool storesUpperCaseQuotedIdentifiers() const = 0;

	virtual bool supportsAlterTableWithAddColumn() const = 0;

	virtual bool supportsAlterTableWithDropColumn() const = 0;

	virtual bool supportsANSI92EntryLevelSQL() const = 0;

	virtual bool supportsANSI92FullSQL() const = 0;

	virtual bool supportsANSI92IntermediateSQL() const = 0;

	virtual bool supportsBatchUpdates() const = 0;

	virtual bool supportsCatalogsInDataManipulation() const = 0;

	virtual bool supportsCatalogsInIndexDefinitions() const = 0;

	virtual bool supportsCatalogsInPrivilegeDefinitions() const = 0;

	virtual bool supportsCatalogsInProcedureCalls() const = 0;

	virtual bool supportsCatalogsInTableDefinitions() const = 0;

	virtual bool supportsColumnAliasing() const = 0;

	virtual bool supportsConvert() const = 0;

	virtual bool supportsCoreSQLGrammar() const = 0;

	virtual bool supportsCorrelatedSubqueries() const = 0;

	virtual bool supportsDataDefinitionAndDataManipulationTransactions() const = 0;

	virtual bool supportsDataManipulationTransactionsOnly() const = 0;

	virtual bool supportsDifferentTableCorrelationNames() const = 0;

	virtual bool supportsExpressionsInOrderBy() const = 0;

	virtual bool supportsExtendedSQLGrammar() const = 0;

	virtual bool supportsFullOuterJoins() const = 0;

	virtual bool supportsGetGeneratedKeys() const = 0;

	virtual bool supportsGroupBy() const = 0;

	virtual bool supportsGroupByBeyondSelect() const = 0;

	virtual bool supportsGroupByUnrelated() const = 0;

	virtual bool supportsLikeEscapeClause() const = 0;

	virtual bool supportsLimitedOuterJoins() const = 0;

	virtual bool supportsMinimumSQLGrammar() const = 0;

	virtual bool supportsMixedCaseIdentifiers() const = 0;

	virtual bool supportsMixedCaseQuotedIdentifiers() const = 0;

	virtual bool supportsMultipleOpenResults() const = 0;

	virtual bool supportsMultipleResultSets() const = 0;

	virtual bool supportsMultipleTransactions() const = 0;

	virtual bool supportsNamedParameters() const = 0;

	virtual bool supportsNonNullableColumns() const = 0;

	virtual bool supportsOpenCursorsAcrossCommit() const = 0;

	virtual bool supportsOpenCursorsAcrossRollback() const = 0;

	virtual bool supportsOpenStatementsAcrossCommit() const = 0;

	virtual bool supportsOpenStatementsAcrossRollback() const = 0;

	virtual bool supportsOrderByUnrelated() const = 0;

	virtual bool supportsOuterJoins() const = 0;

	virtual bool supportsPositionedDelete() const = 0;

	virtual bool supportsPositionedUpdate() const = 0;

	virtual bool supportsResultSetHoldability(int holdability) const = 0;

	virtual bool supportsResultSetType(int type) const = 0;

	virtual bool supportsSavepoints() const = 0;

	virtual bool supportsSchemasInDataManipulation() const = 0;

	virtual bool supportsSchemasInIndexDefinitions() const = 0;

	virtual bool supportsSchemasInPrivilegeDefinitions() const = 0;

	virtual bool supportsSchemasInProcedureCalls() const = 0;

	virtual bool supportsSchemasInTableDefinitions() const = 0;

	virtual bool supportsSelectForUpdate() const = 0;

	virtual bool supportsStatementPooling() const = 0;

	virtual bool supportsStoredProcedures() const = 0;

	virtual bool supportsSubqueriesInComparisons() const = 0;

	virtual bool supportsSubqueriesInExists() const = 0;

	virtual bool supportsSubqueriesInIns() const = 0;

	virtual bool supportsSubqueriesInQuantifieds() const = 0;

	virtual bool supportsTableCorrelationNames() const = 0;

	virtual bool supportsTransactionIsolationLevel(int level) const = 0;

	virtual bool supportsTransactions() const = 0;

	virtual bool supportsTypeConversion() const = 0; /* SDBC */

	virtual bool supportsUnion() const = 0;

	virtual bool supportsUnionAll() const = 0;

	virtual bool updatesAreDetected(int type) const = 0;

	virtual bool usesLocalFilePerTable() const = 0;

	virtual bool usesLocalFiles() const = 0;

	virtual ResultSet *getSchemata(const std::string& catalogName = "") const = 0;

	virtual ResultSet *getSchemaObjects(const std::string& catalogName = "",
										const std::string& schemaName = "",
										const std::string& objectType = "") const = 0;

	virtual ResultSet *getSchemaObjectTypes() const = 0;
};


}; /* namespace sql */

#endif // _METADATA_H_
