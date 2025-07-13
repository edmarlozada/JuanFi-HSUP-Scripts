## JuanFi onLogin/onLogout v9.0b ( lite )
- no need to define hotspot folder! (copyright)

### What's new (2025-07-09)
- now compatible with JuanFi Manager APK
- uses user-email to check valid entry
- cancel user-login if scheduler not created
- cancel user-login if invalid user comment

### What's in v9.0b ( lite )
- system scheduler on-event minimize/with logs
- fix bug on validity ( if Validity <= UserTime )
- create logs for New/Extend user
- show login error on log
- auto create data folder if missing
- auto create sales file if missing
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

#### Step 1: Copy script below and paste to hotspot user profile onLogin. ( _juanfi_hs_v9.0c-starter-onLogin.rsc )
```bash
# JuanFi onLogin v9.0b starter
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
  local iActMail ("$iFileMac@juanfi.$iVer1.active")
  local iRoot    [/ip hotspot profile get [.. get [find interface=$iDevInt] profile] html-directory]
  local iType    "NEW"; if ($iExtCode=1) do={ set iType "EXT" }
  $eLogDebug ("JuanFi-$iType => user=[ $iUser ] ip=[ $iDevIP ] mac=[ $iDevMac ] interface=[ $iDevInt ] comment=[ $iComment ]") $cfgShowLogs

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

  # Add User Scheduler Module
  if ([/system scheduler find name=$iUser]="") do={
    /system scheduler add name=$iUser interval=0
    local i 10;while (([/system scheduler find name=$iUser]="")&&($i>0)) do={set i ($i-1);delay 1s}
  }

  # Cancel User-Login if user-scheduler NOT FOUND!
  if ([/system scheduler find name=$iUser]="") do={
    log error ("   ( $iUser ) OnLogin ERROR: Scheduler Not Found! => email=[$eMail] comment=[$iComment]")
    /ip hotspot active remove [find user=$iUser]; return ""
  }

  # User Validity/Interval/Comment/eMail/BugFix Module
  local cUsrTime "NO-LIMIT"; local cValidty "NO-VALIDITY"
  set iValidty ($iValidty + [/system scheduler get [find name=$iUser] interval])
  if ($iValidty!=0s && $iValidty<=$iUsrTime) do={ set iValidty ($iUsrTime+30s) }; #BugFix ( Validity <= UserTime )
  /syste scheduler set [find name=$iUser] interval=$iValidty
  /ip hotspot user set [find name=$iUser] email=$iActMail comment=""
  if ($iUsrTime>0) do={ set cUsrTime $iUsrTime }
  if ($iValidty>0) do={ set cValidty $iValidty }
  $eLogDebug ("   ( $iUser ) usertime=[ $cUsrTime ] validity=[ $cValidty ] amt=[ $iSaleAmt ] vendo=[ $iVendTag ] email=[ $eMail ] folder=[ $iRoot ]") $cfgShowLogs

  # User Expire Module
  local iUserBeg; local iUserExp "NO-EXPIRY"
  local aSySched [/system scheduler get $iUser]
  local iNextRun ($aSySched->"next-run")
  set   iUserBeg (($aSySched->"start-date")." ".($aSySched->"start-time"))
  if ([len $iNextRun]>1) do={
    set iUserExp [pick $iNextRun 0 ([len $iNextRun]-3)]
  }
  $eLogDebug ("   ( $iUser ) beg=[ $iUserBeg ] expiry=[ $iUserExp ] device=[ $cDevName ] profile=[ $iProfile ]") $cfgShowLogs

  # Set User Scheduler on-event Module
  local iEvent ("# JuanFi $iVer1 $iVer2 #\r\n".\
                "/ip hotspot active remove [find user=\"$iUser\"]\r\n".\
                "local iExp \"Validity\"; if ([len \$1]>0) do={ set iExp \$1 };\r\n".\
                "log debug (\"JuanFi-EXP ( \$iExp ) => user=[ $iUser ] ip=[ $iDevIP ] mac=[ $iDevMac ]\")\r\n".\
                "/ip hotspot cookie remove [find user=\"$iUser\"]\r\n".\
                "/ip hotspot cookie remove [find mac-address=\"$iDevMac\"]\r\n".\
                "/system scheduler  remove [find name=\"$iUser\"]\r\n".\
                "/ip hotspot user   remove [find name=\"$iUser\"]\r\n".\
                "/file remove [find name=\"$iRoot/data/$iFileMac.txt\"]\r\n")
  /system scheduler set [find name=$iUser] on-event=$iEvent

  # Update Sales Module
  local iSalesToday; local iSalesMonth
    local eAddSales do={
      local iUser $1; local iSaleAmt $2; local iSalesName $3; local iSalesComment $4; local iTotalAmt 0
      if ([/system script find name=$iSalesName]!="") do={
        set iTotalAmt ($iSaleAmt + [tonum [/system script get [find name=$iSalesName] source]])
        /system script set [find name=$iSalesName] source="$iTotalAmt" comment=$iSalesComment
      } else={ log error ("   ( $iUser ) OnLogin ERROR: Sales Not Found! => /system script [$iSalesName]") }
      return $iTotalAmt
    }
    set iSalesToday [$eAddSales $iUser $iSaleAmt "SalesToday" "JuanFi Sales Today"]
    set iSalesMonth [$eAddSales $iUser $iSaleAmt "SalesMonth" "JuanFi Sales Month"]

  # Add User Data File Module
    local eSaveData do={
      local iUser $1; local iRoot $2; local iPath $3; local iFile $4; local iContent $5
      if ([/file find name="$iRoot/$iPath"]!="") do={
      if ([/file find name="$iRoot/$iPath/$iFile.txt"]="") do={
        /file print file="$iRoot/$iPath/$iFile.txt" where name="$iFile.txt"
        local i 10;while (([/file find name="$iRoot/$iPath/$iFile.txt"]="")&&($i>0)) do={set i ($i-1);delay 1s}
      }
      } else={ log error ("   ( $iUser ) OnLogin ERROR: Path Not Found! => /file [$iRoot/$iPath]") }
      if ([/file find name="$iRoot/$iPath/$iFile.txt"]!="") do={
        /file set "$iRoot/$iPath/$iFile.txt" contents=$iContent
      } else={ log error ("   ( $iUser ) OnLogin ERROR: File Not Found! => /file [$iRoot/$iPath/$iFile.txt]") }
    }
    $eSaveData $iUser $iRoot "data"  ("$iFileMac")  ("$iUser#$iUserExp")

  # Send Telegram Module
  if ($cfgTelegram) do={
    local iUActive [/ip hotspot active print count-only]
    local iType "new"; if ($iExtCode=1) do={ set iType "ext" }
    local iText ("<<===[ $iVendTag ]===>>%0A".\
                 "User Code : $iUser ( $iType )%0A".\
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
    do { /tool fetch url=$iURL keep-result=no } on-error={ log error ("   ( $iUser ) Telegram ERROR: Telegram Sending Failed") }
  }

}

# Fix Random MAC Login
if (1) do={
  local iDevMac $"mac-address"
  /ip hotspot active remove [find user="$iUser" mac-address!="$iDevMac"]
}

```

