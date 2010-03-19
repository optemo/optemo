from django.db import models
from django.db import connections, transaction

from django.core.management.color import no_style

class LocalModel(models.Model):
    class Meta:
        abstract = True
        
    default_db = 'default'

    common_table_cols = None
    tablename = None

    @classmethod
    def get_manager(cls):
        return cls.objects.using(cls.default_db)

    @classmethod
    def get_db_conn(cls):
        return connections[cls.default_db]

    @classmethod
    def gen_create_table_sql(cls):
        return cls.get_db_conn().creation.sql_create_model(cls, no_style())[0][0]

    @classmethod
    @transaction.commit_on_success
    def create_table(cls):
        c = cls.get_db_conn().cursor()
        c.execute(cls.gen_create_table_sql())
        transaction.set_dirty()

    @classmethod
    def gen_drop_table_sql(cls):
        return cls.get_db_conn().creation.sql_destroy_model(cls, {}, no_style())[0]

    @classmethod
    @transaction.commit_on_success
    def drop_table(cls):
        c = cls.get_db_conn().cursor()
        c.execute(cls.gen_drop_table_sql())
        transaction.set_dirty()

    @classmethod
    @transaction.commit_on_success
    def drop_table_if_exists(cls):
        c = cls.get_db_conn().cursor()
        c.execute("DROP TABLE IF EXISTS %s" % (cls._meta.db_table))
        transaction.set_dirty()

class LocalInsertOnlyModel(LocalModel):
    class Meta:
        abstract = True

    def save(self):
        LocalModel.save(self, force_insert=True)
