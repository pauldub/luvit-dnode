--[[------------------------------------------------------------
lua-functional-doc.lua

Documentation for lua-functional.lua.
version 1.102
for Lua 5.2.0

Bo Waggoner
Modified: 2012-02-02

This software is free.
--------------------------------

VERSION HISTORY

Version          Release Date    Tested with Lua version
1.102 (current)  2012-02-02      5.2.0
1.101            2012-02-02      5.2.0
1.1              2012-02-02      5.2.0
1.001            2011-09-30      5.1.4
1.0              2011-09-29      5.1.4

Changes:
1.102   -- renamed 'select' to 'choose' to avoid conflict with the built-in
           lua function
        -- renamed 'sel' to 'indicator' to correspond, and for clarity
        -- made range() a bit faster
        -- added another example: Levenshtein distance
1.101   -- slightly increased functionality of casef: predicates and results can
           now be of any type; if they are not functions, treat them as values;
           if they are functions, call them with the input arguments.
1.1     -- updated for Lua 5.2:
           -- removed 'pack' (use table.pack instead)
           -- implementation details: fixes relating to use of pack and arg
           -- updated lua-functional-test.lua for same issues
        -- increased functionality of 'casef': a result can now be true, false,
             or nil, or it may be a function of the arguments as previously
        -- increased functionality of 'range': can now be called with only
             one argument, in which case default start value is 1
1.001	fixed bug in apply where it would fail with table arguments
1.0 	first release

--------------------------------

How to get started: See the example after this comment block.


Meta-notes:

The contact address for this project is luafunctional@gmail.com.
The project is hosted at https://bitbucket.org/luafunctional/lua-functional
Please send bug reports, comments, questions, or suggestions for improvement.
Compliments and money are also accepted. Creative insults are all right.


Notes on this file:

This documentation is in the form of an executable lua file.
This is so you can not only see the printed output of the examples,
but also modify the examples or try your own right there in the code.
You are invited to think of this file as a tutorial as well as documentation.

Throughout, I refer to lists and arrays. By these I mean tables, whose
values are usually indexed by 1,2,3,....
When I say tuple, I mean it is definitely indexed by 1,2,3,...
and is in a specific order.


Here is the list of functions. To jump to the entry for "func",
type "Ctrl+f func" and hit enter a couple times.
If that fails, hit ESC, type ":/func" and hit enter a couple times.
If that fails, hit C-g, press C-s, type "func", and maybe hit C-s a few times.
If that fails, try scrolling down or asking a friend for help.

add = function(...)
apply = function(f, ...)
applyn = function(f,n,val,...)
_and = function(...)
case = function(...)
casef = function(...)
choose = function(pred, a, b)
compose = function(...)
concat = function(...)
curry = function(f,n)
div = function(a,b)
eq = function(...)
filter = function(func, t, iter)
filterkey = function(func, t, iter)
filterkeyp = function(func, t, iter)
filterp = function(func, t, iter)
flatten = function(t,iter,t2,ind)
foldl = function(func, val, t, iter)
foldl1 = function(func, t, iter)
foldr1 = function(func, t, iter)
foldr = function(func, val, t, iter)
geq = function(...)
gen = function(seed, succ, cond)
gent = function(seed, succ, cond)
gt = function(...)
id = function(...)
indicator = function(pred)
len = function(...)
leq = function(...)
listcomp = function(func, arr, ...)
loadglobally = function(lf, t)
lt = function(...)
map = function(func, t, iter)
maptup = function(func, t, iter)
max = function(t, compare, iter)
min = function(t, compare, iter)
mod = function(a,b)
mult = function(...)
neg = function(...)
neq = function(...)
_not = function(...)
_or = function(...)
pack = function(...)
pow = function(a,b)
range = function(start,stop,step)
reverse = function(t, iter)
scanl = function(func, val, t, iter)
scanl1 = function(func, t, iter)
scanr = function(func, val, t, iter)
scanr1 = function(func, t, iter)
sub = function(a,b)
takewhile = function(func, t, iter)
zip = function(iter, t1, ...)
zipor = function(iter, ...)
zipwith = function(func, iter, ...)
zipwithtup = function(func, iter, ...)


For more information on functional programming, I suggest you learn Haskell.

--]]-------------------------------------------------------------





-- TO BEGIN:
-- load the library into the table 'lfunc'
lfunc = dofile('lua-functional.lua')

