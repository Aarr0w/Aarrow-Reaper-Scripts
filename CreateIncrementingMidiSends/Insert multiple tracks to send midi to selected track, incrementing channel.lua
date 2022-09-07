--[[
Description: Creates a new tracks which will send midi to selected track on different channels

Version: 1.0
Author: Aarrow 
Donation: 5artsaudio@gmail.com
Links: https://linktr.ee/aarr0w

About:
  Creates new tracks after the selected track which sends midi to selected track on different channels
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

local ret,trackCount = reaper.GetUserInputs("Creating tracks...",1,"How many?",1)
if not ret then return end
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
  
  
    
  
  for x = srcIndx, srcIndx + trackCount - 1 do 
    reaper.InsertTrackAtIndex(x , true)
    source = reaper.GetTrack( 0, x) 
    
    --_MIDIFLAGS : int * : low 5 bits=source channel 0=all, 1-16, next 5 bits=dest channel, 0=orig, 1-16=chan
    
    --31.0 = None
    --(32*destChan) + (1*sourceChannel);  
    --      129 = Channel 1 >> Channel 4 ;
    --      32  = All >> Channel 1 ;
    reaper.SetTrackColor(source, reaper.GetTrackColor(receiver))
    local retval, receiverName = reaper.GetTrackName(receiver)
    reaper.GetSetMediaTrackInfo_String(source,"P_NAME",receiverName .. "\\",true)
    
    
    channel = x-srcIndx+1
    sendIndx = reaper.CreateTrackSend(source,receiver)
    reaper.SetTrackSendInfo_Value(source, 0, sendIndx,"I_MIDIFLAGS", 32*channel)
    reaper.SetTrackSendInfo_Value(source, 0, sendIndx,"I_SRCCHAN", -1)
  end
 

  
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
  
  for x = srcIndx, srcIndx + trackCount - 1 do 
    reaper.InsertTrackAtIndex(x,true)
    source = reaper.GetTrack(0,x)
    
    reaper.SetTrackColor(source, reaper.GetTrackColor(receiver))
    local retval, receiverName = reaper.GetTrackName(receiver)
    reaper.GetSetMediaTrackInfo_String(source,"P_NAME",receiverName .. "\\",true)
    
    channel = x-srcIndx+1
    sendIndx = reaper.CreateTrackSend(source,receiver)
    reaper.SetTrackSendInfo_Value(source, 0, sendIndx,"I_MIDIFLAGS", 32*channel)
    reaper.SetTrackSendInfo_Value(source, 0, sendIndx,"I_SRCCHAN", -1)
  end
  
  reaper.SetMediaTrackInfo_Value(source,"I_FOLDERDEPTH",0)
end
--------------------------------------------------------------------------------------------

--sendIndx = reaper.CreateTrackSend(source,receiver)

--reaper.SetTrackSendInfo_Value(MediaTrack tr, integer category, integer sendidx, string parmname, number newvalue)
-- DSTCHN : 1  = Channels 1,2
--          2  = Channels 3,4
--          3  = Channels 4,5 
--                     ...etc




--------------------------------------------------------------------------------------------
reaper.PreventUIRefresh( -1 )

reaper.TrackList_AdjustWindows( false )
reaper.UpdateArrange()

reaper.Undo_EndBlock("Created new midi send tracks", 0)
--]]
