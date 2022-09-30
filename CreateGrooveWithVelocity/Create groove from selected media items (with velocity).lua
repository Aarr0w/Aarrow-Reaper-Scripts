--[[
Description: Creates Groove From Selected Media Items With Velocity Based on Peak Values
Version: 1.0
Author: Aarrow 
Donation: https://paypal.me/Aarr0w

          
Links: https://linktr.ee/aarr0w

About:
  Creates a new track to serve as a folder parent for the selected tracks,
  prompting the user for a name and color 
--]]

--DOES NOT work on midi items (use SWS 'create groove' function) 
-------------------------------------------------------------------------------------------------
if reaper.CountSelectedMediaItems(0) < 3 then
  return reaper.MB("Not enough items selected","Error",0)
end

-------------------------------------------------------------------------------------------------
reaper.Undo_BeginBlock()
-------------------------------------------------------------------------------------------------
-- Function description --
 -- retval, maximum peak value, maximum peak pos = get_sample_max_val_and_pos(MediaItem_Take, bool adj_for_take_vol, bool adj_for_item_vol, bool val_is_dB)
 
 --  Returns false if failed
 --  maximum peak value: Peak value is returned in decibels if val_is_dB = true
 --  maximum peak pos: Peak sample position in item time
 
 function get_sample_max_val_and_pos(take, adj_for_take_vol, adj_for_item_vol, val_is_dB)
   local ret = false
   if take == nil then
     return
   end
 
   local item = reaper.GetMediaItemTake_Item(take) -- Get parent item
 
   if item == nil then
     return
   end
 
   local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
 
   -- Get media source of media item take
   local take_pcm_source = reaper.GetMediaItemTake_Source(take)
   if take_pcm_source == nil then
     return
   end
 
   -- Create take audio accessor
   local aa = reaper.CreateTakeAudioAccessor(take)
   if aa == nil then
     return
   end
 
   -- Get the start time of the audio that can be returned from this accessor
   local aa_start = reaper.GetAudioAccessorStartTime(aa)
   -- Get the end time of the audio that can be returned from this accessor
   local aa_end = reaper.GetAudioAccessorEndTime(aa)
 
 
   -- Get the length of the source media. If the media source is beat-based,
   -- the length will be in quarter notes, otherwise it will be in seconds.
   local take_source_len, length_is_QN = reaper.GetMediaSourceLength(take_pcm_source)
   if length_is_QN then
     return
   end
 
   -- Get the number of channels in the source media.
   local take_source_num_channels = reaper.GetMediaSourceNumChannels(take_pcm_source)
 
   local channel_data = {} -- max peak values (per channel) are collected to this table
   -- Initialize channel_data table
   for i=1, take_source_num_channels do
     channel_data[i] = {
                         peak_val = 0,
                         peak_sample_index = -1
                       }
   end
 
   -- Get the sample rate. MIDI source media will return zero.
   local take_source_sample_rate = reaper.GetMediaSourceSampleRate(take_pcm_source)
   if take_source_sample_rate == 0 then
     return
   end
 
   -- How many samples are taken from audio accessor and put in the buffer
   local samples_per_channel = take_source_sample_rate
 
   -- Samples are collected to this buffer
   local buffer = reaper.new_array(samples_per_channel * take_source_num_channels)
 
   -- (These are not needed at the moment)
   --local take_start_offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
   --local take_playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
   --take_pos = item_pos-start_offs
 
   local total_samples = math.ceil((aa_end - aa_start) * take_source_sample_rate)
   --total_samples = math.floor((aa_end - aa_start) * take_source_sample_rate)
   --total_samples = (aa_end - aa_start) * take_source_sample_rate
  
   local block = 0
   local sample_count = 0
   local audio_end_reached = false
   local offs = aa_start
 
   local log10 = function(x) return math.log(x, 10) end
   local abs = math.abs
   --local floor = math.floor
 
 
   -- Loop through samples
   while sample_count < total_samples do
     if audio_end_reached then
       break
     end
 
     -- Get a block of samples from the audio accessor.
     -- Samples are extracted immediately pre-FX,
     -- and returned interleaved (first sample of first channel,
     -- first sample of second channel...). Returns 0 if no audio, 1 if audio, -1 on error.
     local aa_ret =
             reaper.GetAudioAccessorSamples(
                                             aa,                       -- AudioAccessor accessor
                                             take_source_sample_rate,  -- integer samplerate
                                             take_source_num_channels, -- integer numchannels
                                             offs,                     -- number starttime_sec
                                             samples_per_channel,      -- integer numsamplesperchannel
                                             buffer                    -- reaper.array samplebuffer
                                           )
 
     if aa_ret <= 0 then
       --msg("no audio or other error")
       --return
     end
 
     for i=1, #buffer, take_source_num_channels do                  --#buffer === length of buffer array
       if sample_count == total_samples then
         audio_end_reached = true
         break
       end
       for j=1, take_source_num_channels do
         local buf_pos = i+j-1
         local curr_val = abs(buffer[buf_pos])
         if curr_val > channel_data[j].peak_val then
           -- store current peak value for this channel
           channel_data[j].peak_val = curr_val
           -- store current peak sample index for this channel
           channel_data[j].peak_sample_index = sample_count
         end
       end
       sample_count = sample_count + 1
     end
     block = block + 1
     offs = offs + samples_per_channel / take_source_sample_rate -- new offset in take source (seconds)
   end
 
   reaper.DestroyAudioAccessor(aa)
 
   local max_peak_val = 0
   local channel = 0
   local peak_sample_index = -1
 
   -- Collect data to "peak_values" -table
   for i=1, take_source_num_channels do
     if channel_data[i].peak_val > max_peak_val then
       -- get max peak value from "channel_data" table
       max_peak_val = channel_data[i].peak_val
       -- get peak sample index from "channel_data" table
       peak_sample_index = channel_data[i].peak_sample_index
       -- max_peak_val found -> store current channel index
       -- channel = i
     end
   end
 
   --peak_values[#peak_values + 1] = max_peak_val
   --[[
   local cursor_pos = item_pos + peak_sample_index/take_source_sample_rate
   reaper.SetEditCurPos(cursor_pos, true, false)
   reaper.UpdateArrange()
   --]]
 
 
   --reaper.UpdateArrange()
   --msg("Getting samples from take " .. tostring(i) .. "/" .. tostring(reaper.CountSelectedMediaItems(0)))
 -- end
 
 
   -- Calculate corrections for take/item volume
   if adj_for_take_vol then
     max_peak_val = max_peak_val * reaper.GetMediaItemTakeInfo_Value(take, "D_VOL")
   end
 
   if adj_for_item_vol then
     max_peak_val = max_peak_val * reaper.GetMediaItemInfo_Value(item, "D_VOL")
   end
 
   if val_is_dB then
     max_peak_val = 20*log10(max_peak_val)
   end
 
   local peak_sample_pos = peak_sample_index/take_source_sample_rate
 
   if max_peak_val > 0 then
     ret = true
   end
 
   if peak_sample_pos >= 0 then
     ret = true
   end
 
   return ret, max_peak_val, peak_sample_pos
 end


-------------------------------------------------------------------------------------------------
function printTable(t)

  s = "{"
  for k, v in pairs(t) do
      s = s .. v .."\n"
  end
  s = s .. "}"
  return s
end
--------------------------------------------------------------------------------
local temp = reaper.GetSelectedMediaItem(0,0)
local selTrack = reaper.GetMediaItem_Track(temp)
--reaper.Main_OnCommandEx(integer command, integer flag, ReaProject proj) 

local iCount = reaper.CountSelectedMediaItems(0)
local ic = iCount
local peaks   = {}
local mPos    = {}
local startPos = reaper.GetMediaItemInfo_Value( reaper.GetSelectedMediaItem(0,0), "D_POSITION" )
local iPos
local selectedItem
local take
----------------------------------------------------------------------------------
for i = 0, ic - 1 do
  
  selectedItem = reaper.GetSelectedMediaItem(0,i)
  if reaper.TakeIsMIDI(reaper.GetMediaItemTake(selectedItem,0)) then
    return reaper.MB("MIDI files selected, please select only peak files","Error",0)
  end
  iPos = reaper.GetMediaItemInfo_Value( selectedItem, "D_POSITION" )
  local take = reaper.GetMediaItemTake(selectedItem, 0)
  
  --********************** MAKE SURE THERE ARENT ANY MIDI ITEMS SELECTED *************************
  local retval, peakVal, peakPos = get_sample_max_val_and_pos(take, false, false, true) -- returns as dB
  --reaper.ShowConsoleMsg("\nPeakValue: " .. peakVal)
  
  peaks[i+1]  = peakVal
  mPos[i+1]   = iPos
  
end

local endPos = iPos + reaper.GetMediaItemInfo_Value( selectedItem, "D_LENGTH" )

--reaper.ShowConsoleMsg("\nICOUNT : " .. iCount)

-- determine outliers-------------------------------------------------------------------------------------
--local orderedPeaks = peaks    .... this copies array by reference.... and causes me headaches
local orderedPeaks = {}
local lowerLimit  
local upperLimit
local IQR
local average
local inc = 0


for j,x in ipairs(peaks) do orderedPeaks[j] = x end
table.sort(orderedPeaks)
--reaper.ShowConsoleMsg("\n-----" .. "\n" .. printTable(orderedPeaks))

if iCount < 5 then
  --reaper.ShowConsoleMsg("\nToo small! At least five items in selection required ")
  lowerLimit = -1000
  upperLimit = 1000
  IQR = math.abs(orderedPeaks[#orderedPeaks]- orderedPeaks[1]) 
else
  local qrtr = math.floor(iCount/4)  
  local thirdQrtr = math.floor( (iCount*3)/4 )
  local q1  =  (orderedPeaks[qrtr] +      orderedPeaks[math.max(1,qrtr+1)])   /2
  local q3  =  (orderedPeaks[thirdQrtr]+  orderedPeaks[thirdQrtr-1])        /2 

  IQR = math.abs(q3-q1)
  lowerLimit = q1 - (1.5*IQR) 
  upperLimit = q3 + (1.5*IQR) 
  --reaper.ShowConsoleMsg("\nQ3 :" .. q3)
  --reaper.ShowConsoleMsg("\nQ1 :" .. q1) 
  --reaper.ShowConsoleMsg("\nIQR :" .. IQR)
  reaper.ShowConsoleMsg("\nlowest Value :" .. orderedPeaks[1])
  reaper.ShowConsoleMsg("\nhighest Value :" .. orderedPeaks[#peaks-1])
  reaper.ShowConsoleMsg("\nLower Limit :" .. lowerLimit)
  reaper.ShowConsoleMsg("\nUpper Limit :" .. upperLimit)
end

-- find average value of peaks

local sum = 0

for k,v in pairs(peaks) do
    if v >= lowerLimit and v<= upperLimit then
      sum = sum + v
      inc = inc +1 
    end
end

average = (sum / inc)
--reaper.ShowConsoleMsg("\nAVERAGE VOLUME : " .. average)
-- create new track and store MIDI------------------------------------------------------------------------

local idx = reaper.GetMediaTrackInfo_Value( selTrack,"IP_TRACKNUMBER")
reaper.InsertTrackAtIndex( reaper.GetMediaTrackInfo_Value( selTrack,"IP_TRACKNUMBER"), true)
local newTrack = reaper.GetTrack(0,idx)
local midiItemTake =  reaper.GetMediaItemTake(reaper.CreateNewMIDIItemInProj(newTrack, startPos, endPos ),0)
local velocity 
local position
local offset 
local qn
local ppq
local scale = 50 / IQR 

local bpm, bpi = reaper.GetProjectTimeSignature()
local noteLength = ( 60000/bpm ) /4 --corresponds to the length on one sixteenth note (assuming bpm doesn't change w/in the project)
reaper.MIDI_Sort(midiItemTake)  -- I *think* this helps when midi is getting frozen


--------------------------------------- place midi with values scaled to velocity --------------------------------
for x = 1, iCount do

  velocity = math.min( 
             math.max( 10, 75 - math.ceil(scale * (average - peaks[x])) ),
                 127)
            --reaper.ShowConsoleMsg("\nCurrent Peak: " .. peaks[x] .. "| adding " .. (velocity-75))
  --]]

  
  position    = mPos[x] 
  offset      = startPos
  qn          = reaper.TimeMap2_timeToQN(nil, position - offset)
  ppq         = reaper.MIDI_GetPPQPosFromProjQN(midiItemTake, qn)  --qn + 1 : FROM THE FORUM FRIENDS
  noteLength  = ppq/4
  

  reaper.MIDI_InsertNote(midiItemTake, false, false, ppq, ppq + noteLength, 1, 69, velocity, true)
  reaper.MIDI_Sort(midiItemTake)
  --Lua: boolean reaper.MIDI_InsertNote(MediaItem_Take take, boolean selected, boolean muted, number startppqpos, number endppqpos, integer chan, integer pitch, integer vel, optional boolean noSortIn)
  x = x + 1
end
  
   --set selected item to the new MIDI item
local id
reaper.SelectAllMediaItems(0, false)
local midiItem = reaper.GetMediaItemTake_Item(midiItemTake)
reaper.SetMediaItemSelected(midiItem, true)

id =  reaper.NamedCommandLookup("_FNG_GET_GROOVE") --"SWS/FNG: Get groove from selected media items"
reaper.Main_OnCommandEx(id, 0)
id =  reaper.NamedCommandLookup("_FNG_SAVE_GROOVE") --"SWS/FNG: Save groove template to file"
reaper.Main_OnCommandEx(id, 0)
----------------------------------------------------------------------------------------------------------------------
reaper.UpdateArrange()
reaper.Undo_EndBlock("Inserted MIDI Item, Created Groove", 0)

 
 