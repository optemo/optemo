#!/usr/bin/env python
import sqlite3

class ClusterTotalCountTable():
    table_cols = \
    {
    "cluster_id" : "integer",
    "parent_cluster_id" : "integer",
    "totalcount" : "integer",
    "numchildren" : "integer"
    }

    tablename = None

    def __init__(self, tablename):
        self.tablename = tablename

    def gen_create_totalcount_table_sql(self):
        return \
        "CREATE TABLE " + self.tablename + " " + \
        "(" + \
        ', '.join(map(lambda (k,v): ' '.join([k,v]),
                      self.table_cols.iteritems())) + \
        ", PRIMARY KEY (cluster_id) " + \
        "CONSTRAINT totalcount_check CHECK (totalcount > 0) " + \
        "CONSTRAINT numchildren_check CHECK (numchildren >= 0)" + \
        ")"

    def create_totalcount_table(self, db):
        c = db.cursor()
        c.execute(self.gen_create_totalcount_table_sql())
        db.commit()
        c.close()

    def drop_totalcount_table(self, db):
        c = db.cursor()
        c.execute("DROP TABLE IF EXISTS " + self.tablename)
        db.commit()
        c.close()

    def gen_insert_totalcount_entry_sql(self):
        return \
        "INSERT INTO " + self.tablename + \
        "(cluster_id, parent_cluster_id, numchildren, totalcount) " + \
        "VALUES (?, ?, ?, ?)"

    def add_totalcount_entry(self, db, cluster_id, parent_cluster_id,
                             numchildren, totalcount):
        c = db.cursor()

        try:
            c.execute(self.gen_insert_totalcount_entry_sql(),
                      (cluster_id, parent_cluster_id,
                       numchildren, totalcount))
            db.commit()
            c.close()
        except sqlite3.IntegrityError:
            print "Integrity error: cluster_id == %d" % \
                  (cluster_id,)

            import pdb
            pdb.set_trace()

            raise

    def gen_select_totalcount_entry_sql(self):
        return \
        "SELECT totalcount from " + self.tablename + \
        " WHERE cluster_id = ?"

    def get_totalcount(self, db, cluster_id):
        c = db.cursor()
        c.execute(self.gen_select_totalcount_entry_sql(),
                  (cluster_id,))
        results = c.fetchall()
        c.close()

        totalcount = None

        if len(results) > 0:
            totalcount = results[0][0]

        return totalcount

    def gen_sum_child_totalcounts_sql(self):
        return \
        "SELECT SUM(totalcount) from " + self.tablename + " " + \
        "WHERE parent_cluster_id = ?"

    def sum_child_cluster_totalcounts\
            (self, db, cluster_id, parent_cluster_id, numchildren):
        c = db.cursor()
        c.execute(self.gen_sum_child_totalcounts_sql(), (cluster_id,))

        while (1):
            row = c.fetchone()
            if row == None:
                break

            totalcountsum = row[0]

            if totalcountsum == 0:
                continue

            self.add_totalcount_entry\
            (db, cluster_id, parent_cluster_id,
             numchildren, totalcountsum)

        c.close()
