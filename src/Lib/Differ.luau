-- LuaDiffer: A simple Lua diff library
--
-- This file returns a function that can be called on two strings to return a table
-- containing the details of the difference between them. Usage:
--     >> local diff = require("diff")
--     >> diff("hello\nworld", "hello\nWORLD\n!!!")
--     {{old="hello", oldFirst=1, oldLast=1, new="hello\n", newFirst=1, newLast=1},
--      {old="world", oldFirst=2, oldLast=2, new="WORLD\n!!!", newFirst=2, newLast=3}}
-- The returned diff table also has a diff:print() method on it that can be used to print
-- the diff in a human-readable form. See below for the print options.
--
-- This implementation uses the Hunt-McIlroy algorithm, and is inspired by Jason Orendorff's
-- lovely python implementation at: http://pynash.org/2013/02/26/diff-in-50-lines/
--
-- Copyright 2017 Bruce Hill
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do
-- so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

type Diffable = string | { any }

local Diff = { __index = {} }

-- Format a (possibly multi-line) chunk for display without a spurious trailing blank line.
-- The previous `([^\n]*)\n?` gsub matched an extra empty line at end-of-string.
local function formatLines(text: string, prefix: string): string
	if text == "" then
		return ""
	end

	local output = {}
	local cursor = 1

	while cursor <= #text do
		local index = text:find("\n", cursor, true)

		if index then
			table.insert(output, prefix .. text:sub(cursor, index - 1))
			cursor = index + 1
		else
			table.insert(output, prefix .. text:sub(cursor))
			break
		end
	end

	return table.concat(output, "\n")
end

-- Return a new diff as if it were a diff of strings, rather than tables.
Diff.__index.stringify = function(self, separator: string?)
	if #self > 0 and type(self[1].old) == "string" then
		return self
	end

	separator = separator or ", "
	local stringified = {}

	for i, chunk in self do
		stringified[i] = {
			old = table.concat(chunk.old, separator),
			oldFirst = chunk.oldFirst,
			oldLast = chunk.oldLast,
			new = table.concat(chunk.new, separator),
			newFirst = chunk.newFirst,
			newLast = chunk.newLast,
		}
	end

	return setmetatable(stringified, Diff)
end

-- With a diff, you can call diff:print() to get the diff as a formatted string.
Diff.__index.print = function(self): string
	local output = ""

	if #self > 0 and type(self[1].old) == "table" then
		self = self:stringify()
	end

	for _, chunk in self do
		if chunk.old == chunk.new then
			-- Unchanged
			output ..= `{formatLines(chunk.old, "  ")}\n`
		else
			-- Changed
			if #chunk.old > 0 then
				output ..= `{formatLines(chunk.old, "- ")}\n`
			end

			if #chunk.new > 0 then
				output ..= `{formatLines(chunk.new, "+ ")}\n`
			end
		end
	end

	return output:sub(1, -2)
end

-- Take two strings or tables, and return a table representing a chunk-by-chunk diff of the two.
-- By default, strings are broken up by lines, but the optional third parameter "separator" lets
-- you provide a different separator to break on.
-- The return value is a list of chunks that have .old, .new corresponding to the old and
-- new versions. For identical chunks, .old == .new.
local function diff(old: Diffable, new: Diffable, separator: string?)
	local oldLines, newLines = {}, {}

	local function slice(lines: { string }, start: number, stop: number): Diffable
		return table.concat(lines, "", start, stop)
	end

	-- Split into a table using separator (default: newline)
	if type(old) == "string" and type(new) == "string" then
		separator = separator or "\n"

		local pattern = `[^{separator}]*{separator}?`

		for chunk in old:gmatch(pattern) do
			table.insert(oldLines, chunk)
		end

		for chunk in new:gmatch(pattern) do
			table.insert(newLines, chunk)
		end
	elseif type(old) == "table" and type(new) == "table" then
		oldLines, newLines = old, new

		slice = function(lines: { any }, start: number, stop: number): Diffable
			local new = {}

			for i = start, stop do
				table.insert(new, lines[i])
			end

			return new
		end
	else
		error(`Two different types passed to diff: {type(old)} and {type(new)}`)
	end

	-- Find the longest common subsequence between oldLines[oldMin..oldMax] and newLines[newMin..newMax] (inclusive),
	-- and return (the starting position in old), (the starting position in new), (the length)
	local function longestCommonSubsequence(oldMin: number, oldMax: number, newMin: number, newMax: number)
		local longest = { old = oldMin, new = newMin, length = 0 }
		local runs = {}

		for old = oldMin, oldMax do
			local newRuns = {}

			for new = newMin, newMax do
				if oldLines[old] == newLines[new] then
					local run = 1 + (runs[new - 1] or 0)
					newRuns[new] = run

					if run > longest.length then
						longest.old = old - run + 1
						longest.new = new - run + 1
						longest.length = run
					end
				end
			end

			runs = newRuns
		end

		return longest
	end

	-- Find *all* the common subsequences between oldLines[oldMin..oldMax] and newLines[newMin..newMax] (inclusive)
	-- and put them into the commonSubsequences table.
	local commonSubsequences = {}

	local function findCommonSubsequences(oldMin: number, oldMax: number, newMin: number, newMax: number)
		-- Take a greedy approach and pull out the longest subsequences first
		local subsequence = longestCommonSubsequence(oldMin, oldMax, newMin, newMax)

		if subsequence.length == 0 then
			return
		end

		findCommonSubsequences(oldMin, subsequence.old - 1, newMin, subsequence.new - 1)
		table.insert(commonSubsequences, subsequence)
		findCommonSubsequences(
			subsequence.old + subsequence.length,
			oldMax,
			subsequence.new + subsequence.length,
			newMax
		)
	end

	findCommonSubsequences(1, #oldLines, 1, #newLines)

	-- For convenience in iteration (this catches matching chunks at the end):
	table.insert(commonSubsequences, { old = #oldLines + 1, new = #newLines + 1, length = 0 })

	local chunks = setmetatable({}, Diff)
	local oldIndex, newIndex = 1, 1

	for _, subsequence in commonSubsequences do
		if subsequence.old > oldIndex or subsequence.new > newIndex then
			table.insert(chunks, {
				old = slice(oldLines, oldIndex, subsequence.old - 1),
				oldFirst = oldIndex,
				oldLast = subsequence.old - 1,
				new = slice(newLines, newIndex, subsequence.new - 1),
				newFirst = newIndex,
				newLast = subsequence.new - 1,
			})
		end

		if subsequence.length > 0 then
			-- Ensure that the *same* table is used for .old and .new so equality checks
			-- suffice and you don't need to do element-wise comparisons.
			local same = slice(oldLines, subsequence.old, subsequence.old + subsequence.length - 1)

			table.insert(chunks, {
				old = same,
				oldFirst = subsequence.old,
				oldLast = subsequence.old + subsequence.length - 1,
				new = same,
				newFirst = subsequence.new,
				newLast = subsequence.new + subsequence.length - 1,
			})
		end

		oldIndex = subsequence.old + subsequence.length
		newIndex = subsequence.new + subsequence.length
	end

	return chunks
end

local Differ = {}

function Differ.diff(old: Diffable, new: Diffable, separator: string?): string
	return diff(old, new, separator):print()
end

return Differ
