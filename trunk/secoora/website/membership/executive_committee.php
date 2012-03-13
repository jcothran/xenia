<?php
  include('globals.php');

  // load Zend libs
  require_once 'Zend/Cache.php';
  require_once 'Zend/Loader.php';

  // front end options
  $frontendOptions = array(
    'lifetime' => NULL
  );

  // backend options
  $backendOptions = array(
    'cache_dir' => $cache_dir // Directory where to put the cache files
  );

  @mkdir($cache_dir,0700,true);

  // make cache object
  $cache = Zend_Cache::factory('Output','File',$frontendOptions,$backendOptions);

  if (!($cache->start('excom'))) {
    // load Zend Gdata libraries
    Zend_Loader::loadClass('Zend_Gdata_Spreadsheets');
    Zend_Loader::loadClass('Zend_Gdata_ClientLogin');

    try {
      // connect to API
      $service = Zend_Gdata_Spreadsheets::AUTH_SERVICE_NAME;
      $client = Zend_Gdata_ClientLogin::getHttpClient($user, $pass, $service);
      $service = new Zend_Gdata_Spreadsheets($client);

      // define worksheet query
      // get list feed for query
      $query = new Zend_Gdata_Spreadsheets_ListQuery();
      $query->setSpreadsheetKey($spreadhsheet_key);
      $query->setWorksheetId($people_wksht);
    } catch (Exception $e) {
      die('ERROR: ' . $e->getMessage());
    }
?>

<ol>
<?php
    // print order
    $posts = array('Chairman','Vice Chairman','Secretary','Treasurer','Past Chairman','Staff');
    $a = array();
    foreach ($posts as $p) {
      $a[$p] = array();
    }

    $query->setSpreadsheetQuery('excompost <> ""');
    $listFeed = $service->getListFeed($query);
    foreach ($listFeed->entries as $entry) {
      array_push($a[(string)$entry->getCustomByName('excompost')],'<a href="mailto:'.$entry->getCustomByName('email').'">'.$entry->getCustomByName('name').'</a>');
    }

    foreach ($posts as $p) {
      foreach ($a[$p] as $person) {
        echo '<li>';
        echo $person.', '.$p;
        echo "</li>\n";
      }
    }
?> 
</ol>

<?php
    $cache->end();
  }
?>
