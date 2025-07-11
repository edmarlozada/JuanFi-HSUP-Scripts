# JuanFi onLogin v9.0b full
# by: Chloe Renae & Edmar Lozada
# ------------------------------

# ( 0=NO / 1=YES ) #
local cfgShowLogs 1 ;# Show Log Debug on Logs
local cfgAddSales 1 ;# Add Sales Today/Month
local cfgAddFiles 1 ;# Add User Data File
local cfgAddInfos 1 ;# Set User/Scheduler Comment Info

local cfgTelegram 0 ;# Send Login Details to Telegram
# Telegram Group Chat ID
local cfgTGChatID "xxxxxxxxxxxxxx"
# Telegram Bot Token
local cfgTGBToken "xxxxxxxxxx:xxxxxxxxxxxxx-xxxxxxxxxxxxxxx-xxxxx"

# ------------------------------ #
# Do NOT Edit below this point   #
# ------------------------------ #
local iUser $username
local aUser [/ip hotspot user get $iUser]
local eMail ($aUser->"email")

# Check Valid Entry via EMail
if (!($eMail~"active")) do={
  local eReplace do={local iRet; local r;for i from=0 to=([len $1]-1) do={set r [pick $1 $i];if ($r=$2) do={set r $3};set iRet ($iRet.$r)}; return $iRet}
  local eLogDebug do={ if ($2) do={ log debug $1 } }

  # Variables Module
  local iVer1 "v9.0b"; local iVer2 "full"
  local iDevIP   $address
  local iDevMac  $"mac-address"
  local iDevInt  $interface
  local iProfile ($aUser->"profile")
  local iUsrTime ($aUser->"limit-uptime")
  local iComment ($aUser->"comment")
  local aComment [toarray $iComment]
  local iValidty [totime ($aComment->0)]
  local iSaleAmt [tonum ($aComment->1)]
  local iExtCode ($aComment->2)
  local iVendTag ($aComment->3)
  local iFileMac [$eReplace $iDevMac ":" ""]
  local iActMail "$iFileMac@juanfi.$iVer1.active"
  local iRoot    [/ip hotspot profile get [.. get [find interface=$iDevInt] profile] html-directory]
  local iDevName; local cDevName "-none-"
  if ([/ip dhcp-server lease find address=$iDevIP]!="") do={
    set iDevName [/ip dhcp-server lease get [find address=$iDevIP] host-name]
  }; if ([len $iDevName]>0) do={ set cDevName $iDevName }
  local iCode "NEW"; if ($iExtCode=1) do={ set iCode "EXT" }
  $eLogDebug ("JuanFi-$iCode => user=[ $iUser ] ip=[ $iDevIP ] mac=[ $iDevMac ] interface=[ $iDevInt ] comment=[ $iComment ]") $cfgShowLogs
  log debug ("   ( $iUser ) iValidty=[ $iValidty ] iSaleAmt=[ $iSaleAmt ] iExtCode=[ $iExtCode ] iVendTag=[ $iVendTag ]")
  log debug ("   ( $iUser ) eMail=[ $eMail ] iFileMac=[ $iFileMac ] iActMail=[ $iActMail ] iRoot=[ $iRoot ]")

  # Invalid Comment Module
  if (!($iValidty>=0 && $iSaleAmt>=0 && ($iExtCode=0 || $iExtCode=1))) do={
    do {
    if ([/system scheduler find name=$iUser]!="") do={
      log debug ("   ( $iUser ) OnLogin UPDATE: Active User Email! => email=[$iActMail] comment=[$iComment]")
      /ip hotspot user set [find name=$iUser] email=$iActMail; return ""
    } else={
      log error ("   ( $iUser ) OnLogin ERROR: No Scheduler/Invalid Comment! => email=[$eMail] comment=[$iComment]")
      # what is the policy on user with invalid comment and/or no scheduler
      /ip hotspot user set [find name=$iUser] email=$iActMail comment="NO SCHEDULER"; return ""
    }
    } on-error={ log error ("   ( $iUser ) OnLogin ERROR: Validate Comment then Update User EMail Module") }
  }
  log debug ("   ( $iUser ) # Invalid Comment Module")

  # Add User Scheduler Module
  if ([/system scheduler find name=$iUser]="") do={
    do {
    /system scheduler add name=$iUser interval=0
    local i 10;while (([/system scheduler find name=$iUser]="")&&($i>0)) do={set i ($i-1);delay 1s}
    } on-error={ log error ("   ( $iUser ) OnLogin ERROR: Add User Scheduler Module") }
  }
  log debug ("   ( $iUser ) # Add User Scheduler Module")

  # Cancel User-Login if user-scheduler NOT FOUND!
  if ([/system scheduler find name=$iUser]="") do={
    log error ("   ( $iUser ) OnLogin ERROR: Scheduler Not Found! => email=[$eMail] comment=[$iComment]")
    /ip hotspot active remove [find user=$iUser]; return ""
  }
  log debug ("   ( $iUser ) # Cancel User-Login if user-scheduler NOT FOUND!")

  # User Validity/Interval/Comment/eMail/BugFix Module
  local cUsrTime "NO-LIMIT"; local cValidty "NO-VALIDITY"
  do {
  set iValidty ($iValidty + [/system scheduler get [find name=$iUser] interval])
  if ($iValidty!=0s && $iValidty<=$iUsrTime) do={ set iValidty ($iUsrTime+30s) }; #BugFix ( Validity <= UserTime )
  /syste scheduler set [find name=$iUser] interval=$iValidty
  /ip hotspot user set [find name=$iUser] email=$iActMail comment=""
  if ($iUsrTime>0) do={ set cUsrTime $iUsrTime }
  if ($iValidty>0) do={ set cValidty $iValidty }
  $eLogDebug ("   ( $iUser ) usertime=[ $cUsrTime ] validity=[ $cValidty ] amt=[ $iSaleAmt ] vendo=[ $iVendTag ] email=[ $eMail ] folder=[ $iRoot ]") $cfgShowLogs
  log debug ("   ( $iUser ) cUsrTime=[ $cUsrTime ] cValidty=[ $cValidty ] iValidty=[ $iValidty ]")
  } on-error={ log error ("   ( $iUser ) OnLogin ERROR: User Validity/Interval/Comment/eMail/BugFix Module") }
  log debug ("   ( $iUser ) # User Validity/Interval/Comment/eMail/BugFix Module")

  # User Expire Module
  local iUserBeg; local iUserExp "NO-EXPIRY"
  do {
  local aSySched [/system scheduler get $iUser]
  local iNextRun ($aSySched->"next-run")
  set   iUserBeg (($aSySched->"start-date")." ".($aSySched->"start-time"))
  if ([len $iNextRun]>1) do={
    set iUserExp [pick $iNextRun 0 ([len $iNextRun]-3)]
  }
  $eLogDebug ("   ( $iUser ) beg=[ $iUserBeg ] expiry=[ $iUserExp ] device=[ $cDevName ] profile=[ $iProfile ]") $cfgShowLogs
  log debug ("   ( $iUser ) iUserBeg=[ $iUserBeg ] iUserExp=[ $iUserExp ] iNextRun=[ $iNextRun ]")
  } on-error={ log error ("   ( $iUser ) OnLogin ERROR: User Expire Module") }
  log debug ("   ( $iUser ) # User Expire Module")

  # Set User Scheduler on-event Module
  do {
  local iEvent ("# JuanFi $iVer1 $iVer2 #\r\n".\
                "/ip hotspot active remove [find user=\"$iUser\"]\r\n")
    if ($cfgShowLogs) do={
    set iEvent ("$iEvent".\
                "\r\n".\
                "local iType \"Validity\"; if ([len \$1]>0) do={ set iType \$1 };\r\n".\
                "log debug (\"JuanFi-EXP ( \$iType ) => user=[ $iUser ] ip=[ $iDevIP ] mac=[ $iDevMac ]\")\r\n".\
                "local cUseT \"NO-UPTIME\";\r\n".\
                "do {\r\n".\
                "if ([/ip hotspot user find name=\"$iUser\"]!=\"\") do={\r\n".\
                "  local iUseT [/ip hotspot user get [find name=\"$iUser\"] uptime];\r\n".\
                "  if (\$iUseT>0) do={ set cUseT \$iUseT };\r\n".\
                "} else={ log error (\"   ( $iUser ) SySched ERROR! User Not Found! => /ip hotspot user [$iUser]\") }\r\n".\
                "if ([/system scheduler find name=\"$iUser\"]!=\"\") do={\r\n".\
                "} else={ log error (\"   ( $iUser ) SySched ERROR! Scheduler Not Found! => /system scheduler [$iUser]\") }\r\n".\
                "} on-error={ log error (\"   ( $iUser ) SySched ERROR! Get Users Data Module!\") }\r\n".\
                "log debug (\"   ( $iUser ) beg=[ $iUserBeg ] expiry=[ $iUserExp ] device=[ $cDevName ]\")\r\n".\
                "log debug (\"   ( $iUser ) usertime=[ $cUsrTime ] validity=[ $iValidty ] uptime=[ \$cUseT ]\")\r\n")
    }
    set iEvent ("$iEvent\r\n".\
                "/ip hotspot cookie remove [find user=\"$iUser\"]\r\n".\
                "/ip hotspot cookie remove [find mac-address=\"$iDevMac\"]\r\n".\
                "/system scheduler  remove [find name=\"$iUser\"]\r\n".\
                "/ip hotspot user   remove [find name=\"$iUser\"]\r\n".\
                "/file remove [find name=\"$iRoot/data/$iFileMac.txt\"]\r\n")
    set iEvent ("$iEvent".\
                "/file remove [find name=\"$iRoot/data/$iUser.txt\"]\r\n".\
                "/file remove [find name=\"$iRoot/xData/U$iUser.txt\"]\r\n".\
                "/file remove [find name=\"$iRoot/xData/M$iFileMac.txt\"]\r\n")
  /system scheduler set [find name=$iUser] on-event=$iEvent
  } on-error={ log error ("   ( $iUser ) OnLogin ERROR: Set User Scheduler on-event Module") }
  log debug ("   ( $iUser ) # Set User Scheduler on-event Module")

  # Update Sales Module
  local iSalesToday; local iSalesMonth; local iSalesTotal
  local iVendoToday; local iVendoMonth; local iVendoTotal
  if ($cfgAddSales) do={
    do {
    local eAddSales do={
      local iUser $1; local iSaleAmt $2; local iSalesName $3; local iSalesComment $4; local iTotalAmt 0
      if ([/system script find name=$iSalesName]="") do={
        log debug ("   ( $iUser ) OnLogin SALES: AutoCreate! => /system script [$iSalesName]")
        /system script add name=$iSalesName source="0"
        local i 10;while (([/system script find name=$iSalesName]="")&&($i>0)) do={set i ($i-1);delay 1s}
      }
      if ([/system script find name=$iSalesName]!="") do={
        log debug ("   ( $iUser ) iSalesName=[ $iSalesName ] OldAmt=[ $[/system script get [find name=$iSalesName] source] ]")
        set iTotalAmt ($iSaleAmt + [tonum [/system script get [find name=$iSalesName] source]])
        /system script set [find name=$iSalesName] source="$iTotalAmt" comment=$iSalesComment
        log debug ("   ( $iUser ) iSalesName=[ $iSalesName ] NewAmt=[ $iTotalAmt ]")
      } else={ log error ("   ( $iUser ) OnLogin ERROR: Sales Not Found! => /system script [$iSalesName]") }
      return $iTotalAmt
    }
    set iSalesToday [$eAddSales $iUser $iSaleAmt "SalesToday" "JuanFi Sales Today"]
    set iSalesMonth [$eAddSales $iUser $iSaleAmt "SalesMonth" "JuanFi Sales Month"]
    } on-error={ log error ("   ( $iUser ) OnLogin ERROR: Update Sales Module") }
  }
  log debug ("   ( $iUser ) # Update Sales Module")

  # Add User Data File Module
  if ($cfgAddFiles) do={
    do {
    local eSaveData do={
      local iUser $1; local iRoot $2; local iPath $3; local iFile $4; local iContent $5
      if ([/file find name="$iRoot"]!="") do={
      if ([/file find name="$iRoot/$iPath"]="") do={
        log debug ("   ( $iUser ) OnLogin PATH: AutoCreate! => /file [$iRoot/$iPath/]")
        do { /tool fetch dst-path=("$iRoot/$iPath/.") url="https://127.0.0.1/" } on-error={ }
        local i 10;while (([/file find name="$iRoot/$iPath"]="")&&($i>0)) do={set i ($i-1);delay 1s}
      }
      } else={ log error ("   ( $iUser ) OnLogin ERROR: Root Not Found! => /file [$iRoot]") }
      if ([/file find name="$iRoot/$iPath"]!="") do={
      if ([/file find name="$iRoot/$iPath/$iFile.txt"]="") do={
        log debug ("   ( $iUser ) OnLogin FILE: AutoCreate! => /file [$iRoot/$iPath/$iFile.txt]")
        /file print file="$iRoot/$iPath/$iFile.txt" where name="$iFile.txt"
        local i 10;while (([/file find name="$iRoot/$iPath/$iFile.txt"]="")&&($i>0)) do={set i ($i-1);delay 1s}
      }
      } else={ log error ("   ( $iUser ) OnLogin ERROR: Path Not Found! => /file [$iRoot/$iPath]") }
      if ([/file find name="$iRoot/$iPath/$iFile.txt"]!="") do={
        /file set "$iRoot/$iPath/$iFile.txt" contents=$iContent
      } else={ log error ("   ( $iUser ) OnLogin ERROR: File Not Found! => /file [$iRoot/$iPath/$iFile.txt]") }
    }
    # Add Data for New Portal
    local iPass [/ip hotspot user get [find name=$iUser] password]
    local jMacData ("{\r\n".\
                    "\"n\":\"$iUser\",\r\n".\
                    "\"p\":\"$iPass\",\r\n".\
                    "\"v\":\"$iVer1\"\r\n".\
                    "}")
    local jUsrData ("{\r\n".\
                    "\"d\":\"$iDevMac\",\r\n".\
                    "\"a\":\"$iSaleAmt\",\r\n".\
                    "\"l\":\"$cUsrTime\",\r\n".\
                    "\"v\":\"$iValidty\",\r\n".\
                    "\"b\":\"$iUserBeg\",\r\n".\
                    "\"e\":\"$iUserExp\",\r\n".\
                    "\"r\":\"$iVer1\"\r\n".\
                    "}")
    $eSaveData $iUser $iRoot "data"  ("$iFileMac")  ("$iUser#$iUserExp")
    $eSaveData $iUser $iRoot "xData" ("U$iUser")    ("$jUsrData")
    $eSaveData $iUser $iRoot "xData" ("M$iFileMac") ("$jMacData")
    } on-error={ log error ("   ( $iUser ) OnLogin ERROR: Add User Data File Module") }
  }
  log debug ("   ( $iUser ) $iFileMac.txt=[ $[/file get [find name="$iRoot/data/$iFileMac.txt"] contents] ]")
  log debug ("   ( $iUser ) # Add User Data File Module")

  # Send Telegram Module
  if ($cfgTelegram) do={
    do {
    set cDevName [pick $cDevName 0 15]
    local iMTIName [/system identity get name]
    local iUActive [/ip hotspot active print count-only]
    local iCode "new"; if ($iExtCode=1) do={ set iCode "ext" }
    local iText ("<<===[ $iMTIName ]===>>%0A".\
                 "Interface : $iDevInt%0A".\
                 "User Code : $iUser ( $iCode )%0A".\
                 "User Time : $cUsrTime%0A".\
                 "Validity : $cValidty%0A".\
                 "Dev IP : $iDevIP%0A".\
                 "Dev MAC : $iDevMac".\
                 "Dev : $cDevName%0A")
    if ($cfgAddSales) do={
      set iText ("$iText%0A%0A".\
                 "Sales Amount : $iSaleAmt%0A".\
                 "Sales Total (Today) : $iSalesToday%0A".\
                 "Sales Total (Month) : $iSalesMonth%0A".\
                 "Vendo Name : $iVendTag%0A".\
                 "Sales (Today) : $iVendoToday%0A".\
                 "Sales (Month) : $iVendoMonth%0A".\
                 "<<==[ ActiveUsers : $iUActive ]==>>")
    }
    set iText [$eReplace ($iText) " " "%20"]
    local iURL ("https://"."api.telegram.org/bot$cfgTGBToken/sendmessage\?chat_id=$cfgTGChatID&text=$iText")
    do { /tool fetch url=$iURL keep-result=no } on-error={ log error ("   ( $iUser ) Telegram ERROR: Telegram Sending Failed") }
    } on-error={ log error ("   ( $iUser ) OnLogin ERROR: Send Telegram Module") }
  }
  log debug ("   ( $iUser ) # Send Telegram Module")

  # Set User/Scheduler Comment Info Module
  if ($cfgAddInfos) do={
    do {
    local cUsrNote "+ ( $iVendTag ) interface=[$iDevInt] mac=[$iDevMac] validity=[$iUserExp] comment=[$iComment] < $iCode >"
    local cSchNote "+ ( $iVendTag ) interface=[$iDevInt] mac=[$iDevMac] limit-uptime=[$cUsrTime] comment=[$iComment] < $iCode >"
    /ip hotspot user  set [find name=$iUser] comment=$cUsrNote
    /system scheduler set [find name=$iUser] comment=$cSchNote
    } on-error={ log error ("   ( $iUser ) OnLogin ERROR: Update User Comment Info Module") }
    log debug ("   ( $iUser ) user-comment=[ $[/ip hotspot user get [find name=$iUser] comment] ]")
    log debug ("   ( $iUser ) scheduler-comment=[ $[/system scheduler get [find name=$iUser] comment] ]")
  }
  log debug ("   ( $iUser ) Set User/Scheduler Comment Info Module")
  log debug ("   ( $iUser ) ===[ TRACKER END ]===")

} else={
  log debug ("JuanFi-ACT => user=[ $iUser ] ip=[ $address ] mac=[ $"mac-address" ] email=[ $eMail ]")
}

# Fix Random MAC Login
if (1) do={
  local iDevMac $"mac-address"
  /ip hotspot active remove [find user="$iUser" mac-address!="$iDevMac"]
}
