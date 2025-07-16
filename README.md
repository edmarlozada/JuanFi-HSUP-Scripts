## JuanFi onLogin/onLogout v9.0d
- no need to define hotspot folder! (copyright)

### What's new (2025-07-09)
- now compatible with JuanFi Manager APK
- uses user-email to check valid login entry
- cancel user-login if scheduler not created
- cancel user-login if invalid user comment

### What's in v9.0d
- system scheduler on-event minimize/with logs
- fix bug on validity ( if Validity <= UserTime )
- create logs for New/Extend user
- show login error on log
- telegram reporting

### Transistion/Migration:
- the new onLogin/onLogout script will take effect on new users
- old active users still uses the old scheduler script
- just leave those old active users as-is until they expire!

### Tested On:
- hAP Lite 6.48.7 Stable
- hEX GR3 7.19.1 Stable
- RB5009 7.8 Long Term
- CCR1009 6.49.10 Long Term

### WARNING:
- test first before deploy!

### Author:
- Chloe Renae & Edmar Lozada

### Facebook Contact:
- https://www.facebook.com/chloe.renae.2000

### Follow these steps:

#### Step 1: Copy script below and paste to hotspot user profile onLogin.
```bash
# JuanFi onLogin v9.0d starter
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
local iUsr $username
local aHSU [/ip hotspot user get $iUsr]
local eMail ($aHSU->"email")

# Check Valid Entry via EMail
if (!($eMail~"active")) do={
  local eReplace do={local iRet; local r;for i from=0 to=([len $1]-1) do={set r [pick $1 $i];if ($r=$2) do={set r $3};set iRet ($iRet.$r)}; return $iRet}
  local eLogDebug do={ if ($2) do={ log debug $1 } }

  # Variables Module
  local iVer1 "v9.0d"; local iVer2 "full"
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
  local iDevName; local cDevName "-none-"
  if ([/ip dhcp-server lease find address=$iDevIP]!="") do={
    set iDevName [/ip dhcp-server lease get [find address=$iDevIP] host-name]
  }; if ([len $iDevName]>0) do={ set cDevName $iDevName }
  $eLogDebug ("JuanFi-$iType => user=[ $iUsr ] ip=[ $iDevIP ] mac=[ $iDevMac ] interface=[ $iDevInt ] comment=[ $iComment ]") $cfgShowLogs

  # Invalid Comment Module
  do {
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
  } on-error={ log error ("   ( $iUsr ) OnLogin ERROR: Validate Comment then Update User EMail Module") }

  # Add User Scheduler Module
  do {
  if ([/system scheduler find name=$iUsr]="") do={
    /system scheduler add name=$iUsr interval=0
    local i 10;while (([/system scheduler find name=$iUsr]="")&&($i>0)) do={set i ($i-1);delay 1s}
  }
  } on-error={ log error ("   ( $iUsr ) OnLogin ERROR: Add User Scheduler Module") }

  # Cancel User-Login if user-scheduler NOT FOUND!
  if ([/system scheduler find name=$iUsr]="") do={
    log error ("   ( $iUsr ) OnLogin ERROR: Scheduler Not Found! => email=[$eMail] comment=[$iComment]")
    /ip hotspot active remove [find user=$iUsr]; return ""
  }

  # User Validity/Interval/Comment/eMail/BugFix Module
  local cUsrTime "NO-LIMIT"; local cValidty "NO-VALIDITY"
  do {
  set iValidty ($iValidty + [/system scheduler get [find name=$iUsr] interval])
  if ($iValidty!=0s && $iValidty<=$iUsrTime) do={ set iValidty ($iUsrTime+30s) }; #BugFix ( Validity <= UserTime )
  /syste scheduler set [find name=$iUsr] interval=$iValidty
  /ip hotspot user set [find name=$iUsr] email=$iActMail comment=""
  if ($iUsrTime>0) do={ set cUsrTime $iUsrTime }
  if ($iValidty>0) do={ set cValidty $iValidty }
  $eLogDebug ("   ( $iUsr ) usertime=[ $cUsrTime ] validity=[ $cValidty ] amt=[ $iSaleAmt ] vendo=[ $iVendTag ] email=[ $eMail ] folder=[ $iRoot ]") $cfgShowLogs
  } on-error={ log error ("   ( $iUsr ) OnLogin ERROR: User Validity/Interval/Comment/eMail/BugFix Module") }

  # User Expire Module
  local iUserBeg; local iUserExp "NO-EXPIRY"
  do {
  local aSySched [/system scheduler get $iUsr]
  local iNextRun ($aSySched->"next-run")
  set   iUserBeg (($aSySched->"start-date")." ".($aSySched->"start-time"))
  if ([len $iNextRun]>1) do={
    set iUserExp [pick $iNextRun 0 ([len $iNextRun]-3)]
  }
  $eLogDebug ("   ( $iUsr ) beg=[ $iUserBeg ] expiry=[ $iUserExp ] device=[ $cDevName ] profile=[ $iProfile ]") $cfgShowLogs
  } on-error={ log error ("   ( $iUsr ) OnLogin ERROR: User Expire Module") }

  # Set User Scheduler on-event Module
  do {
  local iEvent ("# JuanFi $iVer1 $iVer2 #\r\n".\
                "/ip hotspot active remove [find user=\"$iUsr\"]\r\n")
    if ($cfgShowLogs) do={
    set iEvent ("$iEvent".\
                "\r\n".\
                "local iExp \"Validity\"; if ([len \$1]>0) do={ set iExp \$1 };\r\n".\
                "local cUseT \"NO-UPTIME\";\r\n".\
                "log debug (\"JuanFi-EXP ( \$iExp ) => user=[ $iUsr ] ip=[ $iDevIP ] mac=[ $iDevMac ]\")\r\n".\
                "do {\r\n".\
                "if ([/ip hotspot user find name=\"$iUsr\"]!=\"\") do={\r\n".\
                "  local iUseT [/ip hotspot user get [find name=\"$iUsr\"] uptime];\r\n".\
                "  if (\$iUseT>0) do={ set cUseT \$iUseT };\r\n".\
                "} else={ log error (\"   ( $iUsr ) SySched ERROR! User Not Found! => /ip hotspot user [$iUsr]\") }\r\n".\
                "if ([/system scheduler find name=\"$iUsr\"]!=\"\") do={\r\n".\
                "} else={ log error (\"   ( $iUsr ) SySched ERROR! Scheduler Not Found! => /system scheduler [$iUsr]\") }\r\n".\
                "} on-error={ log error (\"   ( $iUsr ) SySched ERROR! Get Users Data Module!\") }\r\n".\
                "log debug (\"   ( $iUsr ) beg=[ $iUserBeg ] expiry=[ $iUserExp ] device=[ $cDevName ]\")\r\n".\
                "log debug (\"   ( $iUsr ) usertime=[ $cUsrTime ] validity=[ $iValidty ] uptime=[ \$cUseT ]\")\r\n")
    }
    set iEvent ("$iEvent\r\n".\
                "/ip hotspot cookie remove [find user=\"$iUsr\"]\r\n".\
                "/ip hotspot cookie remove [find mac-address=\"$iDevMac\"]\r\n".\
                "/system scheduler  remove [find name=\"$iUsr\"]\r\n".\
                "/ip hotspot user   remove [find name=\"$iUsr\"]\r\n".\
                "/file remove [find name=\"$iRoot/data/$iFileMac.txt\"]\r\n")
    set iEvent ("$iEvent".\
                "/file remove [find name=\"$iRoot/data/$iUsr.txt\"]\r\n".\
                "/file remove [find name=\"$iRoot/xData/U$iUsr.txt\"]\r\n".\
                "/file remove [find name=\"$iRoot/xData/M$iFileMac.txt\"]\r\n")
  /system scheduler set [find name=$iUsr] on-event=$iEvent
  } on-error={ log error ("   ( $iUsr ) OnLogin ERROR: Set User Scheduler on-event Module") }

  # Update Sales Module
  local iSalesToday; local iSalesMonth
  do {
  if ($cfgAddSales) do={
    local eAddSales do={
      local iUsr $1; local iSaleAmt $2; local iSalesName $3; local iSalesComment $4; local iTotalAmt 0
      if ([/system script find name=$iSalesName]="") do={
        log debug ("   ( $iUsr ) OnLogin SALES: AutoCreate! => /system script [$iSalesName]")
        /system script add name=$iSalesName source="0"
        local i 10;while (([/system script find name=$iSalesName]="")&&($i>0)) do={set i ($i-1);delay 1s}
      }
      if ([/system script find name=$iSalesName]!="") do={
        set iTotalAmt ($iSaleAmt + [tonum [/system script get [find name=$iSalesName] source]])
        /system script set [find name=$iSalesName] owner="sales script" source="$iTotalAmt" comment=$iSalesComment
      } else={ log error ("   ( $iUsr ) OnLogin ERROR: Sales Not Found! => /system script [$iSalesName]") }
      return $iTotalAmt
    }
    set iSalesToday [$eAddSales $iUsr $iSaleAmt "SalesToday" "juanfi: Sales Today"]
    set iSalesMonth [$eAddSales $iUsr $iSaleAmt "SalesMonth" "juanfi: Sales Month"]
  }
  } on-error={ log error ("   ( $iUsr ) OnLogin ERROR: Update Sales Module") }

  # Add User Data File Module
  do {
  if ($cfgAddFiles) do={
    local eSaveData do={
      local iUsr $1; local iRoot $2; local iPath $3; local iFile $4; local iContent $5
      if ([/file find name="$iRoot"]!="") do={
      if ([/file find name="$iRoot/$iPath"]="") do={
        log debug ("   ( $iUsr ) OnLogin PATH: AutoCreate! => /file [$iRoot/$iPath/]")
        do { /tool fetch dst-path=("$iRoot/$iPath/.") url="https://127.0.0.1/" } on-error={ }
        local i 10;while (([/file find name="$iRoot/$iPath"]="")&&($i>0)) do={set i ($i-1);delay 1s}
      }
      } else={ log error ("   ( $iUsr ) OnLogin ERROR: Root Not Found! => /file [$iRoot]") }
      if ([/file find name="$iRoot/$iPath"]!="") do={
      if ([/file find name="$iRoot/$iPath/$iFile.txt"]="") do={
        /file print file="$iRoot/$iPath/$iFile.txt" where name="$iFile.txt"
        local i 10;while (([/file find name="$iRoot/$iPath/$iFile.txt"]="")&&($i>0)) do={set i ($i-1);delay 1s}
      }
      } else={ log error ("   ( $iUsr ) OnLogin ERROR: Path Not Found! => /file [$iRoot/$iPath]") }
      if ([/file find name="$iRoot/$iPath/$iFile.txt"]!="") do={
        /file set "$iRoot/$iPath/$iFile.txt" contents=$iContent
      } else={ log error ("   ( $iUsr ) OnLogin ERROR: File Not Found! => /file [$iRoot/$iPath/$iFile.txt]") }
    }
    $eSaveData $iUsr $iRoot "data"  ("$iFileMac")  ("$iUsr#$iUserExp")
  }
  } on-error={ log error ("   ( $iUsr ) OnLogin ERROR: Add User Data File Module") }

  # Send Telegram Module
  do {
  if ($cfgTelegram) do={
    set cDevName [pick $cDevName 0 15]
    local iMTIName [/system identity get name]
    local iUActive [/ip hotspot active print count-only]
    local iType "new"; if ($iExtCode=1) do={ set iType "ext" }
    local iText ("<<===[ $iMTIName ]===>>%0A".\
                 "Interface : $iDevInt%0A".\
                 "User Code : $iUsr ( $iType )%0A".\
                 "User Time : $cUsrTime%0A".\
                 "Validity : $cValidty%0A".\
                 "Dev IP : $iDevIP%0A".\
                 "Dev MAC : $iDevMac%0A".\
                 "Dev : $cDevName%0A")
    if ($cfgAddSales) do={
      set iText ("$iText%0A%0A".\
                 "Sales Amount : $iSaleAmt%0A".\
                 "Sales (Today) : $iSalesToday%0A".\
                 "Sales (Month) : $iSalesMonth%0A".\
                 "Vendo Name : $iVendTag%0A".\
                 "Sales (Today) : $iVendoToday%0A".\
                 "Sales (Month) : $iVendoMonth%0A".\
                 "<<==[ ActiveUsers : $iUActive ]==>>")
    }
    set iText [$eReplace ($iText) " " "%20"]
    local iURL ("https://"."api.telegram.org/bot$cfgTGBToken/sendmessage\?chat_id=$cfgTGChatID&text=$iText")
    do { /tool fetch url=$iURL keep-result=no } on-error={ log error ("   ( $iUsr ) Telegram ERROR: Telegram Sending Failed") }
  }
  } on-error={ log error ("   ( $iUsr ) OnLogin ERROR: Send Telegram Module") }

  # Set User/Scheduler Comment Info Module
  do {
  if ($cfgAddInfos) do={
    local cUsrNote "+ ( $iVendTag ) interface=[$iDevInt] mac=[$iDevMac] validity=[$iUserExp] comment=[$iComment] < $iType >"
    local cSchNote "+ ( $iVendTag ) interface=[$iDevInt] mac=[$iDevMac] limit-uptime=[$cUsrTime] comment=[$iComment] < $iType >"
    /ip hotspot user  set [find name=$iUsr] comment=$cUsrNote
    /system scheduler set [find name=$iUsr] comment=$cSchNote
  }
  } on-error={ log error ("   ( $iUsr ) OnLogin ERROR: Update User Comment Info Module") }

} else={
  local aHSA [/ip hotspot active get [find user=$iUsr]]
  log debug ("JuanFi-IN => user=[ $iUsr ] ip=[ $address ] mac=[ $"mac-address" ] email=[ $eMail ] login-by=[ $($aHSA->"login-by") ]")
}

# Fix Random MAC Login
if (1) do={
  local iDevMac $"mac-address"
  /ip hotspot active remove [find user="$iUsr" mac-address!="$iDevMac"]
}

```

