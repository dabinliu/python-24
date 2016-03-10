#
#    Light-weight binding for the Python interpreter
#       (c) 2010 Andreas Rumpf 
#    Based on 'PythonEngine' module by Dr. Dietmar Budelsky
#
#
#************************************************************************
#                                                                        
# Module:  Unit 'PythonEngine'     Copyright (c) 1997                    
#                                                                        
# Version: 3.0                     Dr. Dietmar Budelsky                  
# Sub-Version: 0.25                dbudelsky@web.de                      
#                                  Germany                               
#                                                                        
#                                  Morgan Martinet                       
#                                  4721 rue Brebeuf                      
#                                  H2J 3L2 MONTREAL (QC)                 
#                                  CANADA                                
#                                  e-mail: mmm@free.fr                   
#                                                                        
#  look our page at: http://www.multimania.com/marat                     
#************************************************************************
#  Functionality:  Delphi Components that provide an interface to the    
#                  Python language (see python.txt for more infos on     
#                  Python itself).                                       
#                                                                        
#************************************************************************
#  Contributors:                                                         
#      Grzegorz Makarewicz (mak@mikroplan.com.pl)                        
#      Andrew Robinson (andy@hps1.demon.co.uk)                           
#      Mark Watts(mark_watts@hotmail.com)                                
#      Olivier Deckmyn (olivier.deckmyn@mail.dotcom.fr)                  
#      Sigve Tjora (public@tjora.no)                                     
#      Mark Derricutt (mark@talios.com)                                  
#      Igor E. Poteryaev (jah@mail.ru)                                   
#      Yuri Filimonov (fil65@mail.ru)                                    
#      Stefan Hoffmeister (Stefan.Hoffmeister@Econos.de)                 
#************************************************************************
# This source code is distributed with no WARRANTY, for no reason or use.
# Everyone is allowed to use and change this code free for his own tasks 
# and projects, as long as this header and its copyright text is intact. 
# For changed versions of this code, which are public distributed the    
# following additional conditions have to be fullfilled:                 
# 1) The header has to contain a comment on the change and the author of 
#    it.                                                                 
# 2) A copy of the changed source has to be sent to the above E-Mail     
#    address or my then valid address, if this is possible to the        
#    author.                                                             
# The second condition has the target to maintain an up to date central  
# version of the component. If this condition is not acceptable for      
# confidential or legal reasons, everyone is free to derive a component  
# or to generate a diff file to my or other original sources.            
# Dr. Dietmar Budelsky, 1997-11-17                                       
#************************************************************************

{.deadCodeElim: on.}

import 
  dynlib,
  strutils


when defined(windows): 
  const dllname = "python(27|26|25|24|23|22|21|20|16|15).dll"
elif defined(macosx):
  const dllname = "libpython(2.7|2.6|2.5|2.4|2.3|2.2|2.1|2.0|1.6|1.5).dylib"
else: 
  const dllver = ".1"
  const dllname = "libpython(2.7|2.6|2.5|2.4|2.3|2.2|2.1|2.0|1.6|1.5).so" & 
                  dllver

  
const 
  pytMethodBufferIncrease* = 10
  pytMemberBufferIncrease* = 10
  pytGetsetBufferIncrease* = 10
  # Flag passed to newmethodobject
  methOldargs* = 0x0000
  methVarargs* = 0x0001
  methKeywords* = 0x0002
  methNoargs* = 0x0004
  methO* = 0x0008
  methClass* = 0x0010
  methStatic* = 0x0020
  methCoexist* = 0x0040
  # Masks for the co_flags field of PyCodeObject
  coOptimized* = 0x0001
  coNewlocals* = 0x0002
  coVarargs* = 0x0004
  coVarkeywords* = 0x0008
  coNested* = 0x0010
  coGenerator* = 0x0020
  coFutureDivision* = 0x2000
  coFutureAbsoluteImport* = 0x4000
  coFutureWithStatement* = 0x8000
  coFuturePrintFunction* = 0x10000
  coFutureUnicodeLiterals* = 0x20000
{.deprecated: [PYT_METHOD_BUFFER_INCREASE: pytMethodBufferIncrease].}
{.deprecated: [PYT_MEMBER_BUFFER_INCREASE: pytMemberBufferIncrease].}
{.deprecated: [PYT_GETSET_BUFFER_INCREASE: pytGetsetBufferIncrease].}
{.deprecated: [METH_OLDARGS: methOldargs].}
{.deprecated: [METH_VARARGS: methVarargs].}
{.deprecated: [METH_KEYWORDS: methKeywords].}
{.deprecated: [METH_NOARGS: methNoargs].}
{.deprecated: [METH_O: methO].}
{.deprecated: [METH_CLASS: methClass].}
{.deprecated: [METH_STATIC: methStatic].}
{.deprecated: [METH_COEXIST: methCoexist].}
{.deprecated: [CO_OPTIMIZED: coOptimized].}
{.deprecated: [CO_NEWLOCALS: coNewlocals].}
{.deprecated: [CO_VARARGS: coVarargs].}
{.deprecated: [CO_VARKEYWORDS: coVarkeywords].}
{.deprecated: [CO_NESTED: coNested].}
{.deprecated: [CO_GENERATOR: coGenerator].}
{.deprecated: [CO_FUTURE_DIVISION: coFutureDivision].}
{.deprecated: [CO_FUTURE_ABSOLUTE_IMPORT: coFutureAbsoluteImport].}
{.deprecated: [CO_FUTURE_WITH_STATEMENT: coFutureWithStatement].}
{.deprecated: [CO_FUTURE_PRINT_FUNCTION: coFuturePrintFunction].}
{.deprecated: [CO_FUTURE_UNICODE_LITERALS: coFutureUnicodeLiterals].}

type                          
  # Rich comparison opcodes introduced in version 2.1
  RichComparisonOpcode* = enum 
    pyLT, pyLE, pyEQ, pyNE, pyGT, pyGE

const
  # PySequenceMethods contains sq_contains
  pyTpflagsHaveGetCharBuffer* = (1 shl 0)
  # Objects which participate in garbage collection (see objimp.h)
  pyTpflagsHaveSequenceIn* = (1 shl 1)
  # PySequenceMethods and PyNumberMethods contain in-place operators
  pyTpflagsGc* = (1 shl 2)
  # PyNumberMethods do their own Coercion
  pyTpflagsHaveInplaceops* = (1 shl 3)
  pyTpflagsCheckTypes* = (1 shl 4)
  # Objects which are weakly referencable if their tp_weaklistoffset is > 0
  # XXX Should this have the same value as Py_TPFLAGS_HAVE_RICHCOMPARE?
  # These both indicate a feature that appeared in the same alpha release.
  pyTpflagsHaveRichCompare* = (1 shl 5)
  # tp_iter is defined
  pyTpflagsHaveWeakRefs* = (1 shl 6)
  # New members introduced by Python 2.2 exist
  pyTpflagsHaveIter* = (1 shl 7)
  # Set if the type object is dynamically allocated
  pyTpflagsHaveClass* = (1 shl 8)
  # Set if the type allows subclassing
  pyTpflagsHeapType* = (1 shl 9)
  # Set if the type is 'ready' -- fully initialized
  pyTpflagsBaseType* = (1 shl 10)
  # Set while the type is being 'readied', to prevent recursive ready calls
  pyTpflagsReady* = (1 shl 12)
  # Objects support garbage collection (see objimp.h)
  pyTpflagsReadying* = (1 shl 13)
  pyTpflagsHaveGc* = (1 shl 14)
  pyTpflagsDefault* = pyTpflagsHaveGetCharBuffer or
                      pyTpflagsHaveSequenceIn or
                      pyTpflagsHaveInplaceops or
                      pyTpflagsHaveRichCompare or 
                      pyTpflagsHaveWeakRefs or
                      pyTpflagsHaveIter or 
                      pyTpflagsHaveClass
{.deprecated: [Py_TPFLAGS_HAVE_GETCHARBUFFER: pyTpflagsHaveGetCharBuffer].}
{.deprecated: [Py_TPFLAGS_HAVE_SEQUENCE_IN: pyTpflagsHaveSequenceIn].}
{.deprecated: [Py_TPFLAGS_GC: pyTpflagsGc].}
{.deprecated: [Py_TPFLAGS_HAVE_INPLACEOPS: pyTpflagsHaveInplaceops].}
{.deprecated: [Py_TPFLAGS_CHECKTYPES: pyTpflagsCheckTypes].}
{.deprecated: [Py_TPFLAGS_HAVE_RICHCOMPARE: pyTpflagsHaveRichCompare].}
{.deprecated: [Py_TPFLAGS_HAVE_WEAKREFS: pyTpflagsHaveWeakRefs].}
{.deprecated: [Py_TPFLAGS_HAVE_ITER: pyTpflagsHaveIter].}
{.deprecated: [Py_TPFLAGS_HAVE_CLASS: pyTpflagsHaveClass].}
{.deprecated: [Py_TPFLAGS_HEAPTYPE: pyTpflagsHeapType].}
{.deprecated: [Py_TPFLAGS_BASETYPE: pyTpflagsBaseType].}
{.deprecated: [Py_TPFLAGS_READY: pyTpflagsReady].}
{.deprecated: [Py_TPFLAGS_READYING: pyTpflagsReadying].}
{.deprecated: [Py_TPFLAGS_HAVE_GC: pyTpflagsHaveGc].}
{.deprecated: [Py_TPFLAGS_DEFAULT: pyTpflagsDefault].}

type 
  PFlag* = enum 
    tpfHaveGetCharBuffer, tpfHaveSequenceIn, tpfGC, tpfHaveInplaceOps, 
    tpfCheckTypes, tpfHaveRichCompare, tpfHaveWeakRefs, tpfHaveIter, 
    tpfHaveClass, tpfHeapType, tpfBaseType, tpfReady, tpfReadying, tpfHaveGC
  PFlags* = set[PFlag]

const 
  tpflagsDefault* = {tpfHaveGetCharBuffer, tpfHaveSequenceIn, 
    tpfHaveInplaceOps, tpfHaveRichCompare, tpfHaveWeakRefs, tpfHaveIter, 
    tpfHaveClass}
{.deprecated: [TPFLAGS_DEFAULT: tpflagsDefault].}

const # Python opcodes
  singleInput* = 256 
  fileInput* = 257
  evalInput* = 258
  funcdef* = 259
  parameters* = 260
  varargslist* = 261
  fpdef* = 262
  fplist* = 263
  stmt* = 264
  simpleStmt* = 265
  smallStmt* = 266
  exprStmt* = 267
  augassign* = 268
  printStmt* = 269
  delStmt* = 270
  passStmt* = 271
  flowStmt* = 272
  breakStmt* = 273
  continueStmt* = 274
  returnStmt* = 275
  raiseStmt* = 276
  importStmt* = 277
  importAsName* = 278
  dottedAsName* = 279
  dottedName* = 280
  globalStmt* = 281
  execStmt* = 282
  assertStmt* = 283
  compoundStmt* = 284
  ifStmt* = 285
  whileStmt* = 286
  forStmt* = 287
  tryStmt* = 288
  exceptClause* = 289
  suite* = 290
  test* = 291
  andTest* = 291
  notTest* = 293
  comparison* = 294
  compOp* = 295
  expr* = 296
  xorExpr* = 297
  andExpr* = 298
  shiftExpr* = 299
  arithExpr* = 300
  term* = 301
  factor* = 302
  power* = 303
  atom* = 304
  listmaker* = 305
  lambdef* = 306
  trailer* = 307
  subscriptlist* = 308
  subscript* = 309
  sliceop* = 310
  exprlist* = 311
  testlist* = 312
  dictmaker* = 313
  classdef* = 314
  arglist* = 315
  argument* = 316
  listIter* = 317
  listFor* = 318
  listIf* = 319

const 
  tShort* = 0
  tInt* = 1
  tLong* = 2
  tFloat* = 3
  tDouble* = 4
  tString* = 5
  tObject* = 6
  tChar* = 7                 # 1-character string
  tByte* = 8                 # 8-bit signed int
  tUbyte* = 9
  tUshort* = 10
  tUint* = 11
  tUlong* = 12
  tStringInplace* = 13
  tObjectEx* = 16 
  readonly* = 1
  ro* = readonly              # Shorthand 
  readRestricted* = 2
  writeRestricted* = 4
  restricted* = (readRestricted or writeRestricted)
  pySingleInput* = 256
  pyFileInput*   = 257
  pyEvalInput*   = 258
{.deprecated: [T_SHORT: tShort].}
{.deprecated: [T_INT: tInt].}
{.deprecated: [T_LONG: tLong].}
{.deprecated: [T_FLOAT: tFloat].}
{.deprecated: [T_DOUBLE: tDouble].}
{.deprecated: [T_STRING: tString].}
{.deprecated: [T_OBJECT: tObject].}
{.deprecated: [T_CHAR: tChar].}
{.deprecated: [T_BYTE: tByte].}
{.deprecated: [T_UBYTE: tUbyte].}
{.deprecated: [T_USHORT: tUshort].}
{.deprecated: [T_UINT: tUint].}
{.deprecated: [T_ULONG: tUlong].}
{.deprecated: [T_STRING_INPLACE: tStringInplace].}
{.deprecated: [T_OBJECT_EX: tObjectEx].}
{.deprecated: [READ_RESTRICTED: readRestricted].}
{.deprecated: [WRITE_RESTRICTED: writeRestricted].}

type 
  PyMemberType* = enum 
    mtShort, mtInt, mtLong, mtFloat, mtDouble, mtString, mtObject, mtChar, 
    mtByte, mtUByte, mtUShort, mtUInt, mtULong, mtStringInplace, mtObjectEx
  
  PyMemberFlag* = enum 
    mfDefault, mfReadOnly, mfReadRestricted, mfWriteRestricted, mfRestricted
  
  IntPtr* = ptr int
  
