
require "scheme.rb"
require "schemerepl.rb"
require "test/unit"

def atom(str); Atom.new(str); end
def list(*ls); Cons.from_a(ls); end
def dotted(*ls,tail); Cons.from_a(ls,tail); end
def number(v); Number.new(v); end
def str(str); Str.new(str); end
def bool(b); Bool.new(b); end
def quoted(exp); list(atom("quote"),exp); end

class TestSchmeEval < Test::Unit::TestCase
  
  def setup
    @repl   = SchemeRepl.new
    @parser = @repl.parser
  end
  
  test "setq 1: number: return" do
    x = @repl.evalLine("(setq a 1)")
    assert_equal 1,x.value
  end

  test "setq 1: nubmer: reference" do
    @repl.evalLine("(setq a 1)")
    x = @repl.evalLine("a")
    assert_equal Number.new(1),x
  end

  test "setq 1: symbol: reference" do
    @repl.evalLine("(setq a 'b)")
    x = @repl.evalLine("a")
    assert_equal Atom.new("b"),x
  end

  test "setq 1: cons: reference" do
    @repl.evalLine("(setq a '(a b c))")
    x = @repl.evalLine("a")
    assert_equal list(atom("a"),atom("b"),atom("c")),x
  end

  test "car 1:" do
    x = @repl.evalLine("(car '(a b c))")
    assert_equal atom("a"), x
  end

  test "car 2: null" do
    assert_raise(NoMethodError) do
      @repl.evalLine("(car '())")
    end
  end

  test "cdr 1:" do
    x = @repl.evalLine("(cdr '(a b c))")
    assert_equal list(atom("b"),atom("c")),x
  end

  test "cdr 2: nil" do
    x = @repl.evalLine("(cdr '(a))")
    assert_equal Nil::NIL, x
  end

  test "cdr 3: nil" do
    assert_raise(NoMethodError) do
      @repl.evalLine("(cdr '())")
    end
  end

  test "cons:" do
    x = @repl.evalLine("(cons 'a '(b c))")
    assert_equal list(atom("a"),atom("b"),atom("c")),x
  end
  
  test "+" do
    x = @repl.evalLine("(+ 1 2 3)")
    assert_equal Number.new(6), x
  end

  test "let" do
    x = @repl.evalLine("(let ((a 1)(b 2)) (+ a b))")
    assert_equal Number.new(3), x
  end

  test "lambda: 1" do
    @repl.evalLine("(setq f (lambda (n m) (+ n m)) )")
    x = @repl.evalLine("(f 1 2)")
    assert_equal Number.new(3), x
  end

  test "lambda: 2" do
    x = @repl.evalLine("((lambda (n m) (+ n m)) 1 2)")
    assert_equal Number.new(3), x
  end

  test "lambda: 3" do
    x = @repl.evalLine("((lambda (n . m) (+ n (car m))) 1 2)")
    assert_equal Number.new(3), x
  end

  test "if: 1" do
    x = @repl.evalLine("(if #t 1 2)")
    assert_equal Number.new(1), x
  end

  test "if: 2" do
    x = @repl.evalLine("(if #f 1 2)")
    assert_equal Number.new(2), x
  end

  test "quote" do
    x = @repl.evalLine("(quote a)")
    assert_equal Atom.new("a"), x
  end

  test "quote: '" do
    x = @repl.evalLine("'a")
    assert_equal Atom.new("a"), x
  end

  test "quasiquote: simple" do
    x = @repl.evalLine("`a")
    assert_equal Atom.new("a"), x
  end

  test "quasiquote: nested" do
    x = @repl.evalLine("``a")
    success,s,t = @parser.runParser(@parser.expr,"`a")
    assert_equal t, x
  end

    test "quasiquote: list" do
    x = @repl.evalLine("`(a b c)")
    success,s,t = @parser.runParser(@parser.expr,"(a b c)")
    assert_equal t, x
  end

  test "quasiquote: unquote: 1" do
    x = @repl.evalLine("(setq b 10)")
    x = @repl.evalLine("(setq c 20)")
    x = @repl.evalLine("`(a ,b ,c)")
    success,s,t = @parser.runParser(@parser.expr,"(a 10 20)")
    assert_equal t, x
  end

  test "quasiquote: unquote: 1.1" do
    x = @repl.evalLine("(setq b 10)")
    x = @repl.evalLine("(setq c 20)")
    x = @repl.evalLine("`((a ,b ,c))")
    success,s,t = @parser.runParser(@parser.expr,"((a 10 20))")
    assert_equal t, x
  end

  test "quasiquote: unquote: 1.2" do
    x = @repl.evalLine("(setq b 10)")
    x = @repl.evalLine("(setq c 20)")
    x = @repl.evalLine("`(10 ,b ,c)")
    success,s,t = @parser.runParser(@parser.expr,"(10 10 20)")
    assert_equal t, x
  end

  test "quasiquote: unquote: 1.3" do
    x = @repl.evalLine("(setq b 10)")
    x = @repl.evalLine("(setq c 20)")
    x = @repl.evalLine("`(10 ,(+ b 1) ,c)")
    success,s,t = @parser.runParser(@parser.expr,"(10 11 20)")
    assert_equal t, x
  end
  
  test "quasiquote: unquote: 2" do
    x = @repl.evalLine("(setq b 10)")
    x = @repl.evalLine("(setq c 20)")
    x = @repl.evalLine("`(x `(a ,b ,c))")
    success,s,t = @parser.runParser(@parser.expr,"(x `(a ,b ,c))")
    assert_equal t, x
  end

  test "quasiquote: unquote: 2.1" do
    x = @repl.evalLine("(setq b 10)")
    x = @repl.evalLine("(setq c 20)")
    x = @repl.evalLine("`(`(a ,b ,c) x)")
    success,s,t = @parser.runParser(@parser.expr,"(`(a ,b ,c) x)")
    assert_equal t, x
  end

  test "quasiquote: unquote: 3" do
    x = @repl.evalLine("(setq b 10)")
    x = @repl.evalLine("(setq c 20)")
    x = @repl.evalLine("`(x `(a ,(b ,c)))")
    success,s,t = @parser.runParser(@parser.expr,"(x `(a ,(b 20)))")
    assert_equal t, x
  end

  test "quasiquote: unquote: 3.1" do
    x = @repl.evalLine("(setq b 10)")
    x = @repl.evalLine("(setq c 20)")
    x = @repl.evalLine("`(`(a ,(b ,c)) x)")
    success,s,t = @parser.runParser(@parser.expr,"(`(a ,(b 20)) x)")
    assert_equal t, x
  end

  test "quasiquote: unquote: 4" do
    x = @repl.evalLine("(setq b 10)")
    x = @repl.evalLine("`,b")
    success,s,t = @parser.runParser(@parser.expr,"10")
    assert_equal t, x
  end

  test "quasiquote: unquote: 4.1" do
    x = @repl.evalLine("(setq b '(a b c))")
    x = @repl.evalLine("`,b")
    success,s,t = @parser.runParser(@parser.expr,"(a b c)")
    assert_equal t, x
  end

  test "quasiquote: unquote: 4.2" do
    x = @repl.evalLine("(setq b 10)")
    x = @repl.evalLine("``,,b")
    success,s,t = @parser.runParser(@parser.expr,"`,10")
    assert_equal t, x
  end

  test "quasiquote: unquote-splicing: 1" do
    x = @repl.evalLine("(setq b '(5 10))")
    x = @repl.evalLine("(setq c 20)")
    x = @repl.evalLine("`(a ,@b ,c)")
    success,s,t = @parser.runParser(@parser.expr,"(a 5 10 20)")
    assert_equal t, x
  end

  test "quasiquote: unquote-splicing: 2" do
    x = @repl.evalLine("(setq b '(5 10))")
    x = @repl.evalLine("(setq c 20)")
    x = @repl.evalLine("`(,@b a ,c)")
    success,s,t = @parser.runParser(@parser.expr,"(5 10 a 20)")
    assert_equal t, x
  end

  test "quasiquote: unquote-splicing: 3" do
    x = @repl.evalLine("(setq b '(5 10))")
    x = @repl.evalLine("(setq c 20)")
    x = @repl.evalLine("`(a ,c ,@b)")
    success,s,t = @parser.runParser(@parser.expr,"(a 20 5 10)")
    assert_equal t, x
  end
  
  test "quasiquote: unquote-splicing: 4" do
    x = @repl.evalLine("(setq b '(5 10))")
    x = @repl.evalLine("(setq c 20)")
    x = @repl.evalLine("`(x `(a ,(c ,@b)))")
    success,s,t = @parser.runParser(@parser.expr,"(x `(a ,(c 5 10)))")
    assert_equal t, x
  end
  
  test "def-macro: 1" do
    @repl.evalLine("(def-macro f (lambda (n) n))")
    @repl.evalLine("(setq a 10)")
    x = @repl.evalLine("(f a)")
    assert_equal Number.new(10), x
  end

  test "def-macro: 2" do
    @repl.evalLine("(def-macro f (lambda (n) n))")
    @repl.evalLine("(setq a 10)")
    x = @repl.evalLine("(f 'a)")
    assert_equal Atom.new("a"), x
  end

  test "def-macro: 3" do
    @repl.evalLine("(def-macro myif (lambda (p t e) (if p t e)))")
    x = @repl.evalLine("(myif #t 10 20)")
    assert_equal Number.new(10), x
  end

  test "def-macro: 4" do
    @repl.evalLine("(def-macro myif (lambda (p t e) (list 'if p t e)))")
    @repl.evalLine("(myif #t (setq a 10) (setq a 20))")
    x = @repl.evalLine("a");
    assert_equal Number.new(10), x
  end

  test "def-macro: 5" do
    @repl.evalLine("(def-macro myif (lambda (p t e) `(if ,p ,t ,e)))")
    @repl.evalLine("(myif #t (setq a 10) (setq a 20))")
    x = @repl.evalLine("a");
    assert_equal Number.new(10), x
  end

  
end