#### Step 2: Copy script below and paste to hotspot user profile onLogout.
```bash
# JuanFi onLogout v9.0d starter
# by: Chloe Renae & Edmar Lozada
# ------------------------------

local iUsr $username
local aHSU [/ip hotspot user get $iUsr]
local iUsrTime ($aHSU->"limit-uptime")
local iUseTime ($aHSU->"uptime")

if ($cause!="admin reset") do={
  local cUsrTime "UNLIMITED"
  local iBalTime "UNLIMITED"
  if ($iUsrTime>0) do={
    set cUsrTime $iUsrTime
    set iBalTime ($iUsrTime-$iUseTime)
  }
  log debug ("JuanFi-OUT => user=[ $iUsr ] limit=[ $cUsrTime ] uptime=[ $iUseTime ] remaining=[ $iBalTime ] cause=[ $cause ]")
}

# Check Expiration
if ($cause="traffic limit reached" || (($iUsrTime>0) && ($iUsrTime<=$iUseTime))) do={
  local iSSched [parse [/system scheduler get [find name=$iUsr] on-event]]
  $iSSched "TimeLimit"
}

```

#### Step 3: Copy script below and paste to winbox terminal.
```bash
# ==============================
# JuanFi Sales Reset Daily/Monthly
# by: Chloe Renae & Edmar Lozada
# ------------------------------

{ loca eName "<eJuanFiSalesReset>"
if ([/system scheduler find name=$eName]="") do={ /system scheduler add name=$eName }
/system scheduler set [find name=$eName] start-time=00:00:05 interval=1d \
 disabled=no comment="sysched: JuanFi Sales Reset Daily/Monthly" \
 on-event=("\
# $eName #\r
# by: Chloe Renae & Edmar Lozada\r
# ------------------------------\r
local sToday \"SalesToday\"
local sMonth \"SalesMonth\"
local iSalesToday [/system script get [find name=\$sToday] source]
/log debug \"<<< Sales Today is \$iSalesToday.00 >>>\"
/system script set [find name=\$sToday] owner=\"sales script\" source=\"0\"

local iDate [/system clock get date]
local iDay [pick \$iDate 8 10]
if ([len \$iDate]>10) do={set iDay [pick \$iDate 4 6]}
if (\$iDay=\"01\") do={
  local iSalesMonth [/system script get [find name=\$sMonth] source]
  log debug \"<<< Sales Month is \$iSalesMonth.00 >>>\"
  /system script set [find name=\$sMonth] owner=\"sales script\" source=\"0\"
}
# ------------------------------\r\n") }

```
