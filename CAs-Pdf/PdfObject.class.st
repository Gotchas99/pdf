Class {
	#name : #PdfObject,
	#superclass : #PdfCommon,
	#instVars : [
		'id',
		'version',
		'content',
		'objType'
	],
	#category : #'CAs-Pdf'
}

{ #category : #comparing }
PdfObject >> <= anObj [

^	id <= anObj id
]

{ #category : #accessing }
PdfObject >> content [ ^content
]

{ #category : #api }
PdfObject >> decode [ ^content decode
]

{ #category : #accessing }
PdfObject >> id [

	^ id
]

{ #category : #initialization }
PdfObject >> initialize [ 
objType:='???'
]

{ #category : #accessing }
PdfObject >> objType [


	^ objType 
	
]

{ #category : #printing }
PdfObject >> printOn: aStream [
	"self from printOn: aStream.
	aStream nextPutAll: ' -> '.
	self to printOn: aStream"

	aStream << 'PdfObj(' << objType << '): '.
	id ifNotNil: [ aStream << id asString ].
	objType = #dict ifTrue: [ aStream << '-' << (content at: #Type ifAbsent: '***') ]
]

{ #category : #streaming }
PdfObject >> readArrayFrom: s [

	| ent arr |
	s next.
	arr := OrderedCollection new.
	[
	self skipWhitespace: s.
	s peek asCharacter = $] ] whileFalse: [
		ent := self readObjectFrom: s.
		arr add: ent ].
	"skip closing bracket"
	s next.
	self skipWhitespace: s.
	^ arr
]

{ #category : #streaming }
PdfObject >> readCommentFrom: s [
"inte gjord än"
	| str |
self halt. 	s next.
	str := (s upTo: $) charCode) asString.
	s next.
	self skipWhitespace: s.
	^ str
]

{ #category : #streaming }
PdfObject >> readDictOrStreamFrom: s [

	| tmp oldPos nextWord |
	self skipWhitespace: s.
	[ s peek asCharacter = $< ] whileTrue: [ s next ].
	tmp := self readDictionaryFrom: s.
	self skipWhitespace: s.
	oldPos := s position.
	nextWord := (s next: 6) asString.
	s position: oldPos.
	nextWord = 'stream' ifTrue: [
		tmp := self readStreamFrom: s dict: tmp ].
	^ tmp
]

{ #category : #streaming }
PdfObject >> readDictionaryFrom: s [

	| ent dict |
	dict := Dictionary new.
	[
	self skipWhitespace: s.
	s peek asCharacter = $> ] whileFalse: [
		ent := self readEntryFrom: s.
		dict add: ent ].
	s next: 2.
	self skipWhitespace: s.
	objType:='dict'.
	^ dict
]

{ #category : #streaming }
PdfObject >> readEntryFrom: s [

	| name val |
	name := self readNameFrom: s.
	val := self readObjectFrom: s.
	^name -> val
]

{ #category : #streaming }
PdfObject >> readHexStringFrom: s [

	| str |
	[ s peek asCharacter = $< ] whileTrue: [ s next ].
	str := (s upTo: $> charCode) asString.
	[ s peek asCharacter = $> ] whileTrue: [ s next ].
	self skipWhitespace: s.
	^ str
]

{ #category : #streaming }
PdfObject >> readIndirectFrom: s [

	| token |
	id := self readNumberFrom: s.
	version := self readNumberFrom: s.
	token := self readLineFrom: s.
	token = 'obj' ifFalse: [ Error signal: 'not an obj' ].
	content := self readObjectFrom: s.
	token := self readLineFrom: s.
	token = 'endobj' ifFalse: [ Error signal: 'not an endobj' ]
]

{ #category : #streaming }
PdfObject >> readIntegerFrom: s [

	| digit res |
	res := 0.
	[ (digit := s next) between: 48 and: 57 ] whileTrue: [
		res := res * 10 + (digit-48) ].
	^ res
]

{ #category : #streaming }
PdfObject >> readNameFrom: s [

	| ch |
	self skipWhitespace: s.
	ch := s next asCharacter .
	ch = $/ ifFalse: [ Error signal: 'not a name' ].
	^self readTokenFrom: s
]

{ #category : #streaming }
PdfObject >> readNumericFrom: s [

	| tmp |
	tmp := self tryReadRefFrom: s.
	tmp ifNil: [ ^ self readNumberFrom: s ] ifNotNil: [ ^ tmp ]  
]

{ #category : #streaming }
PdfObject >> readObjectFrom: s [

	| ch |
	self flag: 'Doesn''t do booleans or null'.
	self skipWhitespace: s.
	ch := s peek asCharacter.
	ch = $< ifTrue: [
		s next.
		s peek asCharacter = $<
			ifTrue: [ ^ self readDictOrStreamFrom: s ]
			ifFalse: [ ^ self readHexStringFrom: s ] ].
	ch = $/ ifTrue: [ ^ self readNameFrom: s ].
	ch = $[ ifTrue: [ ^ self readArrayFrom: s ].
	ch = $( ifTrue: [ ^ self readStringFrom: s ].
	ch = $% ifTrue: [ ^ self readCommentFrom: s ].
	ch isDigit ifTrue: [ ^ self readNumericFrom: s ].
	ch = $-  ifTrue: [ ^ self readNumericFrom: s ].
	Error signal: 'Unknown type-indicator:' , ch asString
]

{ #category : #streaming }
PdfObject >> readStreamFrom: s dict: dict [

	| token len |
	len := dict at: #Length.
	token := (self readLineFrom: s) trimmed.
	token = 'stream' ifFalse: [ Error signal: 'not a stream' ].
	content := s next: len.
	self skipWhitespace: s.
	token := self readLineFrom: s.
	token = 'endstream' ifFalse: [ Error signal: 'not an endstream' ].
	objType:='stream'.
	^ PdfStream new
		  dict: dict;
		  content: content
]

{ #category : #streaming }
PdfObject >> readStringFrom: s [

	|  str |
	s next.
	str := (s upTo: $) charCode) asString.
	s next.
	self skipWhitespace: s.
	^ str
]

{ #category : #streaming }
PdfObject >> tryReadRefFrom: s [

	| oldPos o1 o2 o3 |
	oldPos := s position.
	[
	o1 := self readNumberFrom: s.
	o2 := self readNumberFrom: s.
	o3 := self readTokenFrom: s ]
		on: Error
		do: [ :e |
			s position: oldPos.
			^ nil ].
	o3 = 'R' ifFalse: [
		s position: oldPos.
		^ nil ].
	^ {   o1 .o2 .o3 }
]
