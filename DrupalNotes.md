# Introduction #

This page will contain some notes to various gotchas and setup parameters I've run across with my limited Drupal experience.


# Details #

## Database configuration ##
[Here](http://drupal.org/documentation/install/create-database) and [here](http://drupal.org/node/22675) are pages on the Drupal site on the steps needed to get the database configured.
After doing this, I took a copy of the working SECOORA database and imported it using the following mysql command:
```
mysql -u <username> -p <databasename> < <sqlfilename>

<username> is the username created for Drupal to access the database.
<databasename> is the name of the database for Drupal
<sqlfilename> is the exported SQL file of the production SECOORA website that gets backed up every night.
```

## File paths ##

### settings.php ###
In the /sites/default/settings.php file, we need to configure a couple of items for our test system.
  * $db\_url = 'mysql://username:password@localhost/databasename';
> This is the connection string drupal uses to connect to the mysql database.
  * $base\_url = 'http://129.252.139.80/drupal/htdocs';
> Since I use a subdirectory in my /var/www directory to house the test system, I need to tell drupal what the base URL to use.

### .htaccess ###
Have to configure a RewriteBase to tell Drupal where the base directory is going to be. If I don't do this, the relative paths to images will not work.


## Module configurations ##

### Zend Framework ###
**Requirements**
  * Drupal [module](http://drupal.org/project/zend) from the bottom of the page.
  * Zend [framework](http://framework.zend.com/download)

The key to getting Drupal to recognize the Zend module after you enable it in the admin/modules area is to make sure the path to the framework is known. I added it on my php.ini file. Make sure when you put the path in it goes up to the library directory, not library/Zend.
My ini entry looks like: /var/www/drupal/htdocs/sites/all/modules/zend/library