#!/usr/bin/env texlua
-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
-- File: dandelion.lua
-- Copyright (C) 2013 The LaTeX3 Project
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
-- ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

-- variable that holds the name of all valid elements
local dandelionElements = { "id",
    "name",
    "group",
    "author",
    "description",
    "expects" }

-- variable that holds the name of all registers
-- that require parsing in the log output
local dandelionRegisters = { "box",
    "count",
    "dimen",
    "muskip",
    "skip",
    "toks" }

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
-- @param value The element to be checked.
-- @param set The table.
-- @return Boolean value indicating if the element
--         is present.
local function contains(value, set)

    -- for every element in the table
    for _, element in ipairs(set) do

        -- the element exists,
        -- return true
        if value == element then
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

--- Extracts the metadata blocks from the TeX source code.
-- This function extracs the metadata blocks from the TeX source code,
-- according to the defined markup.
-- @param filename The source code filename.
-- @return The TeX engine.
-- @return A table containing all tests found in the source code.
local function extractDataFromSource(filename)

    -- create a file handler and open the
    -- file accordingly
    local fileHandler = io.open(filename, "r")

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
        
        -- we need an engine,
        -- don't we?
        local engine = nil

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
                            print(":: I'm sorry, but there's an invalid entry at line " .. lineCounter .. ".")
                            print(":: Inside the test metadata block, we don't expect")
                            print(":: commented lines without a proper description,")
                            print(":: that is, empty comments. Stopping execution.")

                            -- close the handler, we
                            -- are about to explode
                            fileHandler:close()

                            -- stop, hammertime!
                            os.exit(1)

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
                                print(":: I'm sorry, but there's an invalid entry at line " .. lineCounter .. ".")
                                print(":: You can't have a multiline entry without a previous")
                                print(":: single entry with the proper key. Stopping execution.")

                                -- close the handler, we
                                -- are about to explode
                                fileHandler:close()

                                -- spam, spam, spam, spam,
                                -- lovely spam, wonderful
                                -- spam!
                                os.exit(1)

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
                                print(":: I'm sorry, but there's an invalid entry at line " .. lineCounter .. ".")
                                print(":: I require at least one space separating the comment")
                                print(":: symbol and the content. Stopping execution.")
                                
                                -- close the handler, we
                                -- are about to explode
                                fileHandler:close()

                                -- kill it with fire!
                                os.exit(1)

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
                                print(":: I'm sorry, but there's an invalid entry at line " .. lineCounter .. ".")
                                print(":: The number of extra comment symbols is invalid.")
                                print(":: Stopping execution.")
                                
                                -- close the handler, we
                                -- are about to explode
                                fileHandler:close()

                                -- fire at will!
                                os.exit(1)

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
                                print(":: I'm sorry, but there's an invalid entry at line " .. (lineCounter - 1) .. ".")
                                print(":: A key must always be associated to a value.")
                                print(":: Either set a value or add a multiline comment.")
                                print(":: Stopping execution.")
                                
                                -- close the handler, we
                                -- are about to explode
                                fileHandler:close()

                                -- lalala can't hear
                                -- you lalala
                                os.exit(1)

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
                                print(":: I'm sorry, but there's an invalid entry at line " .. lineCounter .. ".")
                                print(":: It appears there is no key, or the existing one is")
                                print(":: invalid. Stopping execution.")
                                
                                -- close the handler, we
                                -- are about to explode
                                fileHandler:close()

                                -- I like ice cream
                                os.exit(1)

                            end

                            -- we need to ensure we have a
                            -- valid key, otherwise stop
                            -- the press!
                            if not validKey(key) then

                                -- print message
                                print(":: I'm sorry, but there's an invalid entry at line " .. lineCounter .. ".")
                                print(":: It appears the '" .. key .. "' is invalid. Please")
                                print(":: fix it before proceeding. Stopping execution.")
                                
                                -- close the handler, we
                                -- are about to explode
                                fileHandler:close()

                                -- can't read ma, can't read ma,
                                -- no you can't read ma poker face!
                                os.exit(1)

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
                            print(":: I'm sorry, but there's an invalid entry at line " .. (lineCounter - 1) .. ".")
                            print(":: A key must always be associated to a value.")
                            print(":: Either set a value or add a multiline comment.")
                            print(":: Stopping execution.")
                            
                            -- close the handler, we
                            -- are about to explode
                            fileHandler:close()

                            -- walking in a winter
                            -- wonderland
                            os.exit(1)

                        end

                        -- false, false, false
                        grabber = false
                        acceptMultine = false

                        -- increment mapping index
                        mappingIndex = mappingIndex + 1

                    end

                end
                
                -- let's try to get the engine 
                if string.find(currentLine, "^%s*%%%s*!dandelion%s(%w+)$") then
                    
                    
                    -- we already have an engine,
                    -- raise error
                    if engine ~= nil then
                    
                        -- print message
                        print(":: I'm sorry, but there's an invalid entry at line " .. (lineCounter - 1) .. ".")
                        print(":: The engine is already defined in the scope of this file.")
                        print(":: Stopping execution.")
                        
                        -- close the handler, we
                        -- are about to explode
                        fileHandler:close()
    
                        -- the more I see,
                        -- the less I know
                        os.exit(1)
                    
                    end
                    
                    -- get the engine
                    engine = string.match(currentLine, '^%s*%%%s*!dandelion%s(%w+)$')
                    engine = trim(engine)
                        
                end

            end

            -- increment line counter
            lineCounter = lineCounter + 1

        end

        -- close handler, everything
        -- went fine
        fileHandler:close()
        
        -- we need to ensure an engine was
        -- defined in our file
        if engine == nil then
        
            -- print message
            print(":: I'm sorry, but there's no TeX engine defined in the scope")
            print(":: of this file. I cannot proceed. Stopping execution.")

            -- I wanted to be
            -- a lumberjack!
            os.exit(1)
        
        end

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
                print(":: I'm sorry, but there are some elements missing from one")
                print(":: of your tests. Please make sure the test spec has all the")

                -- pew, pew, pew!
                os.exit(1)

            end

            -- now let's search for invalid
            -- entries, that is, empty values
            if not validEntries(v) then

                -- print message
                print(":: I'm sorry, but there are some elements with empty values.")
                print(":: Please make sure the test spec has all the required elements")
                print(":: and their corresponding values. Stopping execution.")

                -- set fire to the rain!
                os.exit(1)

            end

            -- if the current test id is already defined,
            -- an error has to be raised!
            if contains(v["id"], idList) then

                -- print message
                print(":: I'm sorry, but the test ID '" .. v["id"] .. "' is already defined")
                print(":: in your file. Please rename it. Stopping execution.")

                -- to exit or not to exit,
                -- that's the question
                os.exit(1)

            -- new id, let's add it to the list of
            -- test id's
            else
                table.insert(idList, v["id"])
            end

        end
        
        -- return the result
        return engine, mappings
                
    -- Bad dog, bad dog!
    else

        -- print message
        print(":: File '" .. filename .. "' does not exist or is unavailable.")
        print(":: Stopping execution.")

        -- BOOM headshot!
        os.exit(1)
    end

