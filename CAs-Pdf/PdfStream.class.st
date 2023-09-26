Class {
	#name : #PdfStream,
	#superclass : #Object,
	#instVars : [
		'dict',
		'content'
	],
	#category : #'CAs-Pdf'
}

{ #category : #accessing }
PdfStream >> content [

	^ content
]

{ #category : #accessing }
PdfStream >> content: anObject [

	| z |
	content := anObject.
	(dict at: 'Filter') = 'FlateDecode' ifTrue: [
		z := ZLibReadStream on: content.
		"z contents asString inspect" ]
]

{ #category : #accessing }
PdfStream >> decode [

	| z |
	(dict at: 'Filter') = 'FlateDecode' ifFalse: [ ^ self ].
	z := ZLibReadStream on: content.
^	z contents asString
]

{ #category : #accessing }
PdfStream >> dict [

	^ dict
]

{ #category : #accessing }
PdfStream >> dict: anObject [

	dict := anObject
]
