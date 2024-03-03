export type Ref = string
export type Properties = {
	[string]: any,
}

export type Snapshot = {
	id: Ref,
	parent: Ref,
	name: string,
	class: string,
	properties: Properties,
}

export type ModifiedSnapshot = {
	id: Ref,
	name: string?,
	class: string?,
	properties: Properties?,
}

export type RemovedSnapshot = {
	id: Ref,
}

export type Addition = { ['Create']: Snapshot }
export type Modification = { ['Update']: ModifiedSnapshot }
export type Removal = { ['Remove']: RemovedSnapshot }

export type Changes = { Addition | Modification | Removal }

return nil
