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

#ifndef _MYSQL_METADATA_H_
#define _MYSQL_METADATA_H_

#include "dbciface/metadata.h"

namespace sql
{
namespace mysql
{

class MySQL_Connection;
class sql::ResultSet;

class MySQL_ConnectionMetaData : public sql::DatabaseMetaData
{
	MySQL_Connection *connection;
	unsigned long server_version;

public:
	MySQL_ConnectionMetaData(MySQL_Connection *conn);

	virtual ~MySQL_ConnectionMetaData();

	bool allProceduresAreCallable() const;

	bool allTablesAreSelectable() const;

	bool dataDefinitionCausesTransactionCommit() const;

	bool dataDefinitionIgnoredInTransactions() const;

	bool deletesAreDetected(int type) const;

	bool doesMaxRowSizeIncludeBlobs() const;

	sql::ResultSet * getAttributes(std::string& catalog, std::string& schemaPattern, std::string& typeNamePattern, std::string& attributeNamePattern) const;

	sql::ResultSet * getBestRowIdentifier(std::string& catalog, std::string& schema, std::string& table, int scope, bool nullable) const;

	sql::ResultSet * getCatalogs() const;

	const std::string& getCatalogSeparator() const;

	const std::string& getCatalogTerm() const;

	sql::ResultSet * getColumns(std::string& catalog, std::string& schemaPattern, std::string& tableNamePattern, std::string& columnNamePattern) const;

	sql::Connection * getConnection() const;

	int getDatabaseMajorVersion() const;

	int getDatabaseMinorVersion() const;

	const std::string& getDatabaseProductName() const;

	const std::string& getDatabaseProductVersion() const;

	int getDefaultTransactionIsolation() const;

	int getDriverMajorVersion() const;

	int getDriverMinorVersion() const;

	const std::string& getDriverName() const;

	std::string getDriverVersion() const;

	const std::string& getExtraNameCharacters() const;

	const std::string& getIdentifierQuoteString() const;

	sql::ResultSet * getImportedKeys(std::string& catalog, std::string& schema, std::string& table) const;

	sql::ResultSet * getIndexInfo(std::string& catalog, std::string& schema, std::string& table, bool unique, bool approximate) const;

	int getCDBCMajorVersion() const;

	int getCDBCMinorVersion() const;

	int getMaxBinaryLiteralLength() const;

	int getMaxCatalogNameLength() const;

	int getMaxCharLiteralLength() const;

	int getMaxColumnNameLength() const;

	int getMaxColumnsInGroupBy() const;

	int getMaxColumnsInIndex() const;

	int getMaxColumnsInOrderBy() const;

	int getMaxColumnsInSelect() const;

	int getMaxColumnsInTable() const;

	int getMaxConnections() const;

	int getMaxCursorNameLength() const;

	int getMaxIndexLength() const;

	int getMaxProcedureNameLength() const;

	int getMaxRowSize() const;

	int getMaxSchemaNameLength() const;

	int getMaxStatementLength() const;

	int getMaxStatements() const;

	int getMaxTableNameLength() const;

	int getMaxTablesInSelect() const;

	int getMaxUserNameLength() const;

	std::string getNumericFunctions() const;

	sql::ResultSet * getPrimaryKeys(std::string& catalog, std::string& schema, std::string& table) const;

	sql::ResultSet * getProcedures(std::string& catalog, std::string& schemaPattern, std::string& procedureNamePattern) const;

	const std::string& getProcedureTerm() const;

	int getResultSetHoldability() const;

	sql::ResultSet * getSchemas() const;

	const std::string& getSchemaTerm() const;

	const std::string& getSearchStringEscape() const;

	const std::string& getSQLKeywords() const;

	int getSQLStateType() const;

	const std::string& getStringFunctions() const;

	sql::ResultSet * getSuperTables(std::string& catalog, std::string& schemaPattern, std::string& tableNamePattern) const;

	sql::ResultSet * getSuperTypes(std::string& catalog, std::string& schemaPattern, std::string& typeNamePattern) const;

	const std::string& getSystemFunctions() const;

	sql::ResultSet * getTablePrivileges(std::string& catalog, std::string& schemaPattern, std::string& tableNamePattern) const;

	sql::ResultSet * getTables(std::string& catalog, std::string& schemaPattern, std::string& tableNamePattern, std::list<std::string> &types) const;

	sql::ResultSet * getTableTypes() const;

	const std::string& getTimeDateFunctions() const;

	sql::ResultSet * getTypeInfo() const;

	sql::ResultSet * getUDTs(std::string& catalog, std::string& schemaPattern, std::string& typeNamePattern, std::list<int> &types) const;

	std::string getUserName() const;

	sql::ResultSet * getVersionColumns(std::string& catalog, std::string& schema, std::string& table) const;

	bool insertsAreDetected(int type) const;

	bool isCatalogAtStart() const;

	bool isReadOnly() const;

	bool nullPlusNonNullIsNull() const;

	bool nullsAreSortedAtEnd() const;

	bool nullsAreSortedAtStart() const;

	bool nullsAreSortedHigh() const;

