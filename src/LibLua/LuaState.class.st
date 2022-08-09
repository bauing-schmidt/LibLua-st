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
LuaState >> addGlobal: anObject as: aName [ 

	self push: anObject.
	self setGlobal: aName.
]

{ #category : #accessing }
LuaState >> execute: aString [ 

	"one returned object"

	self execute: aString resultsCount: 1.
	^ self read: -1
]

{ #category : #accessing }
LuaState >> execute: aString resultsCount: resultsCount [

	self load: aString.
	self protectedCallArgumentsCount: 0 resultsCount: resultsCount. 
	
]

{ #category : #accessing }
LuaState >> executePushingNone: aString [ 

	self execute: aString resultsCount: 0
]

{ #category : #accessing }
LuaState >> executePushingOne: aString [ 

	self execute: aString resultsCount: 1
]

{ #category : #accessing }
LuaState >> executePushingTwo: aString [ 

	self execute: aString resultsCount: 2
]

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
LuaState >> push: anObject [

	self liblua push: anObject on: self externalAddress
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

{ #category : #accessing }
LuaState >> read: index [ 

	^ self liblua read: index from: self externalAddress.
]

{ #category : #private }
LuaState >> setGlobal: aString [ 

	"Pops a value from the stack and sets it as the new value of global name."
	
	self liblua lua: self externalAddress setglobal: aString
]

{ #category : #accessing }
LuaState >> stringAt: anIndex [ 

	^ self liblua lua: self externalAddress tostring: anIndex
]
