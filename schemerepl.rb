

=begin

    a  port of 'written in 48 hours' scheme using ParsecR

=end

require 'parsecr.rb'
require 'scheme.rb'
require 'schemeobj.rb'
require 'schemeenv.rb'

class SchemeRepl

  def self.chainPrim(v=nil,&proc)
    if v != nil
      prim { 
        |env,expr|
        expr.inject(v,&proc)
      }
    else
      prim { 
        |env,expr|
        expr.inject(&proc)
      }
    end
  end

  def self.binPrim(&proc)
      prim { 
        |env,expr|
        h = expr.head
        t = expr.tail.head
        proc.(h,t)
      }
  end
  
  def self.atom(str)
    Atom.new(str)
  end

  def self.cons(h,t)
    Cons.new(h,t)
  end
  
  def self.translate(env,expr,n)
    case 
    when expr.class == Cons
      case 
      when expr.car.class == Atom
        translateCarAtom(env,expr,n)
      else
        translateCarNoAtom(env,expr,n)
      end
    else
      expr
    end
  end

  def self.translateCarAtom(env,expr,n)
    car = expr.car
    case car.str
    when "quote"
      cons(car,
           translate(env,expr.cdr,n))
    when "quasiquote"
      cons(car,
           translate(env,expr.cdr,n+1))
    when "unquote"
      if n == 0
      then expr.cdr.car.eval(env)
      else cons(car,
                translate(env,expr.cdr,n-1))
      end
    when "unquote-splicing"
      if n == 0 then expr.cdr.car.eval(env)
      else cons(car,
                translate(env,expr.cdr,n-1))
      end
    else
      cons(translate(env,expr.car,n),
           translate(env,expr.cdr,n))
    end
  end
  
  def self.translateCarNoAtom(env,expr,n)
    if n == 0 &&
       expr.car.class == Cons &&
       expr.car.car.class == Atom &&
       expr.car.car.str == "unquote-splicing"
      translate(env,expr.car,n).append(
        translate(env,expr.cdr,n)
      )
    else
      cons(translate(env,expr.car,n),
           translate(env,expr.cdr,n))
    end
  end

  Dict0 = {
    "+"  =>  chainPrim { |m,n| Number.new(m.value + n.value) },
    "-"  =>  chainPrim { |m,n| Number.new(m.value - n.value) },
    "/"  =>  chainPrim { |m,n| Number.new(m.value / n.value) },
    "*"  =>  chainPrim { |m,n| Number.new(m.value * n.value) },
    "eq"  => binPrim   { |m,n| Bool.new(m.value == n.value) },
    "<"  =>  binPrim   { |m,n| Bool.new(m.value < n.value) },
    ">"  =>  binPrim   { |m,n| Bool.new(m.value > n.value) },
    "<=" =>  binPrim   { |m,n| Bool.new(m.value <= n.value) },
    ">=" =>  binPrim   { |m,n| Bool.new(m.value >= n.value) },
    "car" => prim      { |e,expr| expr.car.car },
    "cdr" => prim      { |e,expr| expr.car.cdr },
    "list" => prim     { |e,expr| expr },
    "append" => prim   { |e,expr|
      l1 = expr.car
      l2 = expr.cdr.car
      l1.append(l2)
    },
    "cons" => prim     { |e,expr|
      car = expr.car
      cdr = expr.cdr.car
      cons(car,cdr)
    },
    "if" => syntax {
      |env,expr0|
      pred  = expr0.car
      texpr = expr0.cdr.car
      eexpr = expr0.cdr.cdr.car
      if pred.eval(env).bool
        texpr.eval(env)
      else
        eexpr.eval(env)
      end
    },
    "let" => syntax {
      |env,exprs0|
      assignments = exprs0.car
      exprs = exprs0.cdr
      syms = [];
      args = []
      for asgn in assignments
        sym = asgn.car
        val = asgn.cdr.car
        syms.push(sym)
        args.push(val)
      end
      cons(
        cons( 
          atom("lambda"),
          cons(
            Cons.from_a(syms),
            exprs
          )
        ),
        Cons.from_a(args)
      ).eval(env)
    },
    "setq" => syntax {
      |env,expr0|
      sym  = expr0.car
      expr = expr0.cdr.car
      env.define(sym.str,expr.eval(env))
    },
    "define" => syntax {
      |env,expr0|
      sym  = expr0.car
      expr = expr0.cdr.car
      env.define(sym.str,expr.eval(env))
    },
    "def-macro" => syntax {
      |env,expr0|
      sym  = expr0.car
      expr = expr0.cdr.car
      env.define(sym.str,Macro.new(expr.eval(env)))
    },
    "quote" => syntax {
      |env,expr|
      expr.car
    },
    "lambda" => syntax {
      |env,expr|
      Closure.new(expr,env)
    },
    "quasiquote" => syntax {
      |env,expr|
      translate(env,expr.car,0)
    }
  }

  attr :parser
  
  def initialize
    @root = Env.new
    @root.dict = Dict0.clone
    @parser = Scheme.new
  end

  def mainLoop
    buff = ""
    print "scheme> "
    begin
      loop do
        str=readline
        buff += str
        pos, w = evalLine0(buff)
        if pos != nil
          print w,"\n"
          buff = buff[pos..-1]
          print "scheme> "
        else
        end
      end
    rescue EOFError
    rescue Exception => e
      p e
    end
  end
  
  def evalLine(s)
    success,s,w = @parser.parseExpr(s)
    w.eval(@root)
  end

  def evalLine0(s)
    success,s,w = @parser.parseExpr(s)
    if success 
      [s.pos,w.eval(@root)]
    else
      nil
    end
  end
  
end

if __FILE__ == $PROGRAM_NAME
  (SchemeRepl.new).mainLoop()
end
