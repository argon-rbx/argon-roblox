-- General structs

export type Ref = string | buffer
export type ClassName = string

export type Properties = {
	[string]: any,
}

export type Meta = {
	keepUnknowns: boolean,
}

-- Snapshots

export type Snapshot = {
	id: Ref,
	meta: Meta,
	name: string,
	class: ClassName,
	properties: Properties,
	children: { Snapshot },
}

export type AddedSnapshot = {
	id: Ref,
	meta: Meta,
	parent: Ref,
	name: string,
	class: ClassName,
	properties: Properties,
	children: { Snapshot },
}

export type UpdatedSnapshot = {
	id: Ref,
	meta: Meta?,
	name: string?,
	class: ClassName?,
	properties: Properties?,
}

-- Other structs

export type WatcherEvent = {
	kind: 'Added' | 'Removed' | 'Changed',
	instance: Instance,
	property: string?,
}

export type Changes = {
	additions: { AddedSnapshot },
	updates: { UpdatedSnapshot },
	removals: { Ref | Instance },
}

export type Project = {
	name: string,
	version: string,
	gameId: number?,
	placeIds: { number },
	rootDirs: { string },
}

-- Messages

export type Message = SyncChanges | SyncDetails | ExecuteCode | Disconnect
export type MessageKind = 'SyncChanges' | 'SyncDetails' | 'ExecuteCode' | 'Disconnect'

export type SyncChanges = {
	SyncChanges: Changes,
}

export type SyncDetails = {
	SyncDetails: Project,
}

export type ExecuteCode = {
	code: string,
}

export type Disconnect = {
	message: string,
}

return nil
