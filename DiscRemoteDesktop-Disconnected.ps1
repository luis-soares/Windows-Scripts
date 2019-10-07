






$sessions = query user /server:msrdpviv04
$sessionsact = $sessions |findstr Active
$sessiondisc = $sessions |findstr Disc

#Get Disconnected session ID
$sess = $sessiondisc
foreach ($sessiondiscid in $sess) {
    $sessiondiscid.Split(" ",[system.stringsplitoptions]::removeemptyentries)[1]
}




