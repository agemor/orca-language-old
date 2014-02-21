package elsa;
import elsa.symbol.SymbolTable;
import elsa.Token.Type;
import elsa.symbol.Symbol;
import elsa.symbol.VariableSymbol;
import elsa.symbol.FunctionSymbol;
import elsa.symbol.ClassSymbol;
import elsa.symbol.LiteralSymbol;

/**
 * ...
 * @author 김 현준
 */
class BelugaAssembly {

	/**
	 * 심볼 테이블
	 */
	public var symbolTable:SymbolTable;
	
	/**
	 * 어셈블리 코드
	 */
	public var code:String = "";
	private var frozenCode:String;
	
	public function freeze():Void {
		frozenCode = code;
		code = "";
	}
	
	public function melt():Void {
		code += frozenCode;
		frozenCode = "";
	}	
	
	public function new(symbolTable:SymbolTable) {
		this.symbolTable = symbolTable;
	}
	
	/**
	 * 연산자 번호를 구한다.
	 * 
	 * @param	type
	 * @return
	 */
	public static function getOperatorNumber(type:Token.Type):Int {
		switch (type) {
		case Type.Addition, Type.AdditionAssignment:
			return 1;
		case Type.Subtraction, Type.SubtractionAssignment:
			return 2;
		case Type.Division, Type.DivisionAssignment:
			return 3;
		case Type.Multiplication, Type.MultiplicationAssignment:
			return 4;
		case Type.Modulo, Type.ModuloAssignment:
			return 5;
		case Type.BitwiseAnd, Type.BitwiseAndAssignment:
			return 6;
		case Type.BitwiseOr, Type.BitwiseOrAssignment:
			return 7;
		case Type.BitwiseXor, Type.BitwiseXorAssignment:
			return 8;
		case Type.BitwiseNot:
			return 9;
		case Type.BitwiseLeftShift, Type.BitwiseLeftShiftAssignment:
			return 10;
		case Type.BitwiseRightShift, Type.BitwiseRightShiftAssignment:
			return 11;
		case Type.EqualTo:
			return 12;
		case Type.NotEqualTo:
			return 13;
		case Type.GreaterThan:
			return 14;
		case Type.GreaterThanOrEqualTo:
			return 15;
		case Type.LessThan:
			return 16;
		case Type.LessThanOrEqualTo:
			return 17;
		case Type.LogicalAnd:
			return 18;
		case Type.LogicalOr:
			return 19;
		case Type.LogicalNot:
			return 20;
		case Type.Append, Type.AppendAssignment:
			return 21;
		case Type.CastToNumber:
			return 22;
		case Type.CastToString:
			return 23;
		case Type.RuntimeValueAccess:
			return 24;
		case Type.UnraryMinus:
			return 25;
		case Type.CharAt:
			return 26;
		default:
			return 0;
		}
	}
	
