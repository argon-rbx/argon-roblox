type SemVer = {
	major: number,
	minor: number,
	patch: number,
}

local SemVer = {}
SemVer.__index = SemVer

function SemVer.new(major: number, minor: number, patch: number)
	return setmetatable({
		major = major,
		minor = minor,
		patch = patch,
	}, SemVer)
end

function SemVer.parse(version: string)
	local major, minor, patch = version:match('(%d+)%.(%d+)%.(%d+)')

	return SemVer.new(tonumber(major) or 0, tonumber(minor) or 0, tonumber(patch) or 0)
end

function SemVer:toString()
	return ('%d.%d.%d'):format(self.major, self.minor, self.patch)
end

function SemVer:isCompatible(other: SemVer)
	return self.major == other.major and self.minor == other.minor
end

function SemVer:__eq(other: SemVer)
	return self.major == other.major and self.minor == other.minor and self.patch == other.patch
end

function SemVer:__lt(other: SemVer)
	if self.major < other.major then
		return true
	elseif self.major > other.major then
		return false
	end

	if self.minor < other.minor then
		return true
	elseif self.minor > other.minor then
		return false
	end

	return self.patch < other.patch
end

function SemVer:__le(other: SemVer)
	return self == other or self < other
end

return SemVer
