Class {
	#name : #PdfFile,
	#superclass : #PdfCommon,
	#instVars : [
		'fname',
		'header',
		'body',
		'xref',
		'trailer'
	],
	#category : #'CAs-Pdf'
}

{ #category : #accessing }
PdfFile >> fname: aString [

	fname := aString 
]

{ #category : #accessing }
PdfFile >> parse [

	(File named: fname) readStreamDo: [ :s |
		trailer := self readTrailerFrom: s.
		header := self readHeaderFrom: s.
		body := self readBodyFrom: s.
		"xref := self readXrefFrom: s" ]
]

{ #category : #accessing }
PdfFile >> parse_old [

	fname asFileReference binaryReadStreamDo: [ :s |
		
		header := self readHeaderFrom: s.
		body := self readBodyFrom: s.
		xref := self readXrefFrom: s .trailer := self readTrailerFrom: s.]
]

{ #category : #streaming }
PdfFile >> readBodyFrom: s [

	| tmp |
	tmp := OrderedCollection new.
	xref values select: [ :v | v third = $n ] thenDo: [ :v | 	s position: v first.
		tmp add: (self readObjectFrom: s) ].
	^ tmp
]

{ #category : #streaming }
PdfFile >> readHeaderFrom: s [

	| line |
	s position:0.
	line := (self readLineFrom: s) asString.
	line = '%PDF-1.7' ifFalse: [ Error signal: 'not a pdf' ].
	"consume empty line"
	"self readLineFrom: s."
	^ line
]

{ #category : #streaming }
PdfFile >> readLineFrom: s [

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
PdfFile >> readObjectFrom: s [

	| o |
	o:= PdfObject new readIndirectFrom: s.
	^o
]

{ #category : #streaming }
PdfFile >> readTokenReverseFrom: s [

	| str |
	self skipWhitespaceReverse: s.
	str := ''.
	[ s peek asCharacter isPdfWhitespace ] whileFalse: [
		str := str , s next asCharacter asString. s skip:-2 ].
	^ str reverse
]

{ #category : #streaming }
PdfFile >> readTrailerFrom: s [

	| token xrefOffset dict |
	s setToEnd.
	s skip: -1.
	token := self readTokenReverseFrom: s.
	token = '%%EOF' ifFalse: [ Error signal: 'not %%EOF in trailer' ].
	token := self readTokenReverseFrom: s.
	xrefOffset := Number readFrom: token.
	token := self readTokenReverseFrom: s.
	token = 'startxref' ifFalse: [
		Error signal: 'not startxref in trailer' ].
	xref := self readXrefFrom: s atPosition: xrefOffset.
	token := self readTokenFrom: s.
	token = 'trailer' ifFalse: [ Error signal: 'not trailer' ].
	^ dict := PdfObject new readDictOrStreamFrom: s
]

{ #category : #streaming }
PdfFile >> readTrailerFrom_old: s [

	| dict |
	dict := PdfObject new readDictOrStreamFrom: s.
	(self readLineFrom: s) = 'startxref' ifFalse: [
		Error signal: 'not startxref in trailer' ].
	self readLineFrom: s.
	(self readLineFrom: s) = '%%EOF' ifFalse: [
		Error signal: 'not %%EOF in trailer' ].
	^ dict
]

{ #category : #streaming }
PdfFile >> readXrefFrom: s [

	| token dict firstNo noOfObjects num gen type |
	token := self readTokenFrom: s.
	token = 'xref' ifFalse: [ Error signal: 'not xref' ].
	dict := Dictionary new.
	firstNo := self readNumberFrom: s.
	noOfObjects := self readNumberFrom: s.
	firstNo to: firstNo + noOfObjects - 1 do: [ :i |
		self skipWhitespace: s.
		num := self readNumberFrom: s.
		gen := self readNumberFrom: s.
		s skip: 1.
		type := s next asCharacter.
		dict at: i put: {
				num.
				gen.
				type } ].
	self skipWhitespace: s.
	^ dict
]

{ #category : #streaming }
PdfFile >> readXrefFrom: s atPosition: anInteger [

	s position: anInteger.
	^self readXrefFrom: s
]

{ #category : #streaming }
PdfFile >> skipWhitespaceReverse: s [

	[ s position = 0 ] whileFalse: [
		s peek asCharacter isPdfWhitespace
			ifTrue: [ s skip: -1 ]
			ifFalse: [ ^ self ] ]
]