end

--- Removes the line number reference from the log output.
-- This functions removes the line number reference from the log output,
-- easing the analysis.
-- @param text The text to be parsed.
local function removeLineNumberReference(text)

    -- good old pattern matching, looks for ' on line <digits>'
    -- and replace the occurrences by the correct form
    return string.gsub(text, "%son%sline%s(%d+)", " on line ...")
end

--- Removes the register reference.
-- This function removes the register reference, that is, the number that
-- follows the registry entry.
-- @param register The register name.
-- @param text The text to be parsed.
local function removeRegisterReference(register, text)
    return string.gsub(text, "\\" .. register .. "(%d+)", "\\" .. register .. "...")
end

--- Removes the references from a list of register names.
-- This function removes the references from a list of register names,
-- since Lua's pattern matching acts quite differently from traditional
-- regex approaches.
-- @param registers A table containing all the register names.
-- @param text The text to be parsed.
local function removeRegisterReferences(registers, text)

    -- for every entry in the registers table
    for _, i in ipairs(registers) do
    
        -- parse the text
        text = removeRegisterReference(i, text)
    end
    
    -- return the new text
    return text
end

--- Extracts the output blocks from the provided log file.
-- This function extracts the output blocks from the provided log files,
-- according to the defined markup.
-- @param filename The log filename.
-- @return A table containing all the output blocks with their
--         corresponding identifiers.
local function extractDataFromLog(filename)

    -- create a file handler and open the
    -- file accordingly
    local fileHandler = io.open(filename, "r")

    -- if something bad happens, go to the
    -- 'else' branch, end script and live
    -- happily ever after
    if fileHandler then
    
        -- line counter
        local lineCounter = 1
        
        -- current test name
        local testName
        
        -- list of test id's,
        -- empty at first
        local idList = {}
        
        -- table to store the test
        -- output blocks
        local results = {}
            
        -- a flag indicating if the current line
        -- is part of a test output block
        local grabber = false
        
        -- read every single line of the provided
        -- file and look for the test patterns
        for currentLine in fileHandler:lines() do
        
            -- look for the test output pattern
            -- in the log file
            if string.find(currentLine, "^=====%sbegin:test:(.+)$") then
            
                -- let's get the test name
                testName = string.match(currentLine, '^=====%sbegin:test:(.+)$')
            
                -- if the test name is nil,
                -- we need to raise an error
                if testName == nil then
                
                    -- show message
                    print(":: I'm sorry, but there's an invalid test output block at line " .. (lineCounter - 1) .. ".")
                    print(":: The test output block requires a valid name, otherwise we cannot")
                    print(":: proceed with the analysis. Stopping execution.")
                    
                    -- close the handler, we
                    -- are about to explode
                    fileHandler:close()
                    
                    -- Luke, use the source
                    os.exit(1)
                
                end
                
                -- check if the test name is already
                -- defined in the log file
                if contains(testName, idList) then
            
                    -- print message
                    print(":: I'm sorry, but the test ID '" .. testName .. "' is already defined")
                    print(":: in your log file. Stopping execution.")
                
                    -- close the handler, we
                    -- are about to explode
                    fileHandler:close()
                
                    -- meow!
                    os.exit(1)
            
                -- it's a new name, add
                -- the value to the table
                else
                    table.insert(idList, testName)          
                end             
                
                
                -- enable the flag
                grabber = true
                
                -- initialize the entry
                -- in the results table
                results[testName] = ""
            
            -- let's check if the current line is
            -- the end of a test output block
            elseif string.find(currentLine, "^=====%send:test:(.+)$") then
            
                -- let's get the name again
                local name = string.match(currentLine, '^=====%send:test:(.+)$')
                
                -- if the test name is nil,
                -- we need to raise an error
                if name == nil then
                
                    -- show message
                    print(":: I'm sorry, but there's an invalid test output block at line " .. (lineCounter - 1) .. ".")
                    print(":: The test output block requires a valid name, otherwise we cannot")
                    print(":: proceed with the analysis. Stopping execution.")
                    
                    -- close the handler, we
                    -- are about to explode
                    fileHandler:close()
                    
                    -- Luke, use the source
                    os.exit(1)
                
                end
                
                -- both names have to be equal,
                -- otherwise raise error
                if name ~= testName then
                
                    -- show message
                    print(":: I'm sorry, but there's an invalid test output block at line " .. (lineCounter - 1) .. ".")
                    print(":: The test block closing markup has a different name identifier than")
                    print(":: its opening counterpart. Stopping execution.")
                    
                    -- close the handler, we
                    -- are about to explode
                    fileHandler:close()
                    
                    -- The Final Countdown song
                    -- is now playing inside
                    -- your head
                    os.exit(1)
                
                end
                
                -- we are done, disable
                -- the flag
                grabber = false

            -- if we are inside a
            -- test output block            
            elseif grabber then
            
                -- get the current status of the output
                local entry = results[testName]
                
                -- remove the line number reference
                local parsedLine = removeLineNumberReference(currentLine)
                
                -- remove register references
                parsedLine = removeRegisterReferences(dandelionRegisters, parsedLine)
                
                -- update the output data in the table
                results[testName] = trimNewline(entry .. "\n" .. parsedLine)
            
            end
                    
            -- increment line counter
            lineCounter = lineCounter + 1
        
        end
                
        -- close handler, everything
        -- went fine
        fileHandler:close()
        
        -- return all test output
        -- blocks found
        return results
    
    -- Bad dog, bad dog!
    else

        -- print message
        print(":: File '" .. filename .. "' does not exist or is unavailable.")
        print(":: Stopping execution.")

        -- 99 bottles of beer
        -- in the wall...
        os.exit(1)
    end