-- now any lua-functional function may be accessed as follows:
print(lfunc.add(1,2))  --> 3

-- load the libarary into the global namespace for convenience
lfunc.loadglobally(lfunc)

-- now any lua-functional function may be accessed as follows:
print(add(1,2))  --> 3



--------------------------------
-- add = function(...)
----------------
-- Add all given values together.
-- Parameters:
--   ...: things to add
-- Returns:
--   sum: the sum of the arguments
--        = 0 if no parameters are given
print(add(1,2,3,4,5))  --> 15


--------------------------------
-- apply = function(f, ...)
----------------
-- Partially apply f to the parameters. E.g., apply(f,a1,...,an)
-- returns a function g so that g(b1,...bm) calls f(a1,...,an,b1,...,bm).
-- Parameters:
--   f:   the function to apply
--   ...: the parameters to apply it to
-- Returns:
--   g:   a function: f partially applied to '...'. If f is nil or
--        not a function, g's behavior is undefined.
print(apply(add,1,2,3)(4,5))  --> 15


--------------------------------
-- _and = function(...)
----------------
-- Evaluates the logical AND of all parameters, in short-circuit
-- fashion. Given n arguments, if the first n-1 are true, it returns
-- the nth; if not, it returns the first non-true one.
-- Parameters:
--   ...: the values to AND
-- Returns:
--   v:   the first non-true argument, or the last argument
--        = nil if no arguments are given
print(_and(8,'g',{},false,29))  --> false
print(_and(4,true,-20))         --> -20


--------------------------------
-- case = function(...)
----------------
-- Given a set of cases of the form {predicate, value}, selects the
-- first predicate that is true and evaluates and returns its value.
-- Parameters:
--   ...:   a list of tables, each consisting of {pred,value}
-- Returns:
--   value: the value corresponding to the first non-nil, non-false pred.
--          = nil if no case is matched
print(case({false,10},{'frabjous','day'},{true,5}))  --> 'day'


--------------------------------
-- casef = function(...)
----------------
-- Like case, but wraps up if/elseif chain in a function that gets returned.
-- Also can call functions as predicates and return values.
-- Takes as input a list of pairs {pred, result}.
-- Returns a function g so that a call to g(args) returns the first result whose
-- predicate is true. That is, consider the first pred so that either pred(args)
-- or pred is true. Return the corresponding result(args) or result.
-- In both cases, only treat pred or result as a function if they are of type
-- function; otherwise just use their values.
-- Parameters:
--   ...: each argument is a table of the form {[1]=pred, [2]=result}
-- Return:
--   f: a function that, when called with 'args', for the
--      first time (cond or cond(args)) is non-nil, non-false,
--      return: (pred or pred(args)). For each, call as a function only if it
--         is of type function.
--      If no tables are passed in or no case matches, f returns nil.
g = casef({nil,   function(a,b) return 0 end},
          {gt,    function(a,b) return a+b end},  -- gt is "greater than"
          {lt,    'blue'},
          {1,     function(a,b) return a^b end})
print(g(7,5))  --> 12
print(g(5,7))  --> 'blue'
print(g(6,6))  --> 46656


--------------------------------
-- compose = function(...)
----------------
-- Compose two functions together, from left to right.
-- Returns a function that, when called, first calls the
-- rightmost function with its arguments, then passes those
-- results to the next function, etc.
-- Parameters:
--   ...: a list of functions
-- Returns:
--   g:   the function composition of (...)
--        g returns its arguments if ... is empty
print(compose(pow,neg)(2,-3))  --> -8
print(compose(neg,pow)(2,-3))  --> -0.125

--------------------------------
-- concat = function(...)
----------------
-- Concatenate a list of arguments. They must
-- be strings or numbers.
-- Parameters:
--   ...: a list of strings and/or numbers
-- Returns:
--   str: a string of concatenated arguments
--        = '' if no arguments are given
print(concat('green ',7,'? house'))  --> green 7? house


--------------------------------
-- curry = function(f,n)
----------------
-- Curry a function: Given f, return g, a curried version of f.
-- If g is called with n or more arguments, g evaluates f over
-- those arguments. If g is called with m < n arguments, g
-- partially applies f to those arguments and returns a function h:
-- a curried version of the result over (n-m) arguments.
-- We need to specify n, the total number of arguments to take;
-- otherwise, calls to g(), h(), etc would just keep returning
-- functions and never return a result.
-- Parameters:
--   f: the function to be curried.
--   n: the number of arguments to expect before ouputting a result
-- Returns:
--   g: the curried version of f.
g = curry(add,5)
h = g(1,2,3)
i = h(4)
print(g(1,2,3,4,5))     --> 15
print(h(4,5))           --> 15
print(i(5))             --> 15
print(g(1)(2)(3)(4)(5)) --> 15


