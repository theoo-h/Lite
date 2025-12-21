package lite;

import haxe.exceptions.NotImplementedException;
import lite.Token;

class Lexer {
    public function new() {}

    var tokens:Array<Token>;
    var code:String;
    var position:Int;

    public function parse(code:String)
    {
        this.code = code;
        this.tokens = [];
        this.position = 0;

        while (!StringTools.isEof(currentCharacter()))
        {
            final token = nextToken();

            if (token != null)
                tokens.push(token);
        }

        tokens.push(TEof);

        return tokens;
    }

    function nextToken()
    {
        final c = currentCharacter();
        
        switch (c)
        {
            case isStringDelimiter(c) => true:
                return parseString();
            case isAlpha(c) => true:
                return parseIdent();
            case isDigit(c)=> true:
                return parseNumber();
            case isSymbol(c)=> true:
                return parseSymbol();
            case isWhite(c) => true:
                consume();
                return null;
            default:
                throw 'qe paso pa: ' + String.fromCharCode(currentCharacter());
        }
    }

    function parseString()
    {
        final del = currentCharacter();
        consume();

        var b = new StringBuf();

        while (currentCharacter() != del)
        {
            final char = currentCharacter();

            if (char == '\\'.code)
            {
                consume();
                switch (currentCharacter())
                {
                    case 'n'.code:
                        b.add('\n');
                    case 'r'.code:
                        b.add('\r');
                    case 't'.code:
                        b.add('\t');
                    case '\\'.code:
                        b.add('\\');
                    case '\''.code:
                        b.add('\'');
                    case '\"'.code:
                        b.add('\"');
                    case _:
                        throw 'secuencia de escape invalida: ${String.fromCharCode(currentCharacter())}';
                }
                consume();
                continue;
            }

            b.addChar(char);

            consume();
        }
        consume();

        var kw = TConst(CString(b.toString()));
        b = null;
        return kw;
    }

    // simbolos y operadores
    function parseSymbol()
    {
        return switch (currentCharacter())
        {
            case '+'.code:
                consume();
                if ('='.code == currentCharacter())
                {
                    consume();
                    TOpAddAssign;
                } else if ('+'.code == currentCharacter()) 
                {
                    consume();
                    TOpIncrement;
                } else
                    TOpAdd;
            case '-'.code:
                consume();
                if ('='.code == currentCharacter())
                {
                    consume();
                    TOpSubtractAssign;
                } else if ('-'.code == currentCharacter()) 
                {
                    consume();
                    TOpDecrement;
                } else
                    TOpSubtract;
            case '*'.code:
                consume();
                if ('='.code == currentCharacter())
                {
                    consume();
                    TOpMultAssign;
                } else if ('-'.code == currentCharacter()) 
                {
                    consume();
                    TOpExponentiate;
                } else
                    TOpMult;
            case '/'.code:
                consume();
                if ('='.code == currentCharacter())
                {
                    consume();
                    TOpDivideAssign;
                } else
                    TOpDivide;
            case '%'.code:
                consume();
                if ('='.code == currentCharacter())
                {
                    consume();
                    TOpModAssign;
                } else
                    TOpMod;
            case ':'.code:
                consume();
                TSColon;
            case ';'.code:
                consume();
                TSSemiColon;
            case ','.code:
                consume();
                TSComma;
            case '.'.code:
                consume();
                TSDot;
            case '('.code:
                consume();
                TSLParen;
            case ')'.code:
                consume();
                TSRParen;
            case '{'.code:
                consume();
                TSLBrace;
            case '}'.code:
                consume();
                TSRBrace;
            case '['.code:
                consume();
                TSLBracket;
            case ']'.code:
                consume();
                TSRBracket;
            case '='.code:
                consume();
                if ('='.code == currentCharacter())
                {
                    consume();
                    TOpEqual;
                } else
                    TOpAssign;
            case '<'.code:
                consume();
                if ('='.code == currentCharacter())
                {
                    consume();
                    TOpLessEqualThan;
                } else
                    TOpLessThan;
            case '>'.code:
                consume();
                if ('='.code == currentCharacter())
                {
                    consume();
                    TOpGreaterEqualThan;
                } else
                    TOpGreaterThan;
            case '!'.code:
                consume();
                if ('='.code == currentCharacter())
                {
                    consume();
                    TOpNotEqual;
                } else
                    TOpLogicalNot;
            case _:
                throw new NotImplementedException(String.fromCharCode(currentCharacter()));
        }
    }
    function parseNumber()
    {
        var b = new StringBuf();
        b.addChar(currentCharacter());

        consume();

        var floating = false;

        while (true)
        {
            final c = currentCharacter();
            if (isDigit(c))
            {
                b.addChar(c);
                consume();
            } else if (c == '.'.code) {
                if (floating)
                    throw 'doble punto decimal';
                floating = true;

                b.addChar(c);
                consume();
            } else {
                break;
            }
        }
        final tk:Token = TConst(floating ? CFloat(Std.parseFloat(b.toString())) : CInt(Std.parseInt(b.toString())));

        b = null;
        return tk;
    }
    function parseIdent()
    {
        var b = new StringBuf();
        b.addChar(currentCharacter());

        consume();

        while (true)
        {
            final c = currentCharacter();
            if (isAlpha(c) || isDigit(c))
            {
                b.addChar(currentCharacter());
                consume();
            } else {
                break;
            }
        }

        final res = b.toString();
        final possibleKw = resolveKeyword(res);

        final tk = possibleKw != null ? possibleKw : TIdentifier(res);

        b = null;
        return tk;
    }

    function resolveKeyword(res:String)
    {
        return switch (res)
        {
            case 'class': TKClass;

            case 'var': TKVar;
            case 'const': TKConst;
            
            case 'fun': TKFunction;

            case 'public': TKPublic;
            case 'static': TKStatic;

            case 'return': TKReturn;
            case 'break': TKBreak;
            case 'continue': TKContinue;

            case _:
                null;
        }
    }

    function isStringDelimiter(c:Int)
        return c == '\''.code || c == '\"'.code;
    
    function isAlpha(c:Int)
        return (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == '_'.code;

    function isDigit(c:Int)
        return (c >= 48  && c <= 57);

    function isWhite(c:Int)
		return c == ' '.code || c == '\t'.code || c == '\n'.code || c == '\r'.code;

	function isSymbol(c:Int)
		return c == '+'.code || c == '-'.code || c == '*'.code || c == '/'.code || c == '%'.code || c == '='.code || c == '!'.code
			|| c == '<'.code || c == '>'.code || c == '&'.code || c == '|'.code || c == '^'.code || c == '~'.code || c == '('.code
			|| c == ')'.code || c == '['.code || c == ']'.code || c == '{'.code || c == '}'.code || c == ';'.code || c == ':'.code
			|| c == ','.code || c == '.'.code || c == '?'.code;

    function currentCharacter():Int
        return StringTools.fastCodeAt(code, position);

    function peek():Int
        return StringTools.fastCodeAt(code, position + 1);

    function consume():Int
    {
        return ++position;
    }
}