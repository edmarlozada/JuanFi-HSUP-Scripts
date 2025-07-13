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
