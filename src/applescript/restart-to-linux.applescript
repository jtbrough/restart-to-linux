use scripting additions

on run argv
	set candidateCount to count of argv

	if candidateCount is 0 then
		return ""
	end if

	if candidateCount is 1 then
		return item 1 of argv
	end if

	set chosenTarget to choose from list argv
	if chosenTarget is false then error number -128

	return item 1 of chosenTarget
end run