type
  CstringPtr* = ptr cstring
  FrozenPtrPtr* = ptr Frozen
  FrozenPtr* = ptr Frozen
  PyObjectPtr* = ptr PyObject
  PyObjectPtrPtr* = ptr PyObjectPtr
  PyObjectPtrPtrPtr* = ptr PyObjectPtrPtr
  PyIntObjectPtr* = ptr PyIntObject
  PyTypeObjectPtr* = ptr PyTypeObject
  PySliceObjectPtr* = ptr PySliceObject
  PyCFunction* = proc (self, args: PyObjectPtr): PyObjectPtr{.cdecl.}
  UnaryFunc* = proc (ob1: PyObjectPtr): PyObjectPtr{.cdecl.}
  BinaryFunc* = proc (ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl.}
  TernaryFunc* = proc (ob1, ob2, ob3: PyObjectPtr): PyObjectPtr{.cdecl.}
  Inquiry* = proc (ob1: PyObjectPtr): int{.cdecl.}
  Coercion* = proc (ob1, ob2: PyObjectPtrPtr): int{.cdecl.}
  IntArgFunc* = proc (ob1: PyObjectPtr, i: int): PyObjectPtr{.cdecl.}
  IntIntArgFunc* = proc (ob1: PyObjectPtr, i1, i2: int): PyObjectPtr{.cdecl.}
  IntObjArgProc* = proc (ob1: PyObjectPtr, i: int, 
                         ob2: PyObjectPtr): int{.cdecl.}
  IntIntObjArgProc* = proc (ob1: PyObjectPtr, i1, i2: int, 
                            ob2: PyObjectPtr): int{.cdecl.}
  ObjObjargProc* = proc (ob1, ob2, ob3: PyObjectPtr): int{.cdecl.}
  PyDestructor* = proc (ob: PyObjectPtr){.cdecl.}
  PrintFunc* = proc (ob: PyObjectPtr, f: File, i: int): int{.cdecl.}
  GetAttrFunc* = proc (ob1: PyObjectPtr, name: cstring): PyObjectPtr{.cdecl.}
  SetAttrFunc* = proc (ob1: PyObjectPtr, name: cstring, 
                       ob2: PyObjectPtr): int{.cdecl.}
  CmpFunc* = proc (ob1, ob2: PyObjectPtr): int{.cdecl.}
  ReprFunc* = proc (ob: PyObjectPtr): PyObjectPtr{.cdecl.}
  HashFunc* = proc (ob: PyObjectPtr): int32{.cdecl.}
  GetAttroFunc* = proc (ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl.}
  SetAttroFunc* = proc (ob1, ob2, ob3: PyObjectPtr): int{.cdecl.} 
  GetReadBufferProc* = proc (ob1: PyObjectPtr, i: int, p: pointer): int{.cdecl.}
  GetWriteBufferProc* = proc (ob1: PyObjectPtr, i: int, 
                              p: pointer): int{.cdecl.}
  GetSegCountProc* = proc (ob1: PyObjectPtr, i: int): int{.cdecl.}
  GetCharBufferProc* = proc (ob1: PyObjectPtr, 
                             i: int, pstr: cstring): int{.cdecl.}
  ObjObjProc* = proc (ob1, ob2: PyObjectPtr): int{.cdecl.}
  VisitProc* = proc (ob1: PyObjectPtr, p: pointer): int{.cdecl.}
  TraverseProc* = proc (ob1: PyObjectPtr, prc: VisitProc, 
                        p: pointer): int{.cdecl.}
  RichCmpFunc* = proc (ob1, ob2: PyObjectPtr, i: int): PyObjectPtr{.cdecl.}
  GetIterFunc* = proc (ob1: PyObjectPtr): PyObjectPtr{.cdecl.}
  IterNextFunc* = proc (ob1: PyObjectPtr): PyObjectPtr{.cdecl.}
  DescrGetFunc* = proc (ob1, ob2, ob3: PyObjectPtr): PyObjectPtr{.cdecl.}
  DescrSetFunc* = proc (ob1, ob2, ob3: PyObjectPtr): int{.cdecl.}
  InitProc* = proc (self, args, kwds: PyObjectPtr): int{.cdecl.}
  NewFunc* = proc (subtype: PyTypeObjectPtr, 
                   args, kwds: PyObjectPtr): PyObjectPtr{.cdecl.}
  AllocFunc* = proc (self: PyTypeObjectPtr, nitems: int): PyObjectPtr{.cdecl.}
  PyNumberMethods*{.final.} = object 
    nbAdd*: BinaryFunc
    nbSubstract*: BinaryFunc
    nbMultiply*: BinaryFunc
    nbDivide*: BinaryFunc
    nbRemainder*: BinaryFunc
    nbDivmod*: BinaryFunc
    nbPower*: TernaryFunc
    nbNegative*: UnaryFunc
    nbPositive*: UnaryFunc
    nbAbsolute*: UnaryFunc
    nbNonzero*: Inquiry
    nbInvert*: UnaryFunc
    nbLshift*: BinaryFunc
    nbRshift*: BinaryFunc
    nbAnd*: BinaryFunc
    nbXor*: BinaryFunc
    nbOr*: BinaryFunc
    nbCoerce*: Coercion
    nbInt*: UnaryFunc
    nbLong*: UnaryFunc
    nbFloat*: UnaryFunc
    nbOct*: UnaryFunc
    nbHex*: UnaryFunc       
    # jah 29-sep-2000: updated for python 2.0 added from .h
    nbInplaceAdd*: BinaryFunc
    nbInplaceSubtract*: BinaryFunc
    nbInplaceMultiply*: BinaryFunc
    nbInplaceDivide*: BinaryFunc
    nbInplaceRemainder*: BinaryFunc
    nbInplacePower*: TernaryFunc
    nbInplaceLshift*: BinaryFunc
    nbInplaceRshift*: BinaryFunc
    nbInplaceAnd*: BinaryFunc
    nbInplaceXor*: BinaryFunc
    nbInplaceOr*: BinaryFunc 
    # Added in release 2.2
    # The following require the pyTpflagsHaveClass flag
    nbFloorDivide*: BinaryFunc
    nbTrueDivide*: BinaryFunc
    nbInplaceFloorDivide*: BinaryFunc
    nbInplaceTrueDivide*: BinaryFunc

  PyNumberMethodsPtr* = ptr PyNumberMethods
  PySequenceMethods*{.final.} = object 
    sqLength*: Inquiry
    sqConcat*: BinaryFunc
    sqRepeat*: IntArgFunc
    sqItem*: IntArgFunc
    sqSlice*: IntIntArgFunc
    sqAssItem*: IntObjArgProc
    sqAssSlice*: IntIntObjArgProc 
    sqContains*: ObjObjProc
    sqInplaceConcat*: BinaryFunc
    sqInplaceRepeat*: IntArgFunc

  PySequenceMethodsPtr* = ptr PySequenceMethods
  PyMappingMethods*{.final.} = object 
    mpLength*: Inquiry
    mpSubscript*: BinaryFunc
    mpAssSubscript*: ObjObjargProc

  PyMappingMethodsPtr* = ptr PyMappingMethods 
  PyBufferProcs*{.final.} = object 
    bfGetreadbuffer*: GetReadBufferProc
    bfGetwritebuffer*: GetWriteBufferProc
    bfGetsegcount*: GetSegCountProc
    bfGetcharbuffer*: GetCharBufferProc

  PyBufferProcsPtr* = ptr PyBufferProcs
  PyComplex*{.final.} = object 
    float*: float64
    imag*: float64

  PyObject*{.pure, inheritable.} = object 
    obRefcnt*: int
    obType*: PyTypeObjectPtr

  PyIntObject* = object of RootObj
    obIval*: int32

  BytePtr* = ptr int8
  Frozen*{.final.} = object 
    name*: cstring
    code*: BytePtr
    size*: int

  PySliceObject* = object of PyObject
    start*, stop*, step*: PyObjectPtr

  PyMethodDefPtr* = ptr PyMethodDef
  PyMethodDef*{.final.} = object  # structmember.h
    mlName*: cstring
    mlMeth*: PyCFunction
    mlFlags*: int
    mlDoc*: cstring

  PyMemberDefPtr* = ptr PyMemberDef
  PyMemberDef*{.final.} = object  # descrobject.h Descriptors
    name*: cstring
    theType*: int
    offset*: int
    flags*: int
    doc*: cstring

  Getter* = proc (obj: PyObjectPtr, context: pointer): PyObjectPtr{.cdecl.}
  Setter* = proc (obj, value: PyObjectPtr, context: pointer): int{.cdecl.}
  PyGetSetDefPtr* = ptr PyGetSetDef
  PyGetSetDef*{.final.} = object 
    name*: cstring
    get*: Getter
    Setter*: Setter
    doc*: cstring
    closure*: pointer

  wrapperfunc* = proc (self, args: PyObjectPtr, 
                       wrapped: pointer): PyObjectPtr{.cdecl.}
  wrapperbasePtr* = ptr wrapperbase

  # Various kinds of descriptor objects
  # #define PyDescr_COMMON \
  #          PyObject_HEAD \
  #          PyTypeObject *d_type; \
  #          PyObject *d_name
  wrapperbase*{.final.} = object
    name*: cstring
    wrapper*: wrapperfunc
    doc*: cstring

  PyDescrObjectPtr* = ptr PyDescrObject
  PyDescrObject* = object of PyObject
    dType*: PyTypeObjectPtr
    dName*: PyObjectPtr

  PyMethodDescrObjectPtr* = ptr PyMethodDescrObject
  PyMethodDescrObject* = object of PyDescrObject
    dMethod*: PyMethodDefPtr

  PyMemberDescrObjectPtr* = ptr PyMemberDescrObject
  PyMemberDescrObject* = object of PyDescrObject
    dMember*: PyMemberDefPtr

  PyGetSetDescrObjectPtr* = ptr PyGetSetDescrObject
  PyGetSetDescrObject* = object of PyDescrObject
    dGetset*: PyGetSetDefPtr

  PyWrapperDescrObjectPtr* = ptr PyWrapperDescrObject
  PyWrapperDescrObject* = object of PyDescrObject # object.h
    dBase*: wrapperbasePtr
    dWrapped*: pointer       # This can be any function pointer
  
  PyTypeObject* = object of PyObject
    obSize*: int             # Number of items in variable part
    tpName*: cstring         # For printing
    tpBasicsize*, tpItemsize*: int # For allocation
    # Methods to implement standard operations
    tpDealloc*: PyDestructor
    tpPrint*: PrintFunc
    tpGetattr*: GetAttrFunc
    tpSetattr*: SetAttrFunc
    tpCompare*: CmpFunc
    tpRepr*: ReprFunc
    # Method suites for standard classes
    tpAsNumber*: PyNumberMethodsPtr
    tpAsSequence*: PySequenceMethodsPtr
    # More standard operations (here for binary compatibility)
    tpAsMapping*: PyMappingMethodsPtr
    tpHash*: HashFunc
    tpCall*: TernaryFunc
    tpStr*: ReprFunc
    tpGetattro*: GetAttroFunc
    tpSetattro*: SetAttroFunc
    # Functions to access object as input/output buffer
    tpAsBuffer*: PyBufferProcsPtr
    # Flags to define presence of optional/expanded features
    tpFlags*: int32
    # Documentation string
    tpDoc*: cstring
    # call function for all accessible objects
    tpTraverse*: TraverseProc
    # delete references to contained objects
    tpClear*: Inquiry
    # rich comparisons
    tpRichcompare*: RichCmpFunc
    # weak reference enabler
    tpWeaklistoffset*: int32
    # Iterators
    tpIter*: GetIterFunc
    tpIternext*: IterNextFunc
    # Attribute descriptor and subclassing stuff
    tpMethods*: PyMethodDefPtr
    tpMembers*: PyMemberDefPtr
    tpGetset*: PyGetSetDefPtr
    tpBase*: PyTypeObjectPtr
    tpDict*: PyObjectPtr
    tpDescrGet*: DescrGetFunc
    tpDescrSet*: DescrSetFunc
    tpDictoffset*: int32
    tpInit*: InitProc
    tpAlloc*: AllocFunc
    tpNew*: NewFunc
    tpFree*: PyDestructor   # Low-level free-memory routine
    tpIsGc*: Inquiry       # For PyObject_IS_GC
    tpBases*: PyObjectPtr
    tpMro*: PyObjectPtr        # method resolution order
    tpCache*: PyObjectPtr
    tpSubclasses*: PyObjectPtr
    tpWeaklist*: PyObjectPtr
    #More spares
    tpXxx7*: pointer
    tpXxx8*: pointer

  PyMethodChainPtr* = ptr PyMethodChain
  PyMethodChain*{.final.} = object 
    methods*: PyMethodDefPtr
    link*: PyMethodChainPtr

  PyClassObjectPtr* = ptr PyClassObject
  PyClassObject* = object of PyObject
    clBases*: PyObjectPtr      # A tuple of class objects
    clDict*: PyObjectPtr       # A dictionary
    clName*: PyObjectPtr       # A string
    # The following three are functions or NULL
    clGetattr*: PyObjectPtr
    clSetattr*: PyObjectPtr
    clDelattr*: PyObjectPtr

  PyInstanceObjectPtr* = ptr PyInstanceObject
  PyInstanceObject* = object of PyObject 
    inClass*: PyClassObjectPtr # The class object
    inDict*: PyObjectPtr       # A dictionary
  
  PyMethodObjectPtr* = ptr PyMethodObject
  PyMethodObject* = object of PyObject # Bytecode object, compile.h
    imFunc*: PyObjectPtr       # The function implementing the method
    imSelf*: PyObjectPtr       # The instance it is bound to, or NULL
    imClass*: PyObjectPtr      # The class that defined the method
  
  PyCodeObjectPtr* = ptr PyCodeObject
  PyCodeObject* = object of PyObject # from pystate.h
    coArgcount*: int         # #arguments, except *args
    coNlocals*: int          # #local variables
    coStacksize*: int        # #entries needed for evaluation stack
    coFlags*: int            # CO_..., see below
    coCode*: PyObjectPtr       # instruction opcodes (it hides a PyStringObject)
    coConsts*: PyObjectPtr     # list (constants used)
    coNames*: PyObjectPtr      # list of strings (names used)
    coVarnames*: PyObjectPtr   # tuple of strings (local variable names)
    coFreevars*: PyObjectPtr   # tuple of strings (free variable names)
    coCellvars*: PyObjectPtr   # tuple of strings (cell variable names)
    # The rest doesn't count for hash/cmp
    coFilename*: PyObjectPtr   # string (where it was loaded from)
    coName*: PyObjectPtr       # string (name, for reference)
    coFirstlineno*: int      # first source line number
    coLnotab*: PyObjectPtr     # string (encoding addr<->lineno mapping)
  
  PyInterpreterStatePtr* = ptr PyInterpreterState
  PyThreadStatePtr* = ptr PyThreadState
  PyFrameObjectPtr* = ptr PyFrameObject # Interpreter environments
  PyInterpreterState*{.final.} = object  # Thread specific information
    next*: PyInterpreterStatePtr
    tstate_head*: PyThreadStatePtr
    modules*: PyObjectPtr
    sysdict*: PyObjectPtr
    builtins*: PyObjectPtr
    checkinterval*: int

  PyThreadState*{.final.} = object  # from frameobject.h
    next*: PyThreadStatePtr
    interp*: PyInterpreterStatePtr
    frame*: PyFrameObjectPtr
    recursionDepth*: int
    ticker*: int
    tracing*: int
    sysProfilefunc*: PyObjectPtr
    sysTracefunc*: PyObjectPtr
    curexcType*: PyObjectPtr
    curexcValue*: PyObjectPtr
    curexcTraceback*: PyObjectPtr
    excType*: PyObjectPtr
    excValue*: PyObjectPtr
    excTraceback*: PyObjectPtr
    dict*: PyObjectPtr

  PyTryBlockPtr* = ptr PyTryBlock
  PyTryBlock*{.final.} = object 
    bType*: int              # what kind of block this is
    bHandler*: int           # where to jump to find handler
    bLevel*: int             # value stack level to pop to
  
  coMaxblocks* = range[0..19]
  PyFrameObject* = object of PyObject # start of the VAR_HEAD of an object
    # From traceback.c
    obSize*: int             # Number of items in variable part
    # End of the Head of an object
    fBack*: PyFrameObjectPtr   # previous frame, or NULL
    fCode*: PyCodeObjectPtr    # code segment
    fBuiltins*: PyObjectPtr    # builtin symbol table (PyDictObject)
    fGlobals*: PyObjectPtr     # global symbol table (PyDictObject)
    fLocals*: PyObjectPtr      # local symbol table (PyDictObject)
    fValuestack*: PyObjectPtrPtr # points after the last local
                              # Next free slot in f_valuestack. Frame creation sets to f_valuestack.
                              # Frame evaluation usually NULLs it, but a frame that yields sets it
                              # to the current stack top. 
    fStacktop*: PyObjectPtrPtr
    fTrace*: PyObjectPtr       # Trace function
    fExcType*, fExcValue*, fExcTraceback*: PyObjectPtr
    fTstate*: PyThreadStatePtr
    fLasti*: int             # Last instruction if called
    fLineno*: int            # Current line number
    fRestricted*: int        # Flag set if restricted operations
                              # in this scope
    fIblock*: int            # index in f_blockstack
    fBlockstack*: array[coMaxblocks, PyTryBlock] # for try and loop blocks
    fNlocals*: int           # number of locals
    fNcells*: int
    fNfreevars*: int
    fStacksize*: int         # size of value stack
    fLocalsplus*: array[0..0, PyObjectPtr] # locals+stack, dynamically sized
  
  PyTraceBackObjectPtr* = ptr PyTraceBackObject
  PyTraceBackObject* = object of PyObject # Parse tree node interface
    tbNext*: PyTraceBackObjectPtr
    tbFrame*: PyFrameObjectPtr
    tbLasti*: int
    tbLineno*: int

  NodePtr* = ptr Node
  Node*{.final.} = object    # From weakrefobject.h
    nType*: int16
    nStr*: cstring
    nLineno*: int16
    nNchildren*: int16
    nChild*: NodePtr

  PyWeakReferencePtr* = ptr PyWeakReference
  PyWeakReference* = object of PyObject 
    wr_object*: PyObjectPtr
    wr_callback*: PyObjectPtr
    hash*: int32
    wr_prev*: PyWeakReferencePtr
    wr_next*: PyWeakReferencePtr
{.deprecated: [CO_MAXBLOCKS: coMaxblocks].}

const                         
  pydatetimeDateDatasize* = 4 # of bytes for year, month, and day
  pydatetimeTimeDatasize* = 6 # of bytes for hour, minute, second, and usecond
  pydatetimeDatetimeDatasize* = 10 # of bytes for year, month, 
                                   # day, hour, minute, second, and usecond.
{.deprecated: [PyDateTime_DATE_DATASIZE: pydatetimeDateDatasize].}
{.deprecated: [PyDateTime_TIME_DATASIZE: pydatetimeTimeDatasize].}
{.deprecated: [PyDateTime_DATETIME_DATASIZE: pydatetimeDatetimeDatasize].}

type 
  PyDateTimeDelta* = object of PyObject
    hashcode*: int            # -1 when unknown
    days*: int                # -MAX_DELTA_DAYS <= days <= MAX_DELTA_DAYS
    seconds*: int             # 0 <= seconds < 24*3600 is invariant
    microseconds*: int        # 0 <= microseconds < 1000000 is invariant
  
  PyDateTimeDeltaPtr* = ptr PyDateTimeDelta
  PyDateTimeTZInfo* = object of PyObject # a pure abstract base clase
  PyDateTimeTZInfoPtr* = ptr PyDateTimeTZInfo 
  PyDateTimeBaseTZInfo* = object of PyObject
    hashcode*: int
    # boolean flag
    hastzinfo*: bool
  
  PyDateTimeBaseTZInfoPtr* = ptr PyDateTimeBaseTZInfo 
  PyDateTimeBaseTime* = object of PyDateTimeBaseTZInfo
    data*: array[0..pred(pydatetimeTimeDatasize), int8]

  PyDateTimeBaseTimePtr* = ptr PyDateTimeBaseTime
  PyDateTimeTime* = object of PyDateTimeBaseTime # hastzinfo true
    tzinfo*: PyObjectPtr

  PyDateTimeTimePtr* = ptr PyDateTimeTime 
  PyDateTimeDate* = object of PyDateTimeBaseTZInfo
    data*: array[0..pred(pydatetimeDateDatasize), int8]

  PyDateTimeDatePtr* = ptr PyDateTimeDate 
  PyDateTimeBaseDateTime* = object of PyDateTimeBaseTZInfo
    data*: array[0..pred(pydatetimeDatetimeDatasize), int8]

  PyDateTimeBaseDateTimePtr* = ptr PyDateTimeBaseDateTime
  PyDateTimeDateTime* = object of PyDateTimeBaseTZInfo
    data*: array[0..pred(pydatetimeDatetimeDatasize), int8]
    tzinfo*: PyObjectPtr

  PyDateTimeDateTimePtr* = ptr PyDateTimeDateTime

#----------------------------------------------------#
#                                                    #
#         New exception classes                      #
#                                                    #
#----------------------------------------------------#