--------------------------------
-- div = function(a,b)
----------------
-- Divide a by b.
print(div(7,2))  --> 3.5


--------------------------------
-- eq = function(...)
----------------
-- Test arguments for equality. If each argument
-- is equal to the next, or no arguments are given,
-- returns true.
print(eq(tostring(100),'100'))  --> true


--------------------------------
-- filter = function(func, t, (iter))
----------------
-- Given an array A1, return a new array A2 containing the elements
-- a of A1 for which func(a) is not nil and not false.
-- Parameters:
--   func: a function applied to each element and returning true or false
--   t:    a table (the list)
--   iter: (optional) an iterator function to be used with t
--         Default value: ipairs
-- Returns:
--   t2:   a 1-indexed array satisying that, for each k,v returned by iter,
--         if func(v) then add v to t2
print(unpack(filter(apply(eq,1),{1,2,3,1,4,1})))                 --> 1  1  1
print(unpack(filter(apply(lt,0),{-5,5,green=8,blue=-8},pairs)))  --> 5  8


--------------------------------
-- filterkey = function(func, t, (iter))
----------------
-- Exactly like filter, except that func is passed both the key
-- and the value of each element of t.
-- Parameters:
--   func: a function applied to each key,value pair in t
--   t:    the table
--   iter: (optional) an iterator function to be used with t
--         Default value: ipairs
-- Returns:
--   t2:   a 1-indexed array satisfying that, for each k,v returned by iter,
--         if func(k,v) then add v to t2
print(unpack(filterkey(eq,{1,2,5,4,3,6})))    --> 1  2  4  6
print(unpack(filterkey(neq,
     {2,1,3,red='red',blue='green'},pairs)))  --> 2  1  green


--------------------------------
-- filterkeyp = function(func, t, (iter))
----------------
-- Works like filterkey, but preserves key/value mappings. That is,
-- puts each value in the new table with the same key it had previously.
-- Thus, it uses pairs as the default iterator.
-- Parameters:
--   func: a function applied to each key,value pair in t
--   t:    the table
--   iter: (optional) an iterator function to be used with t
--         Default value: pairs
-- Returns:
--   t2:   an array satisfying that, for each k,v returned by iter,
--         if func(k,v) then t2[k] = v
g = filterkeyp(gt,{1,3,2,red='green',blue='yellow'})  -- {[3]=2,red='green'}
print(unpack(flatten(g,pairs)))  --> 2    green


--------------------------------
-- filterp = function(func, t, (iter))
----------------
-- Works like filter, but preserves key/value mappings. That is,
-- puts each value into t2 with the same key it had in t.
-- Uses pairs as the default iterator.
-- Parameters:
--   func: a function applied to each value in t
--   t:    the table
--   iter: (optional) an iterator function to be used with t
--         Default value: pairs
-- Returns:
--   t2:   an array satisfying that, for each k,v returned by iter,
--         if func(v) then t2[k] = v
g = filterp(apply(gt,5),{6,5,4,3,red=2,blue=7})  -- {[3]=4,[4]=3,red=2}
print(unpack(flatten(g,pairs)))  --> 4   3   2


--------------------------------
-- flatten = function(t, (iter), (t2), (ind))
----------------
-- Turn t into a one-dimensional array, recursively doing the same
-- for any tables in t. Stores the array into t2 starting at ind.
-- Don't call on any tables with cycles!
-- Parameters:
--   t:    the table to flatten
--   iter: (optional) an iterator function over t and its sub-tables
--         Default value: ipairs
--   t2:   (optional) the table in which to store it
--         Default value: a new empty table
--   ind:  (optional) index at which to begin storing the values
--         Default value: 1
-- Returns:
--   t2:   the "flattened" version of t
print(unpack(flatten({1,2,{3,4,{5,{},6}}})))   --> 1  2  3  4  5  6
print(unpack(flatten({1,2,3,d={4,5}},pairs)))  --> 1  2  3  4  5