#### Step 2: Copy script below and paste to hotspot user profile onLogout. ( _juanfi_hs_v9.0c-starter-onLogout.rsc )
```bash
# JuanFi onLogout v9.0a starter
# by: Chloe Renae & Edmar Lozada
# ------------------------------

local iUser $user
local aUser [/ip hotspot user get $iUser]
local iUsrTime ($aUser->"limit-uptime")
local iUseTime ($aUser->"uptime")

# Check Expiration
if ($cause="traffic limit reached" || (($iUsrTime>0) && ($iUsrTime<=$iUseTime))) do={
  local iSSched [parse [/system scheduler get [find name=$iUser] on-event]]
  $iSSched "TimeLimit"
}

```

#### Step 3: Copy script below and paste to winbox terminal ( _juanfi_sysched_sales_reset.rsc )
```bash
# ==============================
# JuanFi Reset Daily/Monthly Sales
# by: Chloe Renae & Edmar Lozada
# ------------------------------

{ loca eName "<JuanFi-Reset-Sales>"
if ([/system scheduler find name=$eName]="") do={ /system scheduler add name=$eName }
/system scheduler set [find name=$eName] start-time=00:00:05 interval=1d \
 disabled=no comment="system_schedulers: JuanFi Reset Daily/Monthly Sales" \
 on-event=("\
# $eName #\r
# by: Chloe Renae & Edmar Lozada\r
# ------------------------------\r
local sToday \"SalesToday\"
local sMonth \"SalesMonth\"
local iSalesToday [/system script get [find name=\$sToday] source]
log debug \"<<< Sales Today is \$iSalesToday.00 >>>\"
/system script set [find name=\$sToday] source=\"0\"

local iDate [/system clock get date]
local iDay [pick \$iDate 8 10]
if ([len \$iDate]>10) do={set iDay [pick \$iDate 4 6]}
if (\$iDay=\"01\") do={
  local iSalesMonth [/system script get [find name=\$sMonth] source]
  log debug \"<<< Sales Month is \$iSalesMonth.00 >>>\"
  /system script set [find name=\$sMonth] source=\"0\"
}
# ------------------------------\r\n") }

```
