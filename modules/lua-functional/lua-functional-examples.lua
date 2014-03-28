--[[-----------------------------------------------------------
lua-functional-examples.lua

A couple of examples for lua-functional.lua.
version 1.102
for Lua 5.2.0

Bo Waggoner
Modified: 2012-02-02

This software is free.
--]]-----------------------------------------------------------


-- initialize the library, save it as 'lfunc'
lfunc = dofile('lua-functional.lua')

-- add 17 to each number in the list {1, 5, 8}
print(unpack(lfunc.map(lfunc.apply(lfunc.add,17),{1,5,8})))

-- load functions into global namespace for less typing
lfunc.loadglobally(lfunc)



-- create a list of strings of a's of even length, with 'b' appended
local lengthtest = compose(apply(leq,10),curry(len,1)) -- check if 10 <= length
local adda = applyn(curry(concat,2),2,'a')             -- append an 'a'
local a_list = gen('a',adda,lengthtest)                -- a, aa, aaa, ...
local is_even = compose(apply(eq,0), applyn(mod,2,2), len)
local append = applyn(concat,2,'b')
print(unpack(listcomp(append,a_list,is_even)))





--------------------------------
-- Project Euler problem 1.
-- Find the sum of all multiples of 3 or 5 below 1000.
local ismult = function(a) return (a%3==0 or a%5==0) end
local multlist = filter(ismult,range(1,999))
print(foldl1(add,multlist))





--------------------------------
-- Project Euler problem 2.
-- By considering the terms in the Fibonacci sequence whose values
-- do not exceed four million, find the sum of the even-valued terms.
local fibs = gent({1,2},function(t,ind) return t[ind-1]+t[ind-2] end,
                        function(t,v) return v>4000000 end)
print(foldl1(add,filter(function(n) return n%2==0 end, fibs)))





--------------------------------
-- Quicksort.
-- Pick a pivot, sort all elements less than it, sort all elements greater
-- than it, and place them in order.
qsort = function(list)
    if #list <= 1 then return list end
    local pivot = list[#list-1]
    table.remove(list,#list-1)
    return flatten({qsort(filter(apply(geq,pivot),list)),
                    pivot,
                    qsort(filter(apply(lt,pivot),list))})
end

print(unpack(qsort({8,-5,3,17,19,-6,-1,3,6,4})))



--------------------------------
-- Levenshtein distance.
-- Given two arrays, find the minimu number of insertions, deletions,
-- or substitutions necessary to turn one into the other.
levenshtein_dist = function(arr1,arr2)
    -- d is a list of #arr1 empty lists
    local d = gen({}, function() return {} end,
                  function(a,ind) return ind>#arr1 end)
    
    f = casef(
      {function(i,j) return i==0 end,    function(i,j) return j end},
      {function(i,j) return j==0 end,    function(i,j) return i end},
      {function(i,j) return d[i][j] end, function(i,j) return d[i][j] end},
      {true, function(i,j)
                 d[i][j] = case({arr1[i]==arr2[j],f(i-1,j-1)},
                                {true, min({f(i-1,j)+1, f(i,j-1)+1,f(i-1,j-1)+1})})
                 return d[i][j]
              end})
    
    return f(#arr1,#arr2)
end

print(levenshtein_dist({1,2,3,4,7,8,9},{2,3,4,6,7,8,10}))



--------------------------------
-- Word count.
-- Count the number of occurrences of each word in the lua-functional
-- documents, and print the 20 most common ones.

-- split a string into words
split = function(str)
    local t = {}
    for s in string.gmatch(str,"%a+") do table.insert(t,s) end
    return t
end

-- read in and split a file
read_in = function(filename)
    f = io.open(filename,'r')
    if not f then return {} end
    return split(f:read("*all"))
end

-- from a word list, get a map of words to counts
get_counts = function(list)
    addto = function(t,word)
        t[word] = (t[word] or 0) + 1
        return t
    end
    return foldl(addto,{},list)
end

-- list the keys of a table
keys = function(t)
    local ans = {}
    for k,v in pairs(t) do table.insert(ans,k) end
    return ans
end

-- read in files, count each, combine them, and take top 20 results
local list = map(compose(get_counts,read_in),
                 {"lua-functional.lua","lua-functional-doc.lua",
                  "lua-functional-test.lua","lua-functional-examples.lua"})
local counts = zipwith(a,pairs,unpack(list))
local sorted = qsort(flatten(counts,pairs))
local cutoff = sorted[#sorted - 20] or 0
local topresults = filterp(apply(lt,cutoff),counts,pairs)
print(unpack(keys(topresults)))











