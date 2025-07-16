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