	/**
	 * 토큰열로 구성된 스택 어셈블리를 직렬화한다.
	 * 
	 * @param tokens
	 */
	public function writeLine(tokens:Array<Token>):Void {
		for ( i in 0...tokens.length) { 
			var token:Token = tokens[i];

			switch (token.type) {

			// 접두형 단항 연산자
			case Type.CastToNumber, Type.CastToString, Type.LogicalNot,
				 Type.BitwiseNot, Type.UnraryMinus:
					 
				writeCode("OPR " + getOperatorNumber(token.type));
				
			// 값을 증감시킨 다음 푸쉬한다.
			case Type.PrefixDecrement, Type.PrefixIncrement:
				
				// 배열 인덱스 연산
				if (token.useAsArrayReference) {					
					
					
					if (token.doNotPush)
						writeCode("POP 0");
				} 
				
				else {
				}
				
			// 값을 푸쉬한 다음 증감시킨다.
			case Type.SuffixDecrement, Type.SuffixIncrement:
				
				// 배열 인덱스 연산
				if (token.useAsArrayReference) {
					if (token.doNotPush)
						writeCode("POP 0");
				} 
				
				else {
					
				}
				
			// 이항 연산자
			case Type.Addition, Type.Subtraction, Type.Division,
				 Type.Multiplication, Type.Modulo, Type.BitwiseAnd,
				 Type.BitwiseOr, Type.BitwiseXor, Type.BitwiseLeftShift,
				 Type.BitwiseRightShift, Type.LogicalAnd, Type.LogicalOr,
				 Type.Append, Type.EqualTo, Type.NotEqualTo,
				 Type.GreaterThan, Type.GreaterThanOrEqualTo, Type.LessThan,
				 Type.LessThanOrEqualTo, Type.RuntimeValueAccess, Type.CharAt:						 
				
				writeCode("OPR " + getOperatorNumber(token.type));
			
			// 이항 연산 후 대입 연산자
			case Type.Assignment, Type.AdditionAssignment, Type.SubtractionAssignment, Type.DivisionAssignment,
				 Type.MultiplicationAssignment, Type.ModuloAssignment, Type.BitwiseAndAssignment,
				 Type.BitwiseOrAssignment, Type.BitwiseXorAssignment, Type.BitwiseLeftShiftAssignment,
				 Type.BitwiseRightShiftAssignment, Type.AppendAssignment:
				
				// 배열 인덱스 연산	 
				if (token.useAsArrayReference) {	 
					writeCode("OPR " + getOperatorNumber(token.type));
				}
				
				// 일반 변수 연산
				else {
					
					writeCode("OPR " + getOperatorNumber(token.type));
				}

			// 배열 참조 연산자
			case Type.ArrayReference:

				// 배열의 차원수를 취득한다.
				var dimensions:Int = Std.parseInt(token.value);
				
				/* a[A][B] =
				 * 
				 * PUSH B
				 * PUSH A
				 * PUSH a
				 * POP 0 // a
				 * POP 1 // B
				 * POP 2 // A
				 * ESI 0, 0, 2
				 * ESI 0, 0, 1
				 */
				var j:Int = dimensions + 1;
				
				if (token.useAsAddress) 
					j --;				
				
				while (-- j > 0)
					writeCode("RDA");
				
			// 함수 호출 / 어드레스 등의 역할
			case Type.ID:

				var symbol:Symbol = token.getTag();

				// 변수일 경우				
				if (Std.is(symbol, VariableSymbol)) {
					
					if (token.useAsAddress)
						writeCode("PSH " + symbol.address);
					else
						writeCode("PSM " + symbol.address);					
				}

				// 함수일 경우
				else if (Std.is(symbol, FunctionSymbol)) {
					
					var functn:FunctionSymbol = cast(symbol, FunctionSymbol);

					// 네이티브 함수일 경우
					if (functn.isNative) {

						// 그냥 네이티브 어셈블리를 쓴다.
						writeCode(functn.nativeFunction.assembly);

					} else {

						/*
						 * 프로시져 호출의 토큰 구조는
						 * 
						 * ARGn, ARGn-1, ... ARG1, PROC_ID 로 되어 있다.
						 */
						
						// 인수를 뽑아 낸 후, 프로시져의 파라미터에 대응시킨다.						
						for( j in 0...functn.parameters.length){									
							writeCode("PSH " + functn.parameters[j].address);								
							writeCode("STO");
						}						

						// 현재 위치를 스택에 넣는다.
						writeCode("PSC");

						// 함수 시작부로 점프한다.
						writeCode("PSH %" + functn.functionEntry);
						writeCode("JMP");
						
						// 파라미터를 시스템에 반환한다.
						for ( j in 0...functn.parameters.length) 
							writeCode("FRE " + functn.parameters[j].address);
						
					}
				}

			case Type.True, Type.False, Type.String, Type.Number:
				
				if (!token.tagged) {					
					writeCode("PSH " + token.value);
					
				} else {
					// 리터럴 심볼을 취득한다.
					var literal:LiteralSymbol = cast(token.getTag(), LiteralSymbol);

					// 리터럴의 값을 추가한다.
					writeCode("PSM " + literal.address);
				}				
			case Type.Array:

				// 현재 토큰의 값이 인수의 갯수가 된다.
				var numberOfArguments:Int = Std.parseInt(token.value);
				
				// 동적 배열을 할당한다.
				writeCode("DAA");
				writeCode("POP 0");
				
				// 배열에 집어넣기 작업
				for ( j in 0...numberOfArguments) {
					writeCode("PSR 0");
					writeCode("STA");
				}					
				writeCode("PSR 0");
				
			case Type.Instance:

				// 앞 토큰은 인스턴스의 클래스이다.
				var targetClass:ClassSymbol = cast(tokens[i - 1].getTag(), ClassSymbol);
				
				// 인스턴스를 동적 할당한다.
				writeCode("DAA");
				writeCode("POP 0");
				
				// 오브젝트의 맴버 변수에 해당하는 데이터를 동적 할당한다.
				var assignedIndex:Int = 0;
				for ( j in 0...targetClass.members.length) {

					if (Std.is(targetClass.members[j], FunctionSymbol))
						continue;

					var member:VariableSymbol = cast(targetClass.members[j], VariableSymbol);
					
					// 초기값을 할당한다.					
					writeCode("PSM " + member.address);
					
					// 인스턴스에 맴버를 추가한다.
					writeCode("PSH " + assignedIndex);
					writeCode("PSR 0");
					writeCode("STA");
					assignedIndex++;
				}

				// 배열을 리턴한다.
				writeCode("PSR 0");
				
				default:
			}
		}
	}

	/**
	 * 어셈블리 코드를 추가한다.
	 * 
	 * @param	code
	 */
	public function writeCode(code:String):Void {
		this.code += code + "\n";
	}

	
	/**
	 * 플래그를 심는다.
	 * 
	 * @param	number
	 */
	public function flag(number:Int):Void {
		writeCode("FLG %" + number);
	}
	
}