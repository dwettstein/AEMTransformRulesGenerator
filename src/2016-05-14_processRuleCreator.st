| numberOfSkippedRules |

numberOfSkippedRules := 0.

self do: [:aemRule | 
	| aemTransformRule className ruleType fromSignatureSize toSignatureSize isFromReceiverUnknown isToReceiverUnknown isBothSignatureUnary isTransformable fromReceiverName toReceiverName |
	
	"Possible ruleTypes: unaryRename, unaryWildcardRename, keywordRename, keywordWildcardRename"
	className := ('AEMTransformRule_', aemRule from asString, '_', aemRule to asString) copyWithRegex: '\s|[?:=]' matchesReplacedWith: '_'.
	
	fromSignatureSize := (aemRule from associations first signature asString) count: [ :char | char = $: ].
	toSignatureSize := (aemRule to associations first signature asString) count: [ :char | char = $: ].
	
	isFromReceiverUnknown := ( aemRule from associations first receiver asString matchesRegex: '\?' ).
	isToReceiverUnknown := ( aemRule to associations first receiver asString matchesRegex: '\?' ).

	isBothSignatureUnary := ( ( aemRule from associations first signature asSymbol isUnary ) and: ( aemRule to associations first signature asSymbol isUnary ) ).
	
	"First check if we can transform the current rule. Not transformable if signature size changed or if fromReceiver is known but toReceiver is unknown."
	isTransformable := (fromSignatureSize = toSignatureSize) and: (((isFromReceiverUnknown not) and: isToReceiverUnknown) not).

	isTransformable
		ifTrue: [  
			"Check if both signatures are unary:"
			isBothSignatureUnary
				ifTrue: [
					(isFromReceiverUnknown and: isToReceiverUnknown)
						ifTrue: [ ruleType := 'unaryWildcardRename'. ]
						ifFalse: [ ruleType := 'unaryRename'. ].
				]
				ifFalse: [ 
					(isFromReceiverUnknown and: isToReceiverUnknown)
						ifTrue: [ ruleType := 'keywordWildcardRename'. ] 
						ifFalse: [ ruleType := 'keywordRename'. ].
				].
			
			Transcript logCr: (ruleType, ' : ', className).
			
			aemTransformRule := RBTransformationRule subclass: className asSymbol
				category: 'AEMTransformRules'.
			aemTransformRule compile: 'name 
				^ ''', aemRule from asString, ' => ', aemRule to asString, ''''.
			aemTransformRule compile: 'category 
				^ ''generatedAEMTransformRules'''.
			aemTransformRule compile: 'group 
				^ ''generatedAEMTransformRules'''.
			
			fromReceiverName := (aemRule from associations first receiver asString) copyReplaceAll: '?' with: '``@object'.
			toReceiverName := (aemRule to associations first receiver asString) copyReplaceAll: '?' with: '``@object'.
			
			"Create subclasses of RBTransformationRule according to ruleType:"
			(ruleType = 'unaryRename' or: ruleType = 'unaryWildcardRename') ifTrue: [ 
				aemTransformRule compile: 'initialize
					super initialize.
					self rewriteRule
						replace: '' ', fromReceiverName, ' ', aemRule from associations first signature asString, ' ''
						with: '' ', toReceiverName, ' ', aemRule to associations first signature asString, ' '' '.
			].
		
			(ruleType = 'keywordRename' or: ruleType = 'keywordWildcardRename') ifTrue: [ 
				| fromMessages toMessages counter |
				fromMessages := ''.
				counter := 0.
				(aemRule from associations first signature asString subStrings: ':') do: [ :keyword | fromMessages := fromMessages, ' ', keyword, ': ``@arg', counter asString. counter := counter + 1. ].
				
				toMessages := ''.
				counter := 0.
				(aemRule to associations first signature asString subStrings: ':') do: [ :keyword | toMessages := toMessages, ' ', keyword, ': ``@arg', counter asString. counter := counter + 1. ].
				
				aemTransformRule compile: 'initialize
					super initialize.
					self rewriteRule
						replace: '' ', fromReceiverName, ' ', fromMessages, ' ''
						with: '' ', toReceiverName, ' ', toMessages, ' '' '.
			].
			
		]
		ifFalse: [
			Transcript logCr: 'INFO: The rule "', className,'" cannot be generated because the number of method arguments changed from "', (aemRule from associations first signature asString), '" to "', (aemRule to associations first signature asString), '".'.
			numberOfSkippedRules := numberOfSkippedRules + 1.
		].
].

Transcript logCr: ''.
Transcript logCr: 'Skipped "',  numberOfSkippedRules asString, '" rules totally.'.