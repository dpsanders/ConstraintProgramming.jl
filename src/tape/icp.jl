# References
# [1] ReverseDiff.jl - Jarrett Revels
# [2] Applied Interval Analysis - Luc Jaulin, Michel Kieffer, Olivier Didrit and Eric Walter

"""
Function to apply the forward-reverse contractor on `input` for `function` f. Returns the contracted array, not modifying `input`.

`function` should currently be a `n to 1` function.

`input` must be a `AbstractVector` of `Interval`s.

`contraint` must be an `Interval`.

`tape` is an optional argument, and should be a `Tape` of `ScalarInstruction`s, which can be pre-recorded to avoid recording redundantly. To record -

`tape = IntervalConstraintProgramming.Tape(f, X, constraint)`

Usage:
```
julia> f(X) = X[1]^2 + X[2]^2
f (generic function with 1 method)

julia> X = [-100..100, -100..100]
2-element Array{IntervalArithmetic.Interval{Float64},1}:
 [-100, 100]
 [-100, 100]

julia> constraint = -∞..1
[-∞, 1]

julia> icp(f, X, constraint)
2-element Array{IntervalArithmetic.Interval{Float64},1}:
 [-1, 1] [-1, 1]
```

"""
function icp(f::Function, input::AbstractArray, constraint::Interval)
    tape = Tape(f, input, constraint)
    reverse_pass!(tape.tape, tape.input.value)
    return tape.input.value
end

function icp(f::Function, input::AbstractArray, constraint::Interval, tape::AbstractTape)
    reverse_pass!(tape.tape, tape.input.value)
    return tape.input.value
end

function icp(f::Function, input::IntervalBox, constraint::Interval)
    tape = Tape(f, input.v, constraint)
    reverse_pass!(tape.tape, tape.input.value)
    return IntervalBox(tape.input.value)
end

function icp(f::Function, input::IntervalBox, constraint::Interval, tape::AbstractTape)
    reverse_pass!(tape.tape, tape.input.value)
    return IntervalBox(tape.input.value)
end

"""
Function to apply the forward-reverse contractor on `input` for `function` f. Modifies `input` to contain the contracted array of `Interval`s.

`function` should currently be a `n to 1` function.

`input` must be a `AbstractVector` of `Interval`s.

`contraint` must be an `Interval`.

`tape` is an optional argument, and should be a `Tape` of `ScalarInstruction`s, which can be pre-recorded to avoid recording redundantly. To record -

`tape = IntervalConstraintProgramming.Tape(f, X, constraint)`

Usage:
```
julia> f(X) = X[1]^2 + X[2]^2
f (generic function with 1 method)

julia> X = [-100..100, -100..100]
2-element Array{IntervalArithmetic.Interval{Float64},1}:
 [-100, 100]
 [-100, 100]

julia> constraint = -∞..1
[-∞, 1]

julia> icp!(f, X, constraint)
2-element Array{IntervalArithmetic.Interval{Float64},1}:
 [-1, 1] [-1, 1]
```

"""

function icp!(f::Function, input::AbstractArray, constraint::Interval)
    tape = Tape(f, input, constraint)
    reverse_pass!(tape.tape, input)
    return input
end

function icp!(f::Function, input::AbstractArray, constraint::Interval, tape::AbstractTape)
    reverse_pass!(tape.tape, input)
    return input
end

function reverse_pass!(tape::InstructionTape, input::AbstractArray)
    n = length(input)
    for i in length(tape):-1:1
        t = tape
        t[i].output.value = t[i].output.value ∩ t[i].cache
        op = IntervalContractors.reverse_operations[Symbol(t[i].func)]
        rev_result = getfield(IntervalContractors, op)(value(t[i].output), value.(t[i].input)...)
        if length(rev_result) == 2
            t[i].input.value = rev_result[2]
            if 0 < t[i].input.index <= n
                input[t[i].input.index] = rev_result[2]
            end
        else
            t[i].input[1].value = rev_result[2]
            if 0 < t[i].input[1].index <= n
                input[t[i].input[1].index] = rev_result[2]
            end
            if istracked(t[i].input[2])
                t[i].input[2].value = rev_result[3]
                if 0 < t[i].input[2].index <= n
                    input[t[i].input[2].index] = rev_result[3]
                end
            end
        end

    end
    return nothing
end

function Tape(f::Function, input::AbstractArray, interval_init::Interval, cfg::Config = Config(input))
    track!(cfg.input, input)
    tracked_ouput = f(cfg.input)
    cfg.tape[length(cfg.tape)] = ScalarInstruction(cfg.tape[length(cfg.tape)].func, cfg.tape[length(cfg.tape)].input, cfg.tape[length(cfg.tape)].output, interval_init)
    return _Tape(f, cfg.input, tracked_ouput, cfg.tape)
end

function Tape(f::Function, input::IntervalBox, interval_init::Interval, cfg::Config = Config(input.v))
    track!(cfg.input, input.v)
    tracked_ouput = f(cfg.input)
    cfg.tape[length(cfg.tape)] = ScalarInstruction(cfg.tape[length(cfg.tape)].func, cfg.tape[length(cfg.tape)].input, cfg.tape[length(cfg.tape)].output, interval_init)
    return _Tape(f, cfg.input, tracked_ouput, cfg.tape)
end
