package lite;

import lite.log.Position;
import lite.Token;

@:publicFields
@:structInit
class Expr
{
    var expr:ExprType;
    var position:Position;

    function toString()
    {
        return expr;
    }
}

enum ExprType
{
    EConst(c:TConstType);
    EIdent(c:String);

    EBinop(left:Expr, right:Expr, op:Token);
    EUnop(expr:Expr, op:Token);
    EPostUnop(expr:Expr, op:Token);

    EAssign(left:Expr, right:Expr, op:Token);
    ECall(left:Expr, args:Array<Expr>);
    EAccess(left:Expr, right:Expr);

    EBlock(arr:Array<Expr>);

    EVarDecl(name:String, value:Null<Expr>);
    EFunDecl(name:String, args:Array<FunArgument>, block:Expr);

    EEscape(type:EscapeT, expr:Null<Expr>);
}

typedef FunArgument = {
	name:String
}

enum abstract EscapeT(Int)
{
    var Return = 0;
    var Break = 1;  
    var Continue = 2;
}