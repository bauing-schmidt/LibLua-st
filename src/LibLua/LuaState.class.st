Class {
	#name : #LuaState,
	#superclass : #Object,
	#instVars : [
		'liblua',
		'externalAddress'
	],
	#category : #LibLua
}

{ #category : #accessing }
LuaState >> externalAddress [

	^ externalAddress
]

{ #category : #accessing }
LuaState >> externalAddress: anObject [

	externalAddress := anObject
]

{ #category : #accessing }
LuaState >> getTop [

	^ self liblua lua_gettop: externalAddress
]

{ #category : #accessing }
LuaState >> liblua [

	^ liblua
]

{ #category : #accessing }
LuaState >> liblua: anObject [

	liblua := anObject
]

{ #category : #accessing }
LuaState >> load: aString [

	self liblua luaL: self externalAddress loadstring: aString
]

{ #category : #accessing }
LuaState >> numberAt: anIndex [ 

	^ self liblua lua: self externalAddress tonumber: anIndex
]

{ #category : #accessing }
LuaState >> on: functionName do: aBlock [ 

	| callback |
	
	callback := self liblua ffiCallback: [ :s | 
		aBlock value: self
	 ].

	self liblua lua: self externalAddress register: functionName cfunction: callback.	
]

{ #category : #accessing }
LuaState >> protectedCallArgumentsCount: argsCount resultsCount: resultsCount [ 

	self liblua lua: self externalAddress pcallnargs: argsCount nresults: resultsCount.
]

{ #category : #accessing }
LuaState >> pushNil [

	self liblua lua_pushnil: self externalAddress
]

{ #category : #accessing }
LuaState >> pushNumber: aNumber [

	self liblua lua: self externalAddress pushnumber: aNumber asFloat
]

{ #category : #accessing }
LuaState >> pushString: aString [

	self liblua lua: self externalAddress pushstring: aString
]
