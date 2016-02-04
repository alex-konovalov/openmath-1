#######################################################################
##
#W  omput.gi                OpenMath Package           Andrew Solomon
#W                                                     Marco Costantini
##
#H  @(#)$Id$
##
#Y    Copyright (C) 1999, 2000, 2001, 2006
#Y    School Math and Comp. Sci., University of St.  Andrews, Scotland
#Y    Copyright (C) 2004, 2005, 2006 Marco Costantini
##
##  Writes a GAP object to an output stream, as an OpenMath object
## 


#######################################################################
##
#M  OMPut( <stream>, <cyc> )  
##
##  Printing for cyclotomics
## 
InstallMethod(OMPut, "for a proper cyclotomic", true,
[IsOutputStream, IsCyc],0,
function(stream, x)
	local
                real,
                imaginary,

		n, # Length(powlist)
		i,
		clist; # x = Sum_i clist[i]*E(n)^(i-1)

    if IsGaussRat( x )  then

        real := x -> (x + ComplexConjugate( x )) / 2;
        imaginary := x -> (x - ComplexConjugate( x )) * -1 / 2 * E( 4 );

        OMPutApplication( stream, "complex1", "complex_cartesian", 
            [ real(x), imaginary(x)] );

    else

	n := Conductor(x);
	clist := CoeffsCyc(x, n);

	OMWriteLine(stream, ["<OMA>"]);
	OMIndent := OMIndent+1;
	OMPutSymbol( stream, "arith1", "plus" );
	for i in [1 .. n] do
		if clist[i] <> 0 then

			OMWriteLine(stream, ["<OMA>"]); # times
			OMIndent := OMIndent+1;
			OMPutSymbol( stream, "arith1", "times" );
			OMPut(stream, clist[i]);

			OMPutApplication( stream, "algnums", "NthRootOfUnity", [ n, i-1 ] );

			OMIndent := OMIndent-1;
			OMWriteLine(stream, ["</OMA>"]); #times
		fi;
	od;
	OMIndent := OMIndent-1;
	OMWriteLine(stream, ["</OMA>"]);

    fi;
end);


#######################################################################
##
#M  OMPut( <stream>, <transformation> )  
##
##  Printing for transformations : specified in permut1.ocd 
## 
InstallMethod(OMPut, "for a transformation", true,
[IsOutputStream, IsTransformation],0,
function(stream, x)
	OMPutApplication( stream, "transform1", "transformation", ImageListOfTransformation(x) );
end);


#######################################################################
##
#M  OMPut( <stream>, <semigroup> )  
##
InstallMethod(OMPut, "for a semigroup", true,
[IsOutputStream, IsSemigroup],0,
function(stream, x)
	OMPutApplication( stream, "semigroup1", "semigroup_by_generators", 
		GeneratorsOfSemigroup(x) );
end);


#######################################################################
##
#M  OMPut( <stream>, <monoid> )  
##
## 
InstallMethod(OMPut, "for a monoid", true,
[IsOutputStream, IsMonoid],0,
function(stream, x)
	OMPutApplication( stream, "monoid1", "monoid_by_generators", 
		GeneratorsOfMonoid(x) );
end);


#######################################################################
##
#M  OMPut( <stream>, <record> )  
##
##  There is no OpenMath representation for records, though this might
##  be done within standard using OMATTR. However, for better efficiency
##  we introduce private symbol for the record, as records are native
##  objects in many programming languages. 
##
##  To minimise the number of OM tags in the resulting OM code, the
##  record with N components will be encoded as a list of the length 
##  2*N where strings with component names will be on odd places and
##  corresponding values will be on even ones.
##
##  As a practical application of this, we consider transmitting 
##  graphs given as records in the Grape package format, which stores
##  extra information not included in the default OpenMath encoding
##  for graphs.
##   
InstallMethod(OMPut, "for a record", true,
[IsOutputStream, IsRecord], 0 ,
function(stream, x )
    local r;
	OMWriteLine(stream, ["<OMA>"]);
	OMIndent := OMIndent+1;
	OMPutSymbol( stream, "record1", "record" );
	for r in RecNames(x) do
	   OMPut( stream, r );
	   OMPut( stream, x.(r) );
	od;
	OMIndent := OMIndent-1;
	OMWriteLine(stream, ["</OMA>"]);	   
end);