end

--- Parses the command line arguments.
-- This function parses the command line arguments according to the
-- flags defined in the specification.
-- @param arguments The command line arguments.
-- @return A string containing the action to be performed.
-- @return The filename to be analyzed.
-- @return A table containing the test ID's, if any.
-- @return A table containing the authors, if any.
-- @return A table containing the groups, if any.
local function parseCommandLine(arguments)

    -- let's define all flags and actions that
    -- our program will support
    local flags = { "--help" , "--version" }
    local modifiers = { "--id", "--author", "--group" }
    local actions = { "test" , "list", "save" }
    
    -- get the number of arguments
    -- passed to the program
    local n = #arguments
    
    -- if there are none
    if n == 0 then
    
        -- print program usage
        -- TODO print usage here
        
        -- nananananananana Batman!
        os.exit(0)
    
    -- first check, we have exactly one
    -- argument, let's expect one of the
    -- flags here
    elseif n == 1 then
    
        -- if the argument is not in
        -- the table of flags
        if not contains(arguments[1], flags) then
            
            -- invalid flag, simply
            -- print usage
            -- TODO print usage here
            
            -- There's no spoon
            os.exit(1)
        
        -- we have either 'help' or 'version',
        -- let's check which one to display
        else
        
            if arguments[1] == "help" then
            
                -- print help
                -- TODO print help here
                
                -- open your heart,
                -- I'm coming home!
                os.exit(0)
            
            -- we have 'version'
            else
            
                -- print version info
                -- TODO print version info here
                
                -- Ouch, that hurts
                os.exit(0)
            
            end
            
        end
        
    -- we have now at least two arguments,
    -- the tricky part begins
    else
    
        -- the first argument must be an action,
        -- check if it's in the actions table
        if not contains(arguments[1], actions) then
        
            -- an action was expected, raise error
            -- TODO add message error about expecting an action
            
            -- boat race!
            os.exit(1)
            
        -- the second argument must not start with a dash,
        -- that is, it cannot be a flag
        elseif string.sub(arguments[2], 1, 1) == "-" then
            
            -- an invalid filename was found,
            -- raise error
            -- TODO add message error about an invalid filename

            -- Rule, Britannia!
            -- Britannia, rule the waves! 
            os.exit(1)
            
        end
        
        -- if the execution reaches this part,
        -- everything fine so far
        
        -- get both action and filename
        local action = arguments[1]
        local filename = arguments[2]
        
        -- now, let's remove them from
        -- the table of arguments, so
        -- we can easy handle them
        table.remove(arguments, 1)
        table.remove(arguments, 1)
        
        -- all the tables to be returned,
        -- initially empty
        local authors = {}
        local groups = {}
        local ids = {}
        
        -- flag that holds the currently
        -- analyzed flag
        local currentFlag = nil

        -- iterating the elements in
        -- the table of arguments
        for index, value in ipairs(arguments) do
        
            -- if the current element is
            -- a potential flag
            if string.sub(value, 1, 1) == "-" then
            
                -- we now expect a valid modifier, that is,
                -- flags that expect a value, let's see if
                -- it's invalid
                if not contains(value, modifiers) then
                    
                    -- we have an invalid flag,
                    -- so raise error and exit
                    -- TODO add error message about invalid modifier flag
                    
                    -- You shall not pass!
                    os.exit(1)
                    
                -- valid flag, proceed
                else
                
                    -- get the reference and
                    -- store in the current flag
                    currentFlag = value
                end
                
                -- sanity check, a flag cannot be last
                -- argument in the command line
                if index == #arguments then
                
                    -- print message
                    -- TODO add error message about flag being the last argument
                    
                    -- please come back!
                    os.exit(1)
                    
                end
                
            -- we have a value instead
            -- of a flag
            else
            
                -- if the current flag is null,
                -- it means the value is in the
                -- wrong order in the arguments
                -- list 
                if currentFlag == nil then
                
                    -- print message
                    -- TODO add error message about the wrong value order 
                    
                    -- this way to the zoo!
                    os.exit(1)
                
                end
                
                -- let's now add the values to their
                -- corresponding tables
                
                -- if the current flag is an ID
                if currentFlag == "--id" then
                
                    -- add the value to the table
                    table.insert(ids, value)
                    
                -- it's an author
                elseif currentFlag == "--author" then
                
                    -- add the value to the table
                    table.insert(authors, value)
                    
                -- when nothing else is left,
                -- we have a group
                else
                
                    -- add the value to the table
                    table.insert(groups, value)
                    
                end
                
            end
            
        end
        
        -- string, string, table, table, table
        return action, filename, ids, authors, groups
        
    end

