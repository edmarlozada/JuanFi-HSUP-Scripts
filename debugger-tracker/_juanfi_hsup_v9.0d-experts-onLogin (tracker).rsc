# JuanFi onLogin v9.0d experts
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
local iUsr $username
local aHSU [/ip hotspot user get $iUsr]
local eMail ($aHSU->"email")

# Check Valid Entry via EMail
if (!($eMail~"active")) do={
  local eReplace do={local iRet; local r;for i from=0 to=([len $1]-1) do={set r [pick $1 $i];if ($r=$2) do={set r $3};set iRet ($iRet.$r)}; return $iRet}
  local eLogDebug do={ if ($2) do={ log debug $1 } }

  # Variables Module
  local iVer1 "v9.0d"; local iVer2 "lite"
  local iDevIP   $address
  local iDevMac  $"mac-address"
  local iDevInt  $interface
  local iProfile ($aHSU->"profile")
  local iUsrTime ($aHSU->"limit-uptime")
  local iComment ($aHSU->"comment")
  local aComment [toarray $iComment]
  local iValidty [totime ($aComment->0)]
  local iSaleAmt [tonum ($aComment->1)]
  local iExtCode ($aComment->2)
  local iVendTag ($aComment->3)
  local iFileMac [$eReplace $iDevMac ":" ""]
  local iActMail ("$iFileMac@juanfi.$iVer1.active")
  local iRoot    [/ip hotspot profile get [.. get [find interface=$iDevInt] profile] html-directory]
  local iType    "NEW"; if ($iExtCode=1) do={ set iType "EXT" }
  $eLogDebug ("JuanFi-$iType => user=[ $iUsr ] ip=[ $iDevIP ] mac=[ $iDevMac ] interface=[ $iDevInt ] comment=[ $iComment ]") $cfgShowLogs
  log debug ("   ( $iUsr ) iValidty=[ $iValidty ] iSaleAmt=[ $iSaleAmt ] iExtCode=[ $iExtCode ] iVendTag=[ $iVendTag ]")
  log debug ("   ( $iUsr ) eMail=[ $eMail ] iFileMac=[ $iFileMac ] iActMail=[ $iActMail ] iRoot=[ $iRoot ]")

  # Invalid Comment Module
  if (!($iValidty>=0 && $iSaleAmt>=0 && ($iExtCode=0 || $iExtCode=1))) do={
    if ([/system scheduler find name=$iUsr]!="") do={
      log debug ("   ( $iUsr ) OnLogin UPDATE: Active User Email! => email=[$iActMail] comment=[$iComment]")
      /ip hotspot user set [find name=$iUsr] email=$iActMail; return ""
    } else={
      log error ("   ( $iUsr ) OnLogin ERROR: No Scheduler/Invalid Comment! => email=[$eMail] comment=[$iComment]")
      # what is the policy on user with invalid comment and/or no scheduler
      /ip hotspot user set [find name=$iUsr] email=$iActMail comment="NO SCHEDULER"; return ""
    }
  }
  log debug ("   ( $iUsr ) # Invalid Comment Module")

  # Add User Scheduler Module
  if ([/system scheduler find name=$iUsr]="") do={
    /system scheduler add name=$iUsr interval=0
    local i 10;while (([/system scheduler find name=$iUsr]="")&&($i>0)) do={set i ($i-1);delay 1s}
  }
  log debug ("   ( $iUsr ) # Add User Scheduler Module")

  # Cancel User-Login if user-scheduler NOT FOUND!
  if ([/system scheduler find name=$iUsr]="") do={
    log error ("   ( $iUsr ) OnLogin ERROR: Scheduler Not Found! => email=[$eMail] comment=[$iComment]")
    /ip hotspot active remove [find user=$iUsr]; return ""
  }
  log debug ("   ( $iUsr ) # Cancel User-Login if user-scheduler NOT FOUND!")

  # User Validity/Interval/Comment/eMail/BugFix Module
  local cUsrTime "NO-LIMIT"; local cValidty "NO-VALIDITY"
  set iValidty ($iValidty + [/system scheduler get [find name=$iUsr] interval])
  if ($iValidty!=0s && $iValidty<=$iUsrTime) do={ set iValidty ($iUsrTime+30s) }; #BugFix ( Validity <= UserTime )
  /syste scheduler set [find name=$iUsr] interval=$iValidty
  /ip hotspot user set [find name=$iUsr] email=$iActMail comment=""
  if ($iUsrTime>0) do={ set cUsrTime $iUsrTime }
  if ($iValidty>0) do={ set cValidty $iValidty }
  $eLogDebug ("   ( $iUsr ) usertime=[ $cUsrTime ] validity=[ $cValidty ] amt=[ $iSaleAmt ] vendo=[ $iVendTag ] email=[ $eMail ] folder=[ $iRoot ]") $cfgShowLogs
  log debug ("   ( $iUsr ) cUsrTime=[ $cUsrTime ] cValidty=[ $cValidty ] iValidty=[ $iValidty ]")
  log debug ("   ( $iUsr ) # User Validity/Interval/Comment/eMail/BugFix Module")

  # User Expire Module
  local iUserBeg; local iUserExp "NO-EXPIRY"
  local aSySched [/system scheduler get $iUsr]
  local iNextRun ($aSySched->"next-run")
  set   iUserBeg (($aSySched->"start-date")." ".($aSySched->"start-time"))
  if ([len $iNextRun]>1) do={
    set iUserExp [pick $iNextRun 0 ([len $iNextRun]-3)]
  }
  $eLogDebug ("   ( $iUsr ) beg=[ $iUserBeg ] expiry=[ $iUserExp ] device=[ $cDevName ] profile=[ $iProfile ]") $cfgShowLogs
  log debug ("   ( $iUsr ) iUserBeg=[ $iUserBeg ] iUserExp=[ $iUserExp ] iNextRun=[ $iNextRun ]")
  log debug ("   ( $iUsr ) # User Expire Module")

  # Set User Scheduler on-event Module
  local iEvent ("# JuanFi $iVer1 $iVer2 #\r\n".\
                "/ip hotspot active remove [find user=\"$iUsr\"]\r\n".\
                "local iExp \"Validity\"; if ([len \$1]>0) do={ set iExp \$1 };\r\n".\
                "log debug (\"JuanFi-EXP ( \$iExp ) => user=[ $iUsr ] ip=[ $iDevIP ] mac=[ $iDevMac ]\")\r\n".\
                "/ip hotspot cookie remove [find user=\"$iUsr\"]\r\n".\
                "/ip hotspot cookie remove [find mac-address=\"$iDevMac\"]\r\n".\
                "/system scheduler  remove [find name=\"$iUsr\"]\r\n".\
                "/ip hotspot user   remove [find name=\"$iUsr\"]\r\n".\
                "/file remove [find name=\"$iRoot/data/$iFileMac.txt\"]\r\n")
  /system scheduler set [find name=$iUsr] on-event=$iEvent
  log debug ("   ( $iUsr ) # Set User Scheduler on-event Module")

  # Update Sales Module
  local iSalesToday; local iSalesMonth
    local eAddSales do={
      local iUsr $1; local iSaleAmt $2; local iSalesName $3; local iSalesComment $4; local iTotalAmt 0
      if ([/system script find name=$iSalesName]!="") do={
        log debug ("   ( $iUsr ) iSalesName=[ $iSalesName ] OldAmt=[ $[/system script get [find name=$iSalesName] source] ]")
        set iTotalAmt ($iSaleAmt + [tonum [/system script get [find name=$iSalesName] source]])
        /system script set [find name=$iSalesName] owner="sales script" source="$iTotalAmt" comment=$iSalesComment
        log debug ("   ( $iUsr ) iSalesName=[ $iSalesName ] NewAmt=[ $iTotalAmt ]")
      } else={ log error ("   ( $iUsr ) OnLogin ERROR: Sales Not Found! => /system script [$iSalesName]") }
      return $iTotalAmt
    }
    set iSalesToday [$eAddSales $iUsr $iSaleAmt "SalesToday" "juanfi: Sales Today"]
    set iSalesMonth [$eAddSales $iUsr $iSaleAmt "SalesMonth" "juanfi: Sales Month"]
  log debug ("   ( $iUsr ) # Update Sales Module")

  # Add User Data File Module
    local eSaveData do={
      local iUsr $1; local iRoot $2; local iPath $3; local iFile $4; local iContent $5
      if ([/file find name="$iRoot/$iPath"]!="") do={
      if ([/file find name="$iRoot/$iPath/$iFile.txt"]="") do={
        log debug ("   ( $iUsr ) OnLogin FILE: AutoCreate! => /file [$iRoot/$iPath/$iFile.txt]")
        /file print file="$iRoot/$iPath/$iFile.txt" where name="$iFile.txt"
        local i 10;while (([/file find name="$iRoot/$iPath/$iFile.txt"]="")&&($i>0)) do={set i ($i-1);delay 1s}
      }
      } else={ log error ("   ( $iUsr ) OnLogin ERROR: Path Not Found! => /file [$iRoot/$iPath]") }
      if ([/file find name="$iRoot/$iPath/$iFile.txt"]!="") do={
        /file set "$iRoot/$iPath/$iFile.txt" contents=$iContent
      } else={ log error ("   ( $iUsr ) OnLogin ERROR: File Not Found! => /file [$iRoot/$iPath/$iFile.txt]") }
    }
    $eSaveData $iUsr $iRoot "data"  ("$iFileMac")  ("$iUsr#$iUserExp")
  log debug ("   ( $iUsr ) $iFileMac.txt=[ $[/file get [find name="$iRoot/data/$iFileMac.txt"] contents] ]")
  log debug ("   ( $iUsr ) # Add User Data File Module")

  # Send Telegram Module
  if ($cfgTelegram) do={
    local iUActive [/ip hotspot active print count-only]
    local iType "new"; if ($iExtCode=1) do={ set iType "ext" }
    local iText ("<<===[ $iVendTag ]===>>%0A".\
                 "User Code : $iUsr ( $iType )%0A".\
                 "User Time : $cUsrTime%0A".\
                 "Validity : $cValidty%0A".\
                 "Dev IP : $iDevIP%0A".\
                 "Dev MAC : $iDevMac%0A".\
                 "Sales Amount : $iSaleAmt%0A".\
                 "Sales (Today) : $iSalesToday%0A".\
                 "Sales (Month) : $iSalesMonth%0A".\
                 "<<==[ ActiveUsers : $iUActive ]==>>")
    set iText [$eReplace ($iText) " " "%20"]
    local iURL ("https://"."api.telegram.org/bot$cfgTGBToken/sendmessage\?chat_id=$cfgTGChatID&text=$iText")
    do { /tool fetch url=$iURL keep-result=no } on-error={ log error ("   ( $iUsr ) Telegram ERROR: Telegram Sending Failed") }
  }
  log debug ("   ( $iUsr ) # Send Telegram Module")

} else={
  local aHSA [/ip hotspot active get [find user=$iUsr]]
  log debug ("JuanFi-IN => user=[ $iUsr ] ip=[ $address ] mac=[ $"mac-address" ] email=[ $eMail ] login-by=[ $($aHSA->"login-by") ]")
}

# Fix Random MAC Login
if (1) do={
  local iDevMac $"mac-address"
  /ip hotspot active remove [find user="$iUsr" mac-address!="$iDevMac"]
}
