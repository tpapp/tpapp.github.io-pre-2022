using BenchmarkTools

str = "1980"

@benchmark tryparse($UInt, $str)

function tryparse_digits(str, start, stop)
    n = 0
    pos = start
    @inbounds while pos ≤ stop
        chr, next_pos = next(str, pos)
        maybe_digit = chr - '0'
        if 0 ≤ maybe_digit ≤ 9
            n = n*10 + maybe_digit
            pos = next_pos
        else
            return -1
        end
    end
    n
end

function tryparse_digits2(str, start, stop)
    n = 0
    pos = start
    @inbounds while pos ≤ stop
        chr, next_pos = next(str, pos)
        if '0' ≤ chr ≤ '9'
            n = n*10 + (chr - '0')
            pos = next_pos
        else
            return Nullable{Int}()
        end
    end
    Nullable(n)
end

function tryparse_digits3(str::Vector{UInt8}, start, stop)
    n = 0
    z = UInt8('0')
    pos = start
    @inbounds while pos ≤ stop
        maybe_digit = str[pos] - z
        if 0 ≤ maybe_digit ≤ 9
            n = n*10 + maybe_digit
            pos += 1
        else
            -1
        end
    end
    n
end



@benchmark tryparse_digits($str, $1, $4)

datestr = "19800101"

@benchmark tryparse_yyyymmdd($datestr)

DF = DateFormat("yyyymmdd")

@benchmark tryparse(Date, $datestr, $DF)

@benchmark tryparse_digits(datestr, 1, 4)
@benchmark tryparse_digits2(datestr, 1, 4)
@benchmark Base.Dates.tryparsenext_base10(datestr, 1, 4, 4, 4)

@code_warntype tryparse_digits2(datestr, 1, 4)
@code_warntype Base.Dates.tryparsenext_base10(datestr, 1, 4, 4, 4)

@edit Base.Dates.tryparsenext_base10(datestr, 1, 4, 4, 4)

str2 = convert(Vector{UInt8}, datestr)

@benchmark tryparse_digits($str2, $1, $4)

@benchmark tryparse_yyyymmdd($str2)
@benchmark tryparse_yyyymmdd(datestr)
@benchmark tryparse(Date, $datestr, $DF)

@benchmark tryparse_digits($str2, 1, 8)