#
#  // Python's exceptions
#  EPythonError   = object(Exception)
#      EName: String;
#      EValue: String;
#  end;
#  EPyExecError   = object(EPythonError)
#  end;
#
#  // Standard exception classes of Python
#
#/// jah 29-sep-2000: updated for python 2.0
#///                   base classes updated according python documentation
#
#{ Hierarchy of Python exceptions, Python 2.3, copied from <INSTALL>\Python\exceptions.c
#
#Exception\n\
# |\n\
# +-- SystemExit\n\
# +-- StopIteration\n\
# +-- StandardError\n\
# |    |\n\
# |    +-- KeyboardInterrupt\n\
# |    +-- ImportError\n\
# |    +-- EnvironmentError\n\
# |    |    |\n\
# |    |    +-- IOError\n\
# |    |    +-- OSError\n\
# |    |         |\n\
# |    |         +-- WindowsError\n\
# |    |         +-- VMSError\n\
# |    |\n\
# |    +-- EOFError\n\
# |    +-- RuntimeError\n\
# |    |    |\n\
# |    |    +-- NotImplementedError\n\
# |    |\n\
# |    +-- NameError\n\
# |    |    |\n\
# |    |    +-- UnboundLocalError\n\
# |    |\n\
# |    +-- AttributeError\n\
# |    +-- SyntaxError\n\
# |    |    |\n\
# |    |    +-- IndentationError\n\
# |    |         |\n\
# |    |         +-- TabError\n\
# |    |\n\
# |    +-- TypeError\n\
# |    +-- AssertionError\n\
# |    +-- LookupError\n\
# |    |    |\n\
# |    |    +-- IndexError\n\
# |    |    +-- KeyError\n\
# |    |\n\
# |    +-- ArithmeticError\n\
# |    |    |\n\
# |    |    +-- OverflowError\n\
# |    |    +-- ZeroDivisionError\n\
# |    |    +-- FloatingPointError\n\
# |    |\n\
# |    +-- ValueError\n\
# |    |    |\n\
# |    |    +-- UnicodeError\n\
# |    |        |\n\
# |    |        +-- UnicodeEncodeError\n\
# |    |        +-- UnicodeDecodeError\n\
# |    |        +-- UnicodeTranslateError\n\
# |    |\n\
# |    +-- ReferenceError\n\
# |    +-- SystemError\n\
# |    +-- MemoryError\n\
# |\n\
# +---Warning\n\
#      |\n\
#      +-- UserWarning\n\
#      +-- DeprecationWarning\n\
#      +-- PendingDeprecationWarning\n\
#      +-- SyntaxWarning\n\
#      +-- OverflowWarning\n\
#      +-- RuntimeWarning\n\
#      +-- FutureWarning"
#}
#   EPyException = class (EPythonError);
#   EPyStandardError = class (EPyException);
#   EPyArithmeticError = class (EPyStandardError);
#   EPyLookupError = class (EPyStandardError);
#   EPyAssertionError = class (EPyStandardError);
#   EPyAttributeError = class (EPyStandardError);
#   EPyEOFError = class (EPyStandardError);
#   EPyFloatingPointError = class (EPyArithmeticError);
#   EPyEnvironmentError = class (EPyStandardError);
#   EPyIOError = class (EPyEnvironmentError);
#   EPyOSError = class (EPyEnvironmentError);
#   EPyImportError = class (EPyStandardError);
#   EPyIndexError = class (EPyLookupError);
#   EPyKeyError = class (EPyLookupError);
#   EPyKeyboardInterrupt = class (EPyStandardError);
#   EPyMemoryError = class (EPyStandardError);
#   EPyNameError = class (EPyStandardError);
#   EPyOverflowError = class (EPyArithmeticError);
#   EPyRuntimeError = class (EPyStandardError);
#   EPyNotImplementedError = class (EPyRuntimeError);
#   EPySyntaxError = class (EPyStandardError)
#   public
#      EFileName: string;
#      ELineStr: string;
#      ELineNumber: Integer;
#      EOffset: Integer;
#   end;
#   EPyIndentationError = class (EPySyntaxError);
#   EPyTabError = class (EPyIndentationError);
#   EPySystemError = class (EPyStandardError);
#   EPySystemExit = class (EPyException);
#   EPyTypeError = class (EPyStandardError);
#   EPyUnboundLocalError = class (EPyNameError);
#   EPyValueError = class (EPyStandardError);
#   EPyUnicodeError = class (EPyValueError);
#   UnicodeEncodeError = class (EPyUnicodeError);
#   UnicodeDecodeError = class (EPyUnicodeError);
#   UnicodeTranslateError = class (EPyUnicodeError);
#   EPyZeroDivisionError = class (EPyArithmeticError);
#   EPyStopIteration = class(EPyException);
#   EPyWarning = class (EPyException);
#   EPyUserWarning = class (EPyWarning);
#   EPyDeprecationWarning = class (EPyWarning);
#   PendingDeprecationWarning = class (EPyWarning);
#   FutureWarning = class (EPyWarning);
#   EPySyntaxWarning = class (EPyWarning);
#   EPyOverflowWarning = class (EPyWarning);
#   EPyRuntimeWarning = class (EPyWarning);
#   EPyReferenceError = class (EPyStandardError);


var 
  PyArg_Parse*: proc (args: PyObjectPtr, format: cstring): int{.cdecl, varargs.} 
  PyArg_ParseTuple*: proc (args: PyObjectPtr, format: cstring, x1: pointer = nil, 
                           x2: pointer = nil, x3: pointer = nil): int{.cdecl, varargs.} 
  Py_BuildValue*: proc (format: cstring): PyObjectPtr{.cdecl, varargs.} 
  PyCode_Addr2Line*: proc (co: PyCodeObjectPtr, addrq: int): int{.cdecl.}
  DLL_Py_GetBuildInfo*: proc (): cstring{.cdecl.}

var
  pyDebugFlag*: IntPtr
  pyVerboseFlag*: IntPtr
  pyInteractiveFlag*: IntPtr
  pyOptimizeFlag*: IntPtr
  pyNoSiteFlag*: IntPtr
  pyUseClassExceptionsFlag*: IntPtr
  pyFrozenFlag*: IntPtr
  pyTabcheckFlag*: IntPtr
  pyUnicodeFlag*: IntPtr
  pyIgnoreEnvironmentFlag*: IntPtr
  pyDivisionWarningFlag*: IntPtr 
  #_PySys_TraceFunc: PyObjectPtrPtr;
  #_PySys_ProfileFunc: PyObjectPtrPtrPtr;
  pyImportFrozenModules*: FrozenPtrPtr
  pyNone*: PyObjectPtr
  pyEllipsis*: PyObjectPtr
  pyFalse*: PyIntObjectPtr
  pyTrue*: PyIntObjectPtr
  pyNotImplemented*: PyObjectPtr
  pyExcAttributeError*: PyObjectPtrPtr
  pyExcEOFError*: PyObjectPtrPtr
  pyExcIOError*: PyObjectPtrPtr
  pyExcImportError*: PyObjectPtrPtr
  pyExcIndexError*: PyObjectPtrPtr
  pyExcKeyError*: PyObjectPtrPtr
  pyExcKeyboardInterrupt*: PyObjectPtrPtr
  pyExcMemoryError*: PyObjectPtrPtr
  pyExcNameError*: PyObjectPtrPtr
  pyExcOverflowError*: PyObjectPtrPtr
  pyExcRuntimeError*: PyObjectPtrPtr
  pyExcSyntaxError*: PyObjectPtrPtr
  pyExcSystemError*: PyObjectPtrPtr
  pyExcSystemExit*: PyObjectPtrPtr
  pyExcTypeError*: PyObjectPtrPtr
  pyExcValueError*: PyObjectPtrPtr
  pyExcZeroDivisionError*: PyObjectPtrPtr
  pyExcArithmeticError*: PyObjectPtrPtr
  pyExcException*: PyObjectPtrPtr
  pyExcFloatingPointError*: PyObjectPtrPtr
  pyExcLookupError*: PyObjectPtrPtr
  pyExcStandardError*: PyObjectPtrPtr
  pyExcAssertionError*: PyObjectPtrPtr
  pyExcEnvironmentError*: PyObjectPtrPtr
  pyExcIndentationError*: PyObjectPtrPtr
  pyExcMemoryErrorInst*: PyObjectPtrPtr
  pyExcNotImplementedError*: PyObjectPtrPtr
  pyExcOSError*: PyObjectPtrPtr
  pyExcTabError*: PyObjectPtrPtr
  pyExcUnboundLocalError*: PyObjectPtrPtr
  pyExcUnicodeError*: PyObjectPtrPtr
  pyExcWarning*: PyObjectPtrPtr
  pyExcDeprecationWarning*: PyObjectPtrPtr
  pyExcRuntimeWarning*: PyObjectPtrPtr
  pyExcSyntaxWarning*: PyObjectPtrPtr
  pyExcUserWarning*: PyObjectPtrPtr
  pyExcOverflowWarning*: PyObjectPtrPtr
  pyExcReferenceError*: PyObjectPtrPtr
  pyExcStopIteration*: PyObjectPtrPtr
  pyExcFutureWarning*: PyObjectPtrPtr
  pyExcPendingDeprecationWarning*: PyObjectPtrPtr
  pyExcUnicodeDecodeError*: PyObjectPtrPtr
  pyExcUnicodeEncodeError*: PyObjectPtrPtr
  pyExcUnicodeTranslateError*: PyObjectPtrPtr
  pyTypeType*: PyTypeObjectPtr
  pyCfunctionType*: PyTypeObjectPtr
  pyCobjectType*: PyTypeObjectPtr
  pyClassType*: PyTypeObjectPtr
  pyCodeType*: PyTypeObjectPtr
  pyComplexType*: PyTypeObjectPtr
  pyDictType*: PyTypeObjectPtr
  pyFileType*: PyTypeObjectPtr
  pyFloatType*: PyTypeObjectPtr
  pyFrameType*: PyTypeObjectPtr
  pyFunctionType*: PyTypeObjectPtr
  pyInstanceType*: PyTypeObjectPtr
  pyIntType*: PyTypeObjectPtr
  pyListType*: PyTypeObjectPtr
  pyLongType*: PyTypeObjectPtr
  pyMethodType*: PyTypeObjectPtr
  pyModuleType*: PyTypeObjectPtr
  pyObjectType*: PyTypeObjectPtr
  pyRangeType*: PyTypeObjectPtr
  pySliceType*: PyTypeObjectPtr
  pyStringType*: PyTypeObjectPtr
  pyTupleType*: PyTypeObjectPtr
  pyBaseobjectType*: PyTypeObjectPtr
  pyBufferType*: PyTypeObjectPtr
  pyCalliterType*: PyTypeObjectPtr
  pyCellType*: PyTypeObjectPtr
  pyClassmethodType*: PyTypeObjectPtr
  pyPropertyType*: PyTypeObjectPtr
  pySeqiterType*: PyTypeObjectPtr
  pyStaticmethodType*: PyTypeObjectPtr
  pySuperType*: PyTypeObjectPtr
  pySymtableentryType*: PyTypeObjectPtr
  pyTracebackType*: PyTypeObjectPtr
  pyUnicodeType*: PyTypeObjectPtr
  pyWrapperdescrType*: PyTypeObjectPtr
  pyBasestringType*: PyTypeObjectPtr
  pyBoolType*: PyTypeObjectPtr
  pyEnumType*: PyTypeObjectPtr
{.deprecated: [Py_DebugFlag: pyDebugFlag].}
{.deprecated: [Py_VerboseFlag: pyVerboseFlag].}
{.deprecated: [Py_InteractiveFlag: pyInteractiveFlag].}
{.deprecated: [Py_OptimizeFlag: pyOptimizeFlag].}
{.deprecated: [Py_NoSiteFlag: pyNoSiteFlag].}
{.deprecated: [Py_UseClassExceptionsFlag: pyUseClassExceptionsFlag].}
{.deprecated: [Py_FrozenFlag: pyFrozenFlag].}
{.deprecated: [Py_TabcheckFlag: pyTabcheckFlag].}
{.deprecated: [Py_UnicodeFlag: pyUnicodeFlag].}
{.deprecated: [Py_IgnoreEnvironmentFlag: pyIgnoreEnvironmentFlag].}
{.deprecated: [Py_DivisionWarningFlag: pyDivisionWarningFlag].}
{.deprecated: [PyImport_FrozenModules: pyImportFrozenModules].}
{.deprecated: [Py_None: pyNone].}
{.deprecated: [Py_Ellipsis: pyEllipsis].}
{.deprecated: [Py_False: pyFalse].}
{.deprecated: [Py_True: pyTrue].}
{.deprecated: [Py_NotImplemented: pyNotImplemented].}
{.deprecated: [PyExc_AttributeError: pyExcAttributeError].}
{.deprecated: [PyExc_EOFError: pyExcEOFError].}
{.deprecated: [PyExc_IOError: pyExcIOError].}
{.deprecated: [PyExc_ImportError: pyExcImportError].}
{.deprecated: [PyExc_IndexError: pyExcIndexError].}
{.deprecated: [PyExc_KeyError: pyExcKeyError].}
{.deprecated: [PyExc_KeyboardInterrupt: pyExcKeyboardInterrupt].}
{.deprecated: [PyExc_MemoryError: pyExcMemoryError].}
{.deprecated: [PyExc_NameError: pyExcNameError].}
{.deprecated: [PyExc_OverflowError: pyExcOverflowError].}
{.deprecated: [PyExc_RuntimeError: pyExcRuntimeError].}
{.deprecated: [PyExc_SyntaxError: pyExcSyntaxError].}
{.deprecated: [PyExc_SystemError: pyExcSystemError].}
{.deprecated: [PyExc_SystemExit: pyExcSystemExit].}
{.deprecated: [PyExc_TypeError: pyExcTypeError].}
{.deprecated: [PyExc_ValueError: pyExcValueError].}
{.deprecated: [PyExc_ZeroDivisionError: pyExcZeroDivisionError].}
{.deprecated: [PyExc_ArithmeticError: pyExcArithmeticError].}
{.deprecated: [PyExc_Exception: pyExcException].}
{.deprecated: [PyExc_FloatingPointError: pyExcFloatingPointError].}
{.deprecated: [PyExc_LookupError: pyExcLookupError].}
{.deprecated: [PyExc_StandardError: pyExcStandardError].}
{.deprecated: [PyExc_AssertionError: pyExcAssertionError].}
{.deprecated: [PyExc_EnvironmentError: pyExcEnvironmentError].}
{.deprecated: [PyExc_IndentationError: pyExcIndentationError].}
{.deprecated: [PyExc_MemoryErrorInst: pyExcMemoryErrorInst].}
{.deprecated: [PyExc_NotImplementedError: pyExcNotImplementedError].}
{.deprecated: [PyExc_OSError: pyExcOSError].}
{.deprecated: [PyExc_TabError: pyExcTabError].}
{.deprecated: [PyExc_UnboundLocalError: pyExcUnboundLocalError].}
{.deprecated: [PyExc_UnicodeError: pyExcUnicodeError].}
{.deprecated: [PyExc_Warning: pyExcWarning].}
{.deprecated: [PyExc_DeprecationWarning: pyExcDeprecationWarning].}
{.deprecated: [PyExc_RuntimeWarning: pyExcRuntimeWarning].}
{.deprecated: [PyExc_SyntaxWarning: pyExcSyntaxWarning].}
{.deprecated: [PyExc_UserWarning: pyExcUserWarning].}
{.deprecated: [PyExc_OverflowWarning: pyExcOverflowWarning].}
{.deprecated: [PyExc_ReferenceError: pyExcReferenceError].}
{.deprecated: [PyExc_StopIteration: pyExcStopIteration].}
{.deprecated: [PyExc_FutureWarning: pyExcFutureWarning].}
{.deprecated: [PyExc_PendingDeprecationWarning: pyExcPendingDeprecationWarning].}
{.deprecated: [PyExc_UnicodeDecodeError: pyExcUnicodeDecodeError].}
{.deprecated: [PyExc_UnicodeEncodeError: pyExcUnicodeEncodeError].}
{.deprecated: [PyExc_UnicodeTranslateError: pyExcUnicodeTranslateError].}
{.deprecated: [PyType_Type: pyTypeType].}
{.deprecated: [PyCFunction_Type: pyCfunctionType].}
{.deprecated: [PyCObject_Type: pyCobjectType].}
{.deprecated: [PyClass_Type: pyClassType].}
{.deprecated: [PyCode_Type: pyCodeType].}
{.deprecated: [PyComplex_Type: pyComplexType].}
{.deprecated: [PyDict_Type: pyDictType].}
{.deprecated: [PyFile_Type: pyFileType].}
{.deprecated: [PyFloat_Type: pyFloatType].}
{.deprecated: [PyFrame_Type: pyFrameType].}
{.deprecated: [PyFunction_Type: pyFunctionType].}
{.deprecated: [PyInstance_Type: pyInstanceType].}
{.deprecated: [PyInt_Type: pyIntType].}
{.deprecated: [PyList_Type: pyListType].}
{.deprecated: [PyLong_Type: pyLongType].}
{.deprecated: [PyMethod_Type: pyMethodType].}
{.deprecated: [PyModule_Type: pyModuleType].}
{.deprecated: [PyObject_Type: pyObjectType].}
{.deprecated: [PyRange_Type: pyRangeType].}
{.deprecated: [PySlice_Type: pySliceType].}
{.deprecated: [PyString_Type: pyStringType].}
{.deprecated: [PyTuple_Type: pyTupleType].}
{.deprecated: [PyBaseObject_Type: pyBaseobjectType].}
{.deprecated: [PyBuffer_Type: pyBufferType].}
{.deprecated: [PyCallIter_Type: pyCalliterType].}
{.deprecated: [PyCell_Type: pyCellType].}
{.deprecated: [PyClassMethod_Type: pyClassmethodType].}
{.deprecated: [PyProperty_Type: pyPropertyType].}
{.deprecated: [PySeqIter_Type: pySeqiterType].}
{.deprecated: [PyStaticMethod_Type: pyStaticmethodType].}
{.deprecated: [PySuper_Type: pySuperType].}
{.deprecated: [PySymtableEntry_Type: pySymtableentryType].}
{.deprecated: [PyTraceBack_Type: pyTracebackType].}
{.deprecated: [PyUnicode_Type: pyUnicodeType].}
{.deprecated: [PyWrapperDescr_Type: pyWrapperdescrType].}
{.deprecated: [PyBaseString_Type: pyBasestringType].}
{.deprecated: [PyBool_Type: pyBoolType].}
{.deprecated: [PyEnum_Type: pyEnumType].}