end

--- Gets the last occurrence of a string in the text.
-- This function gets the last occurrence of the provided string in the text.
-- If the string is not found, the first position is returned.
-- @param text The text to be analyzed.
-- @param lookup The lookup string.
-- @return The last occurrence of the string, if found, or the first
--         position otherwise.
local function getLastOccurrence(text, lookup)
    
    -- variables
    local offset = 0
    local lastOccurrence
    local position = 1

    -- let's repeat the lookup until
    -- no more occurrences are found
    repeat
        
        -- update values
        lastOccurrence = position
        offset = lastOccurrence
        
        -- search the remaining text
        position = string.find(text, lookup, offset + 1, true)

    until position == nil
    
    -- return the index
    return lastOccurrence

end

--- Gets the basename of the provided file.
-- This function returns the basename of the provided file.
-- @param filename The filename.
-- @return The basename of the file.
local function getBasename(filename)

    -- get the last occurrence of the dot character,
    -- where we expect to be the extension part
    local position = getLastOccurrence(filename, ".")
    
    -- return everything before that position
    return string.sub(filename, 1, position - 1)
    
end

--- Generates the reference log file.
-- This function generates the reference log file from the content
-- of the original log file, already extracted and parsed. The program
-- will attempt to save the new file in same place of the original log
-- file.
-- @param filename The name of the original log file.
-- @param content The content of the original file name, already extracted
--        and parsed.
local function generateReferenceLog(filename, content)

    -- let's get the basename and add the
    -- '.tlg' reference log extension
    filename = getBasename(filename) .. ".tlg"
    
    -- create a new file handler, opening
    -- the file for writing
    local fileHandler = io.open(filename, "w")
    
    -- if the file handler is valid
    if fileHandler then
    
        -- total of entries
        local total = 0
        
        -- iterate through the
        -- content table
        for _, _ in pairs(content) do
        
            -- count
            total = total + 1
            
        end
        
        -- write a header with a date reference
        fileHandler:write("% Reference log file generated by dandelion on\n")
        fileHandler:write("% " .. os.date("%A, %B %d, %Y, at %X.\n"))
        fileHandler:write("% ".. total .. " entries added.\n")
    
        -- for every entry in the
        -- content table
        for i, v in pairs(content) do
        
            -- write the test output block
            fileHandler:write("\n===== begin:test:" .. i .. "\n")
            fileHandler:write(v .. "\n")
            fileHandler:write("===== end:test:" .. i .. "\n")
            
        end
    
    -- close handler
    fileHandler:close()
    
    -- TODO add success message
    
    -- something bad happened
    else
    
        -- print message
        -- TODO add error message about the reference log generation
        
        -- do you come from a
        -- land down under?
        os.exit(1)
        
    end
    
end

--- Appends a character to a text according to an integer value. 
-- This function appends a character to a text according to an integer value,
-- or truncates the text if the length is lower than the value itself.
-- @param text The provided text.
-- @param character The character to be repeated.
-- @param number An integer value representing the number of times to repeat
--               the provided character.
-- @param reverse A boolean value indicating if the character will be prepended
--                to the text instead of appended.
local function repeatCharacter(text, character, number, reverse)

    -- check if the text is bigger than
    -- the number itself
    if string.len(text) > number then
    
        -- truncate the text
        text = string.sub(text,1,number)
    
    end
    
    -- while length is lower
    -- than the number, add
    -- the character
    while string.len(text) < number do
    
        -- if we are in
        -- reverse mode
        if reverse then
        
            -- prepend
            text = character .. text
            
        -- normal mode
        else
        
            -- append
            text = text .. character
            
        end
    
    end
    
    -- return the new text
    return text

end

--- Generates a textual counter.
-- This function generates a textual counter based on the current position
-- and the total.
-- @param part The current position.
-- @param total The total.
-- @param open The character to be prepended to the counter.
-- @param close The character to be appended to the counter.
local function generateCounter(part, total, open, close)

    -- convert integer values
    -- to their string counterparts
    local p = tostring(part)
    local t = tostring(total)
    
    -- add spaces to the left
    p = repeatCharacter(p, " ", string.len(t), true)
    
    -- format the counter
    p = open .. p .. "/" .. t .. close
    
    -- return it
    return p

end

