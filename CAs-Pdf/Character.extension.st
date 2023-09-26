Extension { #name : #Character }

{ #category : #'*CAs-Pdf' }
Character >> isPdfDelimiter [
	"(, ), <, >, [, ], {, }, /, and %"

	^ '()<>[]{}/%' includes: self
]

{ #category : #'*CAs-Pdf' }
Character >> isPdfEOL [

	^ #( 10  13 ) includes: self charCode
]

{ #category : #'*CAs-Pdf' }
Character >> isPdfRegular [

	^ (self isPdfDelimiter) not and: [
		  (self isPdfWhitespace) not ]
]

{ #category : #'*CAs-Pdf' }
Character >> isPdfWhitespace [

	^ #( 0 9 10 12 13 32 ) includes: self  charCode
]
