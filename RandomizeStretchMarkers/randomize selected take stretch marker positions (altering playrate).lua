--[[ 
Description: Alters playrate between stretch markers
Version: 1.1
Author: Aarrow 
Donation: https://paypal.me/Aarr0w

          
Links: https://linktr.ee/aarr0w
 
About:
   Alters stretch marker positions w/ 0.0 slope, effectively altering playrate
--]]

local item = reaper.GetSelectedMediaItem(0,0)
local take = reaper.GetTake(item,0)
local position 
local slope = 1

math.randomseed(os.time())
---------------------------------------------------------------------------
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
---------------------------------------------------------------------------

for i = 0, reaper.GetTakeNumStretchMarkers(take) do
  
  retval, position, srcpos = reaper.GetTakeStretchMarker(take, i)
  
  reaper.SetTakeStretchMarkerSlope(take,i,0.0)
  position = position + math.random(-100,100)*0.01  
 
  
  reaper.SetTakeStretchMarker(take,i,position)  
  --local retval, position, srcpos = reaper.GetTakeStretchMarker(take, i)
end      
----------------------------------------------------------------------------
reaper.PreventUIRefresh( -1 )

reaper.TrackList_AdjustWindows( false )
reaper.UpdateArrange()

reaper.Undo_EndBlock("Randomized stretch marker playspeed", 0)