--- Calculates the Levenshtein distance between two strings.
-- This function calculates the Levenshtein distance between two strings.
-- @param a The first string.
-- @param b The second string.
-- @return An integer value indicating the Levenshtein distance.
local function getLevenshteinDistance(a, b)

    -- get the size of
    -- both strings
    local lenA = #a
    local lenB = #b
    
    -- create two tables for storing
    -- each character of each string,
    -- and an additional table for
    -- values
    local charA = {}
    local charB = {}
    local distance = {}
    
    -- add every character from the
    -- first string to the table
    a:gsub('.', function (c)
        table.insert(charA, c)
    end)
    
    -- add every character from the
    -- second string to the table
    b:gsub('.', function (c)
        table.insert(charB, c)
    end)
    
    -- create a matrix to store
    -- the values from the
    -- calculation
    for i = 0, lenA do
        distance[i] = {}
    end
    
    for i = 0, lenA do
        distance[i][0] = i
    end
    
    for i = 0, lenB do
        distance[0][i] = i
    end
    
    -- calculate each cell of
    -- the matrix    
    for i = 1, lenA do
        for j = 1, lenB do
            distance[i][j] = math.min(distance[i-1][j  ] + 1, distance[i  ][j-1] + 1,
            distance[i-1][j-1] + (charA[i] == charB[j] and 0 or 1))
        end
    end
    
    -- return the specific position
    -- which holds the result
    return distance[lenA][lenB]
end