--------------------------------
-- foldl = function(func, val, t, (iter))
----------------
-- Fold from left. (Also known as "reduce" or "accumulate").
-- Assume the iterator returns values v1, v2, etc.
-- First let val = func(val,v1). Next let val = func(val,v2). Etc.
-- Return the final value.
-- Parameters:
--   func: the accumulator function to apply
--   val:  the starting value
--   t:    the table we apply 'func' to
--   iter: (optional) an iterator over t
--         Default value: ipairs
-- Return:
--   val: the final value obtained
--     if 't' is empty, return the parameter val
print(foldl(sub,100,{2,4,3}))                        --> 91
print(foldl(div,720,{1,2,3,4,green=5,red=6},pairs))  --> 1
print(foldl(mod,50,{20,7}))                          --> 3


--------------------------------
-- foldl1 = function(func, t, (iter))
----------------
-- Exactly like foldl, but don't use a starting value,
-- just start at the first value returned by the iterator.
-- If t is empty, return nil.
print(foldl1(sub,{100,2,4,3}))  --> 91
print(foldl1(mod,{50,20,7}))    --> 3


--------------------------------
-- foldr = function(func, val, t, (iter))
----------------
-- Just like foldl, but fold from right. That is, if the
-- iterator returns values t1, ..., tn: First let val = func(tn,val).
-- Then let val = func(tn-1,val). Etc.
print(foldr(mod,7,{50,20}))  --> 2


--------------------------------
-- foldr1 = function(func, t, (iter))
---------------
-- Exactly like foldr, but don't use a starting value;
-- begin at the first two values returned from the iterator.
-- If t is empty, return nil.
print(foldr1(mod,{50,20,7}))  --> 2


--------------------------------
-- geq = function(...)
----------------
-- Return true if each argument is greater than or equal
-- to the next one. If only one argument, it's true.
print(geq(5,3,4,2))             --> false
print(geq('yes','no','no','maybe'))  --> true