	bool nullsAreSortedLow() const;

	bool othersDeletesAreVisible(int type) const;

	bool othersInsertsAreVisible(int type) const;

	bool othersUpdatesAreVisible(int type) const;

	bool ownDeletesAreVisible(int type) const;

	bool ownInsertsAreVisible(int type) const;

	bool ownUpdatesAreVisible(int type) const;

	bool storesLowerCaseIdentifiers() const;

	bool storesLowerCaseQuotedIdentifiers() const;

	bool storesMixedCaseIdentifiers() const;

	bool storesMixedCaseQuotedIdentifiers() const;

	bool storesUpperCaseIdentifiers() const;

	bool storesUpperCaseQuotedIdentifiers() const;

	bool supportsAlterTableWithAddColumn() const;

	bool supportsAlterTableWithDropColumn() const;

	bool supportsANSI92EntryLevelSQL() const;

	bool supportsANSI92FullSQL() const;

	bool supportsANSI92IntermediateSQL() const;

	bool supportsBatchUpdates() const;

	bool supportsCatalogsInDataManipulation() const;

	bool supportsCatalogsInIndexDefinitions() const;

	bool supportsCatalogsInPrivilegeDefinitions() const;

	bool supportsCatalogsInProcedureCalls() const;

	bool supportsCatalogsInTableDefinitions() const;

	bool supportsColumnAliasing() const;

	bool supportsConvert() const;

	bool supportsCoreSQLGrammar() const;

	bool supportsCorrelatedSubqueries() const;

	bool supportsDataDefinitionAndDataManipulationTransactions() const;

	bool supportsDataManipulationTransactionsOnly() const;

	bool supportsDifferentTableCorrelationNames() const;

	bool supportsExpressionsInOrderBy() const;

	bool supportsExtendedSQLGrammar() const;

	bool supportsFullOuterJoins() const;

	bool supportsGetGeneratedKeys() const;

	bool supportsGroupBy() const;

	bool supportsGroupByBeyondSelect() const;

	bool supportsGroupByUnrelated() const;

	bool supportsLikeEscapeClause() const;

	bool supportsLimitedOuterJoins() const;

	bool supportsMinimumSQLGrammar() const;

	bool supportsMixedCaseIdentifiers() const;

	bool supportsMixedCaseQuotedIdentifiers() const;

	bool supportsMultipleOpenResults() const;

	bool supportsMultipleResultSets() const;

	bool supportsMultipleTransactions() const;

	bool supportsNamedParameters() const;

	bool supportsNonNullableColumns() const;

	bool supportsOpenCursorsAcrossCommit() const;

	bool supportsOpenCursorsAcrossRollback() const;

	bool supportsOpenStatementsAcrossCommit() const;

	bool supportsOpenStatementsAcrossRollback() const;

	bool supportsOrderByUnrelated() const;

	bool supportsOuterJoins() const;

	bool supportsPositionedDelete() const;

	bool supportsPositionedUpdate() const;

	bool supportsResultSetHoldability(int holdability) const;

	bool supportsResultSetType(int type) const;

	bool supportsSavepoints() const;

	bool supportsSchemasInDataManipulation() const;

	bool supportsSchemasInIndexDefinitions() const;

	bool supportsSchemasInPrivilegeDefinitions() const;

	bool supportsSchemasInProcedureCalls() const;

	bool supportsSchemasInTableDefinitions() const;

	bool supportsSelectForUpdate() const;

	bool supportsStatementPooling() const;

	bool supportsStoredProcedures() const;

	bool supportsSubqueriesInComparisons() const;

	bool supportsSubqueriesInExists() const;

	bool supportsSubqueriesInIns() const;

	bool supportsSubqueriesInQuantifieds() const;

	bool supportsTableCorrelationNames() const;

	bool supportsTransactionIsolationLevel(int level) const;

	bool supportsTransactions() const;

	bool supportsTypeConversion() const;

	bool supportsUnion() const;

	bool supportsUnionAll() const;

	bool updatesAreDetected(int type) const;

	bool usesLocalFilePerTable() const;

	bool usesLocalFiles() const;

	sql::ResultSet *getSchemata(const std::string& catalogName = "") const;

	sql::ResultSet *getSchemaObjects(const std::string& catalogName = "", 
								const std::string& schemaName = "",
								const std::string& objectType = "") const;

	// Returns all schema object types this database supports
	sql::ResultSet *getSchemaObjectTypes() const;

private:
	bool matchTable(std::string &sPattern, std::string & tPattern, std::string & schema, std::string & table) const;

	/* Prevent use of these */
	MySQL_ConnectionMetaData();
	MySQL_ConnectionMetaData(const MySQL_ConnectionMetaData &);
	void operator=(MySQL_ConnectionMetaData &);
};

}; /* namespace mysql */
}; /* namespace sql */
#endif // _MYSQL_METADATA_H_

/*
 * Local variables:
 * tab-width: 4
 * c-basic-offset: 4
 * End:
 * vim600: noet sw=4 ts=4 fdm=marker
 * vim<600: noet sw=4 ts=4
 */
