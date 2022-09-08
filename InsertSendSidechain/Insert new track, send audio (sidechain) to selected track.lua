--[[
Description: Creates a new track which sends audio to selected track
Version: 1.1
Author: Aarrow 
Donation: https://paypal.me/Aarr0w
Links: https://linktr.ee/aarr0w

About: Creates a new track which sends audio to selected track

--]]

-- Licensed under the GNU GPL v3
-------------------------------------------------------------------------------------------
if reaper.CountSelectedTracks(0) == 0 then
  return reaper.MB("No tracks selected","Error",0)
end
-------------------------------------------------------------------------------------------
local receiver = reaper.GetSelectedTrack(0,0)

local depth = reaper.GetTrackDepth(receiver)
local trueDepth = reaper.GetMediaTrackInfo_Value(receiver,"I_FOLDERDEPTH")
local srcIndx
local source

srcIndx = reaper.GetMediaTrackInfo_Value(receiver,"IP_TRACKNUMBER")
-------------------------------------------------------------------------------------------------
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
----------------------SOURCE TRACK IS NOT A FOLDER-----------------------------------------
if trueDepth ~= 1 then

    reaper.InsertTrackAtIndex(srcIndx , true)
    source = reaper.GetTrack( 0, srcIndx) 
    
    if trueDepth <0 then
       reaper.SetMediaTrackInfo_Value(receiver,"I_FOLDERDEPTH",0)
       reaper.SetMediaTrackInfo_Value(source,"I_FOLDERDEPTH",-depth)
    end
  
else --------------------SOURCE TRACK IS A FOLDER -----------------------------------------

  
  ------ensures the new track is at the same folder - depth as the source track
  -- remember GetTrackDepth !=  MediaTrackInfo_Value(..."FOLDERDEPTH")  // see top for details
  
  while reaper.GetTrackDepth(reaper.GetTrack(0,srcIndx)) ~= depth do  
    srcIndx = srcIndx + 1
    if not reaper.GetTrack(0,srcIndx) then
      break
    end
  end
  

  reaper.InsertTrackAtIndex(srcIndx,true)
  source = reaper.GetTrack(0,srcIndx)
    
  sendIndx = reaper.CreateTrackSend(source,receiver)
  
  reaper.SetMediaTrackInfo_Value(source,"I_FOLDERDEPTH",0)
end
--------------------------------------------------------------------------------------------

reaper.SetTrackColor(source, reaper.GetTrackColor(receiver))
local retval, receiverName = reaper.GetTrackName(receiver)
reaper.GetSetMediaTrackInfo_String(source,"P_NAME",receiverName .. "\\",true)

sendIndx = reaper.CreateTrackSend(source,receiver)
reaper.SetTrackSendInfo_Value(source, 0, sendIndx,"I_MIDIFLAGS", 31.0)
reaper.SetTrackSendInfo_Value(source, 0, sendIndx,"I_SRCCHAN", 0.0)

reaper.SetMediaTrackInfo_Value(receiver,"I_NCHAN",4)
reaper.SetTrackSendInfo_Value(source, 0, sendIndx,"I_DSTCHAN", 2)

--------------------------------------------------------------------------------------------
reaper.PreventUIRefresh( -1 )

reaper.TrackList_AdjustWindows( false )
reaper.UpdateArrange()

reaper.Undo_EndBlock("Created new sidechain send track", 0)
--]]
