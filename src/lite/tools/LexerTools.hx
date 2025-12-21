package lite.tools;

class LexerTools {
    public static function isUnary(token:Token):Bool
    {
        return switch (token)
        {
            case TOpLogicalNot, TOpAdd, TOpSubtract, TOpBitwiseNot, TOpIncrement, TOpDecrement, TOpExponentiate:
                true;
            case _:
                false;
        }
    }
    public static function isPostfixUnary(token:Token):Bool
    {
        return switch (token)
        {
            case TOpIncrement, TOpDecrement, TOpExponentiate:
                true;
            case _:
                false;
        }
    }
    public static function fromIdent(token:Token):Null<String>
    {
        return switch (token)
        {
            case TIdentifier(string):
                string;
            case _:
                null;
        }
    }
}