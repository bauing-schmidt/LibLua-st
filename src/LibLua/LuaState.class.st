Class {
	#name : 'LuaState',
	#superclass : 'Object',
	#instVars : [
		'liblua',
		'externalAddress'
	],
	#category : 'LibLua',
	#package : 'LibLua'
}

{ #category : 'accessing' }
LuaState >> addGlobal: anObject as: aName [ 

	self push: anObject.
	self setGlobal: aName.
]

{ #category : 'accessing' }
LuaState >> booleanAt: anIndex [ 

	^ self liblua lua: self externalAddress toboolean: anIndex
]

{ #category : 'accessing' }
LuaState >> checkTypeAt: anIndex equals: type [

	^ self liblua
		  luaL: self externalAddress
		  check: anIndex
		  type: type
]

{ #category : 'accessing' }
LuaState >> compareAt: index1 toValueAt: index2 [

	^ self liblua lua: self externalAddress compare: index1 eq: index2
]

{ #category : 'accessing' }
LuaState >> copyFrom: fromIndex to: toIndex [

	^ self liblua lua: self externalAddress copy: fromIndex to: toIndex
]

{ #category : 'accessing' }
LuaState >> do: aString [

	^ self liblua luaL: self externalAddress dostring: aString
]

{ #category : 'accessing' }
LuaState >> execute: aString [ 

	"one returned object"

	self execute: aString resultsCount: 1.
	^ self read: -1
]

{ #category : 'accessing' }
LuaState >> execute: aString resultsCount: resultsCount [

	self load: aString.
	^ self protectedCallArgumentsCount: 0 resultsCount: resultsCount. 
	
]

{ #category : 'accessing' }
LuaState >> executePushingNone: aString [ 

	^ self execute: aString resultsCount: 0
]

{ #category : 'accessing' }
LuaState >> executePushingOne: aString [ 

	^ self execute: aString resultsCount: 1
]

{ #category : 'accessing' }
LuaState >> executePushingTwo: aString [ 

	^ self execute: aString resultsCount: 2
]

{ #category : 'accessing' }
LuaState >> externalAddress [

	^ externalAddress
]

{ #category : 'accessing' }
LuaState >> externalAddress: anObject [

	externalAddress := anObject
]

{ #category : 'accessing' }
LuaState >> getField: fieldName ofValueAt: anIndex [

	^ self liblua lua: self externalAddress get: anIndex field: fieldName
]

{ #category : 'accessing' }
LuaState >> getFieldAt: anIndex ofValueAt: valueIndex [

	^ self liblua lua: self externalAddress get: valueIndex i: anIndex
]

{ #category : 'accessing' }
LuaState >> getGlobal: aName [ 

	self liblua lua: self externalAddress getglobal: aName.
]

{ #category : 'accessing' }
LuaState >> getTop [

	^ self liblua lua_gettop: externalAddress
]

{ #category : 'accessing' }
LuaState >> integerAt: anIndex ifNotInteger: aBlock [

	^ self liblua lua: self externalAddress tointegerx: anIndex ifNotInteger: aBlock
]

{ #category : 'accessing' }
LuaState >> liblua [

	^ liblua
]

{ #category : 'accessing' }
LuaState >> liblua: anObject [

	liblua := anObject
]

{ #category : 'accessing' }
LuaState >> load: aString [

	self liblua luaL: self externalAddress loadstring: aString
]

{ #category : 'accessing' }
LuaState >> numberAt: anIndex [ 

	^ self liblua lua: self externalAddress tonumber: anIndex
]

{ #category : 'accessing' }
LuaState >> numberAt: anIndex ifNotNumber: aBlock [

	^ self liblua lua: self externalAddress tonumberx: anIndex ifNotNumber: aBlock
]

{ #category : 'accessing' }
LuaState >> on: functionName do: aBlock [ 

	| callback |
	
	callback := self liblua fficallbackOnBlock: [ :s | aBlock value: self ].

	self liblua lua: self externalAddress register: functionName cfunction: callback.	
]

{ #category : 'private' }
LuaState >> privTypeNameOf: luaTypeId [ 

	^ self liblua
			lua: self externalAddress
			typename: luaTypeId
]

{ #category : 'accessing' }
LuaState >> protectedCallArgumentsCount: argsCount resultsCount: resultsCount [

	^ self liblua
		  lua_pcall: self externalAddress
		  nargs: argsCount
		  nresults: resultsCount
]

{ #category : 'accessing' }
LuaState >> push: anObject [

	self liblua on: self externalAddress push: anObject
]

{ #category : 'accessing' }
LuaState >> pushNewTable [ 

	^ self liblua lua_newtable: self externalAddress.
]

{ #category : 'accessing' }
LuaState >> pushNil [

	self liblua lua_pushnil: self externalAddress
]

{ #category : 'accessing' }
LuaState >> pushNumber: aNumber [

	self liblua lua: self externalAddress pushnumber: aNumber asFloat
]

{ #category : 'accessing' }
LuaState >> pushString: aString [

	self liblua lua: self externalAddress pushstring: aString
]

{ #category : 'accessing' }
LuaState >> read: index [

	^ self liblua on: self externalAddress at: index
]

{ #category : 'accessing' }
LuaState >> readGlobal: aName [ 

	^ self 
		getGlobal: aName;
		read: -1.
]

{ #category : 'accessing' }
LuaState >> registerPath: aPathString [ 

	^ self liblua
		  luaL: self externalAddress
		  dostring:
		  'package.path = package.path .. ";', aPathString, '/?.lua"'
]

{ #category : 'accessing' }
LuaState >> require: packageName [ 

	^ self liblua
		  luaL: self externalAddress
		  dostring: 'require "', packageName, '"'
]

{ #category : 'accessing' }
LuaState >> require: packageName as: aName [

	^ self liblua
		  luaL: self externalAddress
		  dostring:
		  aName , ' = require "', packageName, '"'
]

{ #category : 'accessing' }
LuaState >> setField: fieldName ofValueAt: anIndex [

	^ self liblua lua: self externalAddress set: anIndex field: fieldName
]

{ #category : 'private' }
LuaState >> setGlobal: aString [ 

	"Pops a value from the stack and sets it as the new value of global name."
	
	self liblua lua: self externalAddress setglobal: aString
]

{ #category : 'accessing' }
LuaState >> stringAt: anIndex [ 

	^ self liblua lua: self externalAddress tostring: anIndex
]

{ #category : 'accessing' }
LuaState >> tableAt: anIndex do: aBlock [

	^ self liblua table: self externalAddress at: anIndex do: aBlock
]

{ #category : 'accessing' }
LuaState >> typeIdOf: anObject [ 

	^ self liblua lua:  self externalAddress type: anObject
]

{ #category : 'accessing' }
LuaState >> typeNameOf: anObject [ 

	^ self privTypeNameOf: (self typeIdOf: anObject)
]
