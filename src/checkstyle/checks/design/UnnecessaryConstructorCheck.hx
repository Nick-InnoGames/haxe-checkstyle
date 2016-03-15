package checkstyle.checks.design;

import checkstyle.token.TokenTree;
import haxe.macro.Expr;

@name("UnnecessaryConstructor")
@desc("Checks for unnecessary constructor in classes that contain only static methods or fields.")
class UnnecessaryConstructorCheck extends Check {

	public function new() {
		super(TOKEN);
		categories = [Category.BUG_RISK];
		points = 3;
	}

	override function actualRun() {
		var root:TokenTree = checker.getTokenTree();
		var classes:Array<TokenTree> = root.filter([Kwd(KwdClass)], ALL);
		for (cls in classes) {
			var acceptableTokens:Array<TokenTree> = cls.filter([
				Kwd(KwdFunction),
				Kwd(KwdVar)
			], ALL);

			var haveConstructor:Bool = false;
			var staticTokens:Int = 0;
			var constructorPos = null;
			for (token in acceptableTokens) {
				if (token.filter([Kwd(KwdNew)], FIRST).length > 0) {
					haveConstructor = true;
					constructorPos = token.pos;
					continue;
				}

				if (token.filter([Kwd(KwdStatic)], FIRST).length > 0) {
					staticTokens++;
					continue;
				}
			}

			if (haveConstructor && acceptableTokens.length > 1 && acceptableTokens.length == staticTokens + 1) {
				logPos("Unnecessary constructor found", constructorPos);
			}
		}
	}
}