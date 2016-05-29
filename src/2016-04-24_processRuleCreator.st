self do: [:aemRule | 
	| RuleCreator ruleRegex |
	ruleRegex := '.*(\?|\:).+'.
	(( aemRule from asString matchesRegex: ruleRegex ) and: ( aemRule to asString matchesRegex: ruleRegex )) ifTrue: [Transcript show: aemRule asString] ifFalse: [
		RuleCreator := RBTransformationRule subclass: (('TransformRule_', aemRule from asString, '_', aemRule to asString copyReplaceAll: ' ' with: '_') copyReplaceAll: String lf with: '') asSymbol
		category: 'AEMTransformRules'.

	RuleCreator compile: 'initialize
		super initialize.
		self rewriteRule
			replace: '' ',
			aemRule from associations first receiver, ' ', aemRule from associations first signature,
			' ''
			with:  '' ', aemRule to associations first receiver, ' ', aemRule to associations first signature, ' '' '.
	].
].