-- angels dec 2023 for luck dragon

s = sequins

delay = 0.2 -- time between notes
retrig_count = 1 -- time between additional trigger outs
next_retrig_count = 1
spread = 0 -- probability/amount of octave shifting

chord = 1 -- chord/seq currently playing (1-4 chords, 5 is progression)
next_chord = 1 -- next chord to play when this one is finished

do_quantize = false

a = 1 -- chord tone to play, relative to root b
b = 1 -- chord root

quantize_offset = justvolts(7/8)
function quantize(volts)
	return (math.floor(volts * 12 + 0.5 - quantize_offset) + quantize_offset) / 12
end

function play_note(pitch)

	local volts = justvolts(pitch)
	
	if do_quantize then
		volts = quantize(volts)
	end

	local octave = math.floor(volts)
	-- print('octave', octave)
	volts = volts - octave

	-- magnify octave by up to 2x: low notes become lower, high notes higher
	if math.random() < spread then
		octave = octave * 2
	end
	-- add linear octave offset too
	if math.random() < spread then
		octave = octave + (octave < 1 and -1 or 1) -- low notes become lower, high notes higher
	end
	-- randomize octave
	if math.random() < spread then
		octave = octave + math.floor(math.random() * 3 - 1)
	end
	-- print('new octave', octave)
	volts = volts + octave
	-- avoid out-of-range notes (Beads seems to track up to just under 5V)
	while volts > 4.9 do
		volts = volts - 1
	end
	while volts < -4 do
		volts = volts + 1
	end
	output[1].volts = volts
	output[2]()
	-- print(volts)
end

function set_base_note()
	b = sb()
	print('-- ' .. b .. ' --')
	b = str2n(b)
	local volts = justvolts(b)
	if do_quantize then
		volts = quantize(volts)
	end
	output[3].volts = justvolts(b)
end

-- two functions for the two chord shapes
-- there are four chords available / in the progression, but the third and fourth chord are just the
-- first and second times 3/4

function chord_maj(root)
	-- versions of first chord:
	-- sa = s { 1, 32/21, 2, 18/7, 27/7, 4, 'next' } -- very sub-7: fifth is 29c sharp, third and 7th are 29c sharp from 3-limit or 49c sharp from 5-limit
	--    ^ creates a subharmonic at 4/7 or something (i.e. 1/1 or 1/2 when root note of chord is 7/8).
	-- sa = s { 1, 3/2, 2, 5/2, 15/4, 4, 'next' } -- totally maj 5-limit
	--    ^ creates a subharmonic at 1/2 or something (relative to root note of chord).
	-- sa = s { 1, 3/2, 2, 81/32, 243/64, 4, 'next' } -- maj 3-limit, really more dissonant than the sub-7y one
	--    ^ don't know where the subharmonic is for this one. it just sounds gross
	-- sb = s { 7/8 }
	--
	-- ykw... I'm not sure I like how it feels when 5/ and /7 intervals get combined in one chord...
	-- hmm
	-- also, what about using 7*5/ intervals over the 3/ chords? like... 35/24... a qtone-flat fifth!
	-- here's a take that I AM really digging right now:
	-- sa = s { '1', '3/2', '2', s { '5/2', '18/7' }, s { '15/4', '27/7' }, '4' }
	-- this alternates/undulates between 5/ and /7 intervals in "one" chord, which creates a cool
	-- breathing effect
	-- throw in a 3-limit third for phasing again.
	-- when there's just ONE chord, mixing the 5/, 3/, and /7-based intervals brings life & death
	-- with multiple chords, that might be too much... or might not
	sa = s { '1', '3/2', '2', s { '5/2', '18/7', '81/32' }, s { '15/4', '27/7' }, '4', 'next' }
	-- 6 reps before repeat
	sb = s { root or '7/8' }
	set_base_note()
end

function chord_min(root)
	-- second chord:
	-- sa = s { 1, 3/2, 2, 9/4, s { 3, 7/3, 7/2 }, 4, 'next' } -- cool. subharmonic is the root
	-- sb = s { 3/4 }
	--
	-- sa = s { '1', '3/2', s { '2', '35/18' }, s { '9/4', '7/3', '7/3', '35/12' }, s { '7/3', '28/9', '3', '7/2' }, s { '4', '112/27', '14/3' }, 'next' }
	-- that 7/3 is weird and lovely, and at least in theory, helps tie it in to the 7/8 chord
	-- sb = s { '3/4' }
	--
	-- sa = s { '1', '3/2', s { '2', '35/18' }, s { '9/4', '7/3', '7/3', '35/12' }, s { '7/3', '28/9', '3', '7/2' }, s { '4', '112/27', '14/3' }, 'next' }
	-- that 7/3 is weird and lovely, and at least in theory, helps tie it in to the 7/8 chord
	-- this one is a bit too much of a chord progression unto itself
	-- sa = s { s { '1', '1', '35/36', '35/36' }, s { '3/2', '35/24' }, s { '2', '2', '35/18', '35/18' }, '9/4', s { '7/3', '3', '7/2' }, s { '4', '4', '35/9', '35/9' }, 'next' }
	--
	-- this one wounds pretty good, I think -- more phasing / less obvious, overall shifting up & down
	sa = s { s { '1', '1', '35/36' }, s { '3/2', '35/24' }, s { '2', '35/18', '2', '2' }, '9/4', s { '7/3', '3', '7/2' }, s { '4', '4', '35/9', '112/27' }, 'next' }
	-- 12 reps before repeat
	sb = s { root or '3/4' }
	set_base_note()
