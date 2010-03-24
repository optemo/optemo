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

    # Hack alert: Should probably not be accessing cls._meta directly.
    @classmethod
    def make_all_m2m_fields_autocreated(cls):
        for field in cls._meta.local_many_to_many:
            field.auto_created = True

    @classmethod
    def gen_create_table_sql(cls):
        return cls.get_db_conn().creation\
               .sql_create_model(cls, no_style())[0][0]

    # Hack alert: All many-to-many fields must have auto_created
    # option set to True.
    @classmethod
    def gen_create_many_to_many_sql(cls):
        return cls.get_db_conn().creation\
               .sql_for_many_to_many(cls, no_style())

    @classmethod
    @transaction.commit_on_success
    def create_table(cls):
        cls.make_all_m2m_fields_autocreated()

        c = cls.get_db_conn().cursor()
        c.execute(cls.gen_create_table_sql())

        for stmt in cls.gen_create_many_to_many_sql():
            c.execute(stmt)

        transaction.set_dirty()

    @classmethod
    def gen_drop_table_sql(cls):
        return cls.get_db_conn().creation\
               .sql_destroy_model(cls, {}, no_style())[0]

    # Hack alert: Should probably not be accessing cls._meta directly.
    @classmethod
    def gen_drop_many_to_many_sql(cls):
        return \
        map(lambda f:
            cls.get_db_conn().creation\
            .sql_destroy_many_to_many(cls, f, no_style()),
            cls._meta.local_many_to_many)

    @classmethod
    @transaction.commit_on_success
    def drop_table(cls):
        c = cls.get_db_conn().cursor()
        c.execute(cls.gen_drop_table_sql())

        for stmts in cls.gen_drop_many_to_many_sql():
            for stmt in stmts:
                c.execute(stmt)

        transaction.set_dirty()

    # Hack alert: Should probably not be accessing cls._meta directly.
    @classmethod
    @transaction.commit_on_success
    def drop_table_if_exists(cls):
        tables = [cls._meta.db_table]        
        tables.extend([f.m2m_db_table() for f
                       in cls._meta.local_many_to_many])

        # Ignore non-existant tables
        tables = set(tables) & \
                 set(cls.get_db_conn().introspection.table_names())

        c = cls.get_db_conn().cursor()
        for table in tables:
            c.execute("DROP TABLE `%s`" % (table,))

        transaction.set_dirty()

class LocalInsertOnlyModel(LocalModel):
    class Meta:
        abstract = True

    def save(self):
        LocalModel.save(self, force_insert=True)
