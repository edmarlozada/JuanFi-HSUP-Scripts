## JuanFi onLogin/onLogout v9.0a ( lite )
- no need to define hotspot folder! (copyright)

### What's new (2025-07-07)
- now compatible with JuanFi Manager APK
- uses user-email to check valid entry
- cancel user-login if scheduler not created
- cancel user-login if invalid user comment

### What's in v9.0a ( lite )
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
- hEX GR3 7.12.1 Stable
- RB5009 7.8 Long Term
- CCR1009 6.49.10 Long Term

### WARNING:
- test first before deploy!

### Author:
- Chloe Renae & Edmar Lozada

### Facebook Contact:
- https://www.facebook.com/chloe.renae.2000

### Follow these steps:

#### Step 1: Copy script below and paste to hotspot user profile onLogin. ( _juanfi_hs_v9.0a-lite-onLogin.txt )
```bash
# JuanFi onLogin v9.0a lite
# by: Chloe Renae & Edmar Lozada
# ------------------------------

local cfgTelegram 0 ;# Send Login Details to Telegram
# Telegram Group Chat ID
local cfgTGChatID "xxxxxxxxxxxxxx"
# Telegram Bot Token
local cfgTGBToken "xxxxxxxxxx:xxxxxxxxxxxxx-xxxxxxxxxxxxxxx-xxxxx"

# ------------------------------ #
# Do NOT Edit below this point   #
# ------------------------------ #
local iUser $user
local aUser [/ip hotspot user get $iUser]
local eMail ($aUser->"email")

# Check Valid Entry via EMail
if (!($eMail~"active")) do={
  local eReplace do={loca iRet; loca x;for i from=0 to=([len $1]-1) do={set x [pick $1 $i];if ($x=$2) do={set x $3};set iRet ($iRet.$x)}; return $iRet}

  # Variables Module
  local iVer1 "v9.0a"; local iVer2 "lite"
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

  # Invalid Comment Module
  if (!($iValidty>=0 && $iSaleAmt>=0 && ($iExtCode=0 || $iExtCode=1))) do={
    if ([/system scheduler find name=$iUser]!="") do={
      log error ("   ( $iUser ) ONLOGIN UPDATE! email=[$iActMail] comment=[$iComment] => UPDATE ACTIVE USER EMAIL!")
      /ip hotspot user set [find name=$iUser] email=$iActMail; return ""
    } else={
      log error ("   ( $iUser ) ONLOGIN ERROR! email=[$eMail] comment=[$iComment] => NO SCHEDULER/INVALID COMMENT!")
      # what is the policy on user with invalid comment and/or no scheduler
      /ip hotspot user set [find name=$iUser] email=$iActMail comment="NO SCHEDULER"; return ""
    }
  }

  # Add User Scheduler Module
  if ([/system scheduler find name=$iUser]="") do={
    /system scheduler add name=$iUser interval=0
    loca i 10;while (([/system scheduler find name=$iUser]="")&&($i>0)) do={set i ($i-1);delay 1s}
  }

  # Cancel User-Login if user-scheduler NOT FOUND!
  if ([/system scheduler find name=$iUser]="") do={
    log error ("   ( $iUser ) ONLOGIN ERROR! email=[$eMail] comment=[$iComment] => SCHEDULER NOT FOUND!")
    /ip hotspot active remove [find user=$iUser]; return ""
  }

  # User Validity/Interval/Comment/eMail/BugFix Module
  local cUsrTime "NO-LIMIT"; local cValidty "NO-EXPIRY"
  set iValidty ($iValidty + [/system scheduler get [find name=$iUser] interval])
  if ($iValidty!=0s && $iValidty<=$iUsrTime) do={ set iValidty ($iUsrTime+30s) }; #BugFix ( Validity <= UserTime )
  /syste scheduler set [find name=$iUser] interval=$iValidty
  /ip hotspot user set [find name=$iUser] email=$iActMail comment=""
  if ($iUsrTime>0) do={ set cUsrTime $iUsrTime }
  if ($iValidty>0) do={ set cValidty $iValidty }

  # User Expire Module
  local iUserBeg; local iUserExp "NO EXPIRATION"
  local aSySched [/system scheduler get $iUser]
  local iNextRun ($aSySched->"next-run")
  set   iUserBeg (($aSySched->"start-date")." ".($aSySched->"start-time"))
  if ([len $iNextRun]>1) do={
    set iUserExp [pick $iNextRun 0 ([len $iNextRun]-3)]
  }

  # Set User Scheduler on-event Module
  local iEvent ("# JuanFi $iVer1 $iVer2 #\r\n".\
                "/ip hotspot active remove [find user=\"$iUser\"]\r\n".\
                "/ip hotspot cookie remove [find user=\"$iUser\"]\r\n".\
                "/ip hotspot cookie remove [find mac-address=\"$iDevMac\"]\r\n".\
                "/system scheduler  remove [find name=\"$iUser\"]\r\n".\
                "/ip hotspot user   remove [find name=\"$iUser\"]\r\n".\
                "/file remove [find name=\"$iRoot/data/$iFileMac.txt\"]\r\n")
  /system scheduler set [find name=$iUser] on-event=$iEvent

  # Update Sales Module
  local iSalesToday; local iSalesMonth; local iSalesTotal
    local eAddSales do={
      local iUser $1; local iSaleAmt $2; local iSalesName $3; local iSalesComment $4; local iTotalAmt 0
      if ([/system script find name=$iSalesName]="") do={
        /system script add name=$iSalesName source="0"
        loca i 10;while (([/system script find name=$iSalesName]="")&&($i>0)) do={set i ($i-1);delay 1s}
      }
      if ([/system script find name=$iSalesName]!="") do={
        set iTotalAmt ($iSaleAmt + [tonum [/system script get [find name=$iSalesName] source]])
        /system script set [find name=$iSalesName] source="$iTotalAmt" comment=$iSalesComment
      } else={ log error ("   ( $iUser ) ONLOGIN ERROR! /system script [$iSalesName] => SALES NOT FOUND!") }
      return $iTotalAmt
    }
    set iSalesToday [$eAddSales $iUser $iSaleAmt "SalesToday" "JuanFi Sales Today"]
    set iSalesMonth [$eAddSales $iUser $iSaleAmt "SalesMonth" "JuanFi Sales Month"]

  # Add User Data File Module
    local eSaveData do={
      local iUser $1; local iRoot $2; local iPath $3; local iFile $4; local iContent $5
      if ([/file find name="$iRoot"]!="") do={
      if ([/file find name="$iRoot/$iPath"]="") do={
        do { /tool fetch dst-path=("$iRoot/$iPath/.") url="https://127.0.0.1/" } on-error={ }
        loca i 10;while (([/file find name="$iRoot/$iPath"]="")&&($i>0)) do={set i ($i-1);delay 1s}
      }
      } else={ log error ("   ( $iUser ) ONLOGIN ERROR! /file [$iRoot] => ROOT NOT FOUND!") }
      if ([/file find name="$iRoot/$iPath"]!="") do={
        /file print file="$iRoot/$iPath/$iFile.txt" where name="$iFile.txt"
        loca i 10;while (([/file find name="$iRoot/$iPath/$iFile.txt"]="")&&($i>0)) do={set i ($i-1);delay 1s}
      } else={ log error ("   ( $iUser ) ONLOGIN ERROR! /file [$iRoot/$iPath] => PATH NOT FOUND!") }
      if ([/file find name="$iRoot/$iPath/$iFile.txt"]!="") do={
        /file set "$iRoot/$iPath/$iFile.txt" contents=$iContent
      } else={ log error ("   ( $iUser ) ONLOGIN ERROR! /file [$iRoot/$iPath/$iFile.txt] => FILE NOT FOUND!") }
    }
    $eSaveData $iUser $iRoot "data"  ("$iFileMac")  ("$iUser#$iUserExp")

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
    do { /tool fetch url=$iURL keep-result=no } on-error={ log error ("   ( $iUser ) TELEGRAM ERROR! Telegram Sending Failed") }
  }

}

# Fix Random MAC Login
if (1) do={
  local iDevMac $"mac-address"
  /ip hotspot active remove [find user="$iUser" mac-address!="$iDevMac"]
}

```

#### Step 2: Copy script below and paste to hotspot user profile onLogout. ( _juanfi_hs_v9.0a-lite-onLogout.txt )
```bash
# JuanFi onLogout v9.0a lite
# by: Chloe Renae & Edmar Lozada
# ------------------------------

local iUser $user
local aUser [/ip hotspot user get $iUser]
local iUsrTime ($aUser->"limit-uptime")
local iUseTime ($aUser->"uptime")

# Check Expiration
if ($cause="traffic limit reached" || (($iUsrTime>0) && ($iUsrTime<=$iUseTime))) do={
  [parse [/system scheduler get [find name=$iUser] on-event]]
}

```
