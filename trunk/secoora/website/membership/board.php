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

  if (!($cache->start('bod'))) {
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

<table border="0" width="70%">
  <tbody>
    <tr><td colspan="3"><strong>Industry/Private Sector : Term Limit (yr)</strong></td></tr>
<?php
    $query->setSpreadsheetQuery('bodindustryprivatesector = "Y"');
    $listFeed = $service->getListFeed($query);
    foreach ($listFeed->entries as $entry) {
      echo '<tr>';
      echo '<td width="33%">'.$entry->getCustomByName('name').'</td>';
      echo '<td width="35%">'.$entry->getCustomByName('bodtermlimit').' (as of '.$entry->getCustomByName('bodtermasof').')</td>';
      echo '<td width="33%"><a href="mailto:'.$entry->getCustomByName('email').'">'.$entry->getCustomByName('email').'</a></td>';
      echo "</tr>\n";
    }
?> 

    <tr><td colspan="3">&nbsp;</td></tr>

    <tr><td colspan="3"><strong>Academic/Research/Education Sector : Term Limit (yr)</strong></td></tr>
<?php
    $query->setSpreadsheetQuery('bodacademicresearcheducationsector = "Y"');
    $listFeed = $service->getListFeed($query);
    foreach ($listFeed->entries as $entry) {
      echo '<tr>';
      echo '<td width="33%">'.$entry->getCustomByName('name').'</td>';
      echo '<td width="35%">'.$entry->getCustomByName('bodtermlimit').' (as of '.$entry->getCustomByName('bodtermasof').')</td>';
      echo '<td width="33%"><a href="mailto:'.$entry->getCustomByName('email').'">'.$entry->getCustomByName('email').'</a></td>';
      echo "</tr>\n";
    }
?>

    <tr><td colspan="3">&nbsp;</td></tr>

    <tr><td colspan="3"><strong>Public Agencies/Non Profit/Other Sector : Term Limit (yr)</strong></td></tr>
<?php
    $query->setSpreadsheetQuery('bodpublicagenciesnonprofitothersector = "Y"');
    $listFeed = $service->getListFeed($query);
    foreach ($listFeed->entries as $entry) {
      echo '<tr>';
      echo '<td width="33%">'.$entry->getCustomByName('name').'</td>';
      echo '<td width="35%">'.$entry->getCustomByName('bodtermlimit').' (as of '.$entry->getCustomByName('bodtermasof').')</td>';
      echo '<td width="33%"><a href="mailto:'.$entry->getCustomByName('email').'">'.$entry->getCustomByName('email').'</a></td>';
      echo "</tr>\n";
    }
?>

    <tr><td colspan="3">&nbsp;</td></tr>

    <tr><td colspan="3"><strong>At-Large : Term Limit (yr)</strong></td></tr>
<?php
    $query->setSpreadsheetQuery('bodatlarge = "Y"');
    $listFeed = $service->getListFeed($query);
    foreach ($listFeed->entries as $entry) {
      echo '<tr>';
      echo '<td width="33%">'.$entry->getCustomByName('name').' ('.$entry->getCustomByName('state').')</td>';
      echo '<td width="35%">'.$entry->getCustomByName('bodtermlimit').' (as of '.$entry->getCustomByName('bodtermasof').')</td>';
      echo '<td width="33%"><a href="mailto:'.$entry->getCustomByName('email').'">'.$entry->getCustomByName('email').'</a></td>';
      echo "</tr>\n";
    }
?>

    <tr><td colspan="3">&nbsp;</td></tr>

    <tr><td colspan="3"><strong>Public Seats : Term Limit (yr)</strong></td></tr>
<?php
    $query->setSpreadsheetQuery('bodpublicseat = "Y"');
    $listFeed = $service->getListFeed($query);
    foreach ($listFeed->entries as $entry) {
      echo '<tr>';
      echo '<td width="33%">'.$entry->getCustomByName('name').'</td>';
      echo '<td width="35%">'.$entry->getCustomByName('bodtermlimit').' (as of '.$entry->getCustomByName('bodtermasof').')</td>';
      echo '<td width="33%"><a href="mailto:'.$entry->getCustomByName('email').'">'.$entry->getCustomByName('email').'</a></td>';
      echo "</tr>\n";
    }
?>

    <tr><td colspan="3">&nbsp;</td></tr>

    <tr><td colspan="3"><strong>Affiliate Seats : Term Limit (yr)</strong></td></tr>
<?php
    $query->setSpreadsheetQuery('bodaffiliateseat = "Y"');
    $listFeed = $service->getListFeed($query);
    foreach ($listFeed->entries as $entry) {
      echo '<tr>';
      echo '<td width="33%">'.$entry->getCustomByName('name').'</td>';
      echo '<td width="35%">'.$entry->getCustomByName('bodtermlimit').' (as of '.$entry->getCustomByName('bodtermasof').')</td>';
      echo '<td width="33%"><a href="mailto:'.$entry->getCustomByName('email').'">'.$entry->getCustomByName('email').'</a></td>';
      echo "</tr>\n";
    }
?>

    <tr><td colspan="3">&nbsp;</td></tr>

    <tr><td colspan="3"><strong>Sustaining Seats : Term Limit (yr)</strong></td></tr>
<?php
    $query->setSpreadsheetQuery('bodsustainingseat = "Y"');
    $listFeed = $service->getListFeed($query);
    foreach ($listFeed->entries as $entry) {
      echo '<tr>';
      echo '<td width="33%">'.$entry->getCustomByName('name').'</td>';
      echo '<td width="35%">'.$entry->getCustomByName('bodtermlimit').' (as of '.$entry->getCustomByName('bodtermasof').')</td>';
      echo '<td width="33%"><a href="mailto:'.$entry->getCustomByName('email').'">'.$entry->getCustomByName('email').'</a></td>';
      echo "</tr>\n";
    }
    
?>

  </tbody>
</table>

<?php
    $cache->end();
  }
?>
