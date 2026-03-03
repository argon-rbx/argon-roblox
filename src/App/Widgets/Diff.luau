local Argon = script:FindFirstAncestor("Argon")
local App = Argon.App
local Components = App.Components

local Fusion = require(Argon.Packages.Fusion)

local Theme = require(App.Theme)
local Dom = require(Argon.Dom)
local Types = require(Argon.Types)

local Widget = require(Components.Plugin.Widget)
local ScrollingContainer = require(Components.ScrollingContainer)
local Collapsible = require(Components.Collapsible)
local Container = require(Components.Container)
local Padding = require(Components.Padding)
local List = require(Components.List)
local Text = require(Components.Text)

local New = Fusion.New
local Children = Fusion.Children
local ForValues = Fusion.ForValues
local cleanup = Fusion.cleanup

local MAX_VALUE_LENGTH = 80

local function countDescendants(snapshot: Types.AddedSnapshot): number
	local descendants = 0

	if snapshot.children then
		descendants = #snapshot.children

		for _, child in snapshot.children do
			descendants += countDescendants(child)
		end
	end

	return descendants
end

local function countLines(source: string): number
	return #source:split("\n")
end

local function countSnapshotLines(snapshot: Types.AddedSnapshot | Types.UpdatedSnapshot): number
	local source = snapshot.properties and snapshot.properties.Source

	if not source then
		return 0
	end

	local ok, decoded = Dom.EncodedValue.decode(source)
	return ok and countLines(decoded) or 0
end

local function countInstanceLines(instance: Instance): number
	if not instance:IsA("LuaSourceContainer") then
		return 0
	end

	local ok, source = Dom.readProperty(instance, "Source")
	return ok and countLines(source) or 0
end

local function formatValue(value: any)
	if type(value) == "string" then
		value = `"{value}"`
	elseif typeof(value) == "EnumItem" then
		value = value.Name
	end

	value = tostring(value)

	if value:find(",") then
		value = `({value})`
	end

	if #value > MAX_VALUE_LENGTH then
		return value:sub(1, MAX_VALUE_LENGTH - 3) .. "..."
	end

	return value
end

local function formatSnapshotValue(encoded: any, decoded: any?): string
	local ok, value = Dom.EncodedValue.decode(encoded)

	if ok and typeof(decoded) == "EnumItem" then
		local enum = decoded.EnumType
		value = enum:FromValue(value)
	end

	return ok and formatValue(value) or "?"
end

local function formatInstanceValue(instance: Instance, property: string): (string, any?)
	local ok, value = Dom.readProperty(instance, property)
	return ok and formatValue(value), value or "?", nil
end

type SectionProps = {
	Title: string,
	Color: Color3,
	Elements: { { any } },
}

local function Section(props: SectionProps)
	return Collapsible {
		Title = props.Title,
		Color = props.Color,
		Expanded = true,
		Elements = ForValues(props.Elements, function(_, element)
			return Container {
				Size = UDim2.fromScale(1, 0),
				[Children] = {
					New "Frame" {
						Size = UDim2.new(1, 0, 0, Theme.BorderThickness),
						BackgroundColor3 = Theme.Colors.Border,
						BorderSizePixel = 0,
					},
					Container {
						Size = UDim2.fromScale(1, 1),
						[Children] = {
							List {
								Spacing = 0,
							},
							Padding {},
							element,
						},
					},
				},
			}
		end, cleanup),
	}
end

type TitleProps = {
	Symbol: string,
	Name: string,
	Class: string,
	Color: Color3,
}

local function Title(props: TitleProps)
	return Text {
		Text = `{props.Symbol} [{props.Class}] {props.Name}`,
		Color = props.Color,
		TextSize = Theme.TextSize.Small,
		Font = Theme.Fonts.Mono,
		TextWrapped = true,
	}
end

local function Property(name: string, old: any, new: any?)
	local text

	if new then
		text = `<b>{old}</b> → <b>{new}</b>`
	else
		text = `<b>{old}</b>`
	end

	return Text {
		Text = `    {name}: {text}`,
		Color = Theme.Colors.TextDimmed,
		TextSize = Theme.TextSize.Small,
		Font = Theme.Fonts.Mono,
		TextWrapped = true,
		RichText = true,
	}
