--[[ 
Description: Randomizes slope and position of stretch markers
Version: 1.1
Author: Aarrow 
Donation: https://paypal.me/Aarr0w
  
          
Links: https://linktr.ee/aarr0w
  
About:
  Glitch it up, yo
--]]
   
local item = reaper.GetSelectedMediaItem(0,0)
local take = reaper.GetTake(item,0)
local position 
local slope = 1  

math.randomseed(os.time())
   
-----------------------------------------------------------------------------
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
-----------------------------------------------------------------------------
 
for i = 0, reaper.GetTakeNumStretchMarkers(take) do
  
  retval, position, srcpos = reaper.GetTakeStretchMarker(take, i)
  slope = reaper.GetTakeStretchMarkerSlope(take, i)
  
 
  position = position + math.random(-50,50)*0.01 -- not exactly sure how this works but.... it does :)
  
  slope = math.random(-100,100)* 0.01
  reaper.SetTakeStretchMarkerSlope(take,i,slope)
 
  
  --reaper.SetTakeStretchMarker(take,i,position, position - math.random(100)*0.01)  
  reaper.SetTakeStretchMarker(take,i,position)  
  --retval, position, srcpos = reaper.GetTakeStretchMarker(take, i)

end      
------------------------------------------------------------------------------
reaper.PreventUIRefresh( -1 )

reaper.TrackList_AdjustWindows( false )
reaper.UpdateArrange()

reaper.Undo_EndBlock("randomized stretch markers", 0)
      
