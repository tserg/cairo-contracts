%builtins output

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.serialize import serialize_word

func array_even_product(arr: felt*, size) -> (sum):

	if size == 0:
		return (sum=1)
	end

	let (product_of_rest) = array_even_product(arr=arr+2, size=size-2)
	return (sum=[arr]*product_of_rest)

end

func main{output_ptr: felt*}():
	const ARRAY_SIZE=4

	let (ptr) = alloc()

	assert [ptr] = 5
	assert [ptr+1] = 4
	assert [ptr+2] = 3
	assert [ptr+3] = 2

	let (sum) = array_even_product(arr=ptr, size=ARRAY_SIZE)

	serialize_word(sum)

	return()

end
