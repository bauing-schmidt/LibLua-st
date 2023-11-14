Class {
	#name : 'BaselineOfLibLuast',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfLibLuast',
	#package : 'BaselineOfLibLuast'
}

{ #category : 'baselines' }
BaselineOfLibLuast >> baseline: spec [

	<baseline>
	spec for: #common do: [ "Externals.""Packages"
		spec
			package: 'LibLua';
			package: 'LibLua-Tests' ]
]
