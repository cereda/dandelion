#!/usr/bin/env texlua
-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-- File: dandelion.lua
-- Copyright (C) 1990-2013 The LaTeX3 Project
--
-- It may be distributed and/or modified under the conditions of the
-- LaTeX Project Public License (LPPL), either version 1.3c of this
-- license or (at your option) any later version.  The latest version
-- of this license is in the file
--
--    http://www.latex-project.org/lppl.txt
--
-- This file is part of the "l3kernel bundle" (The Work in LPPL)
-- and all files in that bundle must be distributed together.
--
-- The released version of this bundle is available from CTAN.
-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-- variable that holds the name of all valid elements
local dandelionElements = { "id",
							"name",
							"group",
							"author",
							"description",
							"expects" }

--- Draws the application logo in the terminal.
-- This function simply draws an ASCII logo in the terminal.
-- Joseph told me I should put my name in the copyright line
-- together with the LaTeX3 project, but it's too risky:
-- people will come after me when code starts to fail
-- miserably! :)
local function drawLogo()
	print("    _              _     _ _")         
	print(" __| |__ _ _ _  __| |___| (_)___ _ _") 
	print("/ _` / _` | ' \\/ _` / -_) | / _ \\ ' \\ ")
	print("\\__,_\\__,_|_||_\\__,_\\___|_|_\\___/_||_|")
	print("\nCopyright 2013, The LaTeX3 Project")
	print("All rights reserved.\n")
end

--- Trims leading and trailing spaces from a string.
-- This function removes leading and trailing spaces
-- from the provided string, using pattern matching.
-- @param text The text to be trimmed.
-- @return The new trimmed string.
local function trim(text)
	return (string.gsub(text, "^%s*(.-)%s*$", "%1"))
end

--- Trims leading and trailing newlines.
-- This function removes leading and trailing newline
-- characters from the provided string, using pattern
-- matching.
-- @param text The string to be trimmed.
-- @return The new trimmed string.
local function trimNewline(text)
	return (string.gsub(text, "^\n*(.-)\n*$", "%1"))
end

--- Checks if the table has valid entries.
-- This function checks every key value looking for
-- empty definitions, which might cause trouble
-- later on in the execution.
-- @param t The table.
-- @return A boolean indicating if the table has
--         valid entries.
local function validEntries(t)

	-- iterate through all elements
	for i, v in pairs(t) do
	
		-- the 'expects' key is relaxed on empty values,
		-- so let's ignore it
		if i ~= "expects" then
		
			-- if the values are empty,
			-- return false
			if trim(v) == "" then
				return false
			end		
		end
	end
	
	-- everything is okay
	return true
end

--- Checks if the element is in the provided table.
-- This function checks if the element is in the
-- provided table, return a boolean value accordingly.
-- @param a The element to be checked.
-- @param t The table.
-- @return boolean value indicating if the element
--         is present.
local function contains(a, t)

	-- for every element in the table
	for _, element in ipairs(t) do

		-- the element exists,
		-- return true
		if a == element then
			return true
		end
	end
	
	-- nothing was found
	return false
end

--- Computes the set difference between two tables.
-- This function computes the set difference between
-- the two provided tables.
-- @param tableOne First table.
-- @param tableTwo Second table.
-- @return A new table containing the difference.
local function difference(tableOne, tableTwo)

	-- temporary variable
	local tableThree = {}
	
	-- iterate through all elements in table 1
	for _, element in ipairs(tableOne) do
	
		-- for every element a from table 1 not
		-- in table 2, insert it into table 3
		if not contains(element, tableTwo) then
			table.insert(tableThree, element)
		end
	end
	
	-- return the difference between
	-- table 1 and 2
	return tableThree
end

-- Description: check if the key is valid
-- Parameters:  one string
-- Return:      a boolean value indicating if the
--              provided key is valid
local function validKey(element)
	return contains(element, dandelionElements)
end

