<?php
  header('Content-type: application/vnd.google-earth.kml+xml');
  header('Content-Disposition: attachment; filename=secoora_membership.kml');

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

  if (!($cache->start('members_kml'))) {
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

    // Creates the Document.
    $dom = new DOMDocument('1.0', 'UTF-8');

    // Creates the root KML element and appends it to the root document.
    $node = $dom->createElementNS('http://earth.google.com/kml/2.1', 'kml');
    $parNode = $dom->appendChild($node);

    // Creates a KML Document element and append it to the KML element.
    $dnode = $dom->createElement('Document');
    $docNode = $parNode->appendChild($dnode);

    $styleNode = $dom->CreateElement('Style');
    $styleNode->setAttribute('id','yellow');
    $iconStyleNode = $dom->CreateElement('IconStyle');
    $iconNode = $dom->CreateElement('Icon');
    $iconNode->appendChild($dom->CreateElement('href','http://maps.google.com/mapfiles/kml/paddle/ylw-blank.png'));
    $iconStyleNode->appendChild($iconNode);
    $styleNode->appendChild($iconStyleNode);
    $docNode->appendChild($styleNode);

    $styleNode = $dom->CreateElement('Style');
    $styleNode->setAttribute('id','purple');
    $iconStyleNode = $dom->CreateElement('IconStyle');
    $iconNode = $dom->CreateElement('Icon');
    $iconNode->appendChild($dom->CreateElement('href','http://maps.google.com/mapfiles/kml/paddle/purple-blank.png'));
    $iconStyleNode->appendChild($iconNode);
    $styleNode->appendChild($iconStyleNode);
    $docNode->appendChild($styleNode);

    $styleNode = $dom->CreateElement('Style');
    $styleNode->setAttribute('id','blue');
    $iconStyleNode = $dom->CreateElement('IconStyle');
    $iconNode = $dom->CreateElement('Icon');
    $iconNode->appendChild($dom->CreateElement('href','http://maps.google.com/mapfiles/kml/paddle/ltblu-blank.png'));
    $iconStyleNode->appendChild($iconNode);
    $styleNode->appendChild($iconStyleNode);
    $docNode->appendChild($styleNode);

    $styleNode = $dom->CreateElement('Style');
    $styleNode->setAttribute('id','green');
    $iconStyleNode = $dom->CreateElement('IconStyle');
    $iconNode = $dom->CreateElement('Icon');
    $iconNode->appendChild($dom->CreateElement('href','http://maps.google.com/mapfiles/kml/paddle/grn-blank.png'));
    $iconStyleNode->appendChild($iconNode);
    $styleNode->appendChild($iconStyleNode);
    $docNode->appendChild($styleNode);

    $folderNode = $dom->CreateElement('Folder');
    $folderNode->appendChild($dom->CreateElement('name','Institutional Members'));
    $query->setSpreadsheetQuery('institutional = "Y"');
    $listFeed = $service->getListFeed($query);
    foreach ($listFeed->entries as $entry) {
      $placemarkNode = $dom->CreateElement('Placemark');
      $placemarkNode->appendChild($dom->CreateElement('styleUrl','#yellow'));
      $placemarkNode->appendChild($dom->CreateElement('name',$entry->getCustomByName('name')));
      $descriptionNode = $dom->CreateElement('description');
      $descriptionNode->appendChild($dom->createCDATASection('<table style="width:100%;border:1px solid lightgray">'
        .'<tr>'
          .'<td style="vertical-align:top" colspan=2 align=center><b>Institutional Member</b></td>'
        .'</tr>'
        .'<tr>'
          .'<td style="vertical-align:top">&nbsp;&nbsp;<b>Representative&nbsp;&nbsp;</b></td>'
          .'<td style="vertical-align:top">&nbsp;&nbsp;'.$entry->getCustomByName('representativeorganization').'&nbsp;&nbsp;</td>'
        .'</tr>'
        .'<tr>'
          .'<td style="vertical-align:top">&nbsp;&nbsp;<b>Director?&nbsp;&nbsp;</b></td>'
          .'<td style="vertical-align:top">&nbsp;&nbsp;'.($entry->getCustomByName('director') == 'Y' ? 'Y' : 'N').'&nbsp;&nbsp;</td>'
        .'</tr>'
        .'<tr>'
          .'<td style="vertical-align:top">&nbsp;&nbsp;<b>State&nbsp;&nbsp;</b></td>'
          .'<td style="vertical-align:top">&nbsp;&nbsp;'.$entry->getCustomByName('state').'&nbsp;&nbsp;</td>'
        .'</tr>'
        .'<tr>'
          .'<td style="vertical-align:top">&nbsp;&nbsp;<b>Date Joined&nbsp;&nbsp;</b></td>'
          .'<td style="vertical-align:top">&nbsp;&nbsp;'.$entry->getCustomByName('datejoined').'&nbsp;&nbsp;</td>'
        .'</tr>'
        .'<tr>'
          .'<td style="vertical-align:top" colspan=2 align=center><a href="http://secoora.org"><img border=0 src="http://carocoops.org/spreadsheet/secoora_small.png"></a></td>'
        .'</tr>'
      .'</table>'));
      $placemarkNode->appendChild($descriptionNode);
      $pointNode = $dom->CreateElement('Point');
      $pointNode->appendChild($dom->CreateElement(
         'coordinates'
        ,$entry->getCustomByName('longitude').','.$entry->getCustomByName('latitude'))
      );
      $placemarkNode->appendChild($pointNode);
      $folderNode->appendChild($placemarkNode);
    }
    $docNode->appendChild($folderNode); 

    $folderNode = $dom->CreateElement('Folder');
    $folderNode->appendChild($dom->CreateElement('name','Sustaining Members'));
    $query->setSpreadsheetQuery('sustaining = "Y"');
    $listFeed = $service->getListFeed($query);
    foreach ($listFeed->entries as $entry) {
      $placemarkNode = $dom->CreateElement('Placemark');
      $placemarkNode->appendChild($dom->CreateElement('styleUrl','#purple'));
      $placemarkNode->appendChild($dom->CreateElement('name',$entry->getCustomByName('name')));
      $descriptionNode = $dom->CreateElement('description');
      $descriptionNode->appendChild($dom->createCDATASection('<table style="width:100%;border:1px solid lightgray">'
        .'<tr>'
          .'<td style="vertical-align:top" colspan=2 align=center><b>Sustaining Member</b></td>'
        .'</tr>'
        .'<tr>'
          .'<td style="vertical-align:top">&nbsp;&nbsp;<b>Representative&nbsp;&nbsp;</b></td>'
          .'<td style="vertical-align:top">&nbsp;&nbsp;'.$entry->getCustomByName('representativeorganization').'&nbsp;&nbsp;</td>'
        .'</tr>'
        .'<tr>'
          .'<td style="vertical-align:top">&nbsp;&nbsp;<b>Director?&nbsp;&nbsp;</b></td>'
          .'<td style="vertical-align:top">&nbsp;&nbsp;'.($entry->getCustomByName('director') == 'Y' ? 'Y' : 'N').'&nbsp;&nbsp;</td>'
        .'</tr>'
        .'<tr>'
          .'<td style="vertical-align:top">&nbsp;&nbsp;<b>State&nbsp;&nbsp;</b></td>'
          .'<td style="vertical-align:top">&nbsp;&nbsp;'.$entry->getCustomByName('state').'&nbsp;&nbsp;</td>'
        .'</tr>'
        .'<tr>'
          .'<td style="vertical-align:top">&nbsp;&nbsp;<b>Date Joined&nbsp;&nbsp;</b></td>'
          .'<td style="vertical-align:top">&nbsp;&nbsp;'.$entry->getCustomByName('datejoined').'&nbsp;&nbsp;</td>'
        .'</tr>'
        .'<tr>'
          .'<td style="vertical-align:top" colspan=2 align=center><a href="http://secoora.org"><img border=0 src="http://carocoops.org/spreadsheet/secoora_small.png"></a></td>'
        .'</tr>'
      .'</table>'));
      $placemarkNode->appendChild($descriptionNode);
      $pointNode = $dom->CreateElement('Point');
      $pointNode->appendChild($dom->CreateElement(
         'coordinates'
        ,$entry->getCustomByName('longitude').','.$entry->getCustomByName('latitude'))
      );
      $placemarkNode->appendChild($pointNode);
      $folderNode->appendChild($placemarkNode);
    }
    $docNode->appendChild($folderNode);

    $folderNode = $dom->CreateElement('Folder');
    $folderNode->appendChild($dom->CreateElement('name','Individual Members'));
    $query->setSpreadsheetQuery('individual = "Y"');
    $listFeed = $service->getListFeed($query);
    foreach ($listFeed->entries as $entry) {
      $placemarkNode = $dom->CreateElement('Placemark');
      $placemarkNode->appendChild($dom->CreateElement('styleUrl','#blue'));
      $placemarkNode->appendChild($dom->CreateElement('name',$entry->getCustomByName('name')));
      $descriptionNode = $dom->CreateElement('description');
      $descriptionNode->appendChild($dom->createCDATASection('<table style="width:100%;border:1px solid lightgray">'
        .'<tr>'
          .'<td style="vertical-align:top" colspan=2 align=center><b>Individual Member</b></td>'
        .'</tr>'
        .'<tr>'
          .'<td style="vertical-align:top">&nbsp;&nbsp;<b>Organization&nbsp;&nbsp;</b></td>'
          .'<td style="vertical-align:top">&nbsp;&nbsp;'.$entry->getCustomByName('representativeorganization').'&nbsp;&nbsp;</td>'
        .'</tr>'
        .'<tr>'
          .'<td style="vertical-align:top">&nbsp;&nbsp;<b>State&nbsp;&nbsp;</b></td>'
          .'<td style="vertical-align:top">&nbsp;&nbsp;'.$entry->getCustomByName('state').'&nbsp;&nbsp;</td>'
        .'</tr>'
        .'<tr>'
          .'<td style="vertical-align:top">&nbsp;&nbsp;<b>Date Joined&nbsp;&nbsp;</b></td>'
          .'<td style="vertical-align:top">&nbsp;&nbsp;'.$entry->getCustomByName('datejoined').'&nbsp;&nbsp;</td>'
        .'</tr>'
        .'<tr>'
          .'<td style="vertical-align:top" colspan=2 align=center><a href="http://secoora.org"><img border=0 src="http://carocoops.org/spreadsheet/secoora_small.png"></a></td>'
        .'</tr>'
      .'</table>'));
      $placemarkNode->appendChild($descriptionNode);
      $pointNode = $dom->CreateElement('Point');
      $pointNode->appendChild($dom->CreateElement(
         'coordinates'
        ,$entry->getCustomByName('longitude').','.$entry->getCustomByName('latitude'))
      );
      $placemarkNode->appendChild($pointNode);
      $folderNode->appendChild($placemarkNode);
    }
    $docNode->appendChild($folderNode);

    $folderNode = $dom->CreateElement('Folder');
    $folderNode->appendChild($dom->CreateElement('name','Affiliate Members'));
    $query->setSpreadsheetQuery('affiliate = "Y"');
    $listFeed = $service->getListFeed($query);
    foreach ($listFeed->entries as $entry) {
      $placemarkNode = $dom->CreateElement('Placemark');
      $placemarkNode->appendChild($dom->CreateElement('styleUrl','#green'));
      $placemarkNode->appendChild($dom->CreateElement('name',$entry->getCustomByName('name')));
      $descriptionNode = $dom->CreateElement('description');
      $descriptionNode->appendChild($dom->createCDATASection('<table style="width:100%;border:1px solid lightgray">'
        .'<tr>'
          .'<td style="vertical-align:top" colspan=2 align=center><b>Affiliate Member</b></td>'
        .'</tr>'
        .'<tr>'
          .'<td style="vertical-align:top">&nbsp;&nbsp;<b>Representative&nbsp;&nbsp;</b></td>'
          .'<td style="vertical-align:top">&nbsp;&nbsp;'.$entry->getCustomByName('representativeorganization').'&nbsp;&nbsp;</td>'
        .'</tr>'
        .'<tr>'
          .'<td style="vertical-align:top">&nbsp;&nbsp;<b>Director?&nbsp;&nbsp;</b></td>'
          .'<td style="vertical-align:top">&nbsp;&nbsp;'.($entry->getCustomByName('director') == 'Y' ? 'Y' : 'N').'&nbsp;&nbsp;</td>'
        .'</tr>'
        .'<tr>'
          .'<td style="vertical-align:top">&nbsp;&nbsp;<b>State&nbsp;&nbsp;</b></td>'
          .'<td style="vertical-align:top">&nbsp;&nbsp;'.$entry->getCustomByName('state').'&nbsp;&nbsp;</td>'
        .'</tr>'
        .'<tr>'
          .'<td style="vertical-align:top">&nbsp;&nbsp;<b>Date Joined&nbsp;&nbsp;</b></td>'
          .'<td style="vertical-align:top">&nbsp;&nbsp;'.$entry->getCustomByName('datejoined').'&nbsp;&nbsp;</td>'
        .'</tr>'
        .'<tr>'
          .'<td style="vertical-align:top" colspan=2 align=center><a href="http://secoora.org"><img border=0 src="http://carocoops.org/spreadsheet/secoora_small.png"></a></td>'
        .'</tr>'
      .'</table>'));
      $placemarkNode->appendChild($descriptionNode);
      $pointNode = $dom->CreateElement('Point');
      $pointNode->appendChild($dom->CreateElement(
         'coordinates'
        ,$entry->getCustomByName('longitude').','.$entry->getCustomByName('latitude'))
      );
      $placemarkNode->appendChild($pointNode);
      $folderNode->appendChild($placemarkNode);
    }
    $docNode->appendChild($folderNode);

    // save & output
    $kmlOutput = $dom->saveXML();
    echo $kmlOutput;
    $cache->end();
  }
?>