end

local function Additions(snapshots: { Types.AddedSnapshot }, tree: any)
	local elements = {}

	for _, snapshot in snapshots do
		local parent = tree:getInstance(snapshot.parent)
		local name = snapshot.name

		if parent then
			name = parent:GetFullName() .. "." .. name
		end

		local element = {
			Title {
				Symbol = "+",
				Name = name,
				Class = snapshot.class,
				Color = Theme.Colors.Diff.Add,
			},
		}

		local descendants = countDescendants(snapshot)
		if descendants > 0 then
			table.insert(element, Property("Descendants", descendants))
		end

		local lines = countSnapshotLines(snapshot)
		if lines > 0 then
			table.insert(element, Property("Lines", lines))
		end

		table.insert(elements, element)
	end

	return Section {
		Title = `Additions ({#snapshots})`,
		Color = Theme.Colors.Diff.Add,
		Elements = elements,
	}
end

local function Updates(snapshots: { Types.UpdatedSnapshot }, tree: any)
	local elements = {}

	for _, snapshot in snapshots do
		local instance = tree:getInstance(snapshot.id)
		local element = {
			Title {
				Symbol = "~",
				Name = instance and instance:GetFullName() or snapshot.name or "?",
				Class = instance and instance.ClassName or snapshot.class or "?",
				Color = Theme.Colors.Diff.Update,
			},
		}

		for property, value in snapshot.properties or {} do
			if property ~= "Source" then
				local formatted, raw = "?", nil

				if instance then
					formatted, raw = formatInstanceValue(instance, property)
				end

				table.insert(element, Property(property, formatted, formatSnapshotValue(value, raw)))

				continue
			end

			local new = countSnapshotLines(snapshot)
			local old = instance and countInstanceLines(instance) or 0
			local delta = new - old
			local sign = if delta > 0 then "+" elseif delta < 0 then "-" else "~"

			delta = math.abs(delta)

			table.insert(element, Property(property, `{sign}{delta} line{delta ~= 1 and "s" or ""}`))
		end

		if snapshot.name and instance and instance.Name ~= snapshot.name then
			table.insert(element, Property("Name", instance.Name, snapshot.name))
		end

		table.insert(elements, element)
	end

	return Section {
		Title = `Updates ({#snapshots})`,
		Color = Theme.Colors.Diff.Update,
		Elements = elements,
	}
end

local function Removals(objects: { Types.Ref | Instance }, tree: any)
	local elements = {}

	for _, object in objects do
		local instance = object

		if typeof(object) == "buffer" then
			instance = tree:getInstance(object)
		end

		local element = {
			Title {
				Symbol = "-",
				Name = instance and instance:GetFullName() or "?",
				Class = instance and instance.ClassName or "?",
				Color = Theme.Colors.Diff.Remove,
			},
		}

		local descendants = instance and #instance:GetDescendants() or 0
		if descendants > 0 then
			table.insert(element, Property("Descendants", descendants))
		end

		local lines = instance and countInstanceLines(instance) or 0
		if lines > 0 then
			table.insert(element, Property("Lines", lines))
		end

		table.insert(elements, element)
	end

	return Section {
		Title = `Removals ({#objects})`,
		Color = Theme.Colors.Diff.Remove,
		Elements = elements,
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

	if #changes.additions > 0 then
		table.insert(entries, Additions(changes.additions, tree))
	end

	if #changes.updates > 0 then
		table.insert(entries, Updates(changes.updates, tree))
	end

	if #changes.removals > 0 then
		table.insert(entries, Removals(changes.removals, tree))
	end

	return Widget {
		Name = "Argon - Diff",
		OverrideEnabled = true,
		MinimumSize = Vector2.new(500, 400),
		Closed = props.Closed,
		[Children] = {
			Padding {
				Right = 4,
			},
			ScrollingContainer {
				ScrollBar = true,
				[Children] = {
					List {},
					Padding {
						Padding = Theme.WidgetPadding,
					},
					entries,
				},
			},
		},
	}
end
