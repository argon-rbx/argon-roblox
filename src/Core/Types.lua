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

export type Changes = {
	additions: { AddedSnapshot },
	updates: { UpdatedSnapshot },
	removals: { Ref | Instance },
}

export type ProjectDetails = {
	[string]: any,
}

return nil
