local Argon = script:FindFirstAncestor("Argon")
local App = Argon.App
local Widgets = App.Widgets
local Components = App.Components

local Fusion = require(Argon.Packages.Fusion)
local Dom = require(Argon.Lib.Dom)

local GlobalUtil = require(Argon.Util)
local Types = require(Argon.Types)
local Theme = require(App.Theme)
local Assets = require(App.Assets)

local ScriptDiff = require(Widgets.ScriptDiff)
local Widget = require(Components.Plugin.Widget)
local ScrollingContainer = require(Components.ScrollingContainer)
local Collapsible = require(Components.Collapsible)
local Container = require(Components.Container)
local Padding = require(Components.Padding)
local Image = require(Components.Image)
local List = require(Components.List)
local Text = require(Components.Text)

local New = Fusion.New
local Value = Fusion.Value
local OnEvent = Fusion.OnEvent
local Cleanup = Fusion.Cleanup
local Children = Fusion.Children
local Computed = Fusion.Computed
local ForValues = Fusion.ForValues
local cleanup = Fusion.cleanup
local peek = Fusion.peek

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

local function getSnapshotSource(snapshot: Types.AddedSnapshot | Types.UpdatedSnapshot): string?
	local source = snapshot.properties and snapshot.properties.Source

	if not source then
		return nil
	end

	local ok, decoded = Dom.EncodedValue.decode(source)
	return ok and decoded or ""
end

local function getInstanceSource(instance: Instance): string?
	if not instance:IsA("LuaSourceContainer") then
		return nil
	end

	local ok, source = Dom.readProperty(instance, "Source")
	return ok and source or ""
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

type PropertyProps = {
	Name: string,
	Old: any,
	New: any?,
	Script: string?,
}

local function Property(props: PropertyProps)
	local isHovered = Value(false)
	local scriptDiffWidget = Value(nil)

	local isScript = props.Script ~= nil
	local text

	if isScript and props.New then
		local delta = countLines(props.New) - countLines(props.Old)
		local sign = if delta > 0 then "+" elseif delta < 0 then "-" else "~"

		delta = math.abs(delta)

		text = `<b>{sign}{delta} line{GlobalUtil.plural(delta)}</b>`
	elseif isScript then
		local lines = countLines(props.Old)
		text = `<b>{lines} line{GlobalUtil.plural(lines)}</b>`
	elseif props.New then
		text = `<b>{props.Old}</b> → <b>{props.New}</b>`
	else
		text = `<b>{props.Old}</b>`
	end

	return Text {
		Text = Computed(function(use)
			return if use(isHovered) or use(scriptDiffWidget)
				then `    <u>{props.Name}: {text}  </u>`
				else `    {props.Name}: {text}  `
		end),
		Color = Theme.Colors.TextDimmed,
		TextSize = Theme.TextSize.Small,
		Font = Theme.Fonts.Mono,
		TextWrapped = true,
		RichText = true,
		[OnEvent "InputBegan"] = function(inputObject)
			if not isScript then
				return
			end

			if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
				isHovered:set(true)
				return
			elseif inputObject.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end

			local widget = peek(scriptDiffWidget)

			if widget then
				widget:Destroy()
				widget = nil
			else
				widget = ScriptDiff {
					Name = props.Script,
					OldSource = props.Old,
					NewSource = props.New,
					Closed = function()
						peek(scriptDiffWidget):Destroy()
						scriptDiffWidget:set(nil)
					end,
				}
			end

			scriptDiffWidget:set(widget)
		end,
		[OnEvent "InputEnded"] = function(inputObject)
			if isScript and inputObject.UserInputType == Enum.UserInputType.MouseMovement then
				isHovered:set(false)
			end
		end,
		[Cleanup] = function()
			local widget = peek(scriptDiffWidget)

			if widget then
				widget:Destroy()
				widget = nil
			end
		end,
		[Children] = isScript and Container {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.fromOffset(Theme.TextSize.Small, Theme.TextSize.Small),
			[Children] = {
				Image {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.fromScale(0.3, 0.55),
					Size = UDim2.fromScale(0.6, 0.6),
					Image = Assets.Icons.External,
					ImageColor3 = Theme.Colors.Text,
				},
			},
		} or nil,
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
			table.insert(
				element,
				Property({
					Name = "Descendants",
					Old = descendants,
				})
			)
		end

		local source = getSnapshotSource(snapshot)
		if source then
			table.insert(
				element,
				Property({
					Name = "Source",
					Old = source,
					Script = name,
				})
			)
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
		local name = instance and instance:GetFullName() or snapshot.name or "?"

		local element = {
			Title {
				Symbol = "~",
				Name = name,
				Class = instance and instance.ClassName or snapshot.class or "?",
				Color = Theme.Colors.Diff.Update,
			},
		}

		for property, value in snapshot.properties or {} do
			if property == "Source" then
				local old = instance and getInstanceSource(instance) or ""
				local new = getSnapshotSource(snapshot) or ""

				table.insert(
					element,
					Property({
						Name = property,
						Old = old,
						New = new,
						Script = name,
					})
				)

				continue
			end

			local formatted, raw = "?", nil

			if instance then
				formatted, raw = formatInstanceValue(instance, property)
			end

			table.insert(
				element,
				Property({
					Name = property,
					Old = formatted,
					New = formatSnapshotValue(value, raw),
				})
			)
		end

		if snapshot.name and instance and instance.Name ~= snapshot.name then
			table.insert(
				element,
				Property({
					Name = "Name",
					Old = instance.Name,
					New = snapshot.name,
				})
			)
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
		local name = instance and instance:GetFullName() or "?"

		if typeof(object) == "buffer" then
			instance = tree:getInstance(object)
		end

		local element = {
			Title {
				Symbol = "-",
				Name = name,
				Class = instance and instance.ClassName or "?",
				Color = Theme.Colors.Diff.Remove,
			},
		}

		local descendants = instance and #instance:GetDescendants() or 0
		if descendants > 0 then
			table.insert(
				element,
				Property({
					Name = "Descendants",
					Old = descendants,
				})
			)
		end

		local source = instance and getInstanceSource(instance)
		if source then
			table.insert(
				element,
				Property({
					Name = "Source",
					Old = source,
					Script = name,
				})
			)
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
