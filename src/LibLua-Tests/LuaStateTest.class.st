Class {
	#name : 'LuaStateTest',
	#superclass : 'TestCase',
	#category : 'LibLua-Tests',
	#package : 'LibLua-Tests'
}

{ #category : 'tests' }
LuaStateTest >> averageAndSum: lua [


	| n sum |
	n := lua getTop.
	sum := 0.0.

	1 to: n do: [ :i | sum := sum + (lua numberAt: i) ].

	lua 
		pushNumber: sum / n;
		pushNumber: sum.

	^ 2
]

{ #category : 'tests' }
LuaStateTest >> commandDefLuaSource [

	^ '

function command (tbl)
	return { name = tbl[1], context=1, followups=tbl[2] or {}, action=nil }
end

'
]

{ #category : 'tests' }
LuaStateTest >> commandsLuaSource [

	^ '

commands = {
	command { "create", 
		{ 
			command { "document" }, 
		  	command { "folder" }
		} 
	},
	command { "delete" },
}

'
]

{ #category : 'tests' }
LuaStateTest >> liblua [

	^ LibLua uniqueInstance
]

{ #category : 'tests' }
LuaStateTest >> pushCommandTableOnLua: state random: random acc: aKey [

	"According to https://stackoverflow.com/questions/20147027/creating-a-simple-table-with-lua-tables-c-api"

	| s name lua |
	lua := LuaState new
		externalAddress: state;
		liblua: self liblua implementationPrimitive;
		yourself.

	lua checkTypeAt: 1 equals: #LUA_TTABLE.

	lua pushNewTable.

	name := lua getFieldAt: 1 ofValueAt: -2.
	self assert: name equals: (lua typeIdOfTypeName: #LUA_TSTRING).
	lua setField: 'name' ofValueAt: -2.

	s := random next.
	aKey key: aKey key + s.

	lua
		push: s;
		setField: 'context' ofValueAt: -2.

	lua
		getFieldAt: 2 ofValueAt: -2;
		setField: 'followups' ofValueAt: -2.

	lua
		push: 'noop';
		setField: 'action' ofValueAt: -2.

	^ 1 "number of results"
]

{ #category : 'tests' }
LuaStateTest >> recSumLuaSource [

	^ '

function recSum (tbl) 
	r = 0.0
	for _, c in ipairs(tbl) do
		print(c.name)
		r = r + c.context + recSum (c.followups or {})
	end
	return r
end

'
]

{ #category : 'tests' }
LuaStateTest >> testCFunctionAverage [

	| avg sum |
	self liblua do: [ :lua | 
		| average |
		average := lua on: #foo do: [ :s | self averageAndSum: s  ].
		
		"We push here some values on the stack to test the behaviour of #lua_gettop: 
		 when the stack contains some more values other than the arguments for the 
		 function call."
		
		lua pushNil. 
		lua pushString: 'hello'.

		lua executePushingTwo: 'return foo(12, 43, 43, 450)'.

		avg := lua numberAt: -2.
		sum := lua numberAt: -1.
	].

	self
		assert: avg equals: { 12. 43. 43. 450 } average;
		assert: sum equals: { 12. 43. 43. 450 } sum
]

{ #category : 'tests' }
LuaStateTest >> testCFunctionPCallCoroutine [

	| s e |
	self liblua do: [ :lua | 
		lua
			do: 'co = coroutine.create(function (...) print(pcall(coroutine.yield, ...)) end)';
			executePushingTwo: 'return coroutine.resume(co, "hello")'.
			
		s := lua booleanAt: -2.
		e := lua stringAt: -1 ].

	self
		assert: s equals: 1;
		assert: e equals: 'hello'
]

{ #category : 'tests' }
LuaStateTest >> testCommandsUsingLuaAPI [

	| result random r |
	random := Random seed: 541.

	"The following lookupkey is necessary to keep the sum of
	 random numbers generated call after call."
	r := LookupKey new
		     key: 0.0;
		     yourself.

	result := self liblua do: [ :lua | 
		          lua
			          push: [ :ongoingState | 
				          self
					          pushCommandTableOnLua: ongoingState
					          random: random
					          acc: r ];
			          setGlobal: 'command';
			          do: self recSumLuaSource;
			          do: self commandsLuaSource;
			          executePushingOne: 'return recSum(commands)';
			          numberAt: -1 ifNotNumber: [ Error signal ] ].

	self assert: result equals: r key
]

{ #category : 'tests' }
LuaStateTest >> testCommandsUsingLuaDefs [

	| result |
	result := self liblua do: [ :lua | 
		          lua
			          do: self commandDefLuaSource;
			          do: self recSumLuaSource;
			          do: self commandsLuaSource;
			          executePushingOne: 'return recSum(commands)';
			          integerAt: -1 ifNotInteger: [ Error signal ] ].

	self assert: result equals: 4
]

{ #category : 'tests' }
LuaStateTest >> testCommandsUsingLuaDefsReadingTableBack [

	| result |
	result := self liblua do: [ :lua | 
		          lua
			          do: self commandDefLuaSource;
			          do: self commandsLuaSource;
			          getGlobal: 'commands';
			          getFieldAt: 1 ofValueAt: -1;
						 getField: 'name' ofValueAt: -1;
			          stringAt: -1 ].

	self assert: result equals: 'create'
]

{ #category : 'tests' }
LuaStateTest >> testCommandsUsingLuaDefsTableDo [

	| result |
	result := OrderedCollection new.

	self liblua do: [ :lua | 
		lua
			do: self commandDefLuaSource;
			do: self commandsLuaSource;
			getGlobal: 'commands';
			tableAt: -1 do: [ :k :v | 
				| keyType valueType |
				keyType := lua typeNameOf: k.
				valueType := lua typeNameOf: v.
				result add: keyType -> valueType ] ].

	self
		assert: result first equals: 'number' -> 'table';
		assert: result second equals: 'number' -> 'table';
		assert: result size equals: 2
]

{ #category : 'tests' }
LuaStateTest >> testCopy [

	| result original |
	result := Set new.
	original := Set new.

	self liblua do: [ :lua | 
		lua
			do: 'tbl = { hello = 3.14, "!" }';
			do: 'tbl[ { } ] = 2';
			getGlobal: 'tbl';
			pushNil;
			copyFrom: -2 to: -1;
			tableAt: -1 do: [ :k :v | 
				| keyType valueType |
				keyType := lua typeNameOf: k.
				valueType := lua typeNameOf: v.
				result add: keyType -> valueType ];
			tableAt: -2 do: [ :k :v | 
				| keyType valueType |
				keyType := lua typeNameOf: k.
				valueType := lua typeNameOf: v.
				original add: keyType -> valueType ] ].

	self
		assert: result equals: (Set new
				 add: 'number' -> 'string';
				 add: 'table' -> 'number';
				 add: 'string' -> 'number';
				 yourself);
		assert: result equals: original;
		assert: result size equals: 3
]

{ #category : 'tests' }
LuaStateTest >> testCopyCompare [

	| outer inner |
	self liblua do: [ :lua | 
		outer := lua 
			do: 'tbl = { nested = { } }';
			getGlobal: 'tbl';
			pushNil;
			copyFrom: -2 to: -1;
			compareAt: -2 toValueAt: -1.

		inner := lua
			getField: 'nested' ofValueAt: -2; 
			getField: 'nested' ofValueAt: -2; 
			compareAt: -1 toValueAt: -2. ].

	self
		assert: outer equals: 1;
		assert: inner equals: 1
]

{ #category : 'tests' }
LuaStateTest >> testHeapBench [

	| random array luaTimeToRun smalltalkTimeToRun  |
	self timeLimit: 1 minute.

	random := Random seed: 541.
	array := (1 to: 1e7) asArray shuffleBy: random.

	self liblua do: [ :lua | 
		| c | 
		
		lua
			registerPath: './lua';
			require: 'io.github.massimo-nocentini.on-lua.heapq' as: 'heapq';
			require: 'io.github.massimo-nocentini.on-lua.heapkt' as: 'heapkt';
			require: 'io.github.massimo-nocentini.on-lua.extensions'.

		c := lua
			     getGlobal: 'heapq';
			     getField: 'new' ofValueAt: -1;
			     push: array;
			     protectedCallArgumentsCount: 1 resultsCount: 1.

		self assert: c equals: 0.

		lua
			setGlobal: 'H';
			getGlobal: 'heapq';
			getField: 'heapify' ofValueAt: -1;
			getGlobal: 'H'.

		luaTimeToRun := [ 
                | code |
                code :=  lua protectedCallArgumentsCount: 1 resultsCount: 1.
                self assert: code equals: 0 ] timeToRun.
	].

	smalltalkTimeToRun := [ Heap withAll: array ] timeToRun.

	luaTimeToRun traceCrAs: 'Lua time'.
	smalltalkTimeToRun traceCrAs: 'Pharo time'.
]

{ #category : 'tests' }
LuaStateTest >> testLoadThenPCall [

	| code |
	self liblua do: [ :lua | 
		code := lua executePushingNone: 'do a = 3 + 4; print("The result is: ", a) end'.
	].

	self assert: code equals: 0
]

{ #category : 'tests' }
LuaStateTest >> testLoadThenPCallThenToString [

	| code error |
	self liblua do: [ :lua | 
		code := lua executePushingNone: '(function (a, b) return error("hello") end) (3, 4)'.
		error := lua stringAt: -1
	].

	self assert: code equals: 2.
	self
		assert: error
		equals:
		'[string "(function (a, b) return error("hello") end) (..."]:1: hello'
]

{ #category : 'tests' }
LuaStateTest >> testLoadThenPCallWithReturnInteger [

	| code seven |
	self liblua do: [ :lua | 
		code := lua executePushingOne: 'do a = 3 + 4; print("The result is: ", a); return a + 1 end'.
		seven := lua integerAt: -1 ifNotInteger: [ Error signal ].
	].

	self
		assert: code equals: 0;
		assert: seven equals: 8
]

{ #category : 'tests' }
LuaStateTest >> testLoadThenPCallWithReturnIntegerFail [

	| code seven witness |
	witness := Object new.

	self liblua do: [ :lua | 
		code := lua executePushingOne: 'do a = 3 + 4; print("The result is: ", a); return "just a simple string" end'.
		seven := lua integerAt: -1 ifNotInteger: [ witness ].
	].

	self
		assert: code equals: 0;
		assert: seven equals: witness
]

{ #category : 'tests' }
LuaStateTest >> testLoadThenPCallWithReturnIntegerInString [

	| code seven |

	self liblua do: [ :lua | 
		code := lua executePushingOne: 'do a = 3 + 4; print("The result is: ", a); return tostring(a + 1) end'.
		seven := lua integerAt: -1 ifNotInteger: [ Error signal ].
	].

	self
		assert: code equals: 0;
		assert: seven equals: 8
]

{ #category : 'tests' }
LuaStateTest >> testLoadThenPCallWithReturnNumber [

	| code seven |

	self liblua do: [ :lua | 
		code := lua executePushingOne: 'do a = 3 + 4.2; print("The result is: ", a); return a + 1 end'.
		seven := lua numberAt: -1 ifNotNumber: [ Error signal ].
	].

	self
		assert: code equals: 0;
		assert: seven equals: 8.2
]

{ #category : 'tests' }
LuaStateTest >> testLoadThenPCallWithReturnNumberFail [

	| code seven witness |
	witness := Object new.

	self liblua do: [ :lua | 
		code := lua executePushingOne: 'do a = 3 + 4; print("The result is: ", a); return "just a simple string" end'.
		seven := lua numberAt: -1 ifNotNumber: [ witness ].
	].

	self
		assert: code equals: 0;
		assert: seven equals: witness
]

{ #category : 'tests' }
LuaStateTest >> testLoadThenPCallWithReturnString [

	| code seven |

	self liblua do: [ :lua | 
		code := lua executePushingOne: 'do a = 3 + 4; print("The result is: ", a); return tostring(a) .. " hello " end'.
		seven := lua stringAt: -1.
	].

	self
		assert: code equals: 0;
		assert: seven equals: '7 hello '
]

{ #category : 'tests' }
LuaStateTest >> testLuaSeti [

	| list random array |
	random := Random seed: 541.
	array := (1 to: 100) asArray shuffleBy: random.

	list := self liblua do: [ :lua | 
			lua addGlobal: array as: 'array'.
			lua executePushingOne: 'return  table.concat(array, " ")'.
			lua stringAt: -1. ].

	self assert: '#(' , list , ')' equals: array asString
]

{ #category : 'tests' }
LuaStateTest >> testNewCloseState [

	| three |
	three := self liblua do: [ :lua | 
		         self deny: lua externalAddress equals: ExternalAddress null.
		         3 ].

	self assert: three equals: 3
]

{ #category : 'tests' }
LuaStateTest >> testReadFromArray [

	self liblua do: [ :lua | 
		| result |
		result := lua execute: 'return {1, 2, 3, 4, 5}'.
		self assert: result equals: #( 1 2 3 4 5 ).

		result := lua execute: 'return {1, {1, 2, 3, 4, 5}, 3, 4, 5}'.
		self assert: result equals:  #( 1 #( 1 2 3 4 5 ) 3 4 5 ).

		result := lua execute: 'return {[-1]=1, 2, nil, [100]=4, 5}'.
		self assert: result equals: (Dictionary new
				 at: -1 put: 1;
				 at: 1 put: 2;
				 at: 100 put: 4;
				 at: 3 put: 5;
				 yourself).
	].

]

{ #category : 'tests' }
LuaStateTest >> testReadFromBoolean [

	self liblua do: [ :lua | 
		| result |
		result := lua execute: 'return false'.
		self deny: result.

		result := lua execute: 'return true'.
		self assert: result.
	]
]

{ #category : 'tests' }
LuaStateTest >> testReadFromInteger [

	self liblua do: [ :lua | 
		| result |
		result := lua execute: 'return 12345'.
		self assert: result equals: 12345
	]
]

{ #category : 'tests' }
LuaStateTest >> testReadFromNil [

	self liblua do: [ :lua | 
		| result |
		result := lua execute: 'return nil'.
		self assert: result equals: nil
	]
]

{ #category : 'tests' }
LuaStateTest >> testReadFromNumber [

	self liblua do: [ :lua | 
		| result |
		result := lua execute: 'return 12345.1'.
		self assert: result equals: 12345.1
	]
]

{ #category : 'tests' }
LuaStateTest >> testReadFromString [

	self liblua do: [ :lua | 
		| result |
		result := lua execute: 'return "nil"'.
		self assert: result equals: 'nil'
	]
]

{ #category : 'tests' }
LuaStateTest >> testReadFromTable [

	self liblua do: [ :lua | 
		| result |
		result := lua 
			do: 'tbl = {1, 4}';
			do: 'tbl[{}] = "hello"';
			do: 'tbl[true] = { 1 }';
			execute: 'return tbl'.
		self assert: result equals: (Dictionary new
				 at: 1 put: 1;
				 at: 2 put: 4;
				 at: #(  ) put: 'hello';
				 at: true put: #( 1 );
				 yourself) ]
]

{ #category : 'tests' }
LuaStateTest >> testSetGlobalMySinAsCallback [

	| code result called |
	called := false.

	self liblua do: [ :lua |
		lua
			addGlobal: [ :ongoingState |
				| number |
				called := true.
				self assert: ongoingState equals: lua externalAddress.

				number := lua liblua luaL: lua externalAddress checknumber: 1.

				lua liblua on: ongoingState push: number sin.

				1 "number of results"
			]
			as: 'mysin'.

		code := lua executePushingOne: 'return mysin(3)'.

		"		self liblua luaL:  lua externalAddress loadstring: 'return mysin(3)'.
		code := self liblua lua:  lua externalAddress pcallnargs: 0 nresults: 1.
"

		result := lua numberAt: -1 ifNotNumber: [ Error signal ]
	].

	self
		assert: code equals: 0;
		assert: called;
		assert: result equals: 3 sin
]

{ #category : 'tests' }
LuaStateTest >> testTableMap [

	| list |

	self liblua do: [ :lua | 
		
		lua registerPath: './lua'.
		lua require: 'io.github.massimo-nocentini.on-lua.operator' as: 'op'.
		lua require: 'io.github.massimo-nocentini.on-lua.extensions'.

		list := lua
			do: 'list = {5, 4, 3, 2, 1}';
			do: 'print(table.contains)';
			do: 'print(op.increment)';
			do: 'print(coroutine.zip)';
			do: 'list = table.map(list, op.increment)';
			execute: 'return table.concat(list, ", ")'.
	].

	self assert: list equals: '6, 5, 4, 3, 2'
]
