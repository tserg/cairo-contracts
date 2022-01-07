%builtins output

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.serialize import serialize_word

func get_sqrt(a, upper_bound) -> (result):
	alloc_locals

	local result

	%{
for i in range(1, ids.upper_bound + 1):
	if i ** 2 == ids.a:
		ids.result = i
		break
else:
	raise Exception(
		f"Square root not found in range 1 to {ids.upper_bound}."
		)
	%}

	assert result = a / result
	return (result=result)
end

func output_result{output_ptr : felt*}(
	result):
	serialize_word(result)
	return ()
end

func main{output_ptr : felt*}():
	alloc_locals

	let (local result) = get_sqrt(961, 100)
	output_result(result)
	return ()
end
