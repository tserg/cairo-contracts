%builtins output

from starkware.cairo.common.serialize import serialize_word

func main{output_ptr: felt*}():

	[ap] = 6/3; ap++
	[ap] = 7/3; ap++

	serialize_word([ap-2])
	serialize_word([ap-1])

	[ap] = [ap-2] * 3; ap++

	return ()
end
