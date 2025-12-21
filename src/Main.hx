package;

import sys.io.File;
import lite.Lexer;
import lite.Parser;

class Main {
    static function main() {
        var code = File.getContent("script.lite");
        var miLexer = new Lexer();
        var tokens = miLexer.parse(code);
        var miParser = new Parser();
        trace(miParser.parse(tokens));
    }
}