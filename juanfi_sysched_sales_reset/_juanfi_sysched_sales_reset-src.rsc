# <eJuanFiSalesReset> #
# by: Chloe Renae & Edmar Lozada
# ------------------------------
local sToday "SalesToday"
local sMonth "SalesMonth"
local iSalesToday [/system script get [find name=$sToday] source]
/log debug "<<< Sales Today is $iSalesToday.00 >>>"
/system script set [find name=$sToday] owner="sales script" source="0"

local iDate [/system clock get date]
local iDay [pick $iDate 8 10]
if ([len $iDate]>10) do={set iDay [pick $iDate 4 6]}
if ($iDay="01") do={
  local iSalesMonth [/system script get [find name=$sMonth] source]
  log debug "<<< Sales Month is $iSalesMonth.00 >>>"
  /system script set [find name=$sMonth] owner="sales script" source="0"
}
# ------------------------------
