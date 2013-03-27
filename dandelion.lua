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
	print("All rights reserved.")
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
	
		-- read every single line of the provided
		-- file and look for the test patterns
		for currentLine in fileHandler:lines() do
		
			-- look for the test pattern in the
			-- source code comments
			if string.find(currentLine, "^%s*%%%s*!test$") then
				
				-- TODO write preprocessor
				-- extract all subsequent comment lines until a
				-- non-comment line appears in the processor
				
			end
		
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
