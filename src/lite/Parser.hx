package lite;

import lite.Expr.FunArgument;
import haxe.exceptions.NotImplementedException;

using lite.tools.LexerTools;

// TODO: usar iteracion en todos los niveles de precendencia posible para reducir stack frames
class Parser {

    public function new() {}

    var tokens:Array<Token>;
    var position:Int;

    var ast:Array<Expr>;

    public function parse(tokens:Array<Token>)
    {
        this.tokens = tokens;

        this.position = 0;
        this.ast = [];

        while (currentToken() != TEof)
        {
            var node = nextExpr();

            if (node != null)
            {
                ast.push(node);
            }
        }

        return ast;
    }

    function nextExpr():Null<Expr>
    {
        return switch (currentToken()) {
            case TKVar:
                parseVarDecl();
            case TKFunction:
                parseFuncDecl();
            case TKReturn, TKContinue, TKBreak:
                parseEscape();
            case TSLBrace:
                parseBlock();
            case _:
                var _ = parseExpr();
                expect(TSSemiColon);
                _;
        }
    }

    function parseVarDecl():Expr
    {
        consume();

        var name:String = expectIdent();

        expect(TOpAssign);

        var expr = parseExpr();

        expect(TSSemiColon);

        return {
            expr: EVarDecl(name, expr),
            position: null
        };
    }

    function parseFuncDecl():Expr
    {
        // keyword
        consume();

        var name:String = expectIdent();

        expect(TSLParen);

        var args:Array<FunArgument> = [];

        while (!match(TSRParen))
        {
            var argName:String = expectIdent();

            args.push({
                name: argName
            });

            if (match(TSComma))
                consume();
        }

        consume();

        var block = parseBlock();

        return {
            expr: EFunDecl(name, args, block),
            position: null
        };
    }

    function parseEscape():Expr
    {
        return switch (currentToken())
        {
            case TKReturn:
                consume();

                var _ = parseExpr();
                expect(TSSemiColon);

                {
                    expr: EEscape(Return, _),
                    position: null
                };
            case TKContinue:
                consume();
                expect(TSSemiColon);

                {
                    expr: EEscape(Continue, null),
                    position: null
                };
            case TKBreak:
                consume();
                expect(TSSemiColon);

                {
                    expr: EEscape(Break, null),
                    position: null
                };
            case _:
                unexpect(currentToken());
                null;
        }
    }

    function parseBlock():Expr
    {
        expect(TSLBrace);

        var exprs:Array<Expr> = [];

        while (!match(TSRBrace))
        {
            exprs.push(nextExpr());
        }

        consume();

        return {
            expr: EBlock(exprs),
            position: null
        };
    }

    function parseExpr():Expr
    {
        var _ = parseAssignment();
        return _;
    }

    function parseAssignment():Expr
    {
        var left = parseLogOr();

        return switch (currentToken())
        {
            case TOpAssign, TOpAddAssign, TOpMultAssign, TOpDivideAssign, TOpModAssign:
                var opToken = currentToken();
                consume();

                {
                    expr: EAssign(left, parseAssignment(), opToken),
                    position: null
                };
            case _:
                left;
        }
    }

    function parseLogOr():Expr
    {
        var left = parseLogAnd();

        return switch (currentToken())
        {
            case TOpLogicalOr:
                var opToken = currentToken();
                consume();

                {
                    expr: EBinop(left, parseLogOr(), opToken),
                    position: null
                };
            case _:
                left;
        }
    }

    function parseLogAnd():Expr
    {
        var left = parseEquality();

        return switch (currentToken())
        {
            case TOpLogicalAnd:
                var opToken = currentToken();
                consume();

                {
                    expr: EBinop(left, parseLogAnd(), opToken),
                    position: null
                };
            case _:
                left;
        }
    }

    function parseEquality():Expr
    {
        var left = parseComparision();

        return switch (currentToken())
        {
            case TOpEqual, TOpNotEqual:
                var opToken = currentToken();
                consume();

                {
                    expr: EBinop(left, parseEquality(), opToken),
                    position: null
                };
            case _:
                left; 
        }
    }

    function parseComparision():Expr
    {
        var left = parseTerm();

        return switch (currentToken())
        {
            case TOpGreaterThan, TOpGreaterEqualThan, TOpLessThan, TOpLessEqualThan:
                var opToken = currentToken();
                consume();

                {
                    expr: EBinop(left, parseComparision(), opToken),
                    position: null
                };
            case _:
                left; 
        }
    }

    function parseTerm():Expr
    {
        var left = parseFactor();

        return switch (currentToken())
        {
            case TOpAdd, TOpSubtract:
                var opToken = currentToken();
                consume();

                {
                    expr: EBinop(left, parseTerm(), opToken),
                    position: null
                };
            case _:
                left; 
        }
    }

    function parseFactor():Expr
    {
        var left = parseUnary();

        return switch (currentToken())
        {
            case TOpMult, TOpDivide, TOpMod:
                var opToken = currentToken();
                consume();

                {
                    expr: EBinop(left, parseFactor(), opToken),
                    position: null
                };
            case _:
                left; 
        }
    }

    function parseUnary():Expr {
        return switch (currentToken())
        {
            case LexerTools.isUnary(currentToken()) => true:
                var opToken = currentToken();
                consume();

                {
                    expr: EUnop(parseUnary(), opToken),
                    position: null
                };
            case _:
                parsePostfix(); 
        }
    }

    function parsePostfix():Expr {
        var left = parsePrimary();

        while (true) {
            switch (currentToken()) {

                case TSLParen:
                    consume();

                    var args:Array<Expr> = [];
                    if (currentToken() != TSRParen) {
                        while (true) {
                            args.push(parseExpr());
                            if (match(TSComma))
                                consume();
                            else
                                break;
                        }
                    }

                    expect(TSRParen);

                    left = {
                        expr: ECall(left, args),
                        position: null
                    };

                case TSDot:
                    consume();

                    var name = currentToken().fromIdent();
                    consume();

                    left = {
                        expr: EAccess(left, {
                            expr: EIdent(name),
                            position: null
                        }),
                        position: null
                    };

                case LexerTools.isPostfixUnary(currentToken()) => true:
                    var opToken = currentToken();
                    consume();

                    left = {
                        expr: EPostUnop(left, opToken),
                        position: null
                    };

                case _:
                    return left;
            }
        }
    }

    function parsePrimary():Expr {
        return switch (currentToken())
        {
            case TIdentifier(n):
                consume();
                {
                    expr: EIdent(n),
                    position: null
                };
            case TConst(c):
                consume();
                {
                    expr: EConst(c),
                    position: null
                };
            case TSLParen:
                consume();
                var expr = parseExpr();
                expect(TSRParen);

                return expr;
            case _:
                throw new NotImplementedException(currentToken().getName());
        }
    }

    function expect(tk:Token)
    {
        if (match(tk))
            consume();
        else 
            unexpect(currentToken());
    }
    function expectIdent()
    {
        return switch (currentToken())
        {
            case TIdentifier(n):
                consume();
                n;
            case _:
                unexpect(currentToken());
                null;
        }
    }
    function match(tk:Token)
    {
        return currentToken() == tk;
    }
    function unexpect(tk:Token)
    {
        throw ('Unexpected $tk');
    }
    function currentToken()
        return tokens[position];

    function peek()
        return tokens[position + 1];

    function consume()
        return ++position;
}