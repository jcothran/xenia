<?php
  include('globals.php');

  system("rm -f $cache_dir/*");

  $pages = array(
     'board_development_committee'
    ,'board'
    ,'dmac_committee'
    ,'education_outreach'
    ,'executive_committee'
    ,'finance_committee'
    ,'governance_committee'
    ,'membership'
    ,'operations_maintenance'
    ,'public_policy_committee'
    ,'science_committee'
    ,'stakeholder_council'
    ,'membership_kml'
  );

  foreach ($pages as $p) {
    echo "<a href='$http_root/$p.php'>$p<br>\n";
    file_get_contents("$http_root/$p.php");
  }
  
  //Now go through and re-cache the state membership pages.
  $states = array("SC", "NC", "GA", "FL");
  foreach($states as $state)
  {
    $pageURL = "$http_root/state_membership.php?state=$state";
    echo "<a href='$pageURL'>$state<br>\n";
    file_get_contents($pageURL);
  }
?>
