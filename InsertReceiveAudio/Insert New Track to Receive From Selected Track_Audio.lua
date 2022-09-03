--[[
Description: Creates a new track after the selected track which receives the selected track's audio
Version: 1.0
Author: Aarrow 
Donation: I'll add a paypal later...
          
Links: Aarrow's Website [ to be added later ...] 

About:
  Creates a new track after the selected track which receives the selected track's audio
--]]

-- Licensed under the GNU GPL v3
---------------------- NOTES FOR USING HELPFUL FUNCTIONS  --------------------------------------------------------



--category is <0 for receives, 0=sends, >0 for hardware outputs

--integer reaper.CreateTrackSend(MediaTrack tr, MediaTrack desttrIn)
--reaper.SetTrackSendInfo_Value(MediaTrack tr, integer category, integer sendidx, string parmname, number newvalue)

--[[
I_SRCCHAN : int * : index,&1024=mono, -1 for none

I_DSTCHAN : int * : index, &1024=mono, otherwise stereo pair, hwout:&512=rearoute

P_DESTTRACK : MediaTrack * : destination track, only applies for sends/recvs (read-only)

P_SRCTRACK : MediaTrack * : source track, only applies for sends/recvs (read-only)
--]]


-- *** GetTrackDepth() DOES NOT RETURN THE SAME VALUE AS: GetMediaTrackInfo_Value(..."FOLDERDEPTH")
--[[
    FOR *** GetTrackDepth() :   ***
      0 = not in any folder
      1 = in a folder 
      2 = in a folder of a folder
      3 = in a 3rd level folder
      etc
      (all REGARDLESS of where it is in the folder)
      
    FOR *** GetMediaTrackInfo_Value(..."FOLDERDEPTH"): ***
      1 = folder parent                       (at any depth)
      0 = normal                              (does not start or end a folder)
      -1 = last track in first level folder
      -2 = last track in 2nd level folder
      etc


--]]
-------------------------------------------------------------------------------------------
if reaper.CountSelectedTracks(0) == 0 then
  return reaper.MB("No tracks selected","Error",0)
end
-------------------------------------------------------------------------------------------
local source = reaper.GetSelectedTrack(0,0)

local depth = reaper.GetTrackDepth(source)
local trueDepth = reaper.GetMediaTrackInfo_Value(source,"I_FOLDERDEPTH")
local rcvIndx
local receiver
----------------------SOURCE TRACK IS NOT A FOLDER-----------------------------------------
if trueDepth ~= 1 then
  
  rcvIndx = reaper.GetMediaTrackInfo_Value(source,"IP_TRACKNUMBER")
  reaper.InsertTrackAtIndex(rcvIndx , true)
  receiver = reaper.GetTrack( 0, rcvIndx )
  
  
    if trueDepth <0 then
       reaper.SetMediaTrackInfo_Value(source,"I_FOLDERDEPTH",0)
       reaper.SetMediaTrackInfo_Value(receiver,"I_FOLDERDEPTH",-depth)
    end
  
else --------------------SOURCE TRACK IS A FOLDER -----------------------------------------

  rcvIndx =  reaper.GetMediaTrackInfo_Value(source,"IP_TRACKNUMBER")
  
  ------ensures the new track is at the same folder - depth as the source track
  -- remember GetTrackDepth !=  MediaTrackInfo_Value(..."FOLDERDEPTH")  // see top for details
  while reaper.GetTrackDepth(reaper.GetTrack(0,rcvIndx)) ~= depth do  
    rcvIndx = rcvIndx + 1
    if not reaper.GetTrack(0,rcvIndx) then
      break
    end
  end
  
  reaper.InsertTrackAtIndex(rcvIndx , true)
  receiver = reaper.GetTrack( 0, rcvIndx )
  
  reaper.SetMediaTrackInfo_Value(receiver,"I_FOLDERDEPTH",0)
end
--------------------------------------------------------------------------------------------

reaper.SetTrackColor(receiver, reaper.GetTrackColor(source))
-- boolean retval, string stringNeedBig = reaper.GetSetTrackSendInfo_String(MediaTrack tr, integer category, integer sendidx, string parmname, string stringNeedBig, boolean setNewValue)
local retval, sourceName = reaper.GetTrackName(source)
reaper.GetSetMediaTrackInfo_String(receiver,"P_NAME",sourceName .. "-> ",true)

sendIndx = reaper.CreateTrackSend(source,receiver)
--reaper.SetTrackSendInfo_Value(MediaTrack tr, integer category, integer sendidx, string parmname, number newvalue)
-- DSTCHN : 1  = Channels 1,2
--          2  = Channels 3,4
--          3  = Channels 4,5 
--                     ...etc
reaper.SetTrackSendInfo_Value(source, 0, sendIndx,"I_SRCCHAN", -1)
reaper.SetTrackSendInfo_Value(source, 0, sendIndx,"I_MIDIFLAGS", 0000000000)


--------------------------------------------------------------------------------------------
reaper.PreventUIRefresh( -1 )

reaper.TrackList_AdjustWindows( false )
reaper.UpdateArrange()

reaper.Undo_EndBlock("Created new receive track; audio only", 0)

