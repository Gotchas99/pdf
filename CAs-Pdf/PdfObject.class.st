Class {
	#name : #PdfObject,
	#superclass : #PdfCommon,
	#instVars : [
		'id',
		'version',
		'content'
	],
	#category : #'CAs-Pdf'
}

{ #category : #api }
PdfObject >> decode [ ^content decode
]

{ #category : #printing }
PdfObject >> printOn: aStream [
	"self from printOn: aStream.
	aStream nextPutAll: ' -> '.
	self to printOn: aStream"

	aStream << 'PdfObj: '.
	id ifNotNil: [ aStream << id asString ]
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
		self skipWhitespace: s.version := self readNumberFrom: s.
	self skipWhitespace: s.	token := self readLineFrom: s.
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
PdfObject >> readLineFrom: s [

	| line |
	self flag: 'should handle cr, lf & crlf'.
	"ascii 10 is linefeed (lf)"
	line := (s upTo: 10) asString.
	"s next."
	^ line
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
	ch isDigit ifTrue: [ ^ self readNumericFrom: s ].
	self halt
]

{ #category : #streaming }
PdfObject >> readStreamFrom: s dict: dict [

	| token len |
	len := dict at: #Length.
	token := self readLineFrom: s.
	token = 'stream' ifFalse: [ Error signal: 'not a stream' ].
	content := s next: len.
	self skipWhitespace: s.
	token := self readLineFrom: s.
	token = 'endstream' ifFalse: [ Error signal: 'not an endstream' ].
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
