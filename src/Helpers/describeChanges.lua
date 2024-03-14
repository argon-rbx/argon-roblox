local Argon = script:FindFirstAncestor('Argon')
local App = Argon.App

local Types = require(Argon.Types)
local Theme = require(App.Theme)

local function s(len: number): string
	return len > 1 and 's' or ''
end

local function hex(kind: string): string
	return '#' .. Theme.Colors.Diff[kind]:ToHex()
end

return function(changes: Types.Changes): string
	local additions = #changes.additions
	local updates = #changes.updates
	local removals = #changes.removals

	local text = 'There will be '

	if additions > 0 then
		text ..= `<font color="{hex('Add')}">{additions} addition{s(additions)}</font>`

		if updates > 0 or removals > 0 then
			text ..= ', '
		end
	end

	if updates > 0 then
		text ..= `<font color="{hex('Update')}">{updates} update{s(updates)}</font>`

		if removals > 0 then
			text ..= ', '
		end
	end

	if removals > 0 then
		text ..= `<font color="{hex('Remove')}">{removals} removal{s(removals)}</font>`
	end

	text ..= ' applied compared to the server'

	return text
end
