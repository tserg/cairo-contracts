# Hash [https://www.cairo-lang.org/docs/how_cairo_works/builtins.html]

from starkware.cairo.common.cairo_builtins import HashBuiltin

func hash2(hash_ptr : HashBuiltin*, x, y) -> (
        hash_ptr : HashBuiltin*, z):
    let hash = hash_ptr
    # Invoke the hash function.
    hash.x = x
    hash.y = y
    # Return the updated pointer (increased by 3 memory cells)
    # and the result of the hash.
    return (hash_ptr=hash_ptr + HashBuiltin.SIZE, z=hash.result)
end

func hash3(hash_ptr : HashBuiltin*, x, y, z) -> (
				hash_ptr : HashBuiltin*, a):

		let (hash, nested) = hash2(hash_ptr, x, y)
		let (hash_2, res) = hash2(hash, nested, z)

		return (hash_ptr=hash_2, a=hash_2.result)

end
