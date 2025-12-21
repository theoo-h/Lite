package lite;

import lite.log.Position;

enum Token
{
    // keywords
    TKVar;
    TKConst;
    TKPublic;
    TKStatic;
    TKClass;
    TKFunction;
    TKRequire;
    
    TKReturn;
    TKContinue;
    TKBreak;

    // operadores
    TOpAdd;
    TOpSubtract;
    TOpDivide;
    TOpMult;
    TOpMod;

    TOpIncrement;
    TOpDecrement;
    TOpExponentiate;

    TOpAddAssign;
    TOpSubtractAssign;
    TOpDivideAssign;
    TOpMultAssign;
    TOpModAssign;

    TOpAssign;

    TOpGreaterThan;
    TOpLessThan;

    TOpNotEqual;
    TOpEqual;
    TOpGreaterEqualThan;
    TOpLessEqualThan;

    TOpLogicalNot;
    TOpLogicalOr;
    TOpLogicalAnd;

    TOpBitwiseNot;

    // simbolos
    TSComma;
    TSDot;

    TSSemiColon;
    TSColon;
    
    // ()
    TSLParen;
    TSRParen;

    // {}
    TSLBrace;
    TSRBrace;

    // []
    TSLBracket;
    TSRBracket;

    // valores
    TIdentifier(string:String);
    TConst(c:TConstType);

    TEof;
}

enum TConstType
{
    CInt(c:Int);
    CFloat(c:Float);
    CString(c:String);
    CNull;
}