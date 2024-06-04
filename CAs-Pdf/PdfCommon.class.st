Class {
	#name : #PdfCommon,
	#superclass : #Object,
	#category : #'CAs-Pdf'
}

{ #category : #private }
PdfCommon >> peekTokenFrom: s [

	| str oldPos |
	oldPos := s position.
	str:= self readTokenFrom: s.
	s position: oldPos.
	^ str
]

{ #category : #streaming }
PdfCommon >> readLineFrom: s [

	| line |
	self flag: 'should handle cr, lf & crlf'.
	"ascii 10 is linefeed (lf)"
	line := (s upTo: 10) asString.
	(line > '' and: [ line last = Character lf ]) ifTrue: [
		line := line allButLast ].
	(line > '' and: [ line last = Character cr ]) ifTrue: [
		line := line allButLast ].
	^ line
]

{ #category : #streaming }
PdfCommon >> readNumberFrom: s [

	| str num |
	str := self readTokenFrom: s.
	num := Number readFrom: str.
	^ num
]

{ #category : #private }
PdfCommon >> readTokenFrom: s [

	| str |
	self skipWhitespace: s.
	str := s next asCharacter asString.
	[ s peek asCharacter isPdfRegular ] whileTrue: [
		str := str , s next asCharacter asString ].
	self skipWhitespace: s.
	^ str
]

{ #category : #private }
PdfCommon >> skipWhitespace: s [

	[ s atEnd ] whileFalse: [
		s peek asCharacter isPdfWhitespace
			ifTrue: [ s skip:1 ]
			ifFalse: [ ^ self ] ]
]
