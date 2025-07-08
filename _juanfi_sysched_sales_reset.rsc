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
