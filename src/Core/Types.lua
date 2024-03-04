export type Ref = string
export type Properties = {
	[string]: any,
}

export type AddedSnapshot = {
	id: Ref,
	parent: Ref,
	name: string,
	class: string,
	properties: Properties,
}

export type UpdatedSnapshot = {
	id: Ref,
	name: string?,
	class: string?,
	properties: Properties?,
}

export type RemovedSnapshot = {
	id: Ref,
}

export type Addition = { ['Create']: AddedSnapshot }
export type Update = { ['Update']: UpdatedSnapshot }
export type Removal = { ['Remove']: RemovedSnapshot }

export type Changes = { Addition | Update | Removal }

return nil
