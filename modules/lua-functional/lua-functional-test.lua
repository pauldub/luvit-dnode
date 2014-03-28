--[[------------------------------------------------------------
lua-functional-test.lua

A test suite for lua-functional.lua.
version 1.102
for Lua 5.2.0

Bo Waggoner
Modified: 2012-02-02

This software is free.
--------------------------------

To run, just ensure it is in the same directory as the file
'lua-functional.lua', and execute this file.

The testing work is done by the function 'runtests'.

The test data is located at the bottom of the file.

Please feel free to try adding your own test data.

--]]------------------------------------------------------------


--==============================================
-- Administrative functions
-- String handling, etc
--==============================

-- myassert
-- ensure something is not false/nil; if it is, print the message and quit
myassert = function(val, msg)
    if not val then
        print(msg)
        os.exit(0)
    end
end

-- compare
-- compare two values for equality/inequality recursively
compare = function(v1, v2)
    local tracker = {}
    if type(v1) == 'table' and type(v2) == 'table' then
        for k,v in pairs(v1) do
            if not compare(v2[k],v) then return false end
            tracker[k] = true
        end
        for k,v in pairs(v2) do
            if not tracker[k] then
                if not compare(v1[k],v) then return false end
            end
        end
        return true
    else
        return (v1 == v2)
    end
end

-- iterator
reverseipairs = function(t)
    local ind = #t+1
    return function()
        ind = ind-1
        if ind<=0 then return nil  end
        return ind,t[ind]
    end
end

-- iterator
-- like pairs(), but in a more specific order
mypairs = function(t)
    local keys = {}
    keys[1] = {}
    keys[2] = {}
    keys[3] = {}
    for k,v in pairs(t) do
        if type(k) == 'number' then table.insert(keys[1],k)
        elseif type(k) == 'string' then table.insert(keys[2],k)
        else table.insert(keys[3],k) end
    end
    table.sort(keys[1])
    table.sort(keys[2])
    local kind = 1
    local i = 0
    return function()
        while true do
            i = i+1
            if keys[kind][i] == nil then
                i = 0
                kind = kind+1
                if kind>3 then return nil end
            else
                return keys[kind][i],t[keys[kind][i]]
            end
        end
    end
end

-- makearray
-- convert a value to a string and put it into the array
-- this is a helper function for asstring
-- for a table: print out array values first, then
-- print out all others with their keys
-- for a table, separate key/value pairs with 'sep'
makearray = function(tab,val,sep)
    sep = sep or ','
    if type(val) == 'table' then
        table.insert(tab,'{')
        
        local firsttime=true
        local ind = 0
        for k,v in mypairs(val) do
            if firsttime then
                firsttime = false
            else
                table.insert(tab,sep)
            end
            if type(k)=='number' and k==ind+1 then
                ind = ind+1
            else
                table.insert(tab,tostring(k))
                table.insert(tab,'=')
            end
            makearray(tab,v,sep)
        end
        
        table.insert(tab,'}')
    else
        if type(val) == 'string' then
            table.insert(tab,"'")
        end
        table.insert(tab,tostring(val))
        if type(val) == 'string' then
            table.insert(tab,"'")
        end
    end
end

-- asstring
-- convert a value to a string
-- sep is a separator between (key,value)s printed
-- sep defaults to ','
asstring = function(val,sep)
    sep = sep or ','
    local t = {}
    makearray(t,val,sep)
    return table.concat(t)
end


--==============================================
-- Helper functions
-- Used in the various tests
--==============================

-- helper functions
add2 = function(a)
    return (a + 2)
end

square = function(a)
    return a*a
end

add = function(a,b)
    return a+b
end

add3 = function(a,b,c)
    return a + b + c
end

div = function(a,b)
    return a/b
end

addor0 = function(a,b)
    if b==0 then return 0 end
    return a+b
end

addora0 = function(a,b)
    if a==0 then return 0 end
    return a+b
end

concat = function(a,b)
    return a..b
end

identity = function(...)
    return ...
end

even = function(a)
    return (a%2 == 0)
end

green = function(b)
    return string.find(b,'green')
end

gt2 = function(a)
    return (a>2)
end

firstgreen = function(a,b)
    local ga = string.find(a,'green')
    local gb = string.find(b,'green')
    if ga==gb then return false end
    if gb and not ga then return false end
    if ga and not gb then return true end
    return (ga < gb)
end

twocol = function(a,b)
    return ((string.find(a,'green') or string.find(a,'blue') or string.find(a,'red'))
        and (string.find(b,'green') or string.find(b,'blue') or string.find(b,'red')))
end

alphmatch = function(a,num)
    return a == tostring(num)
end

rep3 = function(...)
    local arg = table.pack(...)
    local t = {}
    local ind = 1
    for i,v in ipairs(arg) do
        t[ind] = v
        t[ind+1] = v
        t[ind+2] = v
        ind = ind+2
    end
    return unpack(t)
end


--==============================================
-- runtests
-- the tester function
--==============================


-- runtests
-- runs all the tests of each function
-- if dopack, pack output into a table
-- if dofunc, call the special test function
runtests = function(funcdata)
    
    local numtests = 0
    local numfuncs = 0
    local testspassed = 0
    
    for i,tests in pairs(funcdata) do
        
        local mypack = tests.dopack and function(...) a = table.pack(...) a.n = nil return a end or function(a) return a end
        local dofunc = tests.dofunc
        
        local numpassed,total = 0,0
    
        print('Testing '..tostring(tests.name))
        io.flush()
       
        for _,test in ipairs(tests) do
            local out
            local inputstr = asstring(test.input)
            if dofunc then
                out = mypack(test.run(unpack(test.input)))
            else
                out = mypack(tests.func(unpack(test.input)))
            end
            total = total + 1
            if compare(test.output,out) then
                numpassed = numpassed + 1
            else
                print('Failed test '..tostring(total))
                print('--> Input:    '..inputstr)
                print('--> Expected: '..asstring(test.output))
                print('--> Got:      '..asstring(out))
            end
        end
        print('Passed '..tostring(numpassed)..'/'..tostring(total)..' tests.\n')
        numfuncs = numfuncs + 1
        numtests = numtests + total
        testspassed = testspassed + numpassed
    end
    
    local numposs = lfunc.len(lfunc.flatten(lfunc,mypairs))
    print('\n----------------')
    print('Tested '..tostring(numfuncs)..'/'..tostring(numposs)..' functions.')
    print('Passed '..tostring(testspassed)..'/'..tostring(numtests)..' tests.')
    print('----------------\n')
end


--==============================================
-- Loading of library
-- and test data!
--==============================

-- load the library but don't execute it (create it) yet
libfunc,errmsg = loadfile('lua-functional.lua')
myassert(libfunc,'ERROR: Could not load library! Received following message:\n'..tostring(errmsg))

-- run the library code (create the functions)
print('Loading library...')
lfunc = libfunc()
print('Loading successful.\nRunning tests...\n')

-- run the tests
runtests({
    
    -- lfunc.len = function(...)
    {
      name = 'len',
      func = lfunc.len,
      dopack = true,
      
      [1] = {   input = {},
                output = {nil}
            },
      [2] = {   input = {{1}},
                output = {1}
            },
      [3] = {   input = {{5,7,10,16}},
                output = {4}
            },
      [4] = {   input = {'green'},
                output = {5}
            },
      [5] = {   input = {{5,7,10,16,[100]=2},'greengreen'},
                output = {4,10}
            },
      [6] = {   input = {{},'',{[10000]=false},'felizcumpleanos'},
                output = {0,0,0,15}
            },
    },
    
    --lfunc._not = function(...)
    {
      name = '_not',
      func = lfunc._not,
      dopack = true,
      
      [1] = {   input = {},
                output = {nil}
            },
      [2] = {   input = {true},
                output = {false},
            },
      [3] = {   input = {true, false, false, 7, 0},
                output = {false, true, true, false, false},
            },
      [4] = {   input = {false, 'green', 8, true},
                output = {true, false, false, false},
            },
      [5] = {   input = {'a', 5, false, nil, true},
                output = {false, false, true, true, false}
            },
    },
    
    --lfunc.neg = function(...)
    {
      name = 'neg',
      func = lfunc.neg,
      dopack = true,
      
      [1] = {   input = {},
                output = {nil}
            },
      [2] = {   input = {5},
                output = {-5},
            },
      [3] = {   input = {.3,-5,0,100},
                output = {-.3,5,0,-100},
            },
    },
    
    --lfunc.id = function(...)
    {
      name = 'id',
      func = lfunc.id,
      dopack = true,
      
      [1] = {   input = {2,3,{6,red='happy'},{green=9}},
                output = {2,3,{6,red='happy'},{green=9}}
            },
      [2] = {   input = {'stringss'},
                output = {'stringss'}
            },
      [3] = {   input = {},
                output = {nil}
            },
      [4] = {   input = {false},
                output = {false}
            },
    },
    
    --lfunc.map = function(func, t, iter)
    {
      name = 'map',
      func = lfunc.map,
        
      [1] = {   input = {add2, {1,3,5,7}},
                output = {3,5,7,9}
            },
      [2] = {   input = {add2, {1,3,5,7}, ipairs},
                output = {3,5,7,9}
            },
      [3] = {   input = {add2, {1,3,5,7}, reverseipairs},
                output = {3,5,7,9}
            },
      [4] = {   input = {add2, {}},
                output = {}
            },
      [5] = {   input = {add2, {}, reverseipairs},
                output = {}
            },
      [6] = {   input = {square, {17}},
                output = {289}
            },
      [7] = {   input = {square, {17}, mypairs},
                output = {289}
            },
      [8] = {   input = {square, {a=1,b=2,c=3,d=4}},
                output = {a=1,b=4,c=9,d=16}
            },
      [9] = {   input = {square, {1,2,3,4,a=10,b=9,c=8,d=7}, ipairs},
                output = {1,4,9,16}
            },
      [10]= {   input = {square, {1,2,3,4,a=10,b=9,c=8,d=7}, mypairs},
                output = {1,4,9,16,a=100,b=81,c=64,d=49}
            },
      [11]= {   input = {add2, {1,3,nil,7}},
                output = {3,5,nil,9}
            },
      [12]= {   input = {add2, {1,3,nil,7}, ipairs},
                output = {3,5}
            },
      [13]= {   input = {tostring, {1,3,false,7,a='blue',b='red'}, ipairs},
                output = {'1','3','false','7'}
            },
      [14]= {   input = {tostring, {1,3,false,7,a='blue',b=137}},
                output = {'1','3','false','7',a='blue',b='137'}
            },
    },
    
    --lfunc.maptup = function(func, t, iter)
    {
      name = 'maptup',
      func = lfunc.maptup,
      
      [1] = {   input = {identity, {1,2,'green',false}},
                output = {{1},{2},{'green'},{false}}
            },
      [2] = {   input = {identity, {1,2,'green',false,[true] = 'red'}, ipairs},
                output = {{1},{2},{'green'},{false}}
            },
      [3] = {   input = {identity, {1,2,'green',false,[true] = 'red'}, mypairs},
                output = {{1},{2},{'green'},{false},[true] = {'red'}}
            },
      [4] = {   input = {rep3, {1,'green',yes='no'}, ipairs},
                output = {{1,1,1},{'green','green','green'}}
            },
      [5] = {   input = {rep3, {1,'green',yes='no'}, mypairs},
                output = {{1,1,1},{'green','green','green'},yes = {'no','no','no'}}
            },
      [6] = {   input = {add2, {}},
                output = {}
            },
      [7] = {   input = {add2, {}, reverseipairs},
                output = {}
            },
      [8] = {   input = {square, {17}},
                output = {{289}}
            },
      [9] = {   input = {identity, {17}, mypairs},
                output = {{17}}
            },
      [10] = {   input = {add2, {1,3,nil,7}, mypairs},
                output = {{3},{5},nil,{9}}
            },
      [11]= {   input = {rep3, {3,5,nil,7}, ipairs},
                output = {{3,3,3},{5,5,5}}
            },
            
    },
    
    --lfunc.foldr = function(func, val, t, iter)
    {
      name = 'foldr',
      func = lfunc.foldr,
      
      [1] = {   input = {add, 0, {1,2,3,4}},
                output = 10
            },
      [2] = {   input = {add, 0, {1,2,3,4}, reverseipairs},
                output = 10
            },
      [3] = {   input = {add, 8, {1,2,3,4}},
                output = 18
            },
      [4] = {   input = {add, 8, {1,2,3,4}, mypairs},
                output = 18
            },
      [5] = {   input = {add, 3, {}},
                output = 3
            },
      [6] = {   input = {add, 11, {}, mypairs},
                output = 11
            },
      [7] = {   input = {add, nil, {}},
                output = nil
            },
      [8] = {   input = {add, nil, {}, mypairs},
                output = nil
            },
      [9] = {   input = {div, 1, {3,6,8,48,a=2}, reverseipairs},
                output = 12
            },
      [10]= {   input = {div, 1, {48,9,6,4,a=2}, mypairs},
                output = 16
            },
      [11]= {   input = {addora0, 1, {2,3,4,0,6}},
                output = 9
            },
      [12]= {   input = {addora0, 1, {2,3,4,0,6}, reverseipairs},
                output = 6
            },
      [13]= {   input = {concat, 'begin ', {'continue',' till ','end!'}},
                output = 'continue till end!begin '
            },
    },
    
    --lfunc.foldl = function(func, val, t, iter)
    {
      name = 'foldl',
      func = lfunc.foldl,
      
      [1] = {   input = {add, 0, {1,2,3,4}},
                output = 10
            },
      [2] = {   input = {add, 0, {1,2,3,4}, reverseipairs},
                output = 10
            },
      [3] = {   input = {add, 8, {1,2,3,4}},
                output = 18
            },
      [4] = {   input = {add, 8, {1,2,3,4}, mypairs},
                output = 18
            },
      [5] = {   input = {add, 3, {}},
                output = 3
            },
      [6] = {   input = {add, 11, {}, mypairs},
                output = 11
            },
      [7] = {   input = {add, nil, {}},
                output = nil
            },
      [8] = {   input = {add, nil, {}, mypairs},
                output = nil
            },
      [9] = {   input = {div, 48, {1,2,3,4,a=2}, reverseipairs},
                output = 2
            },
      [10]= {   input = {div, 48, {1,2,3,4,a=2}, mypairs},
                output = 1
            },
      [11]= {   input = {addor0, 1, {2,3,4,0,6}},
                output = 6
            },
      [12]= {   input = {addor0, 1, {2,3,4,0,6}, reverseipairs},
                output = 9
            },
      [13]= {   input = {concat, 'begin ', {'continue',' till ','end!'}},
                output = 'begin continue till end!'
            },
    },
    
    --lfunc.scanr = function(func, val, t, iter, ind)
    {
      name = 'scanr',
      func = lfunc.scanr,
      
      [1] = {   input = {add, 0, {1,2,3,4}},
                output = {10,9,7,4,0}
            },
      [2] = {   input = {add, 0, {1,2,3,4}, reverseipairs},
                output = {10,6,3,1,0}
            },
      [3] = {   input = {add, 8, {1,2,3,4}},
                output = {18,17,15,12,8}
            },
      [4] = {   input = {add, 8, {1,2,3,4}, mypairs},
                output = {18,17,15,12,8}
            },
      [5] = {   input = {add, 3, {}},
                output = {3}
            },
      [6] = {   input = {add, 11, {}, mypairs},
                output = {11}
            },
      [7] = {   input = {add, nil, {}},
                output = {}
            },
      [8] = {   input = {add, nil, {}, mypairs},
                output = {}
            },
      [9] = {   input = {div, 1, {3,6,8,48,a=2}, reverseipairs},
                output = {12,4,2,3,1}
            },
      [10]= {   input = {div, 1, {48,9,6,4,a=2}, mypairs},
                output = {16,3,3,2,2,1}
            },
      [11]= {   input = {addora0, 1, {2,3,4,0,6}},
                output = {9,7,4,0,7,1}
            },
      [12]= {   input = {addora0, 1, {2,3,4,0,6}, reverseipairs},
                output = {6,0,10,6,3,1}
            },
      [13]= {   input = {concat, 'begin ', {'continue',' till ','end!'}},
                output = {'continue till end!begin ',' till end!begin ','end!begin ','begin '}
            },
      [14]= {   input = {add, 0, {3,4}, nil},
                output = {7,4,0}
            },
      [15]= {   input = {add, 0, {1,2}, reverseipairs},
                output = {3,1,0}
            },
      [16]= {   input = {concat, 'my ', {'heart',' is ','glass?'}, nil},
                output = {'heart is glass?my ',' is glass?my ','glass?my ','my '}
            },
    },
    
    --lfunc.scanl = function(func, val, t, iter, ind)
    {
      name = 'scanl',
      func = lfunc.scanl,
      
      [1] = {   input = {add, 0, {1,2,3,4}},
                output = {0,1,3,6,10}
            },
      [2] = {   input = {add, 0, {1,2,3,4}, reverseipairs},
                output = {0,4,7,9,10}
            },
      [3] = {   input = {add, 8, {1,2,3,4}},
                output = {8,9,11,14,18}
            },
      [4] = {   input = {add, 8, {1,2,3,4}, mypairs},
                output = {8,9,11,14,18}
            },
      [5] = {   input = {add, 3, {}},
                output = {3}
            },
      [6] = {   input = {add, 11, {}, mypairs},
                output = {11}
            },
      [7] = {   input = {add, nil, {}},
                output = {}
            },
      [8] = {   input = {add, nil, {}, mypairs},
                output = {}
            },
      [9] = {   input = {div, 48, {1,2,3,4,a=2}, reverseipairs},
                output = {48,12,4,2,2}
            },
      [10]= {   input = {div, 48, {1,2,3,4,a=2}, mypairs},
                output = {48,48,24,8,2,1}
            },
      [11]= {   input = {addor0, 1, {2,3,4,0,6}},
                output = {1,3,6,10,0,6}
            },
      [12]= {   input = {addor0, 1, {2,3,4,0,6}, reverseipairs},
                output = {1,7,0,4,7,9}
            },
      [13]= {   input = {concat, 'begin ', {'continue',' till ','end!'}},
                output = {'begin ','begin continue','begin continue till ','begin continue till end!'}
            },
      [14]= {   input = {add, 0, {3,4}, nil},
                output = {0,3,7}
            },
      [15]= {   input = {add, 0, {1,2}, reverseipairs},
                output = {0,2,3}
            },
      [16]= {   input = {concat, 'my ', {'heart',' is ','glass?'}, nil},
                output = {'my ','my heart','my heart is ','my heart is glass?'}
            },
    },
    
    --lfunc.foldr1 = function(func, t, iter)
    {
      name = 'foldr1',
      func = lfunc.foldr1,
      
      [1] = {   input = {add, {1,2,3,4,0}},
                output = 10
            },
      [2] = {   input = {add, {1,2,3,4,0}, reverseipairs},
                output = 10
            },
      [3] = {   input = {add, {1,2,3,4,8}},
                output = 18
            },
      [4] = {   input = {add, {1,2,3,4,8}, mypairs},
                output = 18
            },
      [5] = {   input = {add, {3}},
                output = 3
            },
      [6] = {   input = {add, {11}, mypairs},
                output = 11
            },
      [7] = {   input = {add, {}},
                output = nil
            },
      [8] = {   input = {add, {}, mypairs},
                output = nil
            },
      [9] = {   input = {div, {1,3,6,8,48,a=2}, reverseipairs},
                output = 12
            },
      [10]= {   input = {div, {48,9,6,4,a=2,b=1}, mypairs},
                output = 16
            },
      [11]= {   input = {addora0, {2,3,4,0,6,1}},
                output = 9
            },
      [12]= {   input = {addora0, {1,2,3,4,0,6}, reverseipairs},
                output = 6
            },
      [13]= {   input = {concat, {'continue',' till ','end!','begin '}},
                output = 'continue till end!begin '
            },
    },
    
    --lfunc.foldl1 = function(func, t, iter)
    {
      name = 'foldl1',
      func = lfunc.foldl1,
      
      [1] = {   input = {add, {0,1,2,3,4}},
                output = 10
            },
      [2] = {   input = {add, {0,1,2,3,4}, reverseipairs},
                output = 10
            },
      [3] = {   input = {add, {8,1,2,3,4}},
                output = 18
            },
      [4] = {   input = {add, {8,1,2,3,4}, mypairs},
                output = 18
            },
      [5] = {   input = {add, {3}},
                output = 3
            },
      [6] = {   input = {add, {11}, mypairs},
                output = 11
            },
      [7] = {   input = {add, {}},
                output = nil
            },
      [8] = {   input = {add, {}, mypairs},
                output = nil
            },
      [9] = {   input = {div, {1,2,3,4,48,a=2}, reverseipairs},
                output = 2
            },
      [10]= {   input = {div, {48,1,2,3,4,a=2}, mypairs},
                output = 1
            },
      [11]= {   input = {addor0, {1,2,3,4,0,6}},
                output = 6
            },
      [12]= {   input = {addor0, {2,3,4,0,6,1}, reverseipairs},
                output = 9
            },
      [13]= {   input = {concat, {'begin ', 'continue',' till ','end!'}},
                output = 'begin continue till end!'
            },
    },
    
    --lfunc.scanr1 = function(func, t, iter)
    {
      name = 'scanr1',
      func = lfunc.scanr1,
      
      [1] = {   input = {add, {1,2,3,4,0}},
                output = {10,9,7,4,0}
            },
      [2] = {   input = {add, {0,1,2,3,4}, reverseipairs},
                output = {10,6,3,1,0}
            },
      [3] = {   input = {add, {1,2,3,4,8}},
                output = {18,17,15,12,8}
            },
      [4] = {   input = {add, {1,2,3,4,8}, mypairs},
                output = {18,17,15,12,8}
            },
      [5] = {   input = {add, {3}},
                output = {3}
            },
      [6] = {   input = {add, {11}, mypairs},
                output = {11}
            },
      [7] = {   input = {add, {}},
                output = {}
            },
      [8] = {   input = {add, {}, mypairs},
                output = {}
            },
      [9] = {   input = {div, {1,3,6,8,48,a=2}, reverseipairs},
                output = {12,4,2,3,1}
            },
      [10]= {   input = {div, {48,9,6,4,a=2,b=1}, mypairs},
                output = {16,3,3,2,2,1}
            },
      [11]= {   input = {addora0, {2,3,4,0,6,1}},
                output = {9,7,4,0,7,1}
            },
      [12]= {   input = {addora0, {1,2,3,4,0,6}, reverseipairs},
                output = {6,0,10,6,3,1}
            },
      [13]= {   input = {concat, {'continue',' till ','end!','begin '}},
                output = {'continue till end!begin ',' till end!begin ','end!begin ','begin '}
            },
      [14]= {   input = {add, {3,4,0}, nil},
                output = {7,4,0}
            },
      [15]= {   input = {add, {0,1,2}, reverseipairs},
                output = {3,1,0}
            },
      [16]= {   input = {concat, {'heart',' is ','glass?','my '}, nil},
                output = {'heart is glass?my ',' is glass?my ','glass?my ','my '}
            },
    },
    
    --lfunc.scanl1 = function(func, t, iter)
    {
      name = 'scanl1',
      func = lfunc.scanl1,
      
      [1] = {   input = {add, {0,1,2,3,4}},
                output = {0,1,3,6,10}
            },
      [2] = {   input = {add, {1,2,3,4,0}, reverseipairs},
                output = {0,4,7,9,10}
            },
      [3] = {   input = {add, {8,1,2,3,4}},
                output = {8,9,11,14,18}
            },
      [4] = {   input = {add, {8,1,2,3,4}, mypairs},
                output = {8,9,11,14,18}
            },
      [5] = {   input = {add, {3}},
                output = {3}
            },
      [6] = {   input = {add, {11}, mypairs},
                output = {11}
            },
      [7] = {   input = {add, {}},
                output = {}
            },
      [8] = {   input = {add, {}, mypairs},
                output = {}
            },
      [9] = {   input = {div, {1,2,3,4,48,a=2}, reverseipairs},
                output = {48,12,4,2,2}
            },
      [10]= {   input = {div, {48,1,2,3,4,a=2}, mypairs},
                output = {48,48,24,8,2,1}
            },
      [11]= {   input = {addor0, {1,2,3,4,0,6}},
                output = {1,3,6,10,0,6}
            },
      [12]= {   input = {addor0, {2,3,4,0,6,1}, reverseipairs},
                output = {1,7,0,4,7,9}
            },
      [13]= {   input = {concat, {'begin ','continue',' till ','end!'}},
                output = {'begin ','begin continue','begin continue till ','begin continue till end!'}
            },
      [14]= {   input = {add, {0,3,4}, nil},
                output = {0,3,7}
            },
      [15]= {   input = {add, {0,1,2}, reverseipairs},
                output = {2,3,3}
            },
      [16]= {   input = {concat, {'my ', 'heart',' is ','glass?'}, nil},
                output = {'my ','my heart','my heart is ','my heart is glass?'}
            },
    },
    
    --lfunc.filter = function(func, t, iter)
    {
      name = 'filter',
      func = lfunc.filter,
      
      [1] = {   input = {identity, {1,2,3,4,false,6,7}},
                output = {1,2,3,4,6,7}
            },
      [2] = {   input = {identity, {1,2,3,4,false,6,7}, reverseipairs},
                output = {7,6,4,3,2,1}
            },
      [3] = {   input = {identity, {1,2,3,4,blue=false,red=7,green=6}},
                output = {1,2,3,4}
            },
      [4] = {   input = {identity, {1,2,3,4,blue=false,red=7,green=6}, mypairs},
                output = {1,2,3,4,6,7}
            },
      [5] = {   input = {even, {1,2,3,4,5,6,7}},
                output = {2,4,6}
            },
      [6] = {   input = {even, {a=1,b=2,c=3,d=4,e=5,f=6,g=7}},
                output = {}
            },
      [7] = {   input = {even, {a=1,b=2,c=3,d=4,e=5,f=6,g=7}, mypairs},
                output = {2,4,6}
            },
      [8] = {   input = {even, {}, mypairs},
                output = {}
            },
      [9] = {   input = {green, {'blue',happy='green'}},
                output = {}
            },
      [10]= {   input = {green, {'blue','greenhouse','reddoor','facegreen',happy='green'}},
                output = {'greenhouse','facegreen'}
            },
      [11]= {   input = {green, {'blue','greenhouse','reddoor','facegreen',happy='green'}, mypairs},
                output = {'greenhouse','facegreen','green'}
            },
    },
    
    --lfunc.filterp = function(func, t, iter)
    {
      name = 'filterp',
      func = lfunc.filterp,
      
      [1] = {   input = {identity, {1,2,3,4,false,6,7}},
                output = {1,2,3,4,nil,6,7}
            },
      [2] = {   input = {identity, {1,2,3,4,false,6,7}, reverseipairs},
                output = {1,2,3,4,nil,6,7}
            },
      [3] = {   input = {identity, {1,2,3,4,blue=false,red=7,green=6}},
                output = {1,2,3,4,red=7,green=6}
            },
      [4] = {   input = {identity, {1,2,3,4,blue=false,red=7,green=6}, mypairs},
                output = {1,2,3,4,red=7,green=6}
            },
      [5] = {   input = {even, {1,2,3,4,5,6,7}},
                output = {nil,2,nil,4,nil,6}
            },
      [6] = {   input = {even, {a=1,b=2,c=3,d=4,e=5,f=6,g=7}},
                output = {b=2,d=4,f=6}
            },
      [7] = {   input = {even, {a=1,b=2,c=3,d=4,e=5,f=6,g=7}, mypairs},
                output = {b=2,d=4,f=6}
            },
      [8] = {   input = {even, {}, mypairs},
                output = {}
            },
      [9] = {   input = {green, {'blue',happy='green'}},
                output = {happy='green'}
            },
      [10]= {   input = {green, {'blue','greenhouse','reddoor','facegreen',happy='green'}},
                output = {nil,'greenhouse',nil,'facegreen',happy='green'}
            },
      [11]= {   input = {green, {'blue','greenhouse','reddoor','facegreen',happy='green'}, mypairs},
                output = {nil,'greenhouse',nil,'facegreen',happy='green'}
            },
    },
    
    --lfunc.filterkey = function(func, t, iter)
    {
      name = 'filterkey',
      func = lfunc.filterkey,
      
      [1] = {   input = {identity, {1,2,3,4,false,6,7}},
                output = {1,2,3,4,false,6,7}
            },
      [2] = {   input = {identity, {1,2,3,4,false,6,7}, reverseipairs},
                output = {7,6,false,4,3,2,1}
            },
      [3] = {   input = {identity, {1,2,3,4,[false]=5,red=7,green=6}},
                output = {1,2,3,4}
            },
      [4] = {   input = {identity, {1,2,3,4,[false]=5,red=7,green=6}, mypairs},
                output = {1,2,3,4,6,7}
            },
      [5] = {   input = {even, {2,3,4,5,6,7,8}},
                output = {3,5,7}
            },
      [6] = {   input = {green, {a=1,b=2,c=3,d=4,e=5,f=6,g=7}},
                output = {}
            },
      [7] = {   input = {alphmatch, {['1']=1,['2']=2,['c']=3,['d']=4,['5']=5,['9']=6,['7']=7}},
                output = {}
            },
      [8] = {   input = {alphmatch, {['1']=1,['2']=2,['c']=3,['d']=4,['5']=5,['9']=6,['7']=7}, mypairs},
                output = {1,2,5,7}
            },
      [9] = {   input = {even, {}, mypairs},
                output = {}
            },
      [11]= {   input = {green, {green='blue',happy='green'}},
                output = {}
            },
      [12]= {   input = {green, {green='blue',happy='green'}, mypairs},
                output = {'blue'}
            },
      [13]= {   input = {twocol, {red='blue',greenhouse='redbrick','reddoor',bluewall='facegreen',happy='green'}},
                output = {}
            },
      [14]= {   input = {twocol, {red='blue',greenhouse='redbrick','reddoor',bluewall='facegreen',happy='green'}, mypairs},
                output = {'facegreen','redbrick','blue'}
            },
    },
    
    --lfunc.filterkeyp = function(func, t, iter)
    {
      name = 'filterkeyp',
      func = lfunc.filterkeyp,
      
      [1] = {   input = {identity, {1,2,3,4,false,6,7}},
                output = {1,2,3,4,false,6,7}
            },
      [2] = {   input = {identity, {1,2,3,4,false,6,7}, reverseipairs},
                output = {1,2,3,4,false,6,7}
            },
      [3] = {   input = {identity, {1,2,3,4,[false]=5,red=7,green=6}, mypairs},
                output = {1,2,3,4,green=6,red=7}
            },
      [4] = {   input = {identity, {1,2,3,4,[false]=5,red=7,green=6}, ipairs},
                output = {1,2,3,4}
            },
      [5] = {   input = {even, {2,3,4,5,6,7,8}},
                output = {nil,3,nil,5,nil,7}
            },
      [6] = {   input = {green, {a=1,b=2,c=3,d=4,e=5,f=6,g=7}},
                output = {}
            },
      [7] = {   input = {alphmatch, {['1']=1,['2']=2,['c']=3,['d']=4,['5']=5,['9']=6,['7']=7}},
                output = {['1']=1,['2']=2,['5']=5,['7']=7}
            },
      [8] = {   input = {identity, {'a','b','c',[false]='good',[true]='bad'}},
                output = {'a','b','c',[true]='bad'}
            },
      [9] = {   input = {even, {}, mypairs},
                output = {}
            },
      [10]= {   input = {green, {green='blue',happy='green'}},
                output = {green='blue'}
            },
      [11]= {   input = {green, {green='blue',happy='green'}, mypairs},
                output = {green='blue'}
            },
      [12]= {   input = {twocol, {red='blue',greenhouse='redbrick','reddoor',bluewall='facegreen',happy='green'}, mypairs},
                output = {red='blue',greenhouse='redbrick',bluewall='facegreen'}
            },
    },
    
    --lfunc.zip = function(iter, t1, ...)
    {
      name = 'zip',
      func = lfunc.zip,
      
      [1] = {  input = {nil,{}},
               output = {}
            },
      [2] = {  input = {nil,{},{}},
               output = {}
            },
      [3] = {  input = {nil,{1},{2}},
               output = {{1,2}}
            },
      [4] = {  input = {nil,{1,2,3},{'a','b','c'}},
               output = {{1,'a'},{2,'b'},{3,'c'}}
            },
      [5] = {  input = {nil,{1,2,3},{'a','b','c'},{4,5,6},{'d','e','f'}},
               output = {{1,'a',4,'d'},{2,'b',5,'e'},{3,'c',6,'f'}}
            },
      [6] = {  input = {nil,{'a','b',a=1,b=2},{'c','d',c=1,d=2},{'e','f',e=1,f=2}},
               output = {{'a','c','e'},{'b','d','f'}}
            },
      [7] = {  input = {ipairs,{'a','b',a=1,b=2},{'c','d',c=1,d=2},{'e','f',e=1,f=2}},
               output = {{'a','c','e'},{'b','d','f'}}
            },
      [8] = {  input = {nil,{'a','b',a=1,b=2},{'c','d',a=3,b=4},{'e','f',a=5,b=6}},
               output = {{'a','c','e'},{'b','d','f'},a={1,3,5},b={2,4,6}}
            },
      [9] = {  input = {reverseipairs,{'a','b',a=1,b=2},{'c','d',a=3,b=4},{'e','f',a=5,b=6}},
               output = {{'a','c','e'},{'b','d','f'}}
            },
      [10]= {  input = {mypairs,{'a','b',a=1,b=2},{'c','d',a=3,b=4},{'e','f',c=5,b=6}},
               output = {{'a','c','e'},{'b','d','f'},b={2,4,6}}
            },
      [11]= {  input = {nil,{5}},
               output = {{5}}
            },
    },
    
    --lfunc.zipor = function(iter, ...)
    {
      name = 'zipor',
      func = lfunc.zipor,
      
      [1] = {  input = {nil,{}},
               output = {}
            },
      [2] = {  input = {nil,{},{}},
               output = {}
            },
      [3] = {  input = {nil,{1},{2}},
               output = {{1,2}}
            },
      [4] = {  input = {nil,{1,2,3},{'a','b','c'}},
               output = {{1,'a'},{2,'b'},{3,'c'}}
            },
      [5] = {  input = {nil,{1,2,3},{'a','b','c'},{4,5,6},{'d','e','f'}},
               output = {{1,'a',4,'d'},{2,'b',5,'e'},{3,'c',6,'f'}}
            },
      [6] = {  input = {nil,{'a','b',a=1,b=2},{'c','d',c=1,d=2},{'e','f',e=1,f=2}},
               output = {{'a','c','e'},{'b','d','f'},a={1},b={2},c={1},d={2},e={1},f={2}}
            },
      [7] = {  input = {ipairs,{'a','b',a=1,b=2},{'c','d',c=1,d=2},{'e','f',e=1,f=2}},
               output = {{'a','c','e'},{'b','d','f'}}
            },
      [8] = {  input = {nil,{'a','b',a=1,b=2},{'c','d',a=3,b=4},{'e','f',a=5,b=6}},
               output = {{'a','c','e'},{'b','d','f'},a={1,3,5},b={2,4,6}}
            },
      [9] = {  input = {reverseipairs,{'a','b',a=1,b=2},{'c','d',a=3,b=4},{'e','f',a=5,b=6}},
               output = {{'a','c','e'},{'b','d','f'}}
            },
      [10]= {  input = {mypairs,{'a','b',a=1,b=2},{'c','d',a=3,b=4},{'e','f',c=5,b=6}},
               output = {{'a','c','e'},{'b','d','f'},a={1,3},b={2,4,6},c={5}}
            },
    },
    
    --lfunc.zipwith = function(func, iter, ...)
    {
      name = 'zipwith',
      func = lfunc.zipwith,
      
      [1] = {   input = {add2, nil, {5}},
                output = {7}
            },
      [2] = {   input = {add2, ipairs, {5,8,10}},
                output = {7,10,12}
            },
      [3] = {   input = {add, nil, {5,8,10},{1,2,3}},
                output = {6,10,13}
            },
      [4] = {   input = {add, ipairs, {5,red=3},{1,red=4}},
                output = {6}
            },
      [5] = {   input = {add, mypairs, {5,red=3},{1,red=4}},
                output = {6,red=7}
            },
      [6] = {   input = {identity, ipairs, {5,8,red=3,blue=2},{1,9,red=4,blue=0}},
                output = {5,8}
            },
      [7] = {   input = {add3, nil, {5,8,red=3,blue=2},{1,9,red=4,blue=0},{1,1,red=1,blue=1}},
                output = {7,18,red=8,blue=3}
            },
    },
    
    --lfunc.zipwithtup = function(func, iter, ...)
    {
      name = 'zipwithtup',
      func = lfunc.zipwithtup,
      
      [1] = {   input = {add2, nil, {5}},
                output = {{7}}
            },
      [2] = {   input = {add2, ipairs, {5,8,10}},
                output = {{7},{10},{12}}
            },
      [3] = {   input = {add, nil, {5,8,10},{1,2,3}},
                output = {{6},{10},{13}}
            },
      [4] = {   input = {add, ipairs, {5,red=3},{1,red=4}},
                output = {{6}}
            },
      [5] = {   input = {add, mypairs, {5,red=3},{1,red=4}},
                output = {{6},red={7}}
            },
      [6] = {   input = {identity, ipairs, {5,8,red=3,blue=2},{1,9,red=4,blue=0}},
                output = {{5,1},{8,9}}
            },
      [7] = {   input = {identity, nil, {5,8,red=3,blue=2},{1,9,red=4,blue=0}},
                output = {{5,1},{8,9},red={3,4},blue={2,0}}
            },
      [7] = {   input = {add3, mypairs, {5,8,red=3,blue=2},{1,9,red=4,blue=0},{1,1,red=1,blue=1}},
                output = {{7},{18},red={8},blue={3}}
            },
    },
    
    --lfunc.max = function(t, compare, iter)
    {
      name = 'max',
      func = lfunc.max,
      
      [1] = {   input = {{}},
                output = nil
            },
      [2] = {   input = {{0}},
                output = 0
            },
      [3] = {   input = {{-100,100,-50,23,.000004324}},
                output = 100
            },
      [4] = {   input = {{'green','red','blue','yellow','orange'}},
                output = 'yellow'
            },
      [5] = {   input = {{'blue-green','facegreen','wallgreen','mygreenhouse'}},
                output = 'wallgreen'
            },
      [6] = {   input = {{'blue-green','facegreen','wallgreen','mygreenhouse'}, firstgreen},
                output = 'mygreenhouse'
            },
    },
    
    --lfunc.min = function(t, compare, iter)
    {
      name = 'min',
      func = lfunc.min,
      
      [1] = {   input = {{}},
                output = nil
            },
      [2] = {   input = {{0}},
                output = 0
            },
      [3] = {   input = {{-100,100,-50,23,.000004324}},
                output = -100
            },
      [4] = {   input = {{'green','red','blue','yellow','orange'}},
                output = 'blue'
            },
      [5] = {   input = {{'blue-green','facegreen','wallgreen','mygreenhouse'}},
                output = 'blue-green'
            },
      [6] = {   input = {{'blue-green','facegreen','wallgreen','mygreenhouse'}, firstgreen},
                output = 'mygreenhouse'
            },
    },
    
    --lfunc.takewhile = function(func, t, iter)
    {
      name = 'takewhile',
      func = lfunc.takewhile,
      
      [1] = {   input = {gt2, {6,5,4,3,2,1}},
                output = {6,5,4,3}
            },
      [2] = {   input = {gt2, {}},
                output = {}
            },
      [3] = {   input = {gt2, {2}},
                output = {}
            },
      [4] = {   input = {gt2, {4,5,6,7,8,9}},
                output = {4,5,6,7,8,9}
            },
      [5] = {   input = {gt2, {4,5,6,1,8,9}, reverseipairs},
                output = {9,8}
            },
      [6] = {   input = {nil, {1,2,3,false,5,6}},
                output = {1,2,3}
            },
      [7] = {   input = {green, {a='somegreen',b='moregreen',c='greenhousegas',d='bluesky',e='greengrass',f='allgreen'}},
                output = {}
            },
      [8] = {   input = {green, {a='somegreen',b='moregreen',c='greenhousegas',d='bluesky',e='greengrass',f='allgreen'}, mypairs},
                output = {'somegreen','moregreen','greenhousegas'}
            },
    },
    
    --lfunc.add = function(...)
    {
      name = 'add',
      func = lfunc.add,
      
      [1] = {   input = {},
                output = 0
            },
      [2] = {   input = {5},
                output = 5
            },
      [3] = {   input = {2,9},
                output = 11
            },
      [4] = {   input = {4,91,903},
                output = 998
            },
    },
    
    --lfunc.sub = function(a,b)
    {
      name = 'sub',
      func = lfunc.sub,
      
      [1] = {   input = {8,5},
                output = 3
            },
      [2] = {   input = {5,10},
                output = -5
            },
    },
    
    --lfunc.mult = function(...)
    {
      name = 'mult',
      func = lfunc.mult,
      
      [1] = {   input = {},
                output = 1
            },
      [2] = {   input = {7},
                output = 7
            },
      [3] = {   input = {2,9},
                output = 18
            },
      [4] = {   input = {4,20,100},
                output = 8000
            },
    },
    
    --lfunc.div = function(a,b)
    {
      name = 'div',
      func = lfunc.div,
      
      [1] = {   input = {9,10},
                output = .9
            },
      [2] = {   input = {54,9},
                output = 6
            },
    },

    --lfunc.pow = function(a,b)
    {
      name = 'pow',
      func = lfunc.pow,
      
      [1] = {   input = {3,2},
                output = 9
            },
      [2] = {   input = {4,-.5},
                output = .5
            },
    },
    
    --lfunc.mod = function(a,b)
    {
      name = 'mod',
      func = lfunc.mod,
      
      [1] = {   input = {19,7},
                output = 5
            },
      [2] = {   input = {54,10},
                output = 4
            },
    },
    
    --lfunc.eq = function(...)
    {
      name = 'eq',
      func = lfunc.eq,
      
      [1] = {   input = {19,19},
                output = true
            },
      [2] = {   input = {19,18},
                output = false
            },
      [3] = {   input = {19},
                output = true
            },
      [4] = {   input = {19,19,18,19},
                output = false
            },
      [5] = {   input = {19,19,19,19},
                output = true
            },
    },
    
    --lfunc.neq = function(...)
    {
      name = 'neq',
      func = lfunc.neq,
      
      [1] = {   input = {19,19},
                output = false
            },
      [2] = {   input = {19,18},
                output = true
            },
      [3] = {   input = {19},
                output = false
            },
      [4] = {   input = {19,19,18,19},
                output = false
            },
      [5] = {   input = {19,19,19,19},
                output = false
            },
      [6] = {   input = {19,18,17,16},
                output = true
            },
      [7] = {   input = {},
                output = false
            },
      [8] = {   input = {false},
                output = false
            },
    },
    
    --lfunc.lt = function(...)
    {
      name = 'lt',
      func = lfunc.lt,
      
      [1] = {   input = {19,19},
                output = false
            },
      [2] = {   input = {18,19},
                output = true
            },
      [3] = {   input = {19},
                output = true
            },
      [4] = {   input = {17,18,18,19},
                output = false
            },
      [5] = {   input = {16,17,18,19},
                output = true
            },
    },
    
    --lfunc.gt = function(...)
    {
      name = 'gt',
      func = lfunc.gt,
      
      [1] = {   input = {19,19},
                output = false
            },
      [2] = {   input = {19,18},
                output = true
            },
      [3] = {   input = {19},
                output = true
            },
      [4] = {   input = {19,18,18,17},
                output = false
            },
      [5] = {   input = {19,18,17,16},
                output = true
            },
    },
    
    --lfunc.leq = function(...)
    {
      name = 'leq',
      func = lfunc.leq,
      
      [1] = {   input = {19,19},
                output = true
            },
      [2] = {   input = {18,19},
                output = true
            },
      [3] = {   input = {19},
                output = true
            },
      [4] = {   input = {17,18,18,19},
                output = true
            },
      [5] = {   input = {16,17,18,19},
                output = true
            },
      [6] = {   input = {17,18,18,17},
                output = false
            },
      [7] = {   input = {16,16,20,19},
                output = false
            },
    },
    
    --lfunc.geq = function(...)
    {
      name = 'geq',
      func = lfunc.geq,
      
      [1] = {   input = {19,19},
                output = true
            },
      [2] = {   input = {19,18},
                output = true
            },
      [3] = {   input = {19},
                output = true
            },
      [4] = {   input = {19,18,18,17},
                output = true
            },
      [5] = {   input = {19,18,17,16},
                output = true
            },
      [6] = {   input = {19,18,18,19},
                output = false
            },
      [7] = {   input = {19,18,12,15},
                output = false
            },
    },
    
    --lfunc._and = function(...)
    {
      name = '_and',
      func = lfunc._and,
      
      [1] = {   input = {19,19},
                output = 19
            },
      [2] = {   input = {19,false},
                output = false
            },
      [3] = {   input = {false,19},
                output = false
            },
      [4] = {   input = {19,18,18,17},
                output = 17
            },
      [5] = {   input = {19},
                output = 19
            },
      [6] = {   input = {false},
                output = false
            },
    },
    
    --lfunc._or = function(...)
    {
      name = '_or',
      func = lfunc._or,
      
      [1] = {   input = {19,19},
                output = 19
            },
      [2] = {   input = {19,false},
                output = 19
            },
      [3] = {   input = {false,19},
                output = 19
            },
      [4] = {   input = {19,18,18,17},
                output = 19
            },
      [5] = {   input = {19},
                output = 19
            },
      [6] = {   input = {false},
                output = false
            },
      [7] = {   input = {false,false,false},
                output = false
            },
      [8] = {   input = {false,false,false,0},
                output = 0
            },
    },
    
    --lfunc.concat = function(...)
    {
      name = 'concat',
      func = lfunc.concat,
      
      [1] = {   input = {},
                output = ''
            },
      [2] = {   input = {'green'},
                output = 'green'
            },
      [3] = {   input = {'green', 'grass','gross','gruel'},
                output = 'greengrassgrossgruel'
            },
      [4] = {   input = {'green ',' ','','','grass','gross','gruel'},
                output = 'green  grassgrossgruel'
            },
      [5] = {   input = {1,2,3,4,5},
                output = '12345'
            },
      [6] = {   input = {1,'green',5},
                output = '1green5'
            },
    },
    
    --lfunc.flatten = function(t,iter,t2,ind)
    {
      name = 'flatten',
      func = lfunc.flatten,
      
      [1] = {   input = {{1,2,3}},
                output = {1,2,3}
            },
      [2] = {   input = {{1,2,{3,4,5},6,7}},
                output = {1,2,3,4,5,6,7}
            },
      [3] = {   input = {{}},
                output = {}
            },
      [4] = {   input = {{{}}},
                output = {}
            },
      [5] = {   input = {{{10,9,{8,7,6},5},{4,{3}},2,{{{1}}}}},
                output = {10,9,8,7,6,5,4,3,2,1}
            },
      [6] = {   input = {{1,2,{3,4,blue=5,red=6},7,blue=8,red=9,[false]=10}},
                output = {1,2,3,4,7}
            },
      [7] = {   input = {{1,2,{3,4,blue=5,red=6},7,blue=8,red=9,[false]=10}, mypairs},
                output = {1,2,3,4,5,6,7,8,9,10}
            },
    },
    
    --lfunc.choose = function(pred, a, b)
    {
      name = 'choose',
      func = lfunc.choose,
      
      [1] = {   input = {5 > 6, 'red', 'green'},
                output = 'green'
            },
      [2] = {   input = {5 <= 6, 'red', 'green'},
                output = 'red'
            },
      [3] = {   input = {nil, 'red', 'green'},
                output = 'green'
            },
      },
    
    --lfunc.indicator = function(pred)
    {
      name = 'indicator',
      func = lfunc.indicator,
      
      [1] = {   input = {5 > 6},
                output = 0
            },
      [2] = {   input = {5 <= 6},
                output = 1
            },
      [3] = {   input = {nil},
                output = 0
            },
    },
    
    --lfunc.gen = function(seed, succ, cond)
    {
      name = 'gen',
      func = lfunc.gen,
      
      [1] = {   input = {5, add2, function(a) return a>=11 end},
                output = {5,7,9}
            },
      [2] = {   input = {-10, add2, function(a) return a>0 end},
                output = {-10,-8,-6,-4,-2,0}
            },
      [3] = {   input = {1, function(n,ind) return ind*ind end, function(a) return a>50 end},
                output = {1,4,9,16,25,36,49}
            },
      [4] = {   input = {-10, add2, function(a,ind) return ind>4 end},
                output = {-10,-8,-6,-4}
            },
      [5] = {   input = {1, function(n,ind) return lfunc.case({ind%3==0, 0},{true,n+1}) end, function(n,ind) return ind>6 end},
                output = {1, 2, 0, 1, 2, 0}
            },
    },
    
    
    
    --lfunc.gent = function(seed, succ, cond)
    {
      name = 'gent',
      func = lfunc.gent,
      
      [1] = {   input = {{5}, function(t,ind) return t[ind-1]+2 end, function(t,a) return a>=11 end},
                output = {5,7,9}
            },
      [2] = {   input = {{-10}, function(t,ind) return t[ind-1]+2 end, function(t,a) return a>0 end},
                output = {-10,-8,-6,-4,-2,0}
            },
      [3] = {   input = {{1}, function(t,ind) return ind*ind end, function(t,a) return a>50 end},
                output = {1,4,9,16,25,36,49}
            },
      [4] = {   input = {{-10}, function(t,ind) return t[1]+t[ind-1] end, function(t,a,ind) return ind>4 end},
                output = {-10,-20,-30,-40}
            },
      [5] = {   input = {{2}, function(t,ind) return t[1]+t[ind-1] end, function(t,a,ind) return ind>4 end},
                output = {2,4,6,8}
            },
      [6] = {   input = {{1,2}, function(t,ind) return lfunc.case({ind%3==0, 0},{true,t[ind-2]+1}) end, function(t,n,ind) return ind>9 end},
                output = {1, 2, 0, 3, 1, 0, 2, 1, 0}
            },
    },
    
    --lfunc.range = function(start, stop, step)
    {
      name = 'range',
      func = lfunc.range,
      
      [1] = {   input = {0,0,1},
                output = {0}
            },
      [2] = {   input = {0,10,2},
                output = {0,2,4,6,8,10}
            },
      [3] = {   input = {1,100,25},
                output = {1,26,51,76}
            },
      [4] = {   input = {10,0,-3},
                output = {10,7,4,1}
            },
      [5] = {   input = {5},
                output = {1,2,3,4,5}
            },
      [6] = {   input = {2,5},
                output = {2,3,4,5}
            },
      [7] = {   input = {5,2},
                output = {5,4,3,2}
            },
    },
    
    --lfunc.listcomp = function(func, arr, ...)
    {
      name = 'listcomp',
      func = lfunc.listcomp,
      
      [1] = {   input = {nil,{1,2,3,4,5,6}},
                output = {1,2,3,4,5,6}
            },
      [2] = {   input = {nil,lfunc.range(0,10,2)},
                output = {0,2,4,6,8,10}
            },
      [3] = {   input = {lfunc.id,lfunc.range(0,10,2)},
                output = {0,2,4,6,8,10}
            },
      [4] = {   input = {add2,lfunc.range(1,4)},
                output = {3,4,5,6}
            },
      [5] = {   input = {square,lfunc.range(1,4)},
                output = {1,4,9,16}
            },
      [6] = {   input = {square,lfunc.range(1,4),even},
                output = {4,16}
            },
      [7] = {   input = {square,lfunc.range(-4,4),even,gt2},
                output = {16}
            },
    },
    
    --lfunc.apply = function(f, ...)
    {
      name = 'apply',
      func = lfunc.apply,
      dofunc = true,
      
      [1] = {   input = {add, 2, 6},
                output = 8,
                run = function(f, a, b)
                    local g = lfunc.apply(f)
                    return g(a,b)
                end,
             },
      [2] = {   input = {add, 2, 4},
                output = 6,
                run = function(f, a, b)
                    local g = lfunc.apply(f,a)
                    return g(b)
                end,
             },
      [3] = {   input = {add, 1, 6},
                output = 7,
                run = function(f, a, b)
                    local g = lfunc.apply(f,a,b)
                    return g()
                end,
             },
      [4] = {   input = {add3, 1, 6, 9},
                output = 16,
                run = function(f, a, b, c)
                    local g = lfunc.apply(f,a,b)
                    return g(c)
                end,
             },
      },
    
    --lfunc.applyn = function(f,...)
    {
      name = 'applyn',
      func = lfunc.applyn,
      dofunc = true,
      
      [1] = {   input = {add, 2, 6},
                output = 7,
                run = function(f, a, b)
                    local g = lfunc.applyn(f,a,b)
                    return g(1)
                end,
             },
      [2] = {   input = {add, 1, 3, 2, 5},
                output = 8,
                run = function(f, a, b, c, d)
                    local g = lfunc.applyn(f,a,b,c,d)
                    return g()
                end,
             },
      [3] = {   input = {lfunc.pow, 2, 3},
                output = 8,
                run = function(f, a, b)
                    local g = lfunc.applyn(f,a,b)
                    return g(2)
                end,
             },
      [4] = {   input = {lfunc.gt, 3, 6, 5, 4},
                output = true,
                run = function(f, a, b, c, d)
                    local g = lfunc.applyn(f,a,b,c,d)
                    return g(10,7,5,3,2,1)
                end,
             },
      [5] = {   input = {lfunc.gt, 3, 6, 6, 4},
                output = false,
                run = function(f, a, b, c, d)
                    local g = lfunc.applyn(f,a,b,c,d)
                    return g(10,7,5,3,2,1)
                end,
             },
      },
    
    --lfunc.compose = function(...)
    {
      name = 'compose',
      func = lfunc.compose,
      dofunc = true,
      
      [1] = {   input = {add2, add, 2, 6},
                output = 10,
                run = function(f, g, a, b)
                    local h = lfunc.compose(f,g)
                    return h(a,b)
                end,
             },
      [2] = {   input = {},
                output = nil,
                run = function()
                    local g = lfunc.compose()
                    return g()
                end,
             },
      [3] = {   input = {add, 1, 6},
                output = 7,
                run = function(f, a, b)
                    local g = lfunc.compose(f)
                    return f(a,b)
                end,
             },
      [4] = {   input = {add2, add2, add3, 1, 6, 9},
                output = 20,
                run = function(f, g, h, a, b, c)
                    local k = lfunc.compose(f,g,h)
                    return k(a,b,c)
                end,
             },
      },
    
    --lfunc.curry = function(f, n)
    {
      name = 'curry',
      func = lfunc.curry,
      dopack = true,
      dofunc = true,
      
      [1] = {   input = {add,2,5,13},
                output = {18},
                run = function(f, n, a, b)
                    local h = lfunc.curry(f,n)
                    return h(a,b)
                end,
             },
      [2] = {   input = {add,2,5,13},
                output = {18},
                run = function(f, n, a, b)
                    local h = lfunc.curry(f,n)
                    local g = h(a)
                    return g(b)
                end,
             },
      [3] = {   input = {add3,3,5,13,19},
                output = {37},
                run = function(f, n, a, b, c)
                    local h = lfunc.curry(f,n)
                    local g = h(a,b)
                    return g(c)
                end,
             },
      [4] = {   input = {lfunc.apply(add2,9),0},
                output = {11},
                run = function(f, n)
                    local h = lfunc.curry(f,n)
                    return h()
                end,
             },
      [5] = {   input = {lfunc.apply(add,9),1,1},
                output = {10},
                run = function(f, n, a)
                    local h = lfunc.curry(f,n)
                    local g = h()
                    return g(a)
                end,
             },
      [6] = {   input = {lfunc.add,4,10,11,12,13,14,15},
                output = {50,46},
                run = function(f, n, a, b, c, d, e, aa)
                    local fp = lfunc.curry(f,n)
                    local g = fp(a,b)
                    local h = g(c)
                    return g(e,aa),h(d)
                end,
             },
      },
      
    --lfunc.case = function(...)
    {
      name = 'case',
      func = lfunc.case,
      
      [1] = {   input = {{5>3,7},{10>3,-7}},
                output = 7,
            },
      [2] = {   input = {{5<3,7},{10>3,-7}},
                output = -7,
            },
      [3] = {   input = {{5<3,7},{10<3,-7}},
                output = nil,
            },
      [4] = {   input = {{0,'happy'}},
                output = 'happy',
            },
      [5] = {   input = {{false,'sad'}},
                output = nil,
            },
      [6] = {   input = {{5<=3,1},{'green'=='blue',2},{6+7==1,3},{true,4},{false,5}},
                output = 4,
            },
      [7] = {   input = {},
                output = nil,
            },
    },
    
    
    --lfunc.casef = function(...)
    {
      name = 'casef',
      func = lfunc.casef,
      dopack = true,
      dofunc = true,
      
      [1] = {   input = {{even,add2},{true,lfunc.apply(add,-2)}},
                output = {4},
                run = function(...)
                    local f = lfunc.casef(...)
                    return f(2)
                end
            },
      [2] = {   input = {{even,add2},{true,lfunc.apply(add,-2)}},
                output = {1},
                run = function(...)
                    local f = lfunc.casef(...)
                    return f(3)
                end
            },
      [3] = {   input = {{green,identity},{true,lfunc.apply(lfunc.concat,'not ')}},
                output = {'bright green'},
                run = function(...)
                    local f = lfunc.casef(...)
                    return f('bright green')
                end
            },
      [4] = {   input = {{green,identity},{true,lfunc.apply(lfunc.concat,'not ')}},
                output = {'not dark blue'},
                run = function(...)
                    local f = lfunc.casef(...)
                    return f('dark blue')
                end
            },
      [5] = {   input = {{green,identity},{false,lfunc.apply(lfunc.concat,'not ')}},
                output = {nil},
                run = function(...)
                    local f = lfunc.casef(...)
                    return f('dark blue')
                end
            },
      [6] = {   input = {{green,identity},{false,lfunc.apply(lfunc.concat,'not ')}},
                output = {'forest green','extra arg'},
                run = function(...)
                    local f = lfunc.casef(...)
                    return f('forest green','extra arg')
                end
            },
      [7] = {   input = {{green,identity},{identity,lfunc.apply(lfunc.concat,'not ')}},
                output = {'not sky blueextra arg'},
                run = function(...)
                    local f = lfunc.casef(...)
                    return f('sky blue','extra arg')
                end
            },
      [8] = {   input = {{false,false},{true,true}},
                output = {true},
                run = function(...)
                    local f = lfunc.casef(...)
                    return f()
                end
            },
      [9] = {   input = {{false,true},{true,false}},
                output = {false},
                run = function(...)
                    local f = lfunc.casef(...)
                    return f()
                end
            },
      [10]= {   input = {{false,true},{true,nil}},
                output = {nil},
                run = function(...)
                    local f = lfunc.casef(...)
                    return f()
                end
            },
      [11]= {   input = {{false,18},{17,nil}},
                output = {nil},
                run = function(...)
                    local f = lfunc.casef(...)
                    return f()
                end
            },
      [12]= {   input = {{nil,'green'},{true,'blue'}},
                output = {'blue'},
                run = function(...)
                    local f = lfunc.casef(...)
                    return f()
                end
            },
      [13]= {   input = {{even,'red'},{12.4,even}},
                output = {'red'},
                run = function(...)
                    local f = lfunc.casef(...)
                    return f(2)
                end
            },
      [14]= {   input = {{even,'red'},{12.4,even}},
                output = {false},
                run = function(...)
                    local f = lfunc.casef(...)
                    return f(1)
                end
            },
    },
    
    --lfunc.loadglobally = function(lf, t)
    {
      name = 'loadglobally',
      func = lfunc.loadglobally,
      dopack = true,
      dofunc = true,
      
      [1] = {   input = {lfunc,{}},
                output = {3,{8,-3,6,-1,4,1}},
                run = function(f,t)
                    lfunc.loadglobally(f,t)
                    return  t.add(6,-5,4,-3,2,-1),
                            t.map(add2,{6,-5,4,-3,2,-1})
                end
            },
      [2] = {   input = {lfunc},
                output = {3,{8,-3,6,-1,4,1}},
                run = function(f,t)
                    lfunc.loadglobally(f)
                    return  add(6,-5,4,-3,2,-1),
                            map(add2,{6,-5,4,-3,2,-1})
                end
            },
    },
    
    -- lfunc.reverse = function(t, iter)
    {
      name = 'reverse',
      func = lfunc.reverse,
      
      [1] = {   input = {{1,2,3,4,5,6}},
                output = {6,5,4,3,2,1}
            },
      [2] = {   input = {{}},
                output = {}
            },
      [3] = {   input = {{3}},
                output = {3}
            },
      [4] = {   input = {{1,2,3,green=7,red=9},mypairs},
                output = {9,7,3,2,1}
            },
      [5] = {   input = {''},
                output = ''
            },
      [6] = {   input = {'a'},
                output = 'a'
            },
      [7] = {   input = {'bcdefg'},
                output = 'gfedcb'
            },
    },
    
    
})