#######################################################################
##
#M  OMPut( <stream>, <group> )  
##
##  Printing for groups as in openmath/cds/group1.ocd (Note that it 
##  differs from group1.group from the group1 CD at http://www.openmath.org,
##  since we just output the list of generators)
## 
InstallMethod(OMPut, "for a group", true,
[IsOutputStream, IsGroup],0,
function(stream, x)
	OMPutApplication( stream, "group1", "group_by_generators", 
		GeneratorsOfGroup(x) );
end);


#######################################################################
##
#M  OMPut( <stream>, <pcgroup> )  
##
##  Printing for pcgroups as pcgroup1.pcgroup_by_pcgscode:
##  the 1st argument is pcgs code of the group, the 2nd is
##  its order. Note that OMTest will return fail in this
##  case, since the result of parsing the output will be
##  an isomorphic group but not equal to the original one.
## 
InstallMethod(OMPut, "for a pcgroup", true,
[IsOutputStream, IsPcGroup],0,
function(stream, x)
	OMWriteLine(stream, ["<OMA>"]);
	OMIndent := OMIndent+1;
	OMPutSymbol( stream, "pcgroup1", "pcgroup_by_pcgscode" );
    OMPut( stream, CodePcGroup(x) );
	OMPut( stream, Size(x) );
	OMIndent := OMIndent-1;
	OMWriteLine(stream, ["</OMA>"]);	
end);


#######################################################################
## 
## Experimental methods for OMPut for character tables"
##
#######################################################################
##
#F  OMIrredMatEntryPut( <stream>, <entry>, <data> )
##
##  <entry> is a (possibly unknown) cyclotomic
##  <data> is the record of information about names and values
##  used to substitute for complicated irreducible expressions.
##
##  This borrows heavily from Thomas Breuer's 
##  CharacterTableDisplayStringEntryDefault
##
BindGlobal("OMIrredMatEntryPut",
function(stream, entry, data)
	local val, irrstack, irrnames, name, ll, i, letters, n;

  # OMPut(stream,entry);
	if IsCyc( entry ) and not IsInt( entry ) then
      # find shorthand for cyclo
      irrstack:= data.irrstack;
      irrnames:= data.irrnames;
      for i in [ 1 .. Length( irrstack ) ] do
        if entry = irrstack[i] then
          OMPutVar(stream, irrnames[i]);
					return;
        elif entry = -irrstack[i] then
					OMWriteLine(stream, ["<OMA>"]);
					OMIndent := OMIndent +1;
					OMPutSymbol(stream, "arith1", "unary_minus");
          OMPutVar(stream, irrnames[i]);
					OMIndent := OMIndent -1;
					OMWriteLine(stream, ["</OMA>"]);
					return;
        fi;
        val:= GaloisCyc( irrstack[i], -1 );
        if entry = val then
					OMWriteLine(stream, ["<OMA>"]);
					OMIndent := OMIndent +1;
					OMPutSymbol(stream, "complex1", "conjugate");
          OMPutVar(stream, irrnames[i]);
					OMIndent := OMIndent -1;
					OMWriteLine(stream, ["</OMA>"]);
					return;
        elif entry = -val then
					OMWriteLine(stream, ["<OMA>"]);
					OMIndent := OMIndent +1;
					OMPutSymbol(stream, "arith1", "unary_minus");
					OMWriteLine(stream, ["<OMA>"]);
					OMIndent := OMIndent +1;
					OMPutSymbol(stream, "complex1", "conjugate");
          OMPutVar(stream, irrnames[i]);
					OMIndent := OMIndent -1;
					OMWriteLine(stream, ["</OMA>"]);
					OMIndent := OMIndent -1;
					OMWriteLine(stream, ["</OMA>"]);
					return;
        fi;
        val:= StarCyc( irrstack[i] );
        if entry = val then
					OMWriteLine(stream, ["<OMA>"]);
					OMIndent := OMIndent +1;
					OMPutSymbol(stream, "algnums", "star");
          OMPutVar(stream, irrnames[i]);
					OMIndent := OMIndent -1;
					OMWriteLine(stream, ["</OMA>"]);
					return;
        elif -entry = val then
					OMWriteLine(stream, ["<OMA>"]);
					OMIndent := OMIndent +1;
					OMPutSymbol(stream, "arith1", "unary_minus");
					OMWriteLine(stream, ["<OMA>"]);
					OMIndent := OMIndent +1;
					OMPutSymbol(stream, "algnums", "star");
          OMPutVar(stream, irrnames[i]);
					OMIndent := OMIndent -1;
					OMWriteLine(stream, ["</OMA>"]);
					OMIndent := OMIndent -1;
					OMWriteLine(stream, ["</OMA>"]);
					return;
        fi;
        i:= i+1;
      od;
      Add( irrstack, entry );

      # Create a new name for the irrationality.
      name:= "";
      n:= Length( irrstack );
      letters:= data.letters;
      ll:= Length( letters );
      while 0 < n do
        name:= Concatenation( letters[(n-1) mod ll + 1], name );
        n:= QuoInt(n-1, ll);
      od;
      Add( irrnames, name );
      OMPutVar(stream, irrnames[ Length( irrnames ) ]);
			return;

		elif IsUnknown( entry ) then
			OMPutVar(stream, "?"); 
			return;
		else
			OMPut(stream, entry);
			return;
		fi;

end);