--------------------------------
-- gen = function(seed, succ, cond)
---------------
-- Generate a list starting with seed, continuing with succ,
-- until cond. That is, uses the following loop:
-- while not cond(seed,index), add seed to list, then set
-- seed = succ(seed,index). index is 1,2,...
-- Parameters:
--   seed: the initial value
--   succ: a function taking seed,index as arguments
--         and returning the next seed
--   cond: the stopping condition, a function of seed, index
-- Returns:
--   t:    the generated list
t = gen('a',function(str) return concat(str,'.') end,
            function(str) return #str > 4 end)
print(unpack(t))  --> a  .a  ..a  ...a
t = gen(1,function(n,ind) return ind*ind end,applyn(gt,2,50))
print(unpack(t))  --> 1  4  9  16  25  36  49


--------------------------------
-- gent = function(seedt, succ, cond)
---------------
-- Like gen, but start with a seed table. Succ is now a function
-- of the table and the new index, while cond is a function of
-- the table, the new value, and the new index.
-- gent adds values at the end of the current table.
-- You can think of gen as weak induction and gent as strong induction.
-- Parameters:
--   seedt: the initial table (or nil for an empty table)
--   succ:  = function(table,index) returns the next value to put in table
--   cond:  = function(table, value, index) the stopping condition
-- Returns:
--   seedt: the generated list (also placed in parameter seedt if non-nil)
t = gent({1,2},function(t,ind) return t[ind-1]+t[ind-2] end,
               function(t,val,ind) return val > 40 end)
print(unpack(t))  --> 1  2  3  5  8  13  21  34


--------------------------------
-- gt = function(...)
----------------
-- Return true if each argument is greater than the next one.
-- If only one argument, true.
print(gt(5,4,3,3,1))          --> false
print(gt('yes','no','maybe')) --> true


--------------------------------
-- id = function(...)
----------------
-- The identity function. Return the arguments.
print(id(5,'blue',nil,333))  --> 5  'blue'  nil  333


--------------------------------
-- len = function(...)
----------------
-- The length operator. Returns the length of each argument.
print(len({},'',{1,2,4},'truth'))  --> 0  0  3  5


--------------------------------
-- leq = function(...)
----------------
-- Returns true if each argument is less than the next, or
-- there's only one argument.
print(leq(1,10,10,50))   --> true
print(leq('a','d','b'))  --> false


--------------------------------
-- listcomp = function(func, arr, ...)
----------------
-- List comprehension. Returns {func(x) for x in arr satisfying ...}.
-- Pass in func==nil to simply return all x satisfying ....
-- Parameters:
--   func: function applied to array AFTER filters to produce final array
--         if == nil, then the identity function is used
--   arr:  array of values to base the list on (often generated with 'range')
--   ...:  zero or more filter functions f: if f(v) is true for all f,
--         include v in the list
-- Return:
--   t:    a 1-indexed array
square = applyn(pow,2,2)
even = compose(apply(eq,0),applyn(mod,2,2))
gt3 = applyn(gt,2,3)    -- {x^2 in [1,8] where x>3, x is even}
print(unpack(listcomp(square,{1,2,3,4,5,6,7,8},gt3,even)))  --> 16  36  64


--------------------------------
-- loadglobally = function(lf, (t))
----------------
-- Load all lua-functional functions into the global space (or the given
-- table). For an example, see the beginning of this file.
-- Parameters:
--   lf: table produced by dofile('lua-functional.lua')
--   t:  (optional) a table into which to put all the lua functions
--       Default value: _G
-- Returns:
--   lf: the same table
t = {}
loadglobally(lfunc,t)
print(t.add(1,2,3))  --> 6


--------------------------------
-- lt = function(...)
----------------
-- Return true if each argument is less than the next, or there's
-- only one argument.
print(lt(1,5,5,9))  --> false
print(lt('bear'))   --> true


--------------------------------
-- map = function(func, t, (iter))
----------------
-- Apply func to each value of t, returning a new table with the results.
-- Specifically, for each k,v returned by iter, t2[k] = func(v)
-- Parameters:
--   func: the function to apply
--   t:    the array/table to apply it to
--   iter: (optional) an iterator function for t
--         Default value: pairs
-- Returns:
--   t2:   the table created
print(unpack(map(apply(add,2),{4,5,6,7})))  --> 6  7  8  9
t = map(_not,{1,false,g=6,r=false},pairs)   -- t = {false,true,g=false,r=true}
print(unpack(flatten(t,pairs)))             --> false  true  false  true


--------------------------------
-- maptup = function(func, t, (iter))
----------------
-- Just like map, except that all return values of func are packed into
-- a tuple, so the returned table is an table of tuples.
twomult = function(x) return 2*x, 3*x end
t = maptup(twomult,{1,2,3})  -- t = {{2,3},{4,6},{6,9}}
print(unpack(t[1]))  --> 2  3
print(unpack(t[2]))  --> 4  6
print(unpack(t[3]))  --> 6  9


--------------------------------
-- max = function(t, (compare), (iter))
----------------
-- Find the maximal element in t along with the first key that indexes it.
-- Note that if you use >= instead of >, you'll get the last
-- key that indexes the maximal value. compare is a custom comparator.
-- Parameters:
--   t:       the table
--   compare: (optional) a function to compare two elements
--            compare(a,b) = true iff a > b
--            Default value: lfunc.gt
--   iter:    (optional) an iterator over the table
--            Default value: ipairs
-- Return:
--   ans:     the (first) maximal element of the table
--            If t is empty, return nil
--   key:     first key according to iter satisfying t[key] == ans
--            If t is empty, return nil
print(max({100,-2,55,68}))               --> 100  1
print(max({41,-8,g=-17,r=12},lt,pairs))  --> -17  g


--------------------------------
-- min = function(t, (compare), (iter))
----------------
-- Exactly the same as max, except compare defaults to lfunc.lt.
print(min({'who','will','win','big surprise'}))  --> big suprise     4


--------------------------------
-- mod = function(a,b)
----------------
-- Computes a modulo b.
print(mod(17,5))  --> 2


--------------------------------
-- mult = function(...)
----------------
-- Multiplies all the arguments together.
-- Paramters:
--   ...: things to be multiplied
-- Returns:
--   ans: the product of the arguments
--        = 1 if no arguments are given
print(mult(2,3,5,7))  --> 210


--------------------------------
-- neg = function(...)
----------------
-- Negates all arguments. Returns nil if no arguments are passed in.
print(neg(5,100,100000))  --> -5  -100  -100000


--------------------------------
-- neq = function(...)
----------------
-- Return true if any two of the arguments are not equal, or false
-- if they are all equal. Returns false if there is only one argument.
print(neq(1,1,1,0,1))    --> true
print(neq(0,5-5,3-4+1))  --> false


--------------------------------
-- _not = function(...)
----------------
-- Returns the logical not of all arguments.
print(_not('a',5,false,nil,true))  --> false  false  true  true  false


--------------------------------
-- _or = function(...)
----------------
-- Compute the logical OR of the arguments, short-circuited lua style.
-- That is, return the first argument that is non-nil, non-false,
-- or the last argument if all are nil or false.
-- Return nil if no arguments are given.
print(_or(false,5==6))                    --> false
print(_or(nil,false,_not(true),7,false))  --> 7


--------------------------------
-- pow = function(a,b)
----------------
-- return a^b.
print(pow(7,3))  --> 343


--------------------------------
-- range = function((start), stop, (step))
----------------
-- Produce a list of numbers. A special case of gen.
-- Include start, then change start by step until it goes beyond stop.
-- That is, continue while start's relationship to stop is preserved.
-- By relationship, I mean <, >, or ==.
-- If only one argument is given, then it is stop; start is assumed to be 1.
-- start is only optional if there is one argument.
-- Parameters:
--   start: the first number to include in the list
--          if only one parameter is given, it is 'stop'; 'start' is set to 1
--   stop:  continue including numbers until we're past this number
--   step:  (optional) change start by this value each loop
--          Default value: 1 if stop >= start, or -1 otherwise
-- Returns:
--   arr:   an array of numbers
print(unpack(range(3,7)))       --> 3  4  5  6  7
print(unpack(range(8,-10,-5)))  --> 8  3  -2  -7
print(unpack(range(0,0,2)))     --> 0


--------------------------------
-- reverse = function(t, (iter))
----------------
-- Reverse the array or string t.
-- If t is a table, return a 1-indexed array containing the elements of
-- t in the opposite order that they are returned by iter.
-- Parameters:
--   t:    the array or string
--   iter: (optional) if t is a table, an iterator for t
--         Default value: ipairs
-- Returns:
--   t2:   the values of t in reverse order
print(reverse('palindrome'))         --> emordnilap
print(unpack(reverse({5,8,11,13})))  --> 13  11  8  5


--------------------------------
-- scanl = function(func, val, t, (iter))
----------------
-- Like foldl, but returns an array of all values produced,
-- in order. That is, we go through the array t from the left
-- (from the first value v1 returned by iter). We start with val as the first
-- element of our array. Then set val = func(val,v1). We store val in our array
-- and move on. Since we start with val, the size of the array is one greater
-- than that of t.
-- Parameters:
--   func: a function with which to "fold up" or reduce the list
--   val:  an initial value to pass to the function
--   t:    the list
--   iter: (optional) an iterator over t
--         Default value: ipairs
-- Returns:
--   t2:   the produced array (if t is empty, contains just val)
print(unpack(scanl(sub,100,{2,4,3})))  --> 100  98   94   91
print(unpack(scanl(div,720,{1,2,3,4,green=5,red=6},pairs)))
                                       --> 720  720  360  120  30  5  1
print(unpack(scanl(mod,50,{20,7})))    --> 50   10   3

--------------------------------
-- scanl1 = function(func, t, iter)
----------------
-- Exactly like scanl, but don't use a starting value, just
-- start right in on the list with func(v1,v2).
-- If list is empty, return nil.
print(unpack(scanl1(sub,{100,2,4,3})))  --> 100  98   94   91
print(unpack(scanl1(mod,{50,20,7})))    --> 50   10   3


--------------------------------
-- scanr = function(func, t, (iter))
----------------
-- Just like scanl, but fold from right. That is, if the
-- iterator returns values t1, ..., tn: First Let val = func(tn,tn-1).
-- Then let val = func(val,tn-1). Etc.
-- But we fill the array right-to-left.
print(unpack(scanr(mod,7,{50,20})))  --> 2  6  7


--------------------------------
-- scanr1 = function(func, t, (iter))
----------------
-- Exactly like scanr, but don't use a starting value;
-- begin at the first value returned from the iterator.
-- If t is empty, return nil.
print(unpack(scanr1(mod,{50,20,7})))  --> 2  6  7


--------------------------------
-- indicator = function(pred)
----------------
-- Special case of choose: return 1 if pred, 0 otherwise.
print(indicator(5 > 3))   --> 1
print(indicator(2 == 7))  --> 0


--------------------------------
-- choose = function(pred, a, b)
----------------
-- Special case of "case": if pred then return a, otherwise b
print(choose(5 > 3,'is greater','not greater'))  --> is greater
print(choose(2 == 7, 2+7, 2-7))                    --> -5


--------------------------------
-- sub = function(a,b)
----------------
-- Return a - b.
print(sub(24,34))  --> -10


--------------------------------
-- takewhile = function(func, t, (iter))
----------------
-- Return a new array consisting of t up until func(v) is false or nil.
-- Take elements from t while func(v).
-- Parameters:
--   func: the function of a value v that tells us whether to take v
--   t:    the array
--   iter: (optional) an iterator over t; take values in this order
--         Default value: ipairs
-- Returns:
--   t2:   a 1-indexed array of the first n values of t, where the n+1th
--         is the first to fail func(v)
print(unpack(takewhile(applyn(gt,2,0),{4,8,1,-2,3,-5,17})))  --> 4  8  1


--------------------------------
-- zip = function((iter), t1, ...)
----------------
-- Combine multiple tables into a single table.
-- Given tables t1,...,tn, produce a table T of ordered tuples.
-- So T[k] = {t1[k],...,tn[k]}. T contains a key k only if all the
-- input tables contain k.
-- Parameters:
--   iter: (optional) an iterator over t1
--         Default value: pairs (call with nil to use default value)
--   t1:   the first table to include
--         if nil, returns an empty table
--   ...:  (optional) the other tables to zip up with
-- Returns:
--   T:    a table where, for each key k, T[k] is an ordered list
--         of the values at k of each input table
t = zip(nil,{1,2},{'a','b'},{10,11})        -- t = {{1,'a',10},{2,'b',11}}
print(unpack(flatten(t)))  --> 1   a   10  2   b   11
t = zip(nil,{a=1,b=2,c=3},{a=-1,b=-2,d=3})  -- t = {a={1,-1},b={2,-2}}
print(unpack(flatten(t,pairs)))  --> 1   -1  2   -2


--------------------------------
-- zipor = function((iter), ...)
----------------
-- Like zip, but T includes a key if any of the tables contain that key.
-- Thus T may have different-sized tuples for different keys.
-- Parameters:
--   iter: (optional) an iterator over t1
--         Default value: pairs (use nil to get default behavior)
--   ...:  tables to zip up (if none, returns an empty table)
-- Returns:
--   T:    a table where, for each k, T[k] is an ordered list of the
--         values at k of each input table, where applicable
t = zipor(nil,{1,2,nil},{nil,'b','c'})  -- t = {{1},{2,'b'},{'c'}}
print(unpack(flatten(t)))  --> 1  2  b  c 


--------------------------------
-- zipwith = function(func, iter, ...)
----------------
-- Uses a function to combine multiple tables into a single list.
-- Like zip, but T is a value instead of a tuple:
-- T[k] = func(t1[k],...,tn[k]).
-- Note func should only return one value; to handle multiple
-- return values, use zipwithtup.
-- Parameters:
--   func: the function to call using the set of values at a certain key
--   iter: an iterator over the first table
--         if nil, uses pairs
--   ...:  the tables to zip
-- Returns:
--   T:    a table of values: for each k, T[k] = func(t1[k],...tn[k])
t = zipwith(add,nil,{1,1,1},{1,2,3},{10,10,10})
print(unpack(t))  --> 12  13  14
t = zipwith(eq,nil,{4,7,9},{3+1,3+3,3+6},{5-2,5+2,5+4})
print(unpack(t))  --> false  false  true
t = zipwith(compose(max,table.pack),nil,{1,5,8},{3,7,4},{9,2,6})
print(unpack(t))  --> 9  7  8


--------------------------------
-- zipwithtup = function(func, (iter), ...)
----------------
-- Like zipwith, but packs the return value(s) of func into tuples.
-- Thus T[k] = {func(t1[k],...,tn[k])}.
t = zipwithtup(neg,nil,{1,1,1},{1,2,3},{10,10,10})
print(unpack(t[1]))  --> -1  -1  -10
print(unpack(t[2]))  --> -1  -2  -10
print(unpack(t[3]))  --> -1  -3  -10
t = zipwithtup(compose(max,table.pack),nil,{1,5,8},{3,7,4},{9,2,6})
print(unpack(t[1]))  --> 9  3     -- maximum first value is 9 from table 3
print(unpack(t[2]))  --> 7  2
print(unpack(t[3]))  --> 8  1



