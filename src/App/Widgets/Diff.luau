local Argon = script:FindFirstAncestor("Argon")
local App = Argon.App
local Components = App.Components

local Fusion = require(Argon.Packages.Fusion)

local Theme = require(App.Theme)
local Dom = require(Argon.Dom)
local Types = require(Argon.Types)

local Widget = require(Components.Plugin.Widget)
local ScrollingContainer = require(Components.ScrollingContainer)
local Container = require(Components.Container)
local Padding = require(Components.Padding)
local List = require(Components.List)
local Text = require(Components.Text)
local Box = require(Components.Box)

local Children = Fusion.Children

local function countChildren(snapshot: Types.Snapshot): number
	local count = 0
	if snapshot.children then
		count = #snapshot.children
		for _, child in snapshot.children do
			count += countChildren(child)
		end
	end
	return count
end

local function formatValue(encoded: any): string
	local ok, decoded = Dom.EncodedValue.decode(encoded)
	if ok then
		local str = tostring(decoded)
		if #str > 80 then
			return str:sub(1, 77) .. "..."
		end
		return str
	end
	return "?"
end

local function formatSourceValue(encoded: any): string
	local ok, decoded = Dom.EncodedValue.decode(encoded)
	if ok and type(decoded) == "string" then
		local lines = 0
		for _ in decoded:gmatch("[^\n]*\n") do
			lines += 1
		end
		if not decoded:find("\n$") and #decoded > 0 then
			lines += 1
		end
		return `{lines} line{lines ~= 1 and "s" or ""}`
	end
	return formatValue(encoded)
end

local function readCurrentValue(instance: Instance, propertyName: string): string
	local ok, value = Dom.readProperty(instance, propertyName)
	if ok then
		local str = tostring(value)
		if #str > 80 then
			return str:sub(1, 77) .. "..."
		end
		return str
	end
	return "?"
end

local function readCurrentSourceValue(instance: Instance, propertyName: string): string
	local ok, value = Dom.readProperty(instance, propertyName)
	if ok and type(value) == "string" then
		local lines = 0
		for _ in value:gmatch("[^\n]*\n") do
			lines += 1
		end
		if not value:find("\n$") and #value > 0 then
			lines += 1
		end
		return `{lines} line{lines ~= 1 and "s" or ""}`
	end
	return readCurrentValue(instance, propertyName)
end

local function isSourceProperty(propertyName: string): boolean
	return propertyName == "Source"
end

local function SectionHeader(text: string, color: Color3)
	return Container {
		Size = UDim2.fromScale(1, 0),
		[Children] = {
			Padding {
				Top = 4,
				Bottom = 4,
			},
			Text {
				Font = Theme.Fonts.Bold,
				Text = text,
				Color = color,
				TextSize = Theme.TextSize.Medium,
			},
		},
	}
end

local function AdditionEntry(snapshot: Types.AddedSnapshot)
	local childCount = countChildren(snapshot)
	local details = ""
	if childCount > 0 then
		details = `  ({childCount} descendant{childCount ~= 1 and "s" or ""})`
	end

	return Box {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		[Children] = {
			Padding {},
			Text {
				Text = `+ [{snapshot.class}] "{snapshot.name}"{details}`,
				Color = Theme.Colors.Diff.Add,
				TextSize = Theme.TextSize.Small,
				Font = Theme.Fonts.Mono,
				TextWrapped = true,
			},
		},
	}
end

local function PropertyLine(propertyName: string, currentValue: string, newValue: string)
	return Text {
		Text = `    {propertyName}: {currentValue} → {newValue}`,
		Color = Theme.Colors.TextDimmed,
		TextSize = Theme.TextSize.Small,
		Font = Theme.Fonts.Mono,
		TextWrapped = true,
	}
end

local function UpdateEntry(snapshot: Types.UpdatedSnapshot, tree: any)
	local instance = tree:getInstance(snapshot.id)
	local name = if instance then instance.Name else (snapshot.name or "?")
	local className = if instance then instance.ClassName else (snapshot.class or "?")

	local children = {
		Padding {},
		List {
			Spacing = 2,
		},
		Text {
			Text = `~ [{className}] "{name}"`,
			Color = Theme.Colors.Diff.Update,
			TextSize = Theme.TextSize.Small,
			Font = Theme.Fonts.Mono,
			TextWrapped = true,
		},
	}

	if snapshot.properties then
		for propName, encodedValue in snapshot.properties do
			local newVal
			local curVal

			if isSourceProperty(propName) then
				newVal = formatSourceValue(encodedValue)
				curVal = if instance then readCurrentSourceValue(instance, propName) else "?"
			else
				newVal = formatValue(encodedValue)
				curVal = if instance then readCurrentValue(instance, propName) else "?"
			end

			table.insert(children, PropertyLine(propName, curVal, newVal))
		end
	end

	if snapshot.name and instance and instance.Name ~= snapshot.name then
		table.insert(children, PropertyLine("Name", instance.Name, snapshot.name))
	end

	return Box {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		[Children] = children,
	}
end

local function RemovalEntry(ref: Types.Ref, tree: any)
	local instance = tree:getInstance(ref)
	local name = if instance then instance.Name else "?"
	local className = if instance then instance.ClassName else "?"

	return Box {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		[Children] = {
			Padding {},
			Text {
				Text = `- [{className}] "{name}"`,
				Color = Theme.Colors.Diff.Remove,
				TextSize = Theme.TextSize.Small,
				Font = Theme.Fonts.Mono,
				TextWrapped = true,
			},
		},
	}
end

type Props = {
	Changes: Types.Changes,
	Tree: any,
	Closed: (() -> ())?,
}

return function(props: Props): DockWidgetPluginGui
	local changes = props.Changes
	local tree = props.Tree
	local entries = {}

	-- Additions
	if #changes.additions > 0 then
		table.insert(entries, SectionHeader(`Additions ({#changes.additions})`, Theme.Colors.Diff.Add))
		for _, snapshot in changes.additions do
			table.insert(entries, AdditionEntry(snapshot))
		end
	end

	-- Updates
	if #changes.updates > 0 then
		table.insert(entries, SectionHeader(`Updates ({#changes.updates})`, Theme.Colors.Diff.Update))
		for _, snapshot in changes.updates do
			table.insert(entries, UpdateEntry(snapshot, tree))
		end
	end

	-- Removals
	if #changes.removals > 0 then
		table.insert(entries, SectionHeader(`Removals ({#changes.removals})`, Theme.Colors.Diff.Remove))
		for _, ref in changes.removals do
			table.insert(entries, RemovalEntry(ref, tree))
		end
	end

	return Widget {
		Name = "Argon - Diff",
		OverrideEnabled = true,
		MinimumSize = Vector2.new(450, 400),
		Closed = props.Closed,

		[Children] = {
			Padding {
				Right = 4,
			},

			ScrollingContainer {
				ScrollBar = true,

				[Children] = {
					List {
						Spacing = 6,
					},
					Padding {
						Padding = Theme.WidgetPadding,
					},
					entries,
				},
			},
		},
	}
end
