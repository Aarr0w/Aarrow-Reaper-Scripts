--[[
Description: Group selected tracks into a new folder track with a selected color
Version: 1.0
Author: Aarrow 
Donation: I'll add a paypal later...
          
Links: Aarrow's Website [ to be added later ...] 

About:
  Creates a new track to serve as a folder parent for the selected tracks,
  prompting the user for a name and color 
--]]

-- Licensed under the GNU GPL v3
if reaper.CountSelectedTracks(0) == 0 then
  return reaper.MB("No tracks selected","Error",0)
end

local ret,parentName = reaper.GetUserInputs("Creating folder...",1,"Parent name:","newFolder")
if not ret then return end


--integer retval, integer color = reaper.GR_SelectColor(HWND hwnd)\

--local returncol, color = reaper.GR_SelectColor(reaper.GetMainHwnd())
--if not returncol then return end
--local color = reaper.ColorToNative( math.random(256), math.random(256),math.random(256) )
--[[--------------------------------------------
use line 27  if you'd prefer a random color 
or prompting color select menu with lines 25&26 
(and remove line 43 ...'color = ')
---------------------------------------------]]


reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local firstTrack = reaper.GetSelectedTrack(0,0)
local parentIndex = reaper.GetMediaTrackInfo_Value(firstTrack,"IP_TRACKNUMBER")-1
local lastSel = reaper.GetSelectedTrack(0, reaper.CountSelectedTracks(0) - 1)
local lastSelIdx = reaper.GetMediaTrackInfo_Value(lastSel, "IP_TRACKNUMBER") - 1

local color = reaper.GetTrackColor(firstTrack)
-----------------------------------------------------------------------------



reaper.InsertTrackAtIndex(parentIndex,true)
local parent = reaper.GetTrack(0,parentIndex)
reaper.GetSetMediaTrackInfo_String( parent, "P_NAME", parentName, true)
reaper.SetTrackColor(parent,color)

reaper.ReorderSelectedTracks(parentIndex+1,1)
reaper.SetTrackSelected(parent,true)
-----------------------------------------------------------------------------
local t
for indx = parentIndex, parentIndex + reaper.CountSelectedTracks(0)-1 do
  t = reaper.GetTrack(0,indx)
  reaper.SetTrackColor(t,color)
  
  if indx == parentIndex + reaper.CountSelectedTracks(0)-1 and 
    reaper.GetMediaTrackInfo_Value(t, "I_FOLDERDEPTH")==1 then
      repeat
        indx = indx + 1
        t = reaper.GetTrack(0,indx)
        reaper.SetTrackSelected(t,true)
        reaper.SetTrackColor(t,color)
      until  reaper.IsTrackSelected( reaper.GetParentTrack(reaper.GetTrack(0,indx+1)) ) == false
        or reaper.GetParentTrack(reaper.GetTrack(0,indx+1)) == nil
    end
end
-----------------------------------------------------------------------------
reaper.PreventUIRefresh( -1 )

reaper.TrackList_AdjustWindows( false )
reaper.UpdateArrange()

reaper.Undo_EndBlock("Create folder to contain selected tracks, choosing name and color", 0)
