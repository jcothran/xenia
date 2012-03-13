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
  $stateAbbr = "SC";
  if ($_REQUEST['state']) 
  {
    $stateAbbr = $_REQUEST['state'];
  }
  else
  {
  }
  $cachePageName = $stateAbbr . "_members";
  if (!($cache->start($cachePageName))) {
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
      $query->setWorksheetId($membership_wksht);
    } catch (Exception $e) {
      die('ERROR: ' . $e->getMessage());
    }
?>
<table style="font-size: smaller;width:600px">
  <thead>
    <tr bgcolor="#d3f7ff">
      <th style="border: 1px dotted rgb(211, 211, 211);width:250px">Member</th>
      <th style="border: 1px dotted rgb(211, 211, 211);">Organization/Representative</th>
    </tr>
  </thead>
  <tbody>
<?php

    $query->setSpreadsheetQuery('state');
    $listFeed = $service->getListFeed($query);
    $i = 1;
    foreach ($listFeed->entries as $entry) {
      if($entry->getCustomByName('state') == $stateAbbr)
      {
        $bg = '';
        if ($i % 2 == 0) {
          $bg = 'bgcolor="#d3f7ff"';
        }
        echo "<tr $bg>";
        echo '<td style="border: 1px dotted rgb(211, 211, 211);"><a href="' . $entry->getCustomByName('url') .'">'.$entry->getCustomByName('name').'</a></td>';
        echo '<td style="border: 1px dotted rgb(211, 211, 211);">'.$entry->getCustomByName('representativeorganization').'</td>';
        echo "</tr>\n";
        $i++;
      }
    }
?>
  </tbody>
</table>


<?php
    $cache->end();
  }
?>
