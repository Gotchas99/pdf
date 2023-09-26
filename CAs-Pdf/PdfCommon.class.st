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
PdfCommon >> readNumberFrom: s [

	| str num |
	str := self readTokenFrom: s.
	num := Number readFrom: str.
	^ num
]

{ #category : #private }
PdfCommon >> readTokenFrom: s [

	| str |	self skipWhitespace: s.
	str := ''.
	[ s peek asCharacter isPdfWhitespace ] whileFalse: [
		str := str , s next asCharacter asString ].
	^ str
]

{ #category : #private }
PdfCommon >> skipWhitespace: s [

	[ s atEnd ] whileFalse: [
		s peek asCharacter isPdfWhitespace
			ifTrue: [ s skip:1 ]
			ifFalse: [ ^ self ] ]
]
