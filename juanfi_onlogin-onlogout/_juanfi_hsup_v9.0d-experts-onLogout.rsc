# JuanFi onLogout v9.0d experts
# by: Chloe Renae & Edmar Lozada
# ------------------------------

local iUsr $username
local aHSU [/ip hotspot user get $iUsr]
local iUsrTime ($aHSU->"limit-uptime")
local iUseTime ($aHSU->"uptime")

# Check Expiration
if ($cause="traffic limit reached" || (($iUsrTime>0) && ($iUsrTime<=$iUseTime))) do={
  local iSSched [parse [/system scheduler get [find name=$iUsr] on-event]]
  $iSSched "TimeLimit"
}
