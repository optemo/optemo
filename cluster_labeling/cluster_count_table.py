#!/usr/bin/env python
class ClusterCountTable():
    common_table_cols = \
    {
    "cluster_id" : "integer",
    "parent_cluster_id" : "integer",
    "word" : "text",
    "count" : "integer",
    "numchildren" : "integer"
    }

    tablename = None

    def __init__(self, tablename):
        self.tablename = tablename

    def gen_create_count_table_sql(self, extracols = {}):
        table_cols = self.common_table_cols

        if extracols != {}:
            table_cols = list(table_cols.iteritems())
            table_cols = dict(table_cols.extend(extracols.iteritems()))

        return \
        "CREATE TABLE " + self.tablename + " " + \
        "(" + \
        ', '.join(map(lambda (k,v): ' '.join([k,v]),
                      table_cols.iteritems())) + \
        ", PRIMARY KEY (cluster_id, word), " + \
        "CONSTRAINT count_check CHECK (count > 0) " + \
        "CONSTRAINT numchildren_check CHECK (numchildren >= 0)" + \
        ")"

    def create_count_table(self, db):
        c = db.cursor()
        c.execute(self.gen_create_count_table_sql())
        db.commit()
        c.close()

    def drop_count_table(self, db):
        c = db.cursor()
        c.execute("DROP TABLE IF EXISTS " + self.tablename)
        db.commit()
        c.close()

    def gen_insert_count_entry_sql(self):
        return \
        "INSERT INTO " + self.tablename + \
        "(cluster_id, parent_cluster_id, numchildren, word, count) " + \
        "VALUES (?, ?, ?, ?, ?)"

    def add_count_entry(self, db, cluster_id, parent_cluster_id,
                        numchildren, word, count):
        c = db.cursor()

        try:
            c.execute(self.gen_insert_count_entry_sql(),
                      (cluster_id, parent_cluster_id,
                       numchildren, word, count))
            db.commit()
            c.close()
        except sqlite3.IntegrityError:
            print "Integrity error: (cluster_id, word) == (%d, %s)" % \
                  (cluster_id, word)

            import pdb
            pdb.set_trace()

            raise

    def gen_select_count_entry_sql(self):
        return \
        "SELECT count from " + self.tablename + \
        " WHERE cluster_id = ? AND word = ?"

    def get_count(self, db, cluster_id, word):
        c = db.cursor()
        c.execute(self.gen_select_count_entry_sql(),
                  (cluster_id, word))
        results = c.fetchall()
        c.close()

        wordcount = None

        if len(results) > 0:
            wordcount = results[0][0]

        return wordcount

    def gen_sum_child_counts_sql(self):
        return \
        "SELECT word, SUM(count) from " + self.tablename + " " + \
        "WHERE parent_cluster_id = ? GROUP BY word"

    def sum_child_cluster_counts(self, db,
                                 cluster_id, parent_cluster_id,
                                 numchildren):
        c = db.cursor()
        c.execute(self.gen_sum_child_counts_sql(), (cluster_id,))

        while (1):
            row = c.fetchone()
            if row == None:
                break

            word, countsum = row[0:2]
            self.add_count_entry(db, cluster_id, parent_cluster_id,
                                 numchildren, word, countsum)

        c.close()

    def add_counts_from(self, db, cluster, dict):
        numchildren = cluster.get_children().count()
        for (word, count) in dict.iteritems():
            self.add_count_entry(db, cluster.id, cluster.parent_id,
                                 numchildren, word, count)