#######################################################################
##
#F  OMPutIrredMat( <stream>, <x> )
##
##  <x> is a character table
##
##  This borrows heavily from Thomas Breuer's 
##  character table Display routines -- see lib/ctbl.gi
##
BindGlobal("OMPutIrredMat",
function(stream, x)
	local r,i, irredmat, data;

	data := CharacterTableDisplayStringEntryDataDefault( x );
  # irreducibles matrix
  irredmat :=  List(Irr(x), ValuesOfClassFunction);

	# OMPut(stream,irredmat);

  OMWriteLine(stream, ["<OMA>"]);
  OMIndent := OMIndent +1;

  OMPutSymbol( stream, "linalg2", "matrix" );
  for r in irredmat do
    OMWriteLine(stream, ["<OMA>"]);
    OMIndent := OMIndent +1;

      OMPutSymbol( stream, "linalg2", "matrixrow" );

    for i in r do
      OMIrredMatEntryPut(stream, i, data);
    od;

    OMIndent := OMIndent -1;
    OMWriteLine(stream, ["</OMA>"]);


  od;

  OMIndent := OMIndent -1;
  OMWriteLine(stream, ["</OMA>"]);

	# Now output the list of (variable = value) pairs
	OMWriteLine(stream, ["<OMA>"]);
	OMIndent := OMIndent +1;
	OMPutSymbol(stream, "list1", "list");
	for i in [1 .. Length(data.irrstack)] do
		OMWriteLine(stream, ["<OMA>"]);
		OMIndent := OMIndent +1;
		OMPutSymbol(stream, "relation1", "eq");
		OMPutVar(stream, data.irrnames[i]);
		OMPut(stream, data.irrstack[i]);
		OMIndent := OMIndent -1;
		OMWriteLine(stream, ["</OMA>"]);
	od;
	OMIndent := OMIndent -1;
	OMWriteLine(stream, ["</OMA>"]);

end);



#######################################################################
##
#M  OMPut( <stream>, <character table> )  
##
##
InstallMethod(OMPut, "for a character table", true,
[IsOutputStream, IsCharacterTable],0,
function(stream, c)
	local
		centralizersizes,
		centralizerindices,
		centralizerprimes,
		ordersclassreps,
		sizesconjugacyclasses,
		classnames,
		powmap;

  # the centralizer primes
  centralizersizes := SizesCentralizers(c);
  centralizerprimes := AsSSortedList(Factors(Product(centralizersizes)));

  # the indices which define the factorisation of the
  # centralizer orders
  centralizerindices := List(centralizersizes, z->
    List(centralizerprimes, x->Size(Filtered(Factors(z), y->y=x))));

	# ordersclassreps - every element of a conjugacy class has
	# the same order.
  ordersclassreps := OrdersClassRepresentatives( c );

	# SizesConjugacyClasses
	sizesconjugacyclasses := SizesConjugacyClasses( c );

  # the classnames
  classnames := ClassNames(c);

  # the powermap
  powmap := List(centralizerprimes,
    x->List(PowerMap(c, x),z->ClassNames(c)[z]));

  # irreducibles matrix
  # irredmat :=  List(Irr(c), ValuesOfClassFunction);

  OMWriteLine(stream, ["<OMA>"]);
  OMIndent := OMIndent +1;
    OMPutSymbol( stream, "group1", "character_table" );
		OMPutList(stream, classnames);
		OMPutList(stream, centralizersizes);
		OMPutList(stream, centralizerprimes);
		OMPutList(stream, centralizerindices); 
		OMPutList(stream, powmap);
		OMPutList(stream, sizesconjugacyclasses);
		OMPutList(stream, ordersclassreps);
		# OMPut(stream, irredmat); # previous cd version
		OMPutIrredMat(stream, c);
	OMIndent := OMIndent -1;
	OMWriteLine(stream, ["</OMA>"]);
end);

#############################################################################
#E
