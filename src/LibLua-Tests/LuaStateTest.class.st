Class {
	#name : #LuaStateTest,
	#superclass : #TestCase,
	#category : #'LibLua-Tests'
}

{ #category : #tests }
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

{ #category : #tests }
LuaStateTest >> liblua [

	^ LibLua uniqueInstance
]

{ #category : #tests }
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

		lua load: 'return foo(12, 43, 43, 450)'.
		lua protectedCallArgumentsCount: 0 resultsCount: 2. 

		avg := lua numberAt: -2.
		sum := lua numberAt: -1.
	].

	self
		assert: avg equals: { 12. 43. 43. 450 } average;
		assert: sum equals: { 12. 43. 43. 450 } sum
]
