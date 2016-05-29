| RuleCreator |

RuleCreator := RBTransformationRule subclass: (('TransformRule_', self from asString, '_', self to asString copyReplaceAll: ' ' with: '_') copyReplaceAll: String lf with: '') asSymbol
    category: 'AEMTransformRules'.

RuleCreator compile: 'initialize
    super initialize.
    self rewriteRule
        replace: '' ',
        self from associations first receiver, ' ', self from associations first signature,
        ' ''
        with:  '' ', self to associations first receiver, ' ', self to associations first signature, ' '' '.

