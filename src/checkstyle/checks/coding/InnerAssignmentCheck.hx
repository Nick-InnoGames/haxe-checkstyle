package checkstyle.checks.coding;

import checkstyle.token.TokenTree;
import haxe.macro.Expr;
import haxeparser.Data.TokenDef;

@name("InnerAssignment")
@desc("Checks for assignments in subexpressions, such as in `if ((a=b) > 0) return;`.")
class InnerAssignmentCheck extends Check {

	public function new() {
		super(TOKEN);
		categories = [Category.COMPLEXITY, Category.CLARITY, Category.BUG_RISK];
		points = 5;
	}

	override function actualRun() {
		var root:TokenTree = checker.getTokenTree();
		var allAssignments:Array<TokenTree> = root.filter([
			Binop(OpAssign),
			Binop(OpAssignOp(OpAdd)),
			Binop(OpAssignOp(OpSub)),
			Binop(OpAssignOp(OpDiv)),
			Binop(OpAssignOp(OpMult)),
			Binop(OpAssignOp(OpShl)),
			Binop(OpAssignOp(OpShr)),
			Binop(OpAssignOp(OpUShr)),
			Binop(OpAssignOp(OpAnd)),
			Binop(OpAssignOp(OpOr)),
			Binop(OpAssignOp(OpXor))
		], ALL);
		var x:Int = 0;
		for (assignToken in allAssignments) {
			if (isPosSuppressed(assignToken.pos) || !filterAssignment(assignToken)) continue;
			logPos('Inner assignment detected', assignToken.pos);
		}
	}

	function filterAssignment(token:TokenTree):Bool {
		if ((token == null) || (token.tok == null)) return false;
		if (token.previousSibling != null) {
			// tokenizer does not treat >= as OpGte
			// creates OpGt and OpAssign instead
			if (token.previousSibling.is(Binop(OpGt))) return false;
		}
		return switch (token.tok) {
			case Kwd(KwdVar): false;
			case Kwd(KwdFunction): false;
			case Kwd(KwdSwitch): true;
			case Kwd(KwdReturn): true;
			case BrOpen, DblDot: false;
			case POpen: filterPOpen(token.parent);
			default: filterAssignment(token.parent);
		}
	}

	function filterPOpen(token:TokenTree):Bool {
		if ((token == null) || (token.tok == null)) return false;
		return switch (token.tok) {
			case Kwd(KwdFunction): false;
			case Kwd(KwdVar): false;
			case Kwd(KwdNew): !Type.enumEq(Kwd(KwdFunction), token.parent.tok);
			case Kwd(KwdReturn): true;
			case Kwd(KwdWhile): false;
			case POpen, Const(_): filterPOpen(token.parent);
			default: true;
		}
	}
}