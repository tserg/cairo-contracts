%builtins output range_check

from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.squash_dict import squash_dict
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.serialize import serialize_word

struct KeyValue:
    member key : felt
    member value : felt
end


# Builds a DictAccess list for the computation of the cumulative
# sum for each key.
func build_dict(list : KeyValue*, size, dict : DictAccess*) -> (
        dict: DictAccess*):
    if size == 0:
        return (dict=dict)
    end

	%{
KEY_OFFSET = ids.list.address_ + ids.KeyValue.key
VALUE_OFFSET = ids.list.address_ + ids.KeyValue.value

current_key = memory[KEY_OFFSET]
current_value = memory[VALUE_OFFSET]

#print("Current key in build_dict: " + str(current_key))
#print("Current value in build_dict: " + str(current_value))

if current_key in cumulative_sums:
	#print("Found in dict")
	current_cumulative_sum = cumulative_sums[current_key]
	new_cumulative_sum = current_cumulative_sum + current_value
	#print("Old sum: " + str(current_cumulative_sum))
	#print("New sum: " + str(new_cumulative_sum))
else:
	#print("Not found in dict")
	current_cumulative_sum = 0
	new_cumulative_sum = current_value

# Populate ids.dict.prev_value using cumulative_sums...
#print("Adding prev value: " + str(current_cumulative_sum))
#print("Adding new value: " + str(new_cumulative_sum))
ids.dict.prev_value = current_cumulative_sum
ids.dict.new_value = new_cumulative_sum

# Add list.value to cumulative_sums[list.key]...
cumulative_sums[current_key] = new_cumulative_sum
    %}
    # Copy list.key to dict.key...
	assert dict.key = list.key

    # Verify that dict.new_value = dict.prev_value + list.value...
	assert dict.new_value = dict.prev_value + list.value
    # Call recursively to build_dict()...

	let next_list :  KeyValue* = list + KeyValue.SIZE

	return build_dict(
		list=next_list,
		size=size-1,
		dict=dict + DictAccess.SIZE
	)
end

# Verifies that the initial values were 0, and writes the final
# values to result.
func verify_and_output_squashed_dict(
        squashed_dict : DictAccess*,
        squashed_dict_end : DictAccess*, result : KeyValue*) -> (
        result: KeyValue*):
    tempvar diff = squashed_dict_end - squashed_dict
    if diff == 0:
        return (result=result)
    end

	%{
#print("Cumulative sum: " + str(cumulative_sums))
s1 = ids.squashed_dict.address_
s2 = ids.squashed_dict_end.address_

#print("squashed dict size: " + str(s2-s1))

KEY_OFFSET = ids.squashed_dict.address_ + ids.DictAccess.key
PREV_VALUE_OFFSET = ids.squashed_dict.address_ + ids.DictAccess.prev_value
CURRENT_VALUE_OFFSET = ids.squashed_dict.address_ + ids.DictAccess.new_value

current_key = memory[KEY_OFFSET]
prev_value = memory[PREV_VALUE_OFFSET]
current_value = memory[CURRENT_VALUE_OFFSET]

#print("Current key in squashed dict: " + str(current_key))
#print("Previous value in squashed dict: " + str(prev_value))
#print("Current value in squashed dict: " + str(current_value))
	%}

    # Verify prev_value is 0...
	assert squashed_dict.prev_value = 0

    # Copy key to result.key...
	assert result.key = squashed_dict.key

    # Copy new_value to result.value...
	assert result.value = squashed_dict.new_value

    # Call recursively to verify_and_output_squashed_dict...
	let next_squashed_dict : DictAccess* = squashed_dict + DictAccess.SIZE

	return verify_and_output_squashed_dict(
		squashed_dict=next_squashed_dict,
		squashed_dict_end=squashed_dict_end,
		result=result + KeyValue.SIZE
	)
end

# Given a list of KeyValue, sums the values, grouped by key,
# and returns a list of pairs (key, sum_of_values).
func sum_by_key{range_check_ptr}(list : KeyValue*, size) -> (
        result: KeyValue*):
	alloc_locals
    %{
# Initialize cumulative_sums with an empty dictionary.
# This variable will be used by ``build_dict`` to hold
# the current sum for each key.
cumulative_sums = {}
    %}
    # Allocate memory for dict, squashed_dict and res...
	let (local dict_start : DictAccess*) = alloc()
	let (local squashed_dict : DictAccess*) = alloc()
	let (local result : KeyValue*) = alloc()

    # Call build_dict()...
	let (dict_end) = build_dict(
		list=list,
		size=size,
		dict=dict_start
	)
    # Call squash_dict()...
	let (squashed_dict_end : DictAccess*) = squash_dict(
		dict_accesses=dict_start,
		dict_accesses_end=dict_end,
		squashed_dict=squashed_dict
	)
    # Call verify_and_output_squashed_dict()...

	verify_and_output_squashed_dict(
		squashed_dict=squashed_dict,
		squashed_dict_end=squashed_dict_end,
		result=result
	)
	return (result=result)
end

func output_result{output_ptr : felt*}(
		result_dict : KeyValue*, n):
	if n == 0:
		return ()
	end

	serialize_word(result_dict.key)
	serialize_word(result_dict.value)
	return output_result(
		result_dict=result_dict + KeyValue.SIZE, n=n-1
	)
end

func main{output_ptr : felt*, range_check_ptr}():
    alloc_locals

    local key_value_tuple : (KeyValue, KeyValue, KeyValue, KeyValue, KeyValue) = (
        KeyValue(key=1, value=1),
        KeyValue(key=2, value=11),
        KeyValue(key=1, value=21),
        KeyValue(key=2, value=31),
        KeyValue(key=1, value=41),
    )
	let (local result : KeyValue*) = alloc()

    # Get the value of the frame pointer register (fp) so that
    # we can use the address of .
    let (__fp__, _) = get_fp_and_pc()
    let (result) = sum_by_key(
        list=cast(&key_value_tuple, KeyValue*),
        size=5)
	output_result(result_dict=result, n=2)
    return ()
end
