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

-- Description: draw logo in the terminal
-- Parameters:  none
-- Return:      none
--
-- Joseph told me I should put my name in there, but it's too
-- risky: people will come after me when code starts to fail
-- miserably! :)
local function drawLogo()
	print("    _              _     _ _")         
	print(" __| |__ _ _ _  __| |___| (_)___ _ _") 
	print("/ _` / _` | ' \\/ _` / -_) | / _ \\ ' \\ ")
	print("\\__,_\\__,_|_||_\\__,_\\___|_|_\\___/_||_|")
	print("\nCopyright 2013, The LaTeX3 Project")
	print("All rights reserved.\n")
end

-- Description: trim leading and trailing spaces from a string
-- Parameters:  one string
-- Return:      the new trimmed string
local function trim(text)
  return (string.gsub(text, "^%s*(.-)%s*$", "%1"))
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
						
						-- check if we are handling multiline values
						if string.find(entry, "^%%+") then
						
							-- we have a special line here,
							-- so let's find out what's going
							-- on in this code
							
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
							
							-- TODO concatenate content from previous line
						
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
					
					end
					
				end
				
			end
		
			-- increment line counter
			lineCounter = lineCounter + 1
		
		end
	
		-- close handler, everything
		-- went fine
		fileHandler:close()
		
	-- Bad dog, bad dog!
	else
	
		-- print a very polite message
		print("File '" .. filename .. "' does not exist or is unavailable.")
		print("Interrupting script, have a nice day.")
		
		-- BOOM headshot!
		os.exit()
	end

end

-- Description: main function
-- Parameters:  none
-- Return:      none
local function main()
	drawLogo()
end

main()
