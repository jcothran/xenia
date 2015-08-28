# General #

A good intro for getting started with a Django project is [here](https://docs.djangoproject.com/en/dev/intro/tutorial01/).


## Prepping the Database ##
A quick overview of creating a new database [here](http://www.cyberciti.biz/faq/howto-add-postgresql-user-account/).

  1. Create the database user and set the password to use.
```
  CREATE USER tom WITH PASSWORD 'myPassword';
```
  1. Create the database.
```
  CREATE DATABASE jerry;
```
  1. Grant the necessary privileges for the user to operate on the database.
```
  GRANT ALL PRIVILEGES ON DATABASE jerry to tom;
```

In the Django settings\_local.py(or local\_settings.py), you configure your connection like:
```
DATABASES = {
    'default': {
        'ENGINE': 'django.contrib.gis.db.backends.postgis',
        'PORT': '5432',
        'HOST': 'localhost',
        'PASSWORD': 'myPassword',
        'NAME': 'jerry',
        'USER': 'tom',
    }
}

```
Once the database is created, setup the PostGIS tables.
```
sudo -u postgres psql secoora_test -f /usr/share/postgresql/9.3/contrib/postgis-2.1/postgis.sql
```

## Migrating a Model Change ##
> Notes on using South to make model changes and migrate them to the database schema.
  * Initial use.
```
  python manage.py schemamigration <MYAPPNAME> --initial
```

  * Subsequent Changes
```
  python manage.py schemamigration <MYAPPNAME> --auto
```
> If the above migration was successful:
```
  python manage.py migrate <MYAPPNAME>
```