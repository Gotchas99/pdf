Class {
	#name : #PdfStream,
	#superclass : #Object,
	#instVars : [
		'dict',
		'content',
		'opCodes'
	],
	#category : #'CAs-Pdf'
}

{ #category : #parsing }
PdfStream >> addOp: opCode stack: stack [

	| arr param |
	self flag: 'remove initOps'.
	self initOps.
	param := opCodes at: opCode.
	arr := Array new: 1 + param.
	arr at: 1 put: opCode.
	2 to: param + 1 do: [ :ix | arr at: ix put: stack pop ].
	^ arr
]

{ #category : #accessing }
PdfStream >> content [

	^ content
]

{ #category : #accessing }
PdfStream >> content: anObject [

	
	content := anObject.
	"(dict at: 'Filter') = 'FlateDecode' ifTrue: [
		z := ZLibReadStream on: content]"
		"z contents asString inspect" 
]

{ #category : #accessing }
PdfStream >> decode [

	^self decodeBytes  asString
]

{ #category : #accessing }
PdfStream >> decodeBytes [

	| z |
	(dict at: 'Filter') = 'FlateDecode' ifFalse: [ ^ content asString ].
	z := ZLibReadStream on: content.
	^ z contents 
]

{ #category : #accessing }
PdfStream >> dict [

	^ dict
]

{ #category : #accessing }
PdfStream >> dict: anObject [

	dict := anObject
]

{ #category : #initialization }
PdfStream >> distinctOperations [
^(self parseTokens collect:[:each|each first])asSet.
]

{ #category : #initialization }
PdfStream >> initOps [

	opCodes := Dictionary new.
	"c = curve to 
	cm = concatenate to current (CTM) transform matrix
	f = fill
	h = close path 
	l = line to
	m = move to
	n = end path without filling or stroking
	q = save graphics state
	Q = restore graphics state
	rg = setrgbcolor
	W* = even-odd clipping"
	opCodes
		at: #cm put: 6;
		at: #q put: 0;
		at: #Q put: 0;
		at: #m put: 2;
		at: #l put: 2;
		at: #h put: 0;
		at: 'W*' put: 0;
		at: #n put: 0;
		at: #rg put: 3;
		at: #c put: 6;
		at: #f put: 0
]

{ #category : #initialization }
PdfStream >> initialize [ 
self initOps 
]

{ #category : #accessing }
PdfStream >> isDecode [

	^	(dict at: 'Filter') = 'FlateDecode' 
]

{ #category : #parsing }
PdfStream >> parseTokens [

	| tok ops stack num |
	tok := self tokens.
	ops := OrderedCollection new.
	stack := Stack new.
	tok readStreamDo: [ :s |
		s do: [ :t |
			[
			num := t asNumber.
			stack push: num ]
				on: Error
				do: [ :e | ops add: (self addOp: t stack: stack) ] ] ].
	^ ops
]

{ #category : #parsing }
PdfStream >> tokens [

	| arr o |
	arr := OrderedCollection new.
	self decode readStreamDo: [ :s | [ s atEnd ] whileFalse: [o:= PdfObject new readTokenFrom: s. arr add: o ] ].
	^ arr
]
