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

  if (!($cache->start($post_col))) {
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

<?php
    function labelBOD($entry) {
      if ($entry->getCustomByName('bodindustryprivatesector') == 'Y' || $entry->getCustomByName('bodacademicresearcheducationsector') == 'Y' || $entry->getCustomByName('bodpublicagenciesnonprofitothersector') == 'Y' || $entry->getCustomByName('bodatlarge') == 'Y' || $entry->getCustomByName('bodpublicseat') == 'Y' || $entry->getCustomByName('bodaffiliateseat') == 'Y' || $entry->getCustomByName('bodsustainingseat') == 'Y') {
        return ' (B)';
      }
      else {
        return '';
      }
    }

    // print order
    $posts = array('Chair','Co-Chair','Board Liaison','Member','Staff');
    $a = array();
    foreach ($posts as $p) {
      $a[$p] = array();
    }

    $query->setSpreadsheetQuery($post_col.' <> ""');
    $listFeed = $service->getListFeed($query);
    foreach ($listFeed->entries as $entry) {
      $board = labelBOD($entry);
      array_push($a[(string)$entry->getCustomByName($post_col)],'<a href="mailto:'.$entry->getCustomByName('email').'">'.$entry->getCustomByName('name').'</a>'.$board.', '.$entry->getCustomByName('institutionorganization'));
    }

    foreach ($posts as $p) {
      if (count($a[$p]) > 0) {
        $s = '';
        if (count($a[$p]) > 1 && $p != 'Staff') {
          $s = 's';
        }
        echo "<p><em><strong>$p$s</strong></em><br />";
        foreach ($a[$p] as $person) {
          echo $person."<br />";
        }
      }
    }
    $cache->end();
  }
?> 