end

function chord_prog()
	-- two sequences: one for chord shapes (2 uhh "macro-steps"), and another for roots (4 steps)
	sa = s {
		s { '1', '3/2', '2', s { '5/2', '18/7', '81/32' }, s { '15/4', '27/7' }, '4', 'next' }:count(7),
		-- second chord is ALMOST the same as the one in chord_min(), but the root note stays at 1/1.
		-- when dwelling on one chord, playing that slightly flat 35/36 note on the downbeat can sound
		-- great, but when cycling through a set of chords, hitting a note other than 1/1 on the
		-- downbeat tends to just sound confusing.
		s { '1', s { '3/2', '35/24' }, s { '2', '35/18', '2', '2' }, '9/4', s { '7/3', '3', '7/2' }, s { '4', '4', '35/9', '112/27' }, 'next' }:count(7)
	}
	sb = s { '7/8', '3/4', '21/32', '9/16' }
	set_base_note()
end

function get_arrays()

	print('maj notes -----')
	print('[')
	local line = ''
	maj = s { '1', '3/2', '2', s { '5/2', '18/7', '81/32' }, s { '15/4', '27/7' }, '4' }
	for n = 1, 144 do
		local ratio = maj()
		local st = justvolts(str2n(ratio)) * 12
		line = line .. string.format('["%s",%f],', ratio, st)
		if n % 6 == 0 then
			print('  ' .. line)
			line = ''
		end
	end
	print(']')

	print('min notes -----')
	print('[')
	local line = ''
	min = s { s { '1', '1', '35/36' }, s { '3/2', '35/24' }, s { '2', '35/18', '2', '2' }, '9/4', s { '7/3', '3', '7/2' }, s { '4', '4', '35/9', '112/27' } }
	for n = 1, 144 do
		local ratio = min()
		local st = justvolts(str2n(ratio)) * 12
		line = line .. string.format('["%s",%f],', ratio, st)
		if n % 6 == 0 then
			print('  ' .. line)
			line = ''
		end
	end
	print(']')

	-- prg = s {
	-- 	s { '1', '3/2', '2', s { '5/2', '18/7', '81/32' }, s { '15/4', '27/7' }, '4', 'next' }:count(7),
	-- 	s { '1', s { '3/2', '35/24' }, s { '2', '35/18', '2', '2' }, '9/4', s { '7/3', '3', '7/2' }, s { '4', '4', '35/9', '112/27' }, 'next' }:count(7)
	-- }
end

-- take a ratio string like '2/1' and turn it into a number like 2.0
function str2n(str)
	return load('return ' .. str)()
end

function start_clock()
	clock.run(function()
		local n = 0
		while true do
			ii.faders.get(1) -- overall tempo
			ii.faders.get(2) -- retrig rate
			ii.faders.get(3) -- octave spread
			ii.faders.get(4) -- chord(s)
			ii.faders.get(7) -- quantize?
			ii.faders.get(8) -- bass slew rate
			clock.sleep(delay / retrig_count)
			n = n + 1
			if n >= retrig_count then
				n = 0
				retrig_count = next_retrig_count
				a = sa()
				if a == 'next' then
					if chord ~= next_chord then
						chord = next_chord
						if next_chord == 1 then
							chord_maj()
						elseif next_chord == 2 then
							chord_min()
						elseif next_chord == 3 then
							chord_maj('21/32')
						elseif next_chord == 4 then
							chord_min('9/16')
						else
							chord_prog()
						end
					else
						set_base_note()
					end
					a = sa()
				end
				print(a)
				a = str2n(a)
				local pitch = a * b
				play_note(pitch)
				output[4]()
			else
				output[4]()
			end
		end
	end)
end

function init()

	chord_maj()
	-- chord_min()
	-- chord_prog()

	output[2].action = pulse(0.02, 3)

	output[3].slew = 0.9
	output[3].shape = 'log'

	output[4].action = pulse(0.02, 3)

	ii.faders.event = function(f, v)
		if f.name == '1' then
			delay = 1.1 - v / 10
		elseif f.name == '2' then
			next_retrig_count = math.floor(v * 8 / 10) + 1
		elseif f.name == '3' then
			spread = v / 30
		elseif f.name == '4' then
			next_chord = math.min(5, math.floor(v / 2) + 1)
		elseif f.name == '7' then
			do_quantize = v > 5
		elseif f.name == '8' then
			output[3].slew = v / 3
		end
	end

	start_clock()
end