-- TODO add header
local function extractMetadataBlocks(filename)

	-- create a file handler and open the
	-- file accordingly
	local fileHandler = io.open(filename,"r")
	
	-- if something bad happens, go to the 
	-- 'else' branch, end script and live
	-- happily ever after
	if fileHandler then
	
		-- flag to enable or disable parsing of commented
		-- lines, according to the context
		local grabber = false
		
		-- flag to indicate if the current multine parsing
		-- is valid, of course, you need to have a single
		-- line argument first
		local acceptMultine = false
		
		-- line counter
		local lineCounter = 1
		
		-- variable to hold the key
		-- from metadata
		local key
		
		-- mapping table
		local mapping = nil
		
		-- full mappings table
		local mappings = {}
		
		-- index for the mappings table
		local mappingIndex = 1
		
		-- flag for an empty value
		-- for a single entry
		local emptyValue = false
		
	
		-- read every single line of the provided
		-- file and look for the test patterns
		for currentLine in fileHandler:lines() do
		
			-- look for the test pattern in the
			-- source code comments
			if string.find(currentLine, "^%s*%%%s*!test$") then
			
				-- let's reset our mapping table
				mapping = {}
							
				-- we are now in a potential test metadata block,
				-- so let's enable the flag
				grabber = true 
				
			-- not a test line, but we can also
			-- look for test metadata block, if
			-- the flag is enabled
			else
			
				-- apparently, we are in a test metadata block!
				if grabber then
				
					-- extract all subsequent comment lines until a
					-- non commented line appears in the processor
					if string.find(currentLine, "^%s*%%") then
					
						-- create a new local variable
						-- to hold the current entry
						local entry
					
						-- get everything after the comment part
						entry = string.match(currentLine, '^%s*%%(.+)$')
						
						-- if we have a nil value, this is not
						-- good! The test metadata block requires
						-- no empty comment lines.
						if entry == nil then
						
							-- message
							print("I'm sorry, but there's an invalid entry at line " .. lineCounter .. ".")
							print("Inside the test metadata block, we don't expect")
							print("commented lines without a proper description,")
							print("that is, empty comments. Stopping execution.")
							
							-- stop, hammertime!
							os.exit()
						
						end
						
						-- check if we are handling multiline values
						if string.find(entry, "^%%+") then
						
							-- we have a special line here,
							-- so let's find out what's going
							-- on in this code
							
							-- let's see if the scope is valid, that
							-- is, we need to have a previous line
							-- with a key
							if acceptMultine == false then
							
								-- print message
								print("I'm sorry, but there's an invalid entry at line " .. lineCounter .. ".")
								print("You can't have a multiline entry without a previous")
								print("single entry with the proper key. Stopping execution.")
								
								-- spam, spam, spam, spam,
								-- lovely spam, wonderful
								-- spam!
								os.exit()
							
							end
							
							-- let's define a new variable
							-- to set the type of this
							-- multiline block
							local type
							
							-- perform the matching pattern
							-- expects something
							type, entry = string.match(entry, '^(%s*%%+%s)(.*)$')
							
							-- if type is nil, we have a malformed
							-- line not complying with our spec
							if type == nil then
							
								-- alert the user and provide the line
								-- of the offending code
								print("I'm sorry, but there's an invalid entry at line " .. lineCounter .. ".")
								print("I require at least one space separating the comment")
								print("symbol and the content. Stopping execution.")
								
								-- kill it with fire!
								os.exit()
							
							end
							
							-- so we have a valid type, woohoo!
							-- Let's trim it for the greater good							
							type = trim(type)
							
							-- we have two types of multiline
							-- metadata comments:
							--
							-- 1: linebreaks are replaced by
							--    single spaces, named 'docstring'.
							--
							-- 2: linebreaks are preserved, with
							--    the proper line ending, named
							--    'codestring'
							
							local lineEnding
							
							-- we have a docstring
							if #type == 1 then
							
								-- add single space
								lineEnding = " "
							
							-- we have a codestring
							elseif #type == 2 then
							
								-- add a linebreak
								lineEnding = "\n"
							
							-- none of the above,
							-- raise error						
							else
							
								-- print message
								print("I'm sorry, but there's an invalid entry at line " .. lineCounter .. ".")
								print("The number of extra comment symbols is invalid.")
								print("Stopping execution.")
								
								-- fire at will!
								os.exit()
							
							end
							
							-- if we are in a multiline environment,
							-- we expect to fetch values, so let's
							-- disable the flag
							emptyValue = false
							
							-- let's concatenate the values from the previous
							-- lines, since we are in a multiline segment
							entry = mapping[key] .. lineEnding .. entry
							
							-- if docstring, simply trim
							-- the leading and trailing
							-- spaces
							if #type == 1 then
								entry = trim(entry)
								
							-- we have a codestring, then
							-- let's trim the leading and
							-- trailing newlines
							else
								entry = trimNewline(entry)
							end
							
							-- add entry to the mappings
							mapping[key] = entry 
							mappings[mappingIndex] = mapping
													
						-- it seems we are handling a
						-- normal line in here	
						else
						
							-- normal line
							
							-- check if there was a previous single
							-- line with an empty value
							if emptyValue then
							
								-- raise error, print message
								print("I'm sorry, but there's an invalid entry at line " .. (lineCounter - 1) .. ".")
								print("A key must always be associated to a value.")
								print("Either set a value or add a multiline comment.")
								print("Stopping execution.")
								
								-- lalala can't hear you lalala
								os.exit()
								
							end
							
							-- we can now accept subsequent
							-- multiline entries
							acceptMultine = true

							-- let's get both key and the value
							key, entry = string.match(entry, '^%s*(%w+)%s*:(.*)$')
							
							-- a key is required, so if it doesn't comply
							-- with the pattern, the value will be nil
							-- and an error will be raised
							if key == nil then
							
								-- print message
								print("I'm sorry, but there's an invalid entry at line " .. lineCounter .. ".")
								print("It appears there is no key, or the existing one is")
								print("invalid. Stopping execution.")
								
								-- I like ice cream
								os.exit()
								
							end
							
							-- we need to ensure we have a
							-- valid key, otherwise stop
							-- the press!
							if not validKey(key) then
							
								-- print message
								print("I'm sorry, but there's an invalid entry at line " .. lineCounter .. ".")
								print("It appears the '" .. key .. "' is invalid. Please")
								print("fix it before proceeding. Stopping execution.")
								
								-- can't read ma, can't read ma,
								-- no you can't read ma poker face!
								os.exit()
							
							end
							
							-- if the current value is not
							-- empty, set flag to false
							-- and trim spaces
							if entry ~= "" then
								
								-- set flag to false							
								emptyValue = false
								
								-- trim spaces
								entry = trim(entry)								
							
							-- we have an empty value
							else
							
								-- set flag to true,
								-- and now we expect
								-- multiline
								emptyValue = true
							end
							
							-- key is already trimmed because
							-- of the matching pattern, so let's
							-- simply add things here
							mapping[key] = entry
							mappings[mappingIndex] = mapping
						
						end
					
					-- no commented line, so let's disable
					-- the block extraction
					else
					
						-- check if there was a previous single
						-- line with an empty value
						if emptyValue then

							-- raise error, print message
							print("I'm sorry, but there's an invalid entry at line " .. (lineCounter - 1) .. ".")
							print("A key must always be associated to a value.")
							print("Either set a value or add a multiline comment.")
							print("Stopping execution.")
								
							-- lalala I can't hear
							-- you lalala
							os.exit()

						end
					
						-- false, false, false
						grabber = false
						acceptMultine = false
					
						-- increment mapping index
						mappingIndex = mappingIndex + 1
					
					end
					
				end
				
			end
		
			-- increment line counter
			lineCounter = lineCounter + 1
		
		end
	
		-- close handler, everything
		-- went fine
		fileHandler:close()
		
		-- now, let's do some sanity check in order to
		-- ensure our table of mappings is correct
		
		-- list of test id's,
		-- empty at first
		local idList = {}
		
		-- now let's browse our mappings table
		-- looking for all tests we found
		for _, v in ipairs(mappings) do
		
			-- our temporary table to hold the
			-- current test keys
			local keys = {}
			
			-- for every key in the current
			-- test spec, add it to the list
			for j, _ in pairs(v) do
				table.insert(keys, j)				
			end
			
			-- if we have missing elements, the
			-- execution has to stop
			if #difference(dandelionElements, keys) ~= 0 then
			
				-- print message
				print("I'm sorry, but there are some elements missing from one")
				print("of your tests. Please make sure the test spec has all the")
				print("required elements. Stopping execution.")
			
				-- pew, pew, pew!
				os.exit()
			
			end
			
			-- now let's search for invalid
			-- entries, that is, empty values
			if not validEntries(v) then
			
				-- print message
				print("I'm sorry, but there are some elements with empty values.")
				print("Please make sure the test spec has all the required elements")
				print("and their corresponding values. Stopping execution.")
				
				-- set fire to the rain!
				os.exit()
				
			end
			
			-- if the current test id is already defined,
			-- an error has to be raised!
			if contains(v["id"], idList) then
			
				-- print message
				print("I'm sorry, but the test ID '" .. v["id"] .. "' is already defined")
				print("in your file. Please rename it. Stopping execution.")
			
				-- to exit or not to exit,
				-- that's the question
				os.exit()
				
			-- new id, let's add it to the list of
			-- test id's
			else
				table.insert(idList, v["id"])
			end
			
		end
							
	-- Bad dog, bad dog!
	else
	
		-- print a very polite message
		print("File '" .. filename .. "' does not exist or is unavailable.")
		print("Interrupting script, have a nice day.")
		
		-- BOOM headshot!
		os.exit()
	end

end

--- Wraps the main code into a block.
-- This function acts like the main function of the program,
-- wrapping the main code into a block.
local function main()
	drawLogo()
end

main()
