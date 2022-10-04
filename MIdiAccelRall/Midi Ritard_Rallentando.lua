--[[
Description: Creates accel. by shifting selected note positions
Version:  0.1
Author: Aarrow 
Donation: https://paypal.me/Aarr0w

          
Links: https://linktr.ee/aarr0w

About:
  Creates a new track to serve as a folder parent for the selected tracks,
  prompting the user for a name and color 
--]]

-- Licensed under the GNU GPL v3
-------------------------------------------------------------------------------

take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())

if take == nil then
end

local numSelected = reaper.MIDI_EnumSelNotes(take, 0)
if numSelected == 0 then
  return reaper.MB("No Notes Selected","Error",0)
end

local selected = {}
local sppq
local eppq
local chan
local pitch
local idx = -1
local unneeded1
local unneeded2
local vel
local muted
local inc = 0
local depth = 10 --general size of skips (10 is just visible change)
local intensity = 1 --increases gap (depth) incrementally //needs some exponential value in intensity*inc*10

------------------------------------------------------------------------------
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
------------------------------------------------------------------------------

while reaper.MIDI_EnumSelNotes(take,idx) > 0 do
  idx = reaper.MIDI_EnumSelNotes(take,0)
  selected[inc] = idx 
  unneeded1,unneeded2, muted,sppq, eppq, chan, pitch, vel = reaper.MIDI_GetNote(take, idx)
  --reaper.ShowConsoleMsg("\nnote idx :" ..idx .. "\n__sppq : "..sppq.. "\n__eppq :"..eppq .."\n===========")
 --retval, boolean selected, boolean muted, number startppqpos, number endppqpos, integer chan, integer pitch, integer vel = reaper.MIDI_GetNote(MediaItem_Take take, integer noteidx)
  reaper.MIDI_SetNote(take, idx, false, muted, sppq + intensity*inc*depth,  eppq + intensity*(inc+1)*depth, chan, pitch, vel)
 --reaper.MIDI_SetNote(MediaItem_Take take, integer noteidx, optional boolean selectedIn, optional boolean mutedIn, optional number startppqposIn, optional number endppqposIn, optional integer chanIn, optional integer pitchIn, optional integer velIn, optional boolean noSortIn)

 --reaper.MIDIEditor_OnCommand(reaper.MIDIEditor_GetActive(), 40182) // moves notes forward one pixel
 reaper.MIDIEditor_OnCommand(reaper.MIDIEditor_GetActive(), 40405) -- makes notes legato
 inc = inc+1
end
------------------------------------------------------------------------------
--for x in selected do
--end

-----------------------------------------------------------------------------
reaper.PreventUIRefresh( -1 )

reaper.TrackList_AdjustWindows( false )
reaper.UpdateArrange()

reaper.Undo_EndBlock("Gradually Slowed Midi Notes", 0)
