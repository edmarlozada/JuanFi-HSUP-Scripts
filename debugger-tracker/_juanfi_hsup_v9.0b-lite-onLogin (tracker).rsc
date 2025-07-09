# JuanFi onLogin v9.0b lite
# by: Chloe Renae & Edmar Lozada
# ------------------------------

# ( 0=NO / 1=YES ) #
local cfgShowLogs 1 ;# Show Log Debug on Logs

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
  local iVer1 "v9.0b"; local iVer2 "lite"
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
  local iCode "NEW"; if ($iExtCode=1) do={ set iCode "EXT" }
  $eLogDebug ("JuanFi-$iCode => user=[ $iUser ] ip=[ $iDevIP ] mac=[ $iDevMac ] interface=[ $iDevInt ] comment=[ $iComment ]") $cfgShowLogs
  log debug ("   ( $iUser ) iValidty=[ $iValidty ] iSaleAmt=[ $iSaleAmt ] iExtCode=[ $iExtCode ] iVendTag=[ $iVendTag ]")
  log debug ("   ( $iUser ) eMail=[ $eMail ] iFileMac=[ $iFileMac ] iActMail=[ $iActMail ] iRoot=[ $iRoot ]")

  # Invalid Comment Module
  if (!($iValidty>=0 && $iSaleAmt>=0 && ($iExtCode=0 || $iExtCode=1))) do={
    if ([/system scheduler find name=$iUser]!="") do={
      log debug ("   ( $iUser ) OnLogin UPDATE: Active User Email! => email=[$iActMail] comment=[$iComment]")
      /ip hotspot user set [find name=$iUser] email=$iActMail; return ""
    } else={
      log error ("   ( $iUser ) OnLogin ERROR: No Scheduler/Invalid Comment! => email=[$eMail] comment=[$iComment]")
      # what is the policy on user with invalid comment and/or no scheduler
      /ip hotspot user set [find name=$iUser] email=$iActMail comment="NO SCHEDULER"; return ""
    }
  }
  log debug ("   ( $iUser ) # Invalid Comment Module")

  # Add User Scheduler Module
  if ([/system scheduler find name=$iUser]="") do={
    /system scheduler add name=$iUser interval=0
    local i 10;while (([/system scheduler find name=$iUser]="")&&($i>0)) do={set i ($i-1);delay 1s}
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
  set iValidty ($iValidty + [/system scheduler get [find name=$iUser] interval])
  if ($iValidty!=0s && $iValidty<=$iUsrTime) do={ set iValidty ($iUsrTime+30s) }; #BugFix ( Validity <= UserTime )
  /syste scheduler set [find name=$iUser] interval=$iValidty
  /ip hotspot user set [find name=$iUser] email=$iActMail comment=""
  if ($iUsrTime>0) do={ set cUsrTime $iUsrTime }
  if ($iValidty>0) do={ set cValidty $iValidty }
  $eLogDebug ("   ( $iUser ) usertime=[ $cUsrTime ] validity=[ $cValidty ] amt=[ $iSaleAmt ] vendo=[ $iVendTag ] email=[ $eMail ] folder=[ $iRoot ]") $cfgShowLogs
  log debug ("   ( $iUser ) cUsrTime=[ $cUsrTime ] cValidty=[ $cValidty ] iValidty=[ $iValidty ]")
  log debug ("   ( $iUser ) # User Validity/Interval/Comment/eMail/BugFix Module")

  # User Expire Module
  local iUserBeg; local iUserExp "NO-EXPIRY"
  local aSySched [/system scheduler get $iUser]
  local iNextRun ($aSySched->"next-run")
  set   iUserBeg (($aSySched->"start-date")." ".($aSySched->"start-time"))
  if ([len $iNextRun]>1) do={
    set iUserExp [pick $iNextRun 0 ([len $iNextRun]-3)]
  }
  $eLogDebug ("   ( $iUser ) beg=[ $iUserBeg ] expiry=[ $iUserExp ] device=[ $cDevName ] profile=[ $iProfile ]") $cfgShowLogs
  log debug ("   ( $iUser ) iUserBeg=[ $iUserBeg ] iUserExp=[ $iUserExp ] iNextRun=[ $iNextRun ]")
  log debug ("   ( $iUser ) # User Expire Module")

  # Set User Scheduler on-event Module
  local iEvent ("# JuanFi $iVer1 $iVer2 #\r\n".\
                "/ip hotspot active remove [find user=\"$iUser\"]\r\n".\
                "local iType \"Validity\"; if ([len \$1]>0) do={ set iType \$1 };\r\n".\
                "log debug (\"JuanFi-EXP ( \$iType ) => user=[ $iUser ] ip=[ $iDevIP ] mac=[ $iDevMac ]\")\r\n".\
                "/ip hotspot cookie remove [find user=\"$iUser\"]\r\n".\
                "/ip hotspot cookie remove [find mac-address=\"$iDevMac\"]\r\n".\
                "/system scheduler  remove [find name=\"$iUser\"]\r\n".\
                "/ip hotspot user   remove [find name=\"$iUser\"]\r\n".\
                "/file remove [find name=\"$iRoot/data/$iFileMac.txt\"]\r\n")
  /system scheduler set [find name=$iUser] on-event=$iEvent
  log debug ("   ( $iUser ) # Set User Scheduler on-event Module")

  # Update Sales Module
  local iSalesToday; local iSalesMonth; local iSalesTotal
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
  log debug ("   ( $iUser ) # Update Sales Module")

  # Add User Data File Module
    local eSaveData do={
      local iUser $1; local iRoot $2; local iPath $3; local iFile $4; local iContent $5
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
    $eSaveData $iUser $iRoot "data"  ("$iFileMac")  ("$iUser#$iUserExp")
  log debug ("   ( $iUser ) $iFileMac.txt=[ $[/file get [find name="$iRoot/data/$iFileMac.txt"] contents] ]")
  log debug ("   ( $iUser ) # Add User Data File Module")

  # Send Telegram Module
  if ($cfgTelegram) do={
    local iUActive [/ip hotspot active print count-only]
    local iCode "new"; if ($iExtCode=1) do={ set iCode "ext" }
    local iText ("<<===[ $iVendTag ]===>>%0A".\
                 "User Code : $iUser ( $iCode )%0A".\
                 "User Time : $cUsrTime%0A".\
                 "Validity : $cValidty%0A".\
                 "Dev IP : $iDevIP%0A".\
                 "Dev MAC : $iDevMac".\
                 "Sales Amount : $iSaleAmt%0A".\
                 "Sales Total (Today) : $iSalesToday%0A".\
                 "Sales Total (Month) : $iSalesMonth%0A".\
                 "<<==[ ActiveUsers : $iUActive ]==>>")
    set iText [$eReplace ($iText) " " "%20"]
    local iURL ("https://"."api.telegram.org/bot$cfgTGBToken/sendmessage\?chat_id=$cfgTGChatID&text=$iText")
    do { /tool fetch url=$iURL keep-result=no } on-error={ log error ("   ( $iUser ) Telegram ERROR: Telegram Sending Failed") }
  }
  log debug ("   ( $iUser ) # Send Telegram Module")

} else={
  log debug ("JuanFi-ACT => user=[ $iUser ] ip=[ $address ] mac=[ $"mac-address" ] email=[ $eMail ]")
}

# Fix Random MAC Login
if (1) do={
  local iDevMac $"mac-address"
  /ip hotspot active remove [find user="$iUser" mac-address!="$iDevMac"]
}
