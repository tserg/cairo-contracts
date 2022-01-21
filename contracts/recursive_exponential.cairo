# Recursion [https://www.cairo-lang.org/docs/how_cairo_works/functions.html]

func main():
    [ap] = 2; ap++
		[ap] = 1; ap++
    [ap] = 7; ap++
    call exponential

    # Fake assert instruction to check correctness
    [ap - 1] = 1111
    ret
end

func exponential(first_element, total, n) -> (res):
    jmp exponential_body if n != 0
    [ap] = total; ap++
    ret

    exponential_body:
    [ap] = first_element; ap++
		[ap] = total * first_element; ap++
    [ap] = n - 1; ap++
    call exponential
    ret
end
