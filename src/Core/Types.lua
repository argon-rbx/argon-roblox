export type Ref = string
export type ClassName = string
export type Properties = {
	[string]: any,
}

export type Snapshot = {
	id: Ref,
	name: string,
	class: ClassName,
	properties: Properties,
	children: { Snapshot },
}

export type AddedSnapshot = {
	id: Ref,
	parent: Ref,
	name: string,
	class: ClassName,
	properties: Properties,
	children: { Snapshot },
}

export type UpdatedSnapshot = {
	id: Ref,
	name: string?,
	class: ClassName?,
	properties: Properties?,
}

export type RemovedSnapshot = {
	id: Ref,
}

export type Changes = {
	additions: { AddedSnapshot },
	updates: { UpdatedSnapshot },
	removals: { Ref | Instance },
}

export type Addition = { ['Add']: AddedSnapshot }
export type Update = { ['Update']: UpdatedSnapshot }
export type Removal = { ['Remove']: RemovedSnapshot }

export type Message = Addition | Update | Removal

export type ProjectDetails = {
	[string]: any,
}

return nil