proc pyVaBuildValue*(format: cstring; va_list: varargs): PyObjectPtr{.cdecl, importc: "Py_VaBuildValue", dynlib: dllname.}
proc pyBuiltinInit*(){.cdecl, importc: "_PyBuiltin_Init", dynlib: dllname.}
proc pyComplexFromCComplex*(c: PyComplex): PyObjectPtr{.cdecl, importc: "PyComplex_FromCComplex" dynlib: dllname.}
{.deprecated: [PyComplex_FromCComplex: pyComplexFromCComplex].}
proc pyComplexFromDoubles*(realv, imag: float64): PyObjectPtr{.cdecl, importc: "PyComplex_FromDoubles" dynlib: dllname.}
{.deprecated: [PyComplex_FromDoubles: pyComplexFromDoubles].}
proc pyComplexRealAsDouble*(op: PyObjectPtr): float64{.cdecl, importc: "PyComplex_RealAsDouble" dynlib: dllname.}
{.deprecated: [PyComplex_RealAsDouble: pyComplexRealAsDouble].}
proc pyComplexImagAsDouble*(op: PyObjectPtr): float64{.cdecl, importc: "PyComplex_ImagAsDouble" dynlib: dllname.}
{.deprecated: [PyComplex_ImagAsDouble: pyComplexImagAsDouble].}
proc pyComplexAsCComplex*(op: PyObjectPtr): PyComplex{.cdecl, importc: "PyComplex_AsCComplex" dynlib: dllname.}
{.deprecated: [PyComplex_AsCComplex: pyComplexAsCComplex].}
proc pyCfunctionGetFunction*(ob: PyObjectPtr): pointer{.cdecl, importc: "PyCFunction_GetFunction" dynlib: dllname.}
{.deprecated: [PyCFunction_GetFunction: pyCfunctionGetFunction].}
proc pyCfunctionGetSelf*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyCFunction_GetSelf" dynlib: dllname.}
{.deprecated: [PyCFunction_GetSelf: pyCfunctionGetSelf].}
proc pyCallableCheck*(ob: PyObjectPtr): int{.cdecl, importc: "PyCallable_Check" dynlib: dllname.}
{.deprecated: [PyCallable_Check: pyCallableCheck].}
proc pyCobjectFromVoidPtr*(cobj, destruct: pointer): PyObjectPtr{.cdecl, importc: "PyCObject_FromVoidPtr" dynlib: dllname.}
{.deprecated: [PyCObject_FromVoidPtr: pyCobjectFromVoidPtr].}
proc pyCobjectAsVoidPtr*(ob: PyObjectPtr): pointer{.cdecl, importc: "PyCObject_AsVoidPtr" dynlib: dllname.}
{.deprecated: [PyCObject_AsVoidPtr: pyCobjectAsVoidPtr].}
proc pyClassNew*(ob1, ob2, ob3: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyClass_New" dynlib: dllname.}
{.deprecated: [PyClass_New: pyClassNew].}
proc pyClassIsSubclass*(ob1, ob2: PyObjectPtr): int{.cdecl, importc: "PyClass_IsSubclass" dynlib: dllname.}
{.deprecated: [PyClass_IsSubclass: pyClassIsSubclass].}
proc pyInitModule4*(name: cstring, methods: PyMethodDefPtr, doc: cstring, passthrough: PyObjectPtr, Api_Version: int): PyObjectPtr{.cdecl, importc: "Py_InitModule4" dynlib: dllname.}
{.deprecated: [Py_InitModule4: pyInitModule4].}
proc pyErrBadArgument*(): int{.cdecl, importc: "PyErr_BadArgument" dynlib: dllname.}
{.deprecated: [PyErr_BadArgument: pyErrBadArgument].}
proc pyErrBadInternalCall*(){.cdecl, importc: "PyErr_BadInternalCall" dynlib: dllname.}
{.deprecated: [PyErr_BadInternalCall: pyErrBadInternalCall].}
proc pyErrCheckSignals*(): int{.cdecl, importc: "PyErr_CheckSignals" dynlib: dllname.}
{.deprecated: [PyErr_CheckSignals: pyErrCheckSignals].}
proc pyErrClear*(){.cdecl, importc: "PyErr_Clear" dynlib: dllname.}
{.deprecated: [PyErr_Clear: pyErrClear].}
proc pyErrFetch*(errtype, errvalue, errtraceback: PyObjectPtrPtr){.cdecl, importc: "PyErr_Fetch" dynlib: dllname.}
{.deprecated: [PyErr_Fetch: pyErrFetch].}
proc pyErrNoMemory*(): PyObjectPtr{.cdecl, importc: "PyErr_NoMemory" dynlib: dllname.}
{.deprecated: [PyErr_NoMemory: pyErrNoMemory].}
proc pyErrOccurred*(): PyObjectPtr{.cdecl, importc: "PyErr_Occurred" dynlib: dllname.}
{.deprecated: [PyErr_Occurred: pyErrOccurred].}
proc pyErrPrint*(){.cdecl, importc: "PyErr_Print" dynlib: dllname.}
{.deprecated: [PyErr_Print: pyErrPrint].}
proc pyErrRestore*(errtype, errvalue, errtraceback: PyObjectPtr){.cdecl, importc: "PyErr_Restore" dynlib: dllname.}
{.deprecated: [PyErr_Restore: pyErrRestore].}
proc pyErrSetFromErrno*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyErr_SetFromErrno" dynlib: dllname.}
{.deprecated: [PyErr_SetFromErrno: pyErrSetFromErrno].}
proc pyErrSetNone*(value: PyObjectPtr){.cdecl, importc: "PyErr_SetNone" dynlib: dllname.}
{.deprecated: [PyErr_SetNone: pyErrSetNone].}
proc pyErrSetObject*(ob1, ob2: PyObjectPtr){.cdecl, importc: "PyErr_SetObject" dynlib: dllname.}
{.deprecated: [PyErr_SetObject: pyErrSetObject].}
proc pyErrSetString*(ErrorObject: PyObjectPtr, text: cstring){.cdecl, importc: "PyErr_SetString" dynlib: dllname.}
{.deprecated: [PyErr_SetString: pyErrSetString].}
proc pyImportGetModuleDict*(): PyObjectPtr{.cdecl, importc: "PyImport_GetModuleDict" dynlib: dllname.}
{.deprecated: [PyImport_GetModuleDict: pyImportGetModuleDict].}
proc pyIntFromLong*(x: int32): PyObjectPtr{.cdecl, importc: "PyInt_FromLong" dynlib: dllname.}
{.deprecated: [PyInt_FromLong: pyIntFromLong].}
proc pyInitialize*(){.cdecl, importc: "Py_Initialize" dynlib: dllname.}
{.deprecated: [Py_Initialize: pyInitialize].}
proc pyExit*(RetVal: int){.cdecl, importc: "Py_Exit" dynlib: dllname.}
{.deprecated: [Py_Exit: pyExit].}
proc pyEvalGetBuiltins*(): PyObjectPtr{.cdecl, importc: "PyEval_GetBuiltins" dynlib: dllname.}
{.deprecated: [PyEval_GetBuiltins: pyEvalGetBuiltins].}
proc pyDictGetItem*(mp, key: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyDict_GetItem" dynlib: dllname.}
{.deprecated: [PyDict_GetItem: pyDictGetItem].}
proc pyDictSetItem*(mp, key, item: PyObjectPtr): int{.cdecl, importc: "PyDict_SetItem" dynlib: dllname.}
{.deprecated: [PyDict_SetItem: pyDictSetItem].}
proc pyDictDelItem*(mp, key: PyObjectPtr): int{.cdecl, importc: "PyDict_DelItem" dynlib: dllname.}
{.deprecated: [PyDict_DelItem: pyDictDelItem].}
proc pyDictClear*(mp: PyObjectPtr){.cdecl, importc: "PyDict_Clear" dynlib: dllname.}
{.deprecated: [PyDict_Clear: pyDictClear].}
proc pyDictNext*(mp: PyObjectPtr, pos: IntPtr, key, value: PyObjectPtrPtr): int{.cdecl, importc: "PyDict_Next" dynlib: dllname.}
{.deprecated: [PyDict_Next: pyDictNext].}
proc pyDictKeys*(mp: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyDict_Keys" dynlib: dllname.}
{.deprecated: [PyDict_Keys: pyDictKeys].}
proc pyDictValues*(mp: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyDict_Values" dynlib: dllname.}
{.deprecated: [PyDict_Values: pyDictValues].}
proc pyDictItems*(mp: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyDict_Items" dynlib: dllname.}
{.deprecated: [PyDict_Items: pyDictItems].}
proc pyDictSize*(mp: PyObjectPtr): int{.cdecl, importc: "PyDict_Size" dynlib: dllname.}
{.deprecated: [PyDict_Size: pyDictSize].}
proc pyDictDelItemString*(dp: PyObjectPtr, key: cstring): int{.cdecl, importc: "PyDict_DelItemString" dynlib: dllname.}
{.deprecated: [PyDict_DelItemString: pyDictDelItemString].}
proc pyDictNew*(): PyObjectPtr{.cdecl, importc: "PyDict_New" dynlib: dllname.}
{.deprecated: [PyDict_New: pyDictNew].}
proc pyDictGetItemString*(dp: PyObjectPtr, key: cstring): PyObjectPtr{.cdecl, importc: "PyDict_GetItemString" dynlib: dllname.}
{.deprecated: [PyDict_GetItemString: pyDictGetItemString].}
proc pyDictSetItemString*(dp: PyObjectPtr, key: cstring, item: PyObjectPtr): int{.cdecl, importc: "PyDict_SetItemString" dynlib: dllname.}
{.deprecated: [PyDict_SetItemString: pyDictSetItemString].}
proc pyDictproxyNew*(obj: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyDictProxy_New" dynlib: dllname.}
{.deprecated: [PyDictProxy_New: pyDictproxyNew].}
proc pyModuleGetDict*(module: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyModule_GetDict" dynlib: dllname.}
{.deprecated: [PyModule_GetDict: pyModuleGetDict].}
proc pyObjectStr*(v: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyObject_Str" dynlib: dllname.}
{.deprecated: [PyObject_Str: pyObjectStr].}
proc pyRunString*(str: cstring, start: int, globals: PyObjectPtr, locals: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyRun_String" dynlib: dllname.}
{.deprecated: [PyRun_String: pyRunString].}
proc pyRunSimpleString*(str: cstring): int{.cdecl, importc: "PyRun_SimpleString" dynlib: dllname.}
{.deprecated: [PyRun_SimpleString: pyRunSimpleString].}
proc pyStringAsString*(ob: PyObjectPtr): cstring{.cdecl, importc: "PyString_AsString" dynlib: dllname.}
{.deprecated: [PyString_AsString: pyStringAsString].}
proc pyStringFromString*(str: cstring): PyObjectPtr{.cdecl, importc: "PyString_FromString" dynlib: dllname.}
{.deprecated: [PyString_FromString: pyStringFromString].}
proc pySysSetArgv*(argc: int, argv: cstringArray){.cdecl, importc: "PySys_SetArgv" dynlib: dllname.} 
{.deprecated: [PySys_SetArgv: pySysSetArgv].}
#+ means, Grzegorz or me has tested his non object version of this function
#+
proc pyCfunctionNew*(md: PyMethodDefPtr, ob: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyCFunction_New" dynlib: dllname.} #+
{.deprecated: [PyCFunction_New: pyCfunctionNew].}
proc pyEvalCallObject*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyEval_CallObject" dynlib: dllname.} #-
{.deprecated: [PyEval_CallObject: pyEvalCallObject].}
proc pyEvalCallObjectWithKeywords*(ob1, ob2, ob3: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyEval_CallObjectWithKeywords" dynlib: dllname.} #-
{.deprecated: [PyEval_CallObjectWithKeywords: pyEvalCallObjectWithKeywords].}
proc pyEvalGetFrame*(): PyObjectPtr{.cdecl, importc: "PyEval_GetFrame" dynlib: dllname.} #-
{.deprecated: [PyEval_GetFrame: pyEvalGetFrame].}
proc pyEvalGetGlobals*(): PyObjectPtr{.cdecl, importc: "PyEval_GetGlobals" dynlib: dllname.} #-
{.deprecated: [PyEval_GetGlobals: pyEvalGetGlobals].}
proc pyEvalGetLocals*(): PyObjectPtr{.cdecl, importc: "PyEval_GetLocals" dynlib: dllname.} #-
{.deprecated: [PyEval_GetLocals: pyEvalGetLocals].}
proc pyEvalGetOwner*(): PyObjectPtr {.cdecl, importc: "PyEval_GetOwner" dynlib: dllname.}
{.deprecated: [PyEval_GetOwner: pyEvalGetOwner].}
proc pyEvalGetRestricted*(): int{.cdecl, importc: "PyEval_GetRestricted" dynlib: dllname.} #-
{.deprecated: [PyEval_GetRestricted: pyEvalGetRestricted].}
proc pyEvalInitThreads*(){.cdecl, importc: "PyEval_InitThreads" dynlib: dllname.} #-
{.deprecated: [PyEval_InitThreads: pyEvalInitThreads].}
proc pyEvalRestoreThread*(tstate: PyThreadStatePtr){.cdecl, importc: "PyEval_RestoreThread" dynlib: dllname.} #-
{.deprecated: [PyEval_RestoreThread: pyEvalRestoreThread].}
proc pyEvalSaveThread*(): PyThreadStatePtr{.cdecl, importc: "PyEval_SaveThread" dynlib: dllname.} #-
{.deprecated: [PyEval_SaveThread: pyEvalSaveThread].}
proc pyFileFromString*(pc1, pc2: cstring): PyObjectPtr{.cdecl, importc: "PyFile_FromString" dynlib: dllname.} #-
{.deprecated: [PyFile_FromString: pyFileFromString].}
proc pyFileGetLine*(ob: PyObjectPtr, i: int): PyObjectPtr{.cdecl, importc: "PyFile_GetLine" dynlib: dllname.} #-
{.deprecated: [PyFile_GetLine: pyFileGetLine].}
proc pyFileName*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyFile_Name" dynlib: dllname.} #-
{.deprecated: [PyFile_Name: pyFileName].}
proc pyFileSetBufSize*(ob: PyObjectPtr, i: int){.cdecl, importc: "PyFile_SetBufSize" dynlib: dllname.} #-
{.deprecated: [PyFile_SetBufSize: pyFileSetBufSize].}
proc pyFileSoftSpace*(ob: PyObjectPtr, i: int): int{.cdecl, importc: "PyFile_SoftSpace" dynlib: dllname.} #-
{.deprecated: [PyFile_SoftSpace: pyFileSoftSpace].}
proc pyFileWriteObject*(ob1, ob2: PyObjectPtr, i: int): int{.cdecl, importc: "PyFile_WriteObject" dynlib: dllname.} #-
{.deprecated: [PyFile_WriteObject: pyFileWriteObject].}
proc pyFileWriteString*(s: cstring, ob: PyObjectPtr){.cdecl, importc: "PyFile_WriteString" dynlib: dllname.} #+
{.deprecated: [PyFile_WriteString: pyFileWriteString].}
proc pyFloatAsDouble*(ob: PyObjectPtr): float64{.cdecl, importc: "PyFloat_AsDouble" dynlib: dllname.} #+
{.deprecated: [PyFloat_AsDouble: pyFloatAsDouble].}
proc pyFloatFromDouble*(db: float64): PyObjectPtr{.cdecl, importc: "PyFloat_FromDouble" dynlib: dllname.} #-
{.deprecated: [PyFloat_FromDouble: pyFloatFromDouble].}
proc pyFunctionGetCode*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyFunction_GetCode" dynlib: dllname.} #-
{.deprecated: [PyFunction_GetCode: pyFunctionGetCode].}
proc pyFunctionGetGlobals*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyFunction_GetGlobals" dynlib: dllname.} #-
{.deprecated: [PyFunction_GetGlobals: pyFunctionGetGlobals].}
proc pyFunctionNew*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyFunction_New" dynlib: dllname.} #-
{.deprecated: [PyFunction_New: pyFunctionNew].}
proc pyImportAddModule*(name: cstring): PyObjectPtr{.cdecl, importc: "PyImport_AddModule" dynlib: dllname.} #-
{.deprecated: [PyImport_AddModule: pyImportAddModule].}
proc pyImportCleanup*(){.cdecl, importc: "PyImport_Cleanup" dynlib: dllname.} #-
{.deprecated: [PyImport_Cleanup: pyImportCleanup].}
proc pyImportGetMagicNumber*(): int32{.cdecl, importc: "PyImport_GetMagicNumber" dynlib: dllname.} #+
{.deprecated: [PyImport_GetMagicNumber: pyImportGetMagicNumber].}
proc pyImportImportFrozenModule*(key: cstring): int{.cdecl, importc: "PyImport_ImportFrozenModule" dynlib: dllname.} #+
{.deprecated: [PyImport_ImportFrozenModule: pyImportImportFrozenModule].}
proc pyImportImportModule*(name: cstring): PyObjectPtr{.cdecl, importc: "PyImport_ImportModule" dynlib: dllname.} #+
{.deprecated: [PyImport_ImportModule: pyImportImportModule].}
proc pyImportImport*(name: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyImport_Import" dynlib: dllname.} #-
{.deprecated: [PyImport_Import: pyImportImport].}
proc pyImportInit*() {.cdecl, importc: "PyImport_Init" dynlib: dllname.}
{.deprecated: [PyImport_Init: pyImportInit].}
proc pyImportReloadModule*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyImport_ReloadModule" dynlib: dllname.} #-
{.deprecated: [PyImport_ReloadModule: pyImportReloadModule].}
proc pyInstanceNew*(obClass, obArg, obKW: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyInstance_New" dynlib: dllname.} #+
{.deprecated: [PyInstance_New: pyInstanceNew].}
proc pyIntAsLong*(ob: PyObjectPtr): int32{.cdecl, importc: "PyInt_AsLong" dynlib: dllname.} #-
{.deprecated: [PyInt_AsLong: pyIntAsLong].}
proc pyListAppend*(ob1, ob2: PyObjectPtr): int{.cdecl, importc: "PyList_Append" dynlib: dllname.} #-
{.deprecated: [PyList_Append: pyListAppend].}
proc pyListAsTuple*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyList_AsTuple" dynlib: dllname.} #+
{.deprecated: [PyList_AsTuple: pyListAsTuple].}
proc pyListGetItem*(ob: PyObjectPtr, i: int): PyObjectPtr{.cdecl, importc: "PyList_GetItem" dynlib: dllname.} #-
{.deprecated: [PyList_GetItem: pyListGetItem].}
proc pyListGetSlice*(ob: PyObjectPtr, i1, i2: int): PyObjectPtr{.cdecl, importc: "PyList_GetSlice" dynlib: dllname.} #-
{.deprecated: [PyList_GetSlice: pyListGetSlice].}
proc pyListInsert*(dp: PyObjectPtr, idx: int, item: PyObjectPtr): int{.cdecl, importc: "PyList_Insert" dynlib: dllname.} #-
{.deprecated: [PyList_Insert: pyListInsert].}
proc pyListNew*(size: int): PyObjectPtr{.cdecl, importc: "PyList_New" dynlib: dllname.} #-
{.deprecated: [PyList_New: pyListNew].}
proc pyListReverse*(ob: PyObjectPtr): int{.cdecl, importc: "PyList_Reverse" dynlib: dllname.} #-
{.deprecated: [PyList_Reverse: pyListReverse].}
proc pyListSetItem*(dp: PyObjectPtr, idx: int, item: PyObjectPtr): int{.cdecl, importc: "PyList_SetItem" dynlib: dllname.} #-
{.deprecated: [PyList_SetItem: pyListSetItem].}
proc pyListSetSlice*(ob: PyObjectPtr, i1, i2: int, ob2: PyObjectPtr): int{.cdecl, importc: "PyList_SetSlice" dynlib: dllname.} #+
{.deprecated: [PyList_SetSlice: pyListSetSlice].}
proc pyListSize*(ob: PyObjectPtr): int{.cdecl, importc: "PyList_Size" dynlib: dllname.} #-
{.deprecated: [PyList_Size: pyListSize].}
proc pyListSort*(ob: PyObjectPtr): int{.cdecl, importc: "PyList_Sort" dynlib: dllname.} #-
{.deprecated: [PyList_Sort: pyListSort].}
proc pyLongAsDouble*(ob: PyObjectPtr): float64{.cdecl, importc: "PyLong_AsDouble" dynlib: dllname.} #+
{.deprecated: [PyLong_AsDouble: pyLongAsDouble].}
proc pyLongAsLong*(ob: PyObjectPtr): int32{.cdecl, importc: "PyLong_AsLong" dynlib: dllname.} #+
{.deprecated: [PyLong_AsLong: pyLongAsLong].}
proc pyLongFromDouble*(db: float64): PyObjectPtr{.cdecl, importc: "PyLong_FromDouble" dynlib: dllname.} #+
{.deprecated: [PyLong_FromDouble: pyLongFromDouble].}
proc pyLongFromLong*(L: int32): PyObjectPtr{.cdecl, importc: "PyLong_FromLong" dynlib: dllname.} #-
{.deprecated: [PyLong_FromLong: pyLongFromLong].}
proc pyLongFromString*(pc: cstring, ppc: var cstring, i: int): PyObjectPtr{.cdecl, importc: "PyLong_FromString" dynlib: dllname.} #-
{.deprecated: [PyLong_FromString: pyLongFromString].}
proc pyLongFromUnsignedLong*(val: int): PyObjectPtr{.cdecl, importc: "PyLong_FromUnsignedLong" dynlib: dllname.} #-
{.deprecated: [PyLong_FromUnsignedLong: pyLongFromUnsignedLong].}
proc pyLongAsUnsignedLong*(ob: PyObjectPtr): int{.cdecl, importc: "PyLong_AsUnsignedLong" dynlib: dllname.} #-
{.deprecated: [PyLong_AsUnsignedLong: pyLongAsUnsignedLong].}
proc pyLongFromUnicode*(ob: PyObjectPtr, a, b: int): PyObjectPtr{.cdecl, importc: "PyLong_FromUnicode" dynlib: dllname.} #-
{.deprecated: [PyLong_FromUnicode: pyLongFromUnicode].}
proc pyLongFromLongLong*(val: int64): PyObjectPtr{.cdecl, importc: "PyLong_FromLongLong" dynlib: dllname.} #-
{.deprecated: [PyLong_FromLongLong: pyLongFromLongLong].}
proc pyLongAsLongLong*(ob: PyObjectPtr): int64{.cdecl, importc: "PyLong_AsLongLong" dynlib: dllname.} #-
{.deprecated: [PyLong_AsLongLong: pyLongAsLongLong].}
proc pyMappingCheck*(ob: PyObjectPtr): int{.cdecl, importc: "PyMapping_Check" dynlib: dllname.} #-
{.deprecated: [PyMapping_Check: pyMappingCheck].}
proc pyMappingGetItemString*(ob: PyObjectPtr, key: cstring): PyObjectPtr{.cdecl, importc: "PyMapping_GetItemString" dynlib: dllname.} #-
{.deprecated: [PyMapping_GetItemString: pyMappingGetItemString].}
proc pyMappingHasKey*(ob, key: PyObjectPtr): int{.cdecl, importc: "PyMapping_HasKey" dynlib: dllname.} #-
{.deprecated: [PyMapping_HasKey: pyMappingHasKey].}
proc pyMappingHasKeyString*(ob: PyObjectPtr, key: cstring): int{.cdecl, importc: "PyMapping_HasKeyString" dynlib: dllname.} #-
{.deprecated: [PyMapping_HasKeyString: pyMappingHasKeyString].}
proc pyMappingLength*(ob: PyObjectPtr): int{.cdecl, importc: "PyMapping_Length" dynlib: dllname.} #-
{.deprecated: [PyMapping_Length: pyMappingLength].}
proc pyMappingSetItemString*(ob: PyObjectPtr, key: cstring, value: PyObjectPtr): int{.cdecl, importc: "PyMapping_SetItemString" dynlib: dllname.} #-
{.deprecated: [PyMapping_SetItemString: pyMappingSetItemString].}
proc pyMethodClass*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyMethod_Class" dynlib: dllname.} #-
{.deprecated: [PyMethod_Class: pyMethodClass].}
proc pyMethodFunction*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyMethod_Function" dynlib: dllname.} #-
{.deprecated: [PyMethod_Function: pyMethodFunction].}
proc pyMethodNew*(ob1, ob2, ob3: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyMethod_New" dynlib: dllname.} #-
{.deprecated: [PyMethod_New: pyMethodNew].}
proc pyMethodSelf*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyMethod_Self" dynlib: dllname.} #-
{.deprecated: [PyMethod_Self: pyMethodSelf].}
proc pyModuleGetName*(ob: PyObjectPtr): cstring{.cdecl, importc: "PyModule_GetName" dynlib: dllname.} #-
{.deprecated: [PyModule_GetName: pyModuleGetName].}
proc pyModuleNew*(key: cstring): PyObjectPtr{.cdecl, importc: "PyModule_New" dynlib: dllname.} #-
{.deprecated: [PyModule_New: pyModuleNew].}
proc pyNumberAbsolute*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyNumber_Absolute" dynlib: dllname.} #-
{.deprecated: [PyNumber_Absolute: pyNumberAbsolute].}
proc pyNumberAdd*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyNumber_Add" dynlib: dllname.} #-
{.deprecated: [PyNumber_Add: pyNumberAdd].}
proc pyNumberAnd*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyNumber_And" dynlib: dllname.} #-
{.deprecated: [PyNumber_And: pyNumberAnd].}
proc pyNumberCheck*(ob: PyObjectPtr): int{.cdecl, importc: "PyNumber_Check" dynlib: dllname.} #-
{.deprecated: [PyNumber_Check: pyNumberCheck].}
proc pyNumberCoerce*(ob1, ob2: var PyObjectPtr): int{.cdecl, importc: "PyNumber_Coerce" dynlib: dllname.} #-
{.deprecated: [PyNumber_Coerce: pyNumberCoerce].}
proc pyNumberDivide*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyNumber_Divide" dynlib: dllname.} #-
{.deprecated: [PyNumber_Divide: pyNumberDivide].}
proc pyNumberFloorDivide*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyNumber_FloorDivide" dynlib: dllname.} #-
{.deprecated: [PyNumber_FloorDivide: pyNumberFloorDivide].}
proc pyNumberTrueDivide*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyNumber_TrueDivide" dynlib: dllname.} #-
{.deprecated: [PyNumber_TrueDivide: pyNumberTrueDivide].}
proc pyNumberDivmod*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyNumber_Divmod" dynlib: dllname.} #-
{.deprecated: [PyNumber_Divmod: pyNumberDivmod].}
proc pyNumberFloat*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyNumber_Float" dynlib: dllname.} #-
{.deprecated: [PyNumber_Float: pyNumberFloat].}
proc pyNumberInt*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyNumber_Int" dynlib: dllname.} #-
{.deprecated: [PyNumber_Int: pyNumberInt].}
proc pyNumberInvert*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyNumber_Invert" dynlib: dllname.} #-
{.deprecated: [PyNumber_Invert: pyNumberInvert].}
proc pyNumberLong*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyNumber_Long" dynlib: dllname.} #-
{.deprecated: [PyNumber_Long: pyNumberLong].}
proc pyNumberLshift*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyNumber_Lshift" dynlib: dllname.} #-
{.deprecated: [PyNumber_Lshift: pyNumberLshift].}
proc pyNumberMultiply*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyNumber_Multiply" dynlib: dllname.} #-
{.deprecated: [PyNumber_Multiply: pyNumberMultiply].}
proc pyNumberNegative*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyNumber_Negative" dynlib: dllname.} #-
{.deprecated: [PyNumber_Negative: pyNumberNegative].}
proc pyNumberOr*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyNumber_Or" dynlib: dllname.} #-
{.deprecated: [PyNumber_Or: pyNumberOr].}
proc pyNumberPositive*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyNumber_Positive" dynlib: dllname.} #-
{.deprecated: [PyNumber_Positive: pyNumberPositive].}
proc pyNumberPower*(ob1, ob2, ob3: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyNumber_Power" dynlib: dllname.} #-
{.deprecated: [PyNumber_Power: pyNumberPower].}
proc pyNumberRemainder*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyNumber_Remainder" dynlib: dllname.} #-
{.deprecated: [PyNumber_Remainder: pyNumberRemainder].}
proc pyNumberRshift*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyNumber_Rshift" dynlib: dllname.} #-
{.deprecated: [PyNumber_Rshift: pyNumberRshift].}
proc pyNumberSubtract*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyNumber_Subtract" dynlib: dllname.} #-
{.deprecated: [PyNumber_Subtract: pyNumberSubtract].}
proc pyNumberXor*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyNumber_Xor" dynlib: dllname.} #-
{.deprecated: [PyNumber_Xor: pyNumberXor].}
proc pyOsInitInterrupts*(){.cdecl, importc: "PyOS_InitInterrupts" dynlib: dllname.} #-
{.deprecated: [PyOS_InitInterrupts: pyOsInitInterrupts].}
proc pyOsInterruptOccurred*(): int{.cdecl, importc: "PyOS_InterruptOccurred" dynlib: dllname.} #-
{.deprecated: [PyOS_InterruptOccurred: pyOsInterruptOccurred].}
proc pyObjectCallObject*(ob, args: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyObject_CallObject" dynlib: dllname.} #-
{.deprecated: [PyObject_CallObject: pyObjectCallObject].}
proc pyObjectCompare*(ob1, ob2: PyObjectPtr): int{.cdecl, importc: "PyObject_Compare" dynlib: dllname.} #-
{.deprecated: [PyObject_Compare: pyObjectCompare].}
proc pyObjectGetAttr*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyObject_GetAttr" dynlib: dllname.} #+
{.deprecated: [PyObject_GetAttr: pyObjectGetAttr].}
proc pyObjectGetAttrString*(ob: PyObjectPtr, c: cstring): PyObjectPtr{.cdecl, importc: "PyObject_GetAttrString" dynlib: dllname.} #-
{.deprecated: [PyObject_GetAttrString: pyObjectGetAttrString].}
proc pyObjectGetItem*(ob, key: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyObject_GetItem" dynlib: dllname.} #-
{.deprecated: [PyObject_GetItem: pyObjectGetItem].}
proc pyObjectDelItem*(ob, key: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyObject_DelItem" dynlib: dllname.} #-
{.deprecated: [PyObject_DelItem: pyObjectDelItem].}
proc pyObjectHasAttrString*(ob: PyObjectPtr, key: cstring): int{.cdecl, importc: "PyObject_HasAttrString" dynlib: dllname.} #-
{.deprecated: [PyObject_HasAttrString: pyObjectHasAttrString].}
proc pyObjectHash*(ob: PyObjectPtr): int32{.cdecl, importc: "PyObject_Hash" dynlib: dllname.} #-
{.deprecated: [PyObject_Hash: pyObjectHash].}
proc pyObjectIsTrue*(ob: PyObjectPtr): int{.cdecl, importc: "PyObject_IsTrue" dynlib: dllname.} #-
{.deprecated: [PyObject_IsTrue: pyObjectIsTrue].}
proc pyObjectLength*(ob: PyObjectPtr): int{.cdecl, importc: "PyObject_Length" dynlib: dllname.} #-
{.deprecated: [PyObject_Length: pyObjectLength].}
proc pyObjectRepr*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyObject_Repr" dynlib: dllname.} #-
{.deprecated: [PyObject_Repr: pyObjectRepr].}
proc pyObjectSetAttr*(ob1, ob2, ob3: PyObjectPtr): int{.cdecl, importc: "PyObject_SetAttr" dynlib: dllname.} #-
{.deprecated: [PyObject_SetAttr: pyObjectSetAttr].}
proc pyObjectSetAttrString*(ob: PyObjectPtr, key: cstring, value: PyObjectPtr): int{.cdecl, importc: "PyObject_SetAttrString" dynlib: dllname.} #-
{.deprecated: [PyObject_SetAttrString: pyObjectSetAttrString].}
proc pyObjectSetItem*(ob1, ob2, ob3: PyObjectPtr): int{.cdecl, importc: "PyObject_SetItem" dynlib: dllname.} #-
{.deprecated: [PyObject_SetItem: pyObjectSetItem].}
proc pyObjectInit*(ob: PyObjectPtr, t: PyTypeObjectPtr): PyObjectPtr{.cdecl, importc: "PyObject_Init" dynlib: dllname.} #-
{.deprecated: [PyObject_Init: pyObjectInit].}
proc pyObjectInitVar*(ob: PyObjectPtr, t: PyTypeObjectPtr, size: int): PyObjectPtr{.cdecl, importc: "PyObject_InitVar" dynlib: dllname.} #-
{.deprecated: [PyObject_InitVar: pyObjectInitVar].}
proc pyObjectNew*(t: PyTypeObjectPtr): PyObjectPtr{.cdecl, importc: "PyObject_New" dynlib: dllname.} #-
{.deprecated: [PyObject_New: pyObjectNew].}
proc pyObjectNewVar*(t: PyTypeObjectPtr, size: int): PyObjectPtr{.cdecl, importc: "PyObject_NewVar" dynlib: dllname.}
{.deprecated: [PyObject_NewVar: pyObjectNewVar].}
proc pyObjectFree*(ob: PyObjectPtr){.cdecl, importc: "PyObject_Free" dynlib: dllname.} #-
{.deprecated: [PyObject_Free: pyObjectFree].}
proc pyObjectIsInstance*(inst, cls: PyObjectPtr): int{.cdecl, importc: "PyObject_IsInstance" dynlib: dllname.} #-
{.deprecated: [PyObject_IsInstance: pyObjectIsInstance].}
proc pyObjectIsSubclass*(derived, cls: PyObjectPtr): int{.cdecl, importc: "PyObject_IsSubclass" dynlib: dllname.}
{.deprecated: [PyObject_IsSubclass: pyObjectIsSubclass].}
proc pyObjectGenericGetAttr*(obj, name: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyObject_GenericGetAttr" dynlib: dllname.}
{.deprecated: [PyObject_GenericGetAttr: pyObjectGenericGetAttr].}
proc pyObjectGenericSetAttr*(obj, name, value: PyObjectPtr): int{.cdecl, importc: "PyObject_GenericSetAttr" dynlib: dllname.} #-
{.deprecated: [PyObject_GenericSetAttr: pyObjectGenericSetAttr].}
proc pyObjectGCMalloc*(size: int): PyObjectPtr{.cdecl, importc: "PyObject_GC_Malloc" dynlib: dllname.} #-
{.deprecated: [PyObject_GC_Malloc: pyObjectGCMalloc].}
proc pyObjectGCNew*(t: PyTypeObjectPtr): PyObjectPtr{.cdecl, importc: "PyObject_GC_New" dynlib: dllname.} #-
{.deprecated: [PyObject_GC_New: pyObjectGCNew].}
proc pyObjectGCNewVar*(t: PyTypeObjectPtr, size: int): PyObjectPtr{.cdecl, importc: "PyObject_GC_NewVar" dynlib: dllname.} #-
{.deprecated: [PyObject_GC_NewVar: pyObjectGCNewVar].}
proc pyObjectGCResize*(t: PyObjectPtr, newsize: int): PyObjectPtr{.cdecl, importc: "PyObject_GC_Resize" dynlib: dllname.} #-
{.deprecated: [PyObject_GC_Resize: pyObjectGCResize].}
proc pyObjectGCDel*(ob: PyObjectPtr){.cdecl, importc: "PyObject_GC_Del" dynlib: dllname.} #-
{.deprecated: [PyObject_GC_Del: pyObjectGCDel].}
proc pyObjectGCTrack*(ob: PyObjectPtr){.cdecl, importc: "PyObject_GC_Track" dynlib: dllname.} #-
{.deprecated: [PyObject_GC_Track: pyObjectGCTrack].}
proc pyObjectGCUnTrack*(ob: PyObjectPtr){.cdecl, importc: "PyObject_GC_UnTrack" dynlib: dllname.} #-
{.deprecated: [PyObject_GC_UnTrack: pyObjectGCUnTrack].}
proc pyRangeNew*(l1, l2, l3: int32, i: int): PyObjectPtr{.cdecl, importc: "PyRange_New" dynlib: dllname.} #-
{.deprecated: [PyRange_New: pyRangeNew].}
proc pySequenceCheck*(ob: PyObjectPtr): int{.cdecl, importc: "PySequence_Check" dynlib: dllname.} #-
{.deprecated: [PySequence_Check: pySequenceCheck].}
proc pySequenceConcat*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PySequence_Concat" dynlib: dllname.} #-
{.deprecated: [PySequence_Concat: pySequenceConcat].}
proc pySequenceCount*(ob1, ob2: PyObjectPtr): int{.cdecl, importc: "PySequence_Count" dynlib: dllname.} #-
{.deprecated: [PySequence_Count: pySequenceCount].}
proc pySequenceGetItem*(ob: PyObjectPtr, i: int): PyObjectPtr{.cdecl, importc: "PySequence_GetItem" dynlib: dllname.} #-
{.deprecated: [PySequence_GetItem: pySequenceGetItem].}
proc pySequenceGetSlice*(ob: PyObjectPtr, i1, i2: int): PyObjectPtr{.cdecl, importc: "PySequence_GetSlice" dynlib: dllname.} #-
{.deprecated: [PySequence_GetSlice: pySequenceGetSlice].}
proc pySequenceIn*(ob1, ob2: PyObjectPtr): int{.cdecl, importc: "PySequence_In" dynlib: dllname.} #-
{.deprecated: [PySequence_In: pySequenceIn].}
proc pySequenceIndex*(ob1, ob2: PyObjectPtr): int{.cdecl, importc: "PySequence_Index" dynlib: dllname.} #-
{.deprecated: [PySequence_Index: pySequenceIndex].}
proc pySequenceLength*(ob: PyObjectPtr): int{.cdecl, importc: "PySequence_Length" dynlib: dllname.} #-
{.deprecated: [PySequence_Length: pySequenceLength].}
proc pySequenceRepeat*(ob: PyObjectPtr, count: int): PyObjectPtr{.cdecl, importc: "PySequence_Repeat" dynlib: dllname.} #-
{.deprecated: [PySequence_Repeat: pySequenceRepeat].}
proc pySequenceSetItem*(ob: PyObjectPtr, i: int, value: PyObjectPtr): int{.cdecl, importc: "PySequence_SetItem" dynlib: dllname.} #-
{.deprecated: [PySequence_SetItem: pySequenceSetItem].}
proc pySequenceSetSlice*(ob: PyObjectPtr, i1, i2: int, value: PyObjectPtr): int{.cdecl, importc: "PySequence_SetSlice" dynlib: dllname.} #-
{.deprecated: [PySequence_SetSlice: pySequenceSetSlice].}
proc pySequenceDelSlice*(ob: PyObjectPtr, i1, i2: int): int{.cdecl, importc: "PySequence_DelSlice" dynlib: dllname.} #-
{.deprecated: [PySequence_DelSlice: pySequenceDelSlice].}
proc pySequenceTuple*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PySequence_Tuple" dynlib: dllname.} #-
{.deprecated: [PySequence_Tuple: pySequenceTuple].}
proc pySequenceContains*(ob, value: PyObjectPtr): int{.cdecl, importc: "PySequence_Contains" dynlib: dllname.} #-
{.deprecated: [PySequence_Contains: pySequenceContains].}
proc pySliceGetIndices*(ob: PySliceObjectPtr, len: int, start, stop, step: var int): int{.cdecl, importc: "PySlice_GetIndices" dynlib: dllname.} #-
{.deprecated: [PySlice_GetIndices: pySliceGetIndices].}
proc pySliceGetIndicesEx*(ob: PySliceObjectPtr, len: int, start, stop, step, slicelength: var int): int{.cdecl, importc: "PySlice_GetIndicesEx" dynlib: dllname.} #-
{.deprecated: [PySlice_GetIndicesEx: pySliceGetIndicesEx].}
proc pySliceNew*(start, stop, step: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PySlice_New" dynlib: dllname.} #-
{.deprecated: [PySlice_New: pySliceNew].}
proc pyStringConcat*(ob1: var PyObjectPtr, ob2: PyObjectPtr){.cdecl, importc: "PyString_Concat" dynlib: dllname.} #-
{.deprecated: [PyString_Concat: pyStringConcat].}
proc pyStringConcatAndDel*(ob1: var PyObjectPtr, ob2: PyObjectPtr){.cdecl, importc: "PyString_ConcatAndDel" dynlib: dllname.} #-
{.deprecated: [PyString_ConcatAndDel: pyStringConcatAndDel].}
proc pyStringFormat*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyString_Format" dynlib: dllname.} #-
{.deprecated: [PyString_Format: pyStringFormat].}
proc pyStringFromStringAndSize*(s: cstring, i: int): PyObjectPtr{.cdecl, importc: "PyString_FromStringAndSize" dynlib: dllname.} #-
{.deprecated: [PyString_FromStringAndSize: pyStringFromStringAndSize].}
proc pyStringSize*(ob: PyObjectPtr): int{.cdecl, importc: "PyString_Size" dynlib: dllname.} #-
{.deprecated: [PyString_Size: pyStringSize].}
proc pyStringDecodeEscape*(s: cstring, length: int, errors: cstring, unicode: int, recode_encoding: cstring): PyObjectPtr{.cdecl, importc: "PyString_DecodeEscape" dynlib: dllname.} #-
{.deprecated: [PyString_DecodeEscape: pyStringDecodeEscape].}
proc pyStringRepr*(ob: PyObjectPtr, smartquotes: int): PyObjectPtr{.cdecl, importc: "PyString_Repr" dynlib: dllname.} #+
{.deprecated: [PyString_Repr: pyStringRepr].}
proc pySysGetObject*(s: cstring): PyObjectPtr{.cdecl, importc: "PySys_GetObject" dynlib: dllname.} #-
{.deprecated: [PySys_GetObject: pySysGetObject].}
#-
#PySys_Init:procedure; cdecl, importc, dynlib: dllname;
#-
proc pySysSetObject*(s: cstring, ob: PyObjectPtr): int{.cdecl, importc: "PySys_SetObject" dynlib: dllname.} #-
{.deprecated: [PySys_SetObject: pySysSetObject].}
proc pySysSetPath*(path: cstring){.cdecl, importc: "PySys_SetPath" dynlib: dllname.} #-
{.deprecated: [PySys_SetPath: pySysSetPath].}
#PyTraceBack_Fetch:function:PyObjectPtr; cdecl, importc, dynlib: dllname;
#-
proc pyTracebackHere*(p: pointer): int{.cdecl, importc: "PyTraceBack_Here" dynlib: dllname.} #-
{.deprecated: [PyTraceBack_Here: pyTracebackHere].}
proc pyTracebackPrint*(ob1, ob2: PyObjectPtr): int{.cdecl, importc: "PyTraceBack_Print" dynlib: dllname.} #-
{.deprecated: [PyTraceBack_Print: pyTracebackPrint].}
#PyTraceBack_Store:function (ob:PyObjectPtr):integer; cdecl, importc, dynlib: dllname;
#+
proc pyTupleGetItem*(ob: PyObjectPtr, i: int): PyObjectPtr{.cdecl, importc: "PyTuple_GetItem" dynlib: dllname.} #-
{.deprecated: [PyTuple_GetItem: pyTupleGetItem].}
proc pyTupleGetSlice*(ob: PyObjectPtr, i1, i2: int): PyObjectPtr{.cdecl, importc: "PyTuple_GetSlice" dynlib: dllname.} #+
{.deprecated: [PyTuple_GetSlice: pyTupleGetSlice].}
proc pyTupleNew*(size: int): PyObjectPtr{.cdecl, importc: "PyTuple_New" dynlib: dllname.} #+
{.deprecated: [PyTuple_New: pyTupleNew].}
proc pyTupleSetItem*(ob: PyObjectPtr, key: int, value: PyObjectPtr): int{.cdecl, importc: "PyTuple_SetItem" dynlib: dllname.} #+
{.deprecated: [PyTuple_SetItem: pyTupleSetItem].}
proc pyTupleSize*(ob: PyObjectPtr): int{.cdecl, importc: "PyTuple_Size" dynlib: dllname.} #+
{.deprecated: [PyTuple_Size: pyTupleSize].}
proc pyTypeIsSubtype*(a, b: PyTypeObjectPtr): int{.cdecl, importc: "PyType_IsSubtype" dynlib: dllname.}
{.deprecated: [PyType_IsSubtype: pyTypeIsSubtype].}
proc pyTypeGenericAlloc*(atype: PyTypeObjectPtr, nitems: int): PyObjectPtr{.cdecl, importc: "PyType_GenericAlloc" dynlib: dllname.}
{.deprecated: [PyType_GenericAlloc: pyTypeGenericAlloc].}
proc pyTypeGenericNew*(atype: PyTypeObjectPtr, args, kwds: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyType_GenericNew" dynlib: dllname.}
{.deprecated: [PyType_GenericNew: pyTypeGenericNew].}
proc pyTypeReady*(atype: PyTypeObjectPtr): int{.cdecl, importc: "PyType_Ready" dynlib: dllname.} #+
{.deprecated: [PyType_Ready: pyTypeReady].}
proc pyUnicodeFromWideChar*(w: pointer, size: int): PyObjectPtr{.cdecl, importc: "PyUnicode_FromWideChar" dynlib: dllname.} #+
{.deprecated: [PyUnicode_FromWideChar: pyUnicodeFromWideChar].}
proc pyUnicodeAsWideChar*(unicode: PyObjectPtr, w: pointer, size: int): int{.cdecl, importc: "PyUnicode_AsWideChar" dynlib: dllname.} #-
{.deprecated: [PyUnicode_AsWideChar: pyUnicodeAsWideChar].}
proc pyUnicodeFromOrdinal*(ordinal: int): PyObjectPtr{.cdecl, importc: "PyUnicode_FromOrdinal" dynlib: dllname.}
{.deprecated: [PyUnicode_FromOrdinal: pyUnicodeFromOrdinal].}
proc pyWeakrefGetObject*(theRef: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyWeakref_GetObject" dynlib: dllname.}
{.deprecated: [PyWeakref_GetObject: pyWeakrefGetObject].}
proc pyWeakrefNewProxy*(ob, callback: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyWeakref_NewProxy" dynlib: dllname.}
{.deprecated: [PyWeakref_NewProxy: pyWeakrefNewProxy].}
proc pyWeakrefNewRef*(ob, callback: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyWeakref_NewRef" dynlib: dllname.}
{.deprecated: [PyWeakref_NewRef: pyWeakrefNewRef].}
proc pyWrapperNew*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyWrapper_New" dynlib: dllname.}
{.deprecated: [PyWrapper_New: pyWrapperNew].}
proc pyBoolFromLong*(ok: int): PyObjectPtr{.cdecl, importc: "PyBool_FromLong" dynlib: dllname.} #-
{.deprecated: [PyBool_FromLong: pyBoolFromLong].}
proc pyAtExit*(prc: proc () {.cdecl.}): int{.cdecl, importc: "Py_AtExit" dynlib: dllname.} #-
{.deprecated: [Py_AtExit: pyAtExit].}
#Py_Cleanup:procedure; cdecl, importc, dynlib: dllname;
#-
proc pyCompileString*(s1, s2: cstring, i: int): PyObjectPtr{.cdecl, importc: "Py_CompileString" dynlib: dllname.} #-
{.deprecated: [Py_CompileString: pyCompileString].}
proc pyFatalError*(s: cstring){.cdecl, importc: "Py_FatalError" dynlib: dllname.} #-
{.deprecated: [Py_FatalError: pyFatalError].}
proc pyFindMethod*(md: PyMethodDefPtr, ob: PyObjectPtr, key: cstring): PyObjectPtr{.cdecl, importc: "Py_FindMethod" dynlib: dllname.} #-
{.deprecated: [Py_FindMethod: pyFindMethod].}
proc pyFindMethodInChain*(mc: PyMethodChainPtr, ob: PyObjectPtr, key: cstring): PyObjectPtr{.cdecl, importc: "Py_FindMethodInChain" dynlib: dllname.}                 #-
{.deprecated: [Py_FindMethodInChain: pyFindMethodInChain].}
proc pyFlushLine*(){.cdecl, importc: "Py_FlushLine" dynlib: dllname.} #+
{.deprecated: [Py_FlushLine: pyFlushLine].}
proc pyFinalize*(){.cdecl, importc: "Py_Finalize" dynlib: dllname.} #-
{.deprecated: [Py_Finalize: pyFinalize].}
proc pyErrExceptionMatches*(exc: PyObjectPtr): int{.cdecl, importc: "PyErr_ExceptionMatches" dynlib: dllname.} #-
{.deprecated: [PyErr_ExceptionMatches: pyErrExceptionMatches].}
proc pyErrGivenExceptionMatches*(raised_exc, exc: PyObjectPtr): int{.cdecl, importc: "PyErr_GivenExceptionMatches" dynlib: dllname.} #-
{.deprecated: [PyErr_GivenExceptionMatches: pyErrGivenExceptionMatches].}
proc pyEvalEvalCode*(co: PyCodeObjectPtr, globals, locals: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyEval_EvalCode" dynlib: dllname.} #+
{.deprecated: [PyEval_EvalCode: pyEvalEvalCode].}
proc pyGetVersion*(): cstring{.cdecl, importc: "Py_GetVersion" dynlib: dllname.} #+
{.deprecated: [Py_GetVersion: pyGetVersion].}
proc pyGetCopyright*(): cstring{.cdecl, importc: "Py_GetCopyright" dynlib: dllname.} #+
{.deprecated: [Py_GetCopyright: pyGetCopyright].}
proc pyGetExecPrefix*(): cstring{.cdecl, importc: "Py_GetExecPrefix" dynlib: dllname.} #+
{.deprecated: [Py_GetExecPrefix: pyGetExecPrefix].}
proc pyGetPath*(): cstring{.cdecl, importc: "Py_GetPath" dynlib: dllname.} #+
{.deprecated: [Py_GetPath: pyGetPath].}
proc pyGetPrefix*(): cstring{.cdecl, importc: "Py_GetPrefix" dynlib: dllname.} #+
{.deprecated: [Py_GetPrefix: pyGetPrefix].}
proc pyGetProgramName*(): cstring{.cdecl, importc: "Py_GetProgramName" dynlib: dllname.} #-
{.deprecated: [Py_GetProgramName: pyGetProgramName].}
proc pyParserSimpleParseString*(str: cstring, start: int): NodePtr{.cdecl, importc: "PyParser_SimpleParseString" dynlib: dllname.} #-
{.deprecated: [PyParser_SimpleParseString: pyParserSimpleParseString].}
proc pyNodeFree*(n: NodePtr){.cdecl, importc: "PyNode_Free" dynlib: dllname.} #-
{.deprecated: [PyNode_Free: pyNodeFree].}
proc pyErrNewException*(name: cstring, base, dict: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyErr_NewException" dynlib: dllname.} #-
{.deprecated: [PyErr_NewException: pyErrNewException].}
proc pyMalloc*(size: int): pointer {.cdecl, importc: "Py_Malloc" dynlib: dllname.}
{.deprecated: [Py_Malloc: pyMalloc].}
proc pyMemMalloc*(size: int): pointer {.cdecl, importc: "PyMem_Malloc" dynlib: dllname.}
{.deprecated: [PyMem_Malloc: pyMemMalloc].}
proc pyObjectCallMethod*(obj: PyObjectPtr, theMethod, format: cstring): PyObjectPtr{.cdecl, importc: "PyObject_CallMethod" dynlib: dllname.}
{.deprecated: [PyObject_CallMethod: pyObjectCallMethod].}
proc pySetProgramName*(name: cstring){.cdecl, importc: "Py_SetProgramName" dynlib: dllname.}
{.deprecated: [Py_SetProgramName: pySetProgramName].}
proc pyIsInitialized*(): int{.cdecl, importc: "Py_IsInitialized" dynlib: dllname.}
{.deprecated: [Py_IsInitialized: pyIsInitialized].}
proc pyGetProgramFullPath*(): cstring{.cdecl, importc: "Py_GetProgramFullPath" dynlib: dllname.}
{.deprecated: [Py_GetProgramFullPath: pyGetProgramFullPath].}
proc pyNewInterpreter*(): PyThreadStatePtr{.cdecl, importc: "Py_NewInterpreter" dynlib: dllname.}
{.deprecated: [Py_NewInterpreter: pyNewInterpreter].}
proc pyEndInterpreter*(tstate: PyThreadStatePtr){.cdecl, importc: "Py_EndInterpreter" dynlib: dllname.}
{.deprecated: [Py_EndInterpreter: pyEndInterpreter].}
proc pyEvalAcquireLock*(){.cdecl, importc: "PyEval_AcquireLock" dynlib: dllname.}
{.deprecated: [PyEval_AcquireLock: pyEvalAcquireLock].}
proc pyEvalReleaseLock*(){.cdecl, importc: "PyEval_ReleaseLock" dynlib: dllname.}
{.deprecated: [PyEval_ReleaseLock: pyEvalReleaseLock].}
proc pyEvalAcquireThread*(tstate: PyThreadStatePtr){.cdecl, importc: "PyEval_AcquireThread" dynlib: dllname.}
{.deprecated: [PyEval_AcquireThread: pyEvalAcquireThread].}
proc pyEvalReleaseThread*(tstate: PyThreadStatePtr){.cdecl, importc: "PyEval_ReleaseThread" dynlib: dllname.}
{.deprecated: [PyEval_ReleaseThread: pyEvalReleaseThread].}
proc pyInterpreterstateNew*(): PyInterpreterStatePtr{.cdecl, importc: "PyInterpreterState_New" dynlib: dllname.}
{.deprecated: [PyInterpreterState_New: pyInterpreterstateNew].}
proc pyInterpreterstateClear*(interp: PyInterpreterStatePtr){.cdecl, importc: "PyInterpreterState_Clear" dynlib: dllname.}
{.deprecated: [PyInterpreterState_Clear: pyInterpreterstateClear].}
proc pyInterpreterstateDelete*(interp: PyInterpreterStatePtr){.cdecl, importc: "PyInterpreterState_Delete" dynlib: dllname.}
{.deprecated: [PyInterpreterState_Delete: pyInterpreterstateDelete].}
proc pyThreadStateNew*(interp: PyInterpreterStatePtr): PyThreadStatePtr{.cdecl, importc: "PyThreadState_New" dynlib: dllname.}
{.deprecated: [PyThreadState_New: pyThreadStateNew].}
proc pyThreadStateClear*(tstate: PyThreadStatePtr){.cdecl, importc: "PyThreadState_Clear" dynlib: dllname.}
{.deprecated: [PyThreadState_Clear: pyThreadStateClear].}
proc pyThreadStateDelete*(tstate: PyThreadStatePtr){.cdecl, importc: "PyThreadState_Delete" dynlib: dllname.}
{.deprecated: [PyThreadState_Delete: pyThreadStateDelete].}
proc pyThreadStateGet*(): PyThreadStatePtr{.cdecl, importc: "PyThreadState_Get" dynlib: dllname.}
{.deprecated: [PyThreadState_Get: pyThreadStateGet].}
proc pyThreadStateSwap*(tstate: PyThreadStatePtr): PyThreadStatePtr{.cdecl, importc: "PyThreadState_Swap" dynlib: dllname.} 
{.deprecated: [PyThreadState_Swap: pyThreadStateSwap].}

# Run the interpreter independantly of the Nim application
proc pyMain*(argc: int, argv: CstringPtr): int{.cdecl, importc: "Py_Main" dynlib: dllname.}
{.deprecated: [Py_Main: pyMain].}
# Execute a script from a file
proc pyRunAnyFile*(filename: string): int =
  result = pyRunSimpleString(readFile(filename))

#Further exported Objects, may be implemented later
#
#    PyCode_New: Pointer;
#    PyErr_SetInterrupt: Pointer;
#    PyFile_AsFile: Pointer;
#    PyFile_FromFile: Pointer;
#    PyFloat_AsString: Pointer;
#    PyFrame_BlockPop: Pointer;
#    PyFrame_BlockSetup: Pointer;
#    PyFrame_ExtendStack: Pointer;
#    PyFrame_FastToLocals: Pointer;
#    PyFrame_LocalsToFast: Pointer;
#    PyFrame_New: Pointer;
#    PyGrammar_AddAccelerators: Pointer;
#    PyGrammar_FindDFA: Pointer;
#    PyGrammar_LabelRepr: Pointer;
#    PyInstance_DoBinOp: Pointer;
#    PyInt_GetMax: Pointer;
#    PyMarshal_Init: Pointer;
#    PyMarshal_ReadLongFromFile: Pointer;
#    PyMarshal_ReadObjectFromFile: Pointer;
#    PyMarshal_ReadObjectFromString: Pointer;
#    PyMarshal_WriteLongToFile: Pointer;
#    PyMarshal_WriteObjectToFile: Pointer;
#    PyMember_Get: Pointer;
#    PyMember_Set: Pointer;
#    PyNode_AddChild: Pointer;
#    PyNode_Compile: Pointer;
#    PyNode_New: Pointer;
#    PyOS_GetLastModificationTime: Pointer;
#    PyOS_Readline: Pointer;
#    PyOS_strtol: Pointer;
#    PyOS_strtoul: Pointer;
#    PyObject_CallFunction: Pointer;
#    PyObject_CallMethod: Pointer;
#    PyObject_Print: Pointer;
#    PyParser_AddToken: Pointer;
#    PyParser_Delete: Pointer;
#    PyParser_New: Pointer;
#    PyParser_ParseFile: Pointer;
#    PyParser_ParseString: Pointer;
#    PyParser_SimpleParseFile: Pointer;
#    PyRun_File: Pointer;
#    PyRun_InteractiveLoop: Pointer;
#    PyRun_InteractiveOne: Pointer;
#    PyRun_SimpleFile: Pointer;
#    PySys_GetFile: Pointer;
#    PyToken_OneChar: Pointer;
#    PyToken_TwoChars: Pointer;
#    PyTokenizer_Free: Pointer;
#    PyTokenizer_FromFile: Pointer;
#    PyTokenizer_FromString: Pointer;
#    PyTokenizer_Get: Pointer;
#    _PyObject_NewVar: Pointer;
#    _PyParser_Grammar: Pointer;
#    _PyParser_TokenNames: Pointer;
#    _PyThread_Started: Pointer;
#    _Py_c_diff: Pointer;
#    _Py_c_neg: Pointer;
#    _Py_c_pow: Pointer;
#    _Py_c_prod: Pointer;
#    _Py_c_quot: Pointer;
#    _Py_c_sum: Pointer;
#

# This function handles all cardinals, pointer types (with no adjustment of pointers!)
# (Extended) floats, which are handled as Python doubles and currencies, handled
# as (normalized) Python doubles.
proc pyImportExecCodeModule*(name: string, codeobject: PyObjectPtr): PyObjectPtr
{.deprecated: [PyImport_ExecCodeModule: pyImportExecCodeModule].}
proc pyStringCheck*(obj: PyObjectPtr): bool
{.deprecated: [PyString_Check: pyStringCheck].}
proc pyStringCheckExact*(obj: PyObjectPtr): bool
{.deprecated: [PyString_CheckExact: pyStringCheckExact].}
proc pyFloatCheck*(obj: PyObjectPtr): bool
{.deprecated: [PyFloat_Check: pyFloatCheck].}
proc pyFloatCheckExact*(obj: PyObjectPtr): bool
{.deprecated: [PyFloat_CheckExact: pyFloatCheckExact].}
proc pyIntCheck*(obj: PyObjectPtr): bool
{.deprecated: [PyInt_Check: pyIntCheck].}
proc pyIntCheckExact*(obj: PyObjectPtr): bool
{.deprecated: [PyInt_CheckExact: pyIntCheckExact].}
proc pyLongCheck*(obj: PyObjectPtr): bool
{.deprecated: [PyLong_Check: pyLongCheck].}
proc pyLongCheckExact*(obj: PyObjectPtr): bool
{.deprecated: [PyLong_CheckExact: pyLongCheckExact].}
proc pyTupleCheck*(obj: PyObjectPtr): bool
{.deprecated: [PyTuple_Check: pyTupleCheck].}
proc pyTupleCheckExact*(obj: PyObjectPtr): bool
{.deprecated: [PyTuple_CheckExact: pyTupleCheckExact].}
proc pyInstanceCheck*(obj: PyObjectPtr): bool
{.deprecated: [PyInstance_Check: pyInstanceCheck].}
proc pyClassCheck*(obj: PyObjectPtr): bool
{.deprecated: [PyClass_Check: pyClassCheck].}
proc pyMethodCheck*(obj: PyObjectPtr): bool
{.deprecated: [PyMethod_Check: pyMethodCheck].}
proc pyListCheck*(obj: PyObjectPtr): bool
{.deprecated: [PyList_Check: pyListCheck].}
proc pyListCheckExact*(obj: PyObjectPtr): bool
{.deprecated: [PyList_CheckExact: pyListCheckExact].}
proc pyDictCheck*(obj: PyObjectPtr): bool
{.deprecated: [PyDict_Check: pyDictCheck].}
proc pyDictCheckExact*(obj: PyObjectPtr): bool
{.deprecated: [PyDict_CheckExact: pyDictCheckExact].}
proc pyModuleCheck*(obj: PyObjectPtr): bool
{.deprecated: [PyModule_Check: pyModuleCheck].}
proc pyModuleCheckExact*(obj: PyObjectPtr): bool
{.deprecated: [PyModule_CheckExact: pyModuleCheckExact].}
proc pySliceCheck*(obj: PyObjectPtr): bool
{.deprecated: [PySlice_Check: pySliceCheck].}
proc pyFunctionCheck*(obj: PyObjectPtr): bool
{.deprecated: [PyFunction_Check: pyFunctionCheck].}
proc pyUnicodeCheck*(obj: PyObjectPtr): bool
{.deprecated: [PyUnicode_Check: pyUnicodeCheck].}
proc pyUnicodeCheckExact*(obj: PyObjectPtr): bool
{.deprecated: [PyUnicode_CheckExact: pyUnicodeCheckExact].}
proc pyTypeISGC*(t: PyTypeObjectPtr): bool
{.deprecated: [PyType_IS_GC: pyTypeISGC].}
proc pyObjectISGC*(obj: PyObjectPtr): bool
{.deprecated: [PyObject_IS_GC: pyObjectISGC].}
proc pyBoolCheck*(obj: PyObjectPtr): bool
{.deprecated: [PyBool_Check: pyBoolCheck].}
proc pyBasestringCheck*(obj: PyObjectPtr): bool
{.deprecated: [PyBaseString_Check: pyBasestringCheck].}
proc pyEnumCheck*(obj: PyObjectPtr): bool
{.deprecated: [PyEnum_Check: pyEnumCheck].}
proc pyObjectTypeCheck*(obj: PyObjectPtr, t: PyTypeObjectPtr): bool
{.deprecated: [PyObject_TypeCheck: pyObjectTypeCheck].}
proc pyInitModule*(name: cstring, md: PyMethodDefPtr): PyObjectPtr
{.deprecated: [Py_InitModule: pyInitModule].}
proc pyTypeHasFeature*(AType: PyTypeObjectPtr, AFlag: int): bool
{.deprecated: [PyType_HasFeature: pyTypeHasFeature].}

# implementation
proc pyIncref*(op: PyObjectPtr) {.inline.} = 
  inc(op.obRefcnt)
{.deprecated: [Py_INCREF: pyIncref].}

proc pyDecref*(op: PyObjectPtr) {.inline.} = 
  dec(op.obRefcnt)
  if op.obRefcnt == 0: 
    op.obType.tpDealloc(op)
{.deprecated: [Py_DECREF: pyDecref].}

proc pyXIncref*(op: PyObjectPtr) {.inline.} = 
  if op != nil: pyIncref(op)
{.deprecated: [Py_XINCREF: pyXIncref].}
  
proc pyXDecref*(op: PyObjectPtr) {.inline.} = 
  if op != nil: pyDecref(op)
{.deprecated: [Py_XDECREF: pyXDecref].}
  
proc pyImportExecCodeModule(name: string, codeobject: PyObjectPtr): PyObjectPtr = 
  var m, d, v, modules: PyObjectPtr
  m = pyImportAddModule(cstring(name))
  if m == nil: 
    return nil
  d = pyModuleGetDict(m)
  if pyDictGetItemString(d, "__builtins__") == nil: 
    if pyDictSetItemString(d, "__builtins__", pyEvalGetBuiltins()) != 0: 
      return nil
  if pyDictSetItemString(d, "__file__", 
                          PyCodeObjectPtr(codeobject).coFilename) != 0: 
    pyErrClear() # Not important enough to report
  v = pyEvalEvalCode(PyCodeObjectPtr(codeobject), d, d) # XXX owner ?
  if v == nil: 
    return nil
  pyXDecref(v)
  modules = pyImportGetModuleDict()
  if pyDictGetItemString(modules, cstring(name)) == nil: 
    pyErrSetString(pyExcImportError[] , cstring(
        "Loaded module " & name & "not found in sys.modules"))
    return nil
  pyXIncref(m)
  result = m

proc pyStringCheck(obj: PyObjectPtr): bool = 
  result = pyObjectTypeCheck(obj, pyStringType)

proc pyStringCheckExact(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj.obType == pyStringType)

proc pyFloatCheck(obj: PyObjectPtr): bool = 
  result = pyObjectTypeCheck(obj, pyFloatType)

proc pyFloatCheckExact(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj.obType == pyFloatType)

proc pyIntCheck(obj: PyObjectPtr): bool = 
  result = pyObjectTypeCheck(obj, pyIntType)

proc pyIntCheckExact(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj.obType == pyIntType)

proc pyLongCheck(obj: PyObjectPtr): bool = 
  result = pyObjectTypeCheck(obj, pyLongType)

proc pyLongCheckExact(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj.obType == pyLongType)

proc pyTupleCheck(obj: PyObjectPtr): bool = 
  result = pyObjectTypeCheck(obj, pyTupleType)

proc pyTupleCheckExact(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj[].obType == pyTupleType)

proc pyInstanceCheck(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj[].obType == pyInstanceType)

proc pyClassCheck(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj[].obType == pyClassType)

proc pyMethodCheck(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj[].obType == pyMethodType)

proc pyListCheck(obj: PyObjectPtr): bool = 
  result = pyObjectTypeCheck(obj, pyListType)

proc pyListCheckExact(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj[].obType == pyListType)

proc pyDictCheck(obj: PyObjectPtr): bool = 
  result = pyObjectTypeCheck(obj, pyDictType)

proc pyDictCheckExact(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj[].obType == pyDictType)

proc pyModuleCheck(obj: PyObjectPtr): bool = 
  result = pyObjectTypeCheck(obj, pyModuleType)

proc pyModuleCheckExact(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj[].obType == pyModuleType)

proc pySliceCheck(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj[].obType == pySliceType)

proc pyFunctionCheck(obj: PyObjectPtr): bool = 
  result = (obj != nil) and
      ((obj.obType == pyCfunctionType) or
      (obj.obType == pyFunctionType))

proc pyUnicodeCheck(obj: PyObjectPtr): bool = 
  result = pyObjectTypeCheck(obj, pyUnicodeType)

proc pyUnicodeCheckExact(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj.obType == pyUnicodeType)

proc pyTypeISGC(t: PyTypeObjectPtr): bool = 
  result = pyTypeHasFeature(t, pyTpflagsHaveGc)

proc pyObjectISGC(obj: PyObjectPtr): bool = 
  result = pyTypeISGC(obj.obType) and
      ((obj.obType.tpIsGc == nil) or (obj.obType.tpIsGc(obj) == 1))

proc pyBoolCheck(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj.obType == pyBoolType)

proc pyBasestringCheck(obj: PyObjectPtr): bool = 
  result = pyObjectTypeCheck(obj, pyBasestringType)

proc pyEnumCheck(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj.obType == pyEnumType)

proc pyObjectTypeCheck(obj: PyObjectPtr, t: PyTypeObjectPtr): bool = 
  result = (obj != nil) and (obj.obType == t)
  if not result and (obj != nil) and (t != nil): 
    result = pyTypeIsSubtype(obj.obType, t) == 1
  
proc pyInitModule(name: cstring, md: PyMethodDefPtr): PyObjectPtr = 
  result = pyInitModule4(name, md, nil, nil, 1012)

proc pyTypeHasFeature(AType: PyTypeObjectPtr, AFlag: int): bool = 
  #(((t)->tp_flags & (f)) != 0)
  result = (AType.tpFlags and AFlag) != 0

proc init(lib: LibHandle) = 
  pyDebugFlag = cast[IntPtr](symAddr(lib, "Py_DebugFlag"))
  pyVerboseFlag = cast[IntPtr](symAddr(lib, "Py_VerboseFlag"))
  pyInteractiveFlag = cast[IntPtr](symAddr(lib, "Py_InteractiveFlag"))
  pyOptimizeFlag = cast[IntPtr](symAddr(lib, "Py_OptimizeFlag"))
  pyNoSiteFlag = cast[IntPtr](symAddr(lib, "Py_NoSiteFlag"))
  pyUseClassExceptionsFlag = cast[IntPtr](symAddr(lib, "Py_UseClassExceptionsFlag"))
  pyFrozenFlag = cast[IntPtr](symAddr(lib, "Py_FrozenFlag"))
  pyTabcheckFlag = cast[IntPtr](symAddr(lib, "Py_TabcheckFlag"))
  pyUnicodeFlag = cast[IntPtr](symAddr(lib, "Py_UnicodeFlag"))
  pyIgnoreEnvironmentFlag = cast[IntPtr](symAddr(lib, "Py_IgnoreEnvironmentFlag"))
  pyDivisionWarningFlag = cast[IntPtr](symAddr(lib, "Py_DivisionWarningFlag"))
  pyNone = cast[PyObjectPtr](symAddr(lib, "_Py_NoneStruct"))
  pyEllipsis = cast[PyObjectPtr](symAddr(lib, "_Py_EllipsisObject"))
  pyFalse = cast[PyIntObjectPtr](symAddr(lib, "_Py_ZeroStruct"))
  pyTrue = cast[PyIntObjectPtr](symAddr(lib, "_Py_TrueStruct"))
  pyNotImplemented = cast[PyObjectPtr](symAddr(lib, "_Py_NotImplementedStruct"))
  pyImportFrozenModules = cast[FrozenPtrPtr](symAddr(lib, "PyImport_FrozenModules"))
  pyExcAttributeError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_AttributeError"))
  pyExcEOFError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_EOFError"))
  pyExcIOError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_IOError"))
  pyExcImportError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_ImportError"))
  pyExcIndexError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_IndexError"))
  pyExcKeyError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_KeyError"))
  pyExcKeyboardInterrupt = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_KeyboardInterrupt"))
  pyExcMemoryError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_MemoryError"))
  pyExcNameError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_NameError"))
  pyExcOverflowError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_OverflowError"))
  pyExcRuntimeError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_RuntimeError"))
  pyExcSyntaxError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_SyntaxError"))
  pyExcSystemError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_SystemError"))
  pyExcSystemExit = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_SystemExit"))
  pyExcTypeError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_TypeError"))
  pyExcValueError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_ValueError"))
  pyExcZeroDivisionError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_ZeroDivisionError"))
  pyExcArithmeticError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_ArithmeticError"))
  pyExcException = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_Exception"))
  pyExcFloatingPointError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_FloatingPointError"))
  pyExcLookupError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_LookupError"))
  pyExcStandardError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_StandardError"))
  pyExcAssertionError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_AssertionError"))
  pyExcEnvironmentError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_EnvironmentError"))
  pyExcIndentationError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_IndentationError"))
  pyExcMemoryErrorInst = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_MemoryErrorInst"))
  pyExcNotImplementedError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_NotImplementedError"))
  pyExcOSError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_OSError"))
  pyExcTabError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_TabError"))
  pyExcUnboundLocalError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_UnboundLocalError"))
  pyExcUnicodeError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_UnicodeError"))
  pyExcWarning = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_Warning"))
  pyExcDeprecationWarning = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_DeprecationWarning"))
  pyExcRuntimeWarning = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_RuntimeWarning"))
  pyExcSyntaxWarning = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_SyntaxWarning"))
  pyExcUserWarning = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_UserWarning"))
  pyExcOverflowWarning = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_OverflowWarning"))
  pyExcReferenceError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_ReferenceError"))
  pyExcStopIteration = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_StopIteration"))
  pyExcFutureWarning = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_FutureWarning"))
  pyExcPendingDeprecationWarning = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_PendingDeprecationWarning"))
  pyExcUnicodeDecodeError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_UnicodeDecodeError"))
  pyExcUnicodeEncodeError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_UnicodeEncodeError"))
  pyExcUnicodeTranslateError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_UnicodeTranslateError"))
  pyTypeType = cast[PyTypeObjectPtr](symAddr(lib, "PyType_Type"))
  pyCfunctionType = cast[PyTypeObjectPtr](symAddr(lib, "PyCFunction_Type"))
  pyCobjectType = cast[PyTypeObjectPtr](symAddr(lib, "PyCObject_Type"))
  pyClassType = cast[PyTypeObjectPtr](symAddr(lib, "PyClass_Type"))
  pyCodeType = cast[PyTypeObjectPtr](symAddr(lib, "PyCode_Type"))
  pyComplexType = cast[PyTypeObjectPtr](symAddr(lib, "PyComplex_Type"))
  pyDictType = cast[PyTypeObjectPtr](symAddr(lib, "PyDict_Type"))
  pyFileType = cast[PyTypeObjectPtr](symAddr(lib, "PyFile_Type"))
  pyFloatType = cast[PyTypeObjectPtr](symAddr(lib, "PyFloat_Type"))
  pyFrameType = cast[PyTypeObjectPtr](symAddr(lib, "PyFrame_Type"))
  pyFunctionType = cast[PyTypeObjectPtr](symAddr(lib, "PyFunction_Type"))
  pyInstanceType = cast[PyTypeObjectPtr](symAddr(lib, "PyInstance_Type"))
  pyIntType = cast[PyTypeObjectPtr](symAddr(lib, "PyInt_Type"))
  pyListType = cast[PyTypeObjectPtr](symAddr(lib, "PyList_Type"))
  pyLongType = cast[PyTypeObjectPtr](symAddr(lib, "PyLong_Type"))
  pyMethodType = cast[PyTypeObjectPtr](symAddr(lib, "PyMethod_Type"))
  pyModuleType = cast[PyTypeObjectPtr](symAddr(lib, "PyModule_Type"))
  pyObjectType = cast[PyTypeObjectPtr](symAddr(lib, "PyObject_Type"))
  pyRangeType = cast[PyTypeObjectPtr](symAddr(lib, "PyRange_Type"))
  pySliceType = cast[PyTypeObjectPtr](symAddr(lib, "PySlice_Type"))
  pyStringType = cast[PyTypeObjectPtr](symAddr(lib, "PyString_Type"))
  pyTupleType = cast[PyTypeObjectPtr](symAddr(lib, "PyTuple_Type"))
  pyUnicodeType = cast[PyTypeObjectPtr](symAddr(lib, "PyUnicode_Type"))
  pyBaseobjectType = cast[PyTypeObjectPtr](symAddr(lib, "PyBaseObject_Type"))
  pyBufferType = cast[PyTypeObjectPtr](symAddr(lib, "PyBuffer_Type"))
  pyCalliterType = cast[PyTypeObjectPtr](symAddr(lib, "PyCallIter_Type"))
  pyCellType = cast[PyTypeObjectPtr](symAddr(lib, "PyCell_Type"))
  pyClassmethodType = cast[PyTypeObjectPtr](symAddr(lib, "PyClassMethod_Type"))
  pyPropertyType = cast[PyTypeObjectPtr](symAddr(lib, "PyProperty_Type"))
  pySeqiterType = cast[PyTypeObjectPtr](symAddr(lib, "PySeqIter_Type"))
  pyStaticmethodType = cast[PyTypeObjectPtr](symAddr(lib, "PyStaticMethod_Type"))
  pySuperType = cast[PyTypeObjectPtr](symAddr(lib, "PySuper_Type"))
  pySymtableentryType = cast[PyTypeObjectPtr](symAddr(lib, "PySymtableEntry_Type"))
  pyTracebackType = cast[PyTypeObjectPtr](symAddr(lib, "PyTraceBack_Type"))
  pyWrapperdescrType = cast[PyTypeObjectPtr](symAddr(lib, "PyWrapperDescr_Type"))
  pyBasestringType = cast[PyTypeObjectPtr](symAddr(lib, "PyBaseString_Type"))
  pyBoolType = cast[PyTypeObjectPtr](symAddr(lib, "PyBool_Type"))
  pyEnumType = cast[PyTypeObjectPtr](symAddr(lib, "PyEnum_Type"))


# Unfortunately we have to duplicate the loading mechanism here, because Nimrod
# used to not support variables from dynamic libraries. Well designed API's
# don't require this anyway. Python is an exception.

var
  lib: LibHandle

when defined(windows):
  const
    LibNames = ["python27.dll", "python26.dll", "python25.dll",
      "python24.dll", "python23.dll", "python22.dll", "python21.dll",
      "python20.dll", "python16.dll", "python15.dll"]
elif defined(macosx):
  const
    LibNames = ["libpython2.7.dylib", "libpython2.6.dylib",
      "libpython2.5.dylib", "libpython2.4.dylib", "libpython2.3.dylib", 
      "libpython2.2.dylib", "libpython2.1.dylib", "libpython2.0.dylib",
      "libpython1.6.dylib", "libpython1.5.dylib"]
else:
  const
    LibNames = [
      "libpython2.7.so" & dllver,
      "libpython2.6.so" & dllver, 
      "libpython2.5.so" & dllver, 
      "libpython2.4.so" & dllver, 
      "libpython2.3.so" & dllver, 
      "libpython2.2.so" & dllver, 
      "libpython2.1.so" & dllver, 
      "libpython2.0.so" & dllver,
      "libpython1.6.so" & dllver, 
      "libpython1.5.so" & dllver]
  
for libName in items(LibNames): 
  lib = loadLib(libName, global_symbols=true)
  if lib != nil:
    echo "Loaded dynamic library: '$1'" % libName
    break

if lib == nil:
  quit("could not load python library")
init(lib)


## Deprecated type definitions
{.deprecated: [TAllocFunc: AllocFunc].}
{.deprecated: [TBinaryFunc: BinaryFunc].}
{.deprecated: [PByte: BytePtr].}
{.deprecated: [TCmpFunc: CmpFunc].}
{.deprecated: [TCO_MAXBLOCKS: coMaxblocks].}
{.deprecated: [TCoercion: Coercion].}
{.deprecated: [TDescrGetFunc: DescrGetFunc].}
{.deprecated: [TDescrSetFunc: DescrSetFunc].}
{.deprecated: [Tfrozen: Frozen].}
{.deprecated: [P_frozen: FrozenPtr].}
{.deprecated: [PP_frozen: FrozenPtrPtr].}
{.deprecated: [TGetAttrFunc: GetAttrFunc].}
{.deprecated: [TGetAttroFunc: GetAttroFunc].}
{.deprecated: [TGetCharBufferProc: GetCharBufferProc].}
{.deprecated: [TGetIterFunc: GetIterFunc].}
{.deprecated: [TGetReadBufferProc: GetReadBufferProc].}
{.deprecated: [TGetSegCountProc: GetSegCountProc].}
{.deprecated: [TGetter: Getter].}
{.deprecated: [TGetWriteBufferProc: GetWriteBufferProc].}
{.deprecated: [THashFunc: HashFunc].}
{.deprecated: [TInitProc: InitProc].}
{.deprecated: [TInquiry: Inquiry].}
{.deprecated: [TIntArgFunc: IntArgFunc].}
{.deprecated: [TIntIntArgFunc: IntIntArgFunc].}
{.deprecated: [TIntIntObjArgProc: IntIntObjArgProc].}
{.deprecated: [TIntObjArgProc: IntObjArgProc].}
{.deprecated: [PInt: IntPtr].}
{.deprecated: [TIterNextFunc: IterNextFunc].}
{.deprecated: [TNewFunc: NewFunc].}
{.deprecated: [Tnode: Node].}
{.deprecated: [PNode: NodePtr].}
{.deprecated: [TObjObjargProc: ObjObjargProc].}
{.deprecated: [TObjObjProc: ObjObjProc].}
{.deprecated: [TPFlag: PFlag].}
{.deprecated: [TPFlags: PFlags].}
{.deprecated: [TPrintFunc: PrintFunc].}
{.deprecated: [pwrapperbase: wrapperbasePtr].}
{.deprecated: [TPyComplex: PyComplex].}
{.deprecated: [TPyBufferProcs: PyBufferProcs].}
{.deprecated: [PPyBufferProcs: PyBufferProcsPtr].}
{.deprecated: [TPyCFunction: PyCFunction].}
{.deprecated: [TPyClassObject: PyClassObject].}
{.deprecated: [PPyClassObject: PyClassObjectPtr].}
{.deprecated: [TPyCodeObject: PyCodeObject].}
{.deprecated: [PPyCodeObject: PyCodeObjectPtr].}
{.deprecated: [TPyDateTime_BaseDateTime: PyDateTime_BaseDateTime].}
{.deprecated: [PPyDateTime_BaseDateTime: PyDateTime_BaseDateTimePtr].}
{.deprecated: [TPyDateTime_BaseTime: PyDateTime_BaseTime].}
{.deprecated: [PPyDateTime_BaseTime: PyDateTime_BaseTimePtr].}
{.deprecated: [TPyDateTime_BaseTZInfo: PyDateTime_BaseTZInfo].}
{.deprecated: [PPyDateTime_BaseTZInfo: PyDateTime_BaseTZInfoPtr].}
{.deprecated: [TPyDateTime_Date: PyDateTime_Date].}
{.deprecated: [PPyDateTime_Date: PyDateTime_DatePtr].}
{.deprecated: [TPyDateTime_DateTime: PyDateTime_DateTime].}
{.deprecated: [PPyDateTime_DateTime: PyDateTime_DateTimePtr].}
{.deprecated: [TPyDateTime_Delta: PyDateTime_Delta].}
{.deprecated: [PPyDateTime_Delta: PyDateTime_DeltaPtr].}
{.deprecated: [TPyDateTime_Time: PyDateTime_Time].}
{.deprecated: [PPyDateTime_Time: PyDateTime_TimePtr].}
{.deprecated: [TPyDateTime_TZInfo: PyDateTime_TZInfo].}
{.deprecated: [PPyDateTime_TZInfo: PyDateTime_TZInfoPtr].}
{.deprecated: [TPyDescrObject: PyDescrObject].}
{.deprecated: [PPyDescrObject: PyDescrObjectPtr].}
{.deprecated: [TPyDestructor: PyDestructor].}
{.deprecated: [TPyFrameObject: PyFrameObject].}
{.deprecated: [PPyFrameObject: PyFrameObjectPtr].}
{.deprecated: [TPyGetSetDef: PyGetSetDef].}
{.deprecated: [PPyGetSetDef: PyGetSetDefPtr].}
{.deprecated: [TPyGetSetDescrObject: PyGetSetDescrObject].}
{.deprecated: [PPyGetSetDescrObject: PyGetSetDescrObjectPtr].}
{.deprecated: [TPyInstanceObject: PyInstanceObject].}
{.deprecated: [PPyInstanceObject: PyInstanceObjectPtr].}
{.deprecated: [TPyInterpreterState: PyInterpreterState].}
{.deprecated: [PPyInterpreterState: PyInterpreterStatePtr].}
{.deprecated: [TPyIntObject: PyIntObject].}
{.deprecated: [PPyIntObject: PyIntObjectPtr].}
{.deprecated: [TPyMappingMethods: PyMappingMethods].}
{.deprecated: [PPyMappingMethods: PyMappingMethodsPtr].}
{.deprecated: [TPyMemberDef: PyMemberDef].}
{.deprecated: [PPyMemberDef: PyMemberDefPtr].}
{.deprecated: [TPyMemberDescrObject: PyMemberDescrObject].}
{.deprecated: [PPyMemberDescrObject: PyMemberDescrObjectPtr].}
{.deprecated: [TPyMemberFlag: PyMemberFlag].}
{.deprecated: [TPyMemberType: PyMemberType].}
{.deprecated: [TPyMethodChain: PyMethodChain].}
{.deprecated: [PPyMethodChain: PyMethodChainPtr].}
{.deprecated: [TPyMethodDef: PyMethodDef].}
{.deprecated: [PPyMethodDef: PyMethodDefPtr].}
{.deprecated: [TPyMethodDescrObject: PyMethodDescrObject].}
{.deprecated: [PPyMethodDescrObject: PyMethodDescrObjectPtr].}
{.deprecated: [TPyMethodObject: PyMethodObject].}
{.deprecated: [PPyMethodObject: PyMethodObjectPtr].}
{.deprecated: [TPyNumberMethods: PyNumberMethods].}
{.deprecated: [PPyNumberMethods: PyNumberMethodsPtr].}
{.deprecated: [TPyObject: PyObject].}
{.deprecated: [PPyObject: PyObjectPtr].}
{.deprecated: [PPPyObject: PyObjectPtrPtr].}
{.deprecated: [PPPPyObject: PyObjectPtrPtrPtr].}
{.deprecated: [TPySequenceMethods: PySequenceMethods].}
{.deprecated: [PPySequenceMethods: PySequenceMethodsPtr].}
{.deprecated: [TPySliceObject: PySliceObject].}
{.deprecated: [PPySliceObject: PySliceObjectPtr].}
{.deprecated: [TPyThreadState: PyThreadState].}
{.deprecated: [PPyThreadState: PyThreadStatePtr].}
{.deprecated: [TPyTraceBackObject: PyTraceBackObject].}
{.deprecated: [PPyTraceBackObject: PyTraceBackObjectPtr].}
{.deprecated: [TPyTryBlock: PyTryBlock].}
{.deprecated: [PPyTryBlock: PyTryBlockPtr].}
{.deprecated: [TPyTypeObject: PyTypeObject].}
{.deprecated: [PPyTypeObject: PyTypeObjectPtr].}
{.deprecated: [TPyWeakReference: PyWeakReference].}
{.deprecated: [PPyWeakReference: PyWeakReferencePtr].}
{.deprecated: [TPyWrapperDescrObject: PyWrapperDescrObject].}
{.deprecated: [PPyWrapperDescrObject: PyWrapperDescrObjectPtr].}
{.deprecated: [TReprFunc: ReprFunc].}
{.deprecated: [TRichCmpFunc: RichCmpFunc].}
{.deprecated: [TRichComparisonOpcode: RichComparisonOpcode].}
{.deprecated: [TSetAttrFunc: SetAttrFunc].}
{.deprecated: [TSetAttroFunc: SetAttroFunc].}
{.deprecated: [TSetter: Setter].}
{.deprecated: [TTernaryFunc: TernaryFunc].}
{.deprecated: [TTraverseProc: TraverseProc].}
{.deprecated: [TUnaryFunc: UnaryFunc].}
{.deprecated: [TVisitProc: VisitProc].}
{.deprecated: [Twrapperbase: wrapperbase].}
{.deprecated: [Twrapperfunc: wrapperfunc].}