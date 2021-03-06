Class {
	#name : #ArtTreeTest,
	#superclass : #TestCase,
	#instVars : [
		'tree',
		'words'
	],
	#classVars : [
		'Charset',
		'Words'
	],
	#category : #'AdaptiveRadixTree-Tests-Core'
}

{ #category : #'initialize - event' }
ArtTreeTest class >> initialize [
	Charset := ByteArray new: 256.
	1 to: 255 do: [ :i | Charset at: i put: i ]
]

{ #category : #accessing }
ArtTreeTest class >> resetWords [
	<script>
	Words := nil
]

{ #category : #accessing }
ArtTreeTest class >> words [
	^ Words
		ifNil: [ Words := ('/usr/share/dict/words' asFileReference contents
				splitOn: Character lf) select: [ :each | each isNotEmpty ].
			Words := Words shuffled copyFrom: 1 to: 3333
			]
]

{ #category : #accessing }
ArtTreeTest >> defaultTimeLimit [
	^ 360 seconds
]

{ #category : #running }
ArtTreeTest >> setUp [
	super setUp.
	tree := ArtTree new
]

{ #category : #tests }
ArtTreeTest >> stringFrom: start to: end [
	^ (Charset copyFrom: start to: end) asString
]

{ #category : #tests }
ArtTreeTest >> testGrowFrom16to48 [
	| data offset root prefix |

	offset := 96.
	prefix := 'pfx-'.

	data := (1 to: 17)
		collect: [ :i | prefix , (self stringFrom: offset + i to: offset + i + 4) ].

	data do: [ :each | tree at: each put: each ].

	root := tree root.
	root should beKindOf: ArtNode48.
	data do: [ :each | (tree at: each) should equal: each ].

	root prefixSize should equal: prefix size.
	(root prefix first: prefix size) should equal: prefix asByteArray.

	(root children select: #isNotNil) size should equal: data size.

	(root children first: 17)
		withIndexDo: [ :child :index | 
			| byte |

			child should beKindOf: ArtLeafNode.
			child key should
				equal: (data at: index) asByteArray nullTerminated.
			child value should equal: (data at: index).
			child parent should be: root.
			byte := child key at: prefix size + 1.
			(root keys at: byte + 1) should equal: index ]
]

{ #category : #tests }
ArtTreeTest >> testGrowFrom48to256 [
	| data offset root prefix children |

	offset := 96.
	prefix := 'pfx-'.

	data := (1 to: 49)
		collect: [ :i | prefix , (self stringFrom: offset + i to: offset + i + 4) ].

	data do: [ :each | tree at: each put: each ].

	root := tree root.
	root should beKindOf: ArtNode256.
	data do: [ :each | (tree at: each) should equal: each ].

	root prefixSize should equal: prefix size.
	(root prefix first: prefix size) should equal: prefix asByteArray.

	root children
		withIndexDo:
			[ :child :index | child ifNotNil: [ (child key at: prefix size + 1) should equal: index - 1 ] ].

	(root children select: #isNotNil) size should equal: data size.

	children := root children select: #isNotNil.
	children size should equal: 49.
	children
		withIndexDo: [ :child :index | 
			| byte |

			child should beKindOf: ArtLeafNode.
			child key should
				equal: (data at: index) asByteArray nullTerminated.
			child value should equal: (data at: index).
			child parent should be: root.
			byte := child key at: prefix size + 1 ]
]

{ #category : #tests }
ArtTreeTest >> testGrowFrom4to16 [
	| data offset root prefix |

	offset := 96.
	prefix := 'pfx-'.

	data := (1 to: 5)
		collect: [ :i | prefix , (self stringFrom: offset + i to: offset + i + 4) ].

	data do: [ :each | tree at: each put: each ].

	root := tree root.
	root should beKindOf: ArtNode16.
	data do: [ :each | (tree at: each) should equal: each ].

	root prefixSize should equal: prefix size.
	(root prefix first: prefix size) should equal: prefix asByteArray.

	(root keys first: 5) should
		equal:
			(data
				collect: [ :each | (each at: prefix size + 1) asInteger ]
				as: ByteArray).
				
	(root children first: 5)
		withIndexDo: [ :child :index | 
			child should beKindOf: ArtLeafNode.
			child key should
				equal: (data at: index) asByteArray nullTerminated.
			child value should equal: (data at: index).
			child parent should be: root ]
]

{ #category : #tests }
ArtTreeTest >> testInsert1 [
	tree at: 'hello' put: 'world'.
	tree size should equal: 1.
	tree root should beKindOf: ArtLeafNode.
	tree root key should equal: 'hello' asByteArray nullTerminated.
	tree root value should equal: 'world'.
	(tree at: 'hello') should equal: 'world'.
]

{ #category : #tests }
ArtTreeTest >> testInsert1Remove1 [
	tree at: 'hello' put: 'world'.
	tree size should equal: 1.
	tree removeKey: 'hello'.
	tree size should equal: 0.
	tree root should be: nil
]

{ #category : #tests }
ArtTreeTest >> testInsert2Identical [
	tree at: 'abc' put: 'ABC'.
	tree at: 'abc' put: 'ABC'.
	tree size should equal: 1.

	tree root should beKindOf: ArtLeafNode
]

{ #category : #tests }
ArtTreeTest >> testInsert2Remove1 [
	tree at: 'hello' put: 'world'.
	tree at: 'good' put: 'bye'.
	tree size should equal: 2.
	tree removeKey: 'hello'.
	tree size should equal: 1.
	(tree at: 'good') should equal: 'bye'.
	tree root should beKindOf: ArtLeafNode
]

{ #category : #tests }
ArtTreeTest >> testInsert2Remove2 [
	tree at: 'hello' put: 'world'.
	tree at: 'good' put: 'bye'.
	tree size should equal: 2.
	tree removeKey: 'hello'.
	tree removeKey: 'good'.
	tree size should equal: 0.
	tree root should be: nil
]

{ #category : #tests }
ArtTreeTest >> testInsert2Similar [
	| root firstChild secondChild |

	tree at: 'abc' put: 'ABC'.
	tree at: 'abd' put: 'ABD'.
	tree size should equal: 2.

	root := tree root.
	root should beKindOf: ArtNode4.
	root size should equal: 2.
	(root prefix copyFrom: 1 to: 2) should equal: 'ab' asByteArray.

	firstChild := root children first.
	firstChild should beKindOf: ArtLeafNode.
	firstChild key should equal: 'abc' asByteArray nullTerminated.
	firstChild value should equal: 'ABC'.
	
	secondChild := root children second.
	secondChild should beKindOf: ArtLeafNode.
	secondChild key should equal: 'abd' asByteArray nullTerminated.
	secondChild value should equal: 'ABD'
]

{ #category : #tests }
ArtTreeTest >> testInsert3Dissimilar [
	| root firstChild secondChild thirdChild |

	tree at: 'alice' put: 'Alice'.
	tree at: 'bob' put: 'Bob'.
	tree at: 'carl' put: 'Carl'.
	tree size should equal: 3.

	root := tree root.
	root should beKindOf: ArtNode4.
	root size should equal: 3.
	root prefix asSet should equal: (Set with: 0).

	firstChild := root children first.
	firstChild should beKindOf: ArtLeafNode.
	firstChild key should equal: 'alice' asByteArray nullTerminated.
	firstChild value should equal: 'Alice'.

	secondChild := root children second.
	secondChild should beKindOf: ArtLeafNode.
	secondChild key should equal: 'bob' asByteArray nullTerminated.
	secondChild value should equal: 'Bob'.

	thirdChild := root children third.
	thirdChild should beKindOf: ArtLeafNode.
	thirdChild key should equal: 'carl' asByteArray nullTerminated.
	thirdChild value should equal: 'Carl'
]

{ #category : #tests }
ArtTreeTest >> testInsert3Dissimilar2 [
	| root firstChild secondChild thirdChild |

	tree at: 'Charadrii' put: 'Charadrii'.
	tree at: 'tamable' put: 'tamable'.
	tree at: 'lengthy' put: 'lengthy'.
	tree size should equal: 3.

	root := tree root.
	root should beKindOf: ArtNode4.
	root size should equal: 3.
	root prefix asSet should equal: (Set with: 0).

	firstChild := root children first.
	firstChild should beKindOf: ArtLeafNode.
	firstChild key should equal: 'Charadrii' asByteArray nullTerminated.
	firstChild value should equal: 'Charadrii'.

	secondChild := root children second.
	secondChild should beKindOf: ArtLeafNode.
	secondChild key should equal: 'lengthy' asByteArray nullTerminated.
	secondChild value should equal: 'lengthy'.

	thirdChild := root children third.
	thirdChild should beKindOf: ArtLeafNode.
	thirdChild key should equal: 'tamable' asByteArray nullTerminated.
	thirdChild value should equal: 'tamable'
]

{ #category : #tests }
ArtTreeTest >> testInsertAndRemoveDictWords [
	self words do: [ :word | tree at: word put: word ].
	self words
		do: [ :word | 
			| oldCount node parent |

			oldCount := tree size.

			node := tree nodeAt: word.
			node should not be: nil.
			parent := node parent.
			parent should not be: nil.

			(tree removeKey: word ifAbsent: [ nil ]) should not be: nil.
			tree size should equal: oldCount - 1.
			(tree includes: word) should not be.

			(tree allNodes
				detect: [ :each | 
					(each isKindOf: ArtContainerNode)
						and: [ each size < each class minSize ] ]
				ifNone: [ nil ]) should be: nil.

			[ tree removeKey: word ] should raise: Error ]
]

{ #category : #tests }
ArtTreeTest >> testInsertDictWords [
	self class words
		do: [ :word | 
			| node |

			tree at: word put: word.
			(tree at: word) should equal: word.
			node := tree nodeAt: word.
			node should beKindOf: ArtLeafNode.
			node value should equal: word ]
]

{ #category : #tests }
ArtTreeTest >> testInsertFrom: start to: end expectedType: aType [
	start to: end do: [ :i | 
		| s |

		s := self stringFrom: i to: i + 1.
		tree at: s put: s.
		(tree at: s) should equal: s ].
	tree size should equal: end - start + 1.

	tree root size should equal: end - start + 1.
	tree root should beKindOf: aType.

	start to: end do: [ :i | 
		| s |

		s := self stringFrom: i to: i + 1.
		(tree at: s) should equal: s ]
]

{ #category : #tests }
ArtTreeTest >> testInsertMany [
	self testInsertFrom: 1 to: 2 expectedType: ArtNode4.
	self testInsertFrom: 1 to: 4 expectedType: ArtNode4.
	self testInsertFrom: 1 to: 5 expectedType: ArtNode16.
	self testInsertFrom: 1 to: 16 expectedType: ArtNode16.
	self testInsertFrom: 1 to: 17 expectedType: ArtNode48.
	self testInsertFrom: 1 to: 48 expectedType: ArtNode48.
	self testInsertFrom: 1 to: 49 expectedType: ArtNode256.
	self testInsertFrom: 1 to: 255 expectedType: ArtNode256
]

{ #category : #tests }
ArtTreeTest >> testInsertTwice [
	| root firstChild secondChild thirdChild |

	tree at: 'Charadrii' put: 'Charadrii'.
	tree at: 'tamable' put: 'tamable'.
	tree at: 'lengthy' put: 'lengthy'.
	tree at: 'Charadrii' put: 'Charadrii'.
	tree at: 'tamable' put: 'tamable'.
	tree at: 'lengthy' put: 'lengthy'.
	tree size should equal: 3.

	root := tree root.
	root should beKindOf: ArtNode4.
	root size should equal: 3.
	root prefix asSet should equal: (Set with: 0).

	firstChild := root children first.
	firstChild should beKindOf: ArtLeafNode.
	firstChild key should equal: 'Charadrii' asByteArray nullTerminated.
	firstChild value should equal: 'Charadrii'.

	secondChild := root children second.
	secondChild should beKindOf: ArtLeafNode.
	secondChild key should equal: 'lengthy' asByteArray nullTerminated.
	secondChild value should equal: 'lengthy'.

	thirdChild := root children third.
	thirdChild should beKindOf: ArtLeafNode.
	thirdChild key should equal: 'tamable' asByteArray nullTerminated.
	thirdChild value should equal: 'tamable'
]

{ #category : #tests }
ArtTreeTest >> testRemoveNonExistingFromLeaf [
	tree at: 'foo' put: 'Foo'.
	(tree removeKey: 'fooz' ifAbsent: [ nil ]) should equal: nil
]

{ #category : #tests }
ArtTreeTest >> testShrinkFoldingFrom16to4 [
	| data root |

	data := #('pitifully' 'pileous' 'pileweed' 'pichuric' 'pictorialness' 'pippin' 'piecette').
	data do: [ :word | tree at: word put: word ].
	tree size should equal: data size.
	data
		withIndexDo: [ :word :index | 
			| child count |

			count := tree size.
			child := tree removeKey: word ifAbsent: [ nil ].
			child should not be: nil.
			tree size should equal: count - 1.

			root := tree root.
			index = data size
				ifTrue: [ root should be: nil ]
				ifFalse: [ index = (data size - 1)
						ifTrue: [ root isLeaf should be ]
						ifFalse: [ root isLeaf
								ifFalse: [ (root size between: root class minSize and: root class maxSize)
										should be ] ] ] ]
]

{ #category : #tests }
ArtTreeTest >> testShrinkFrom16To4 [
	| data offset |
	
	offset := 97.
	data := (1 to: 5) collect: [ :i | self stringFrom: offset + i to: offset + i + 3 ].
	data do: [ :word | tree at: word put: word ].
	tree size should equal: 5.
	tree removeKey: data last.
	tree size should equal: 4.
	tree root should beKindOf: ArtNode4
]

{ #category : #tests }
ArtTreeTest >> testShrinkFrom256To48 [
	self testShrinkFrom: 49 to: 48.
	tree root should beKindOf: ArtNode48
]

{ #category : #tests }
ArtTreeTest >> testShrinkFrom48To16 [
	| data offset |
	
	offset := 97.
	data := (1 to: 17) collect: [ :i | self stringFrom: offset + i to: offset + i + 3 ].
	data do: [ :word | tree at: word put: word ].
	tree size should equal: 17.
	tree removeKey: data last.
	tree size should equal: 16.
	tree root should beKindOf: ArtNode16
]

{ #category : #tests }
ArtTreeTest >> testShrinkFrom4ToLeaf [
	tree at: 'abc' put: 'ABC'.
	tree at: 'zba' put: 'zba'.
	tree removeKey: 'abc'.
	tree size should equal: 1.
	tree root should beKindOf: ArtLeafNode.
	tree root key should equal: 'zba' asByteArray nullTerminated.
	tree root value should equal: 'zba'
]

{ #category : #tests }
ArtTreeTest >> testShrinkFrom: fromSize to: toSize [
	| data offset |

	offset := 97.
	data := (1 to: fromSize)
		collect: [ :i | self stringFrom: offset + i to: offset + i + 3 ].
	data do: [ :word | tree at: word put: word ].
	tree size should equal: fromSize.
	fromSize - toSize timesRepeat: [ tree removeKey: data last ].
	tree size should equal: toSize
]

{ #category : #tests }
ArtTreeTest >> testShrinkFromLeafToNil [
	tree at: 'abc' put: 'ABC'.
	tree removeKey: 'abc'.
	tree size should equal: 0.
	tree root should be: nil.
]

{ #category : #accessing }
ArtTreeTest >> words [
	^ self class words
]