--- Generates the test report.
-- This function generates the test report based on the source code and
-- the log file.
-- @param ids The command line list of IDs, if any.
-- @param authors The command line list of authors, if any.
-- @param groups The command line list of groups, if any.
-- @param fromSource The mapping table from the source code.
-- @param fromLog The mapping table from the log file.
-- @param sourceName The name of the source file.
-- @param logName The name of the log file.
local function generateReport(ids, authors, groups, fromSource, fromLog, sourceName, logName)
    
    -- let's get all information from
    -- the source code for the later
    -- query
    local idsFromSource = {}
    local authorsFromSource = {}
    local groupsFromSource = {}
    
    -- store all the test ID's found
    -- in the log file
    local idsFromLog = {}
    
    -- iterate the mapping table
    for _, v in pairs(fromSource) do
    
        -- add all info to the
        -- temporary variables
        table.insert(idsFromSource, v["id"])
        table.insert(authorsFromSource, v["author"])
        table.insert(groupsFromSource, v["group"])
        
    end
    
    -- get all test ID's from
    -- the log file and add them
    -- to the temporary table
    for i, _ in pairs(fromLog) do
        table.insert(idsFromLog, i)
    end
    
    -- if their size don't match, we
    -- might have conflicting codes
    if #difference(idsFromSource, idsFromLog) ~= 0 or
        #difference(idsFromLog, idsFromSource) ~= 0 then
    
        -- TODO add error message that both source and log tests differ

        -- One more time, but
        -- with feeling
        os.exit(1)
    
    end
    
    -- let's check if there are invalid
    -- test ID's from the command line
    if #difference(ids, idsFromSource) ~= 0 then
    
        -- TODO add error message that there are invalid CLI ID's
        
        -- I can't believe it took so
        -- long to fix this
        os.exit(1)
    
    end
    
    -- let's check if there are invalid
    -- authors from the command line
    if #difference(authors, authorsFromSource) ~= 0 then
    
        -- TODO add error message that there are invalid CLI authors
        
        -- FOR REAL!
        os.exit(1)
    
    end
    
    -- let's check if there are invalid
    -- groups from the command line
    if #difference(groups, groupsFromSource) ~= 0 then
    
        -- TODO add error message that there are invalid CLI groups
        
        -- This is why the cat shouldn't
        -- sit on my keyboard
        os.exit(1)
    
    end
    
    -- our final selection
    -- of tests
    local selection = {}
    
    -- some variables to help with
    -- the query, they store a boolean
    -- value on the size of the
    -- command line parameters
    local disableIds = (#ids == 0)
    local disableAuthors = (#authors == 0)
    local disableGroups = (#groups == 0)
    
    -- for every entry in the mapping table
    for _, v in pairs(fromSource) do
    
        -- let's do some trickery with boolean
        -- values, which ease the whole process!
        if (disableIds or contains(v["id"], ids)) and
            (disableAuthors or contains(v["author"], authors)) and
            (disableGroups or contains(v["group"], groups))  then
            
            -- get the output from
            -- the log table
            local output = fromLog[v["id"]]
            
            -- append it to the current
            -- table entry 
            v["output"] = output
            
            -- calculate the Levenshtein distance
            -- using the values from the expected
            -- and obtained results, and add the
            -- integer value to the current table
            -- entry
            v["levenshtein"] = getLevenshteinDistance(v["expects"], output)
            
            -- insert the result into
            -- the new selection
            table.insert(selection, v)
            
        end
    
    end
    
    -- our query didn't fetch
    -- any test at all
    if #selection == 0 then
    
        -- TODO add error message that the query returned an empty value
        
        -- lolwut?
        os.exit(1)
        
    end
    
    -- variables to store the
    -- tests according to the
    -- results
    local testsPassed = {}
    local testsFailed = {}
    
    -- store the maximum value found
    -- for the Levenshtein distance
    local maximum = 0
    
    -- let's analyze our selection
    for i, v in ipairs(selection) do
    
        -- if the Levenshtein distance is
        -- equals to zero, it means the two
        -- strings are equal, so the test
        -- passed!
        if v["levenshtein"] == 0 then
        
            -- add the current test to
            -- the success table!
            table.insert(testsPassed, v)
            
        -- a value greater than zero,
        -- the test failed
        else
        
            -- check if the maximum value
            -- is lower than the current
            -- Levenshtein distance
            if maximum < v["levenshtein"] then
                
                -- update the value
                maximum = v["levenshtein"]
                
            end
            
            -- add the current test to the
            -- failure table!
            table.insert(testsFailed, v)
        
        end
        
    end
    
    -- print info about the files
    print(repeatCharacter("TeX file ", ".", 15, false) .. " " .. sourceName)
    print(repeatCharacter("Log file ", ".", 15, false) .. " " .. logName .. "\n")
    
    -- print header
    print("########## Test Execution Report ##########\n")
    
    -- counters
    local counter = 0
    local total = #selection
    
    -- temporary variable
    -- to create the entry
    local entry
    
    -- message for well succeeded tests
    print("The following tests passed:\n")
    
    -- if no tests succeeded
    if #testsPassed == 0 then
    
        -- print message
        print("- I'm afraid to tell you none of your tests passed.")
        
    -- we have tests that succeeded!
    else
            
        -- let's print them!
        for _, v in ipairs(testsPassed) do
        
            -- increment counter
            counter = counter + 1
            
            -- generate the report entry
            entry = "- " .. generateCounter(counter, total, "[", "]") .. " "
            entry = entry .. repeatCharacter(v["group"] .. ":" .. v["id"] .. " ", ".", 30, false)
            entry = entry .. " [ PASSED ] (LD " .. repeatCharacter(tostring(0), " ", #tostring(maximum), true)
            entry = entry .. ", S " .. string.format("%5.1f", 100) .. "%)"
            
            -- and print it
            print(entry)
        
        end
    
    end
    
    -- message for failed tests
    print("\nThe following tests failed:\n")
    
    -- if no tests failed
    if #testsFailed == 0 then
    
        -- print message
        print("- Congratulations, none of your tests failed!")
        
    -- oh no, we have tests
    -- that failed!
    else
            
        -- let's print them!
        for _, v in ipairs(testsFailed) do
        
            -- increment counter
            counter = counter + 1

            -- a temporary
            -- variable
            local denominator
            
            -- get the value of the
            -- greater length
            if #v["expects"] > #v["output"] then
                denominator = #v["expects"]             
            else            
                denominator = #v["output"]              
            end
            
            -- let's calculate the similarity
            local similarity = v["levenshtein"] / denominator
            
            -- generate the report entry
            entry = "- " .. generateCounter(counter, total, "[", "]") .. " "
            entry = entry .. repeatCharacter(v["group"] .. ":" .. v["id"] .. " ", ".", 30, false)
            entry = entry .. " [ FAILED ] (LD " .. repeatCharacter(tostring(v["levenshtein"]), " ", #tostring(maximum), true)
            entry = entry .. ", S " .. string.format("%5.1f", similarity) .. "%)"
            
            -- and print it
            print(entry)
        
        end
    
    end
    
    -- calculations
    local passed = string.format("%0.1f", ((#testsPassed / total) * 100))
    local failed = string.format("%0.1f", ((#testsFailed / total) * 100))
    
    -- summary
    print("\n:: " .. passed .. "% passed, " .. failed .. "% failed.")
    
end

--- Wraps the main code into a block.
-- This function acts like the main function of the program,
-- wrapping the main code into a block.
local function main()

    -- first of all, draw
    -- the program logo
    drawLogo()

end

-- call the main
-- function
main()
