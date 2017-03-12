

=begin

    a  port of 'written in 48 hours' scheme using ParsecR

=end

require 'parsecr.rb'
require 'schemeobj.rb'
require 'schemeenv.rb'

class Scheme

  include ParsecR

  attr :letter, :symbol, :spaces, :string, :atom, :number,
       :expr, :list, :dotted, :quoted
  
  def initialize

    @letter = pR(/[a-z]/i)
    @digit  = pR(/\d/)
    @symbol = pR(/[!#$%&|*+\-\/:<=>?@^_~]/)
    @spaces = k(pR(/\s+/))
    @string = tokenA( para(pS('"'),
                           pR(/[^"]*/),
                           pS('"')) ) {
      |t| Str.new(t.word)
    }
    @atom   = tokenA(
      d( o( @letter, @symbol ),
         m(o(@letter, @symbol, @digit))  )
    ) {
      |*ts|
      s = ts.map { |t| t.word }.join("")
      case s
      when "#t"
        Bool.new(true)
      when "#f"
        Bool.new(false)
      else
        Atom.new(s)
      end
    }
    @number = tokenA( m1( @digit ) ) { |*ts|
      i = ts.map { |t| t.word }.join("").to_i
      Number.new(i)
    }

    @list = m( r{@expr} ) {
      |*ts| Cons.from_a( ts )
    }

    @dotted = d(
      m1( r{@expr} ), tS("."), r{@expr}
    ) {
      |*head,dot,tail|
      Cons.from_a(head,tail)
    }

    @quoted = d( pS("'"), r{@expr} ) {
      |apos,expr|
      Cons.from_a([Atom.new("quote"), expr])
    }

    @quasiquote = d( pS("`"), r{@expr} ) {
      |apos,expr|
      Cons.from_a([Atom.new("quasiquote"), expr])
    }

    @unquote = d( pS(","), r{@expr} ) {
      |apos,expr|
      Cons.from_a([Atom.new("unquote"), expr])
    }

    @unquote_splicing = d( pS(",@"), r{@expr} ) {
      |apos,expr|
      Cons.from_a([Atom.new("unquote-splicing"), expr])
    }
    
    @expr = o( @atom,
               @string,
               @number,
               @quoted,
               @quasiquote,
               @unquote_splicing,
               @unquote,
               para( tS("("),
                     o( u(@dotted), @list ),
                     tS(")") )
             )

    @expr1 = d(opt(@spaces), @expr )

  end

  def parseExpr(s)
    runParser(@expr1,s)
  end

end

