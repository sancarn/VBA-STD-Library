VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "stdArray"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'@TODO:
'* Implement Exceptions throughout all Array functions.
'* Fully implement pInitialised where necessary.
'* Build Methods Slice; Splice; Sort
'* Add methods from ruby
'* Documentation of methods

#If VBA6 Then
  Private Declare PtrSafe Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" (ByVal Destination As LongPtr, ByVal Source As LongPtr, ByVal Length As Long)
#Else
  Private Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" (ByVal Destination As Long, ByVal Source As Long, ByVal Length As Long)
#End If
Private Enum SortDirection
    Ascending = 1
    Descending = 2
End Enum
Private Type SortStruct
  Value as variant
  SortValue as variant
End Type

Private pArr() As Variant
Private pProxyLength As Long
Private pLength As Long

Private pChunking As Long
Private pInitialised As Boolean



Public Event BeforeArrLet(ByRef arr as stdArray, ByRef arr as variant)
Public Event AfterArrLet(ByRef arr as stdArray, ByRef arr as variant)
Public Event BeforeAdd(ByRef arr As stdArray, ByVal iIndex As Long, ByRef item As Variant, ByRef cancel As Boolean)
Public Event AfterAdd(ByRef arr as stdArray, ByVal iIndex as long, ByRef item as variant)
Public Event BeforeRemove(ByRef arr as stdArray, ByVal iIndex as long, ByRef item as variant, ByRef cancel as Boolean)
Public Event AfterRemove(ByRef arr as stdArray, ByVal iIndex as long)
Public Event AfterClone(ByRef clone as stdArray)
Public Event AfterCreate(ByRef arr as stdArray)

Public Function Create(ParamArray params() As Variant) As stdArray
    Set Create = New stdArray
    
    Dim i As Long
    Dim lb As Long: lb = LBound(params)
    Dim ub As Long: ub = UBound(params)
    
    Call Create.init(ub - lb + 1, 10)
    
    For i = lb To ub
        Call Create.Push(params(i))
    Next

    'Raise AfterCreate event
    RaiseEvent AfterCreate(Create)
End Function


Public Function CreateWithOptions(ByVal iInitialLength As Long, ByVal iChunking As Long, ParamArray params() As Variant) As stdArray
    Set CreateWithOptions = New stdArray
    
    Dim i As Long
    Dim lb As Long: lb = LBound(params)
    Dim ub As Long: ub = UBound(params)
    
    Call CreateWithOptions.init(iInitialLength, iChunking)
    For i = lb To ub
        Call CreateWithOptions.Push(params(i))
    Next

    'Raise AfterCreate event
    RaiseEvent AfterCreate(Create)
End Function


Public Function CreateFromArray(ByVal arr As Variant) As stdArray
    Set CreateFromArray = New stdArray
    
    Dim i As Long
    Dim lb As Long: lb = LBound(arr)
    Dim ub As Long: ub = UBound(arr)
    Call CreateFromArray.init(ub - lb + 1, 10)
    
    For i = lb To ub
        Call CreateFromArray.Push(arr(i))
    Next

    'Raise AfterCreate event
    RaiseEvent AfterCreate(Create)
End Function


Friend Sub init(ByVal iInitialLength As Long, ByVal iChunking As Long)
  If iChunking > iInitialLength Then iInitialLength = iChunking
  If Not pInitialised Then
    pProxyLength = iInitialLength
    ReDim pArr(1 To iInitialLength) As Variant
    pChunking = iChunking
    pInitialised = True
  End If
End Sub

Public Property Get Length() As Long
    Length = pLength
End Property
Public Property Get zProxyLength() As Long
    zProxyLength = pProxyLength
End Property

Public Sub Resize(ByVal iLength As Long)
  pLength = iLength
End Sub

Public Sub Rechunk()
  Dim fNumChunks As Double, iNumChunks As Long
  fNumChunks = pLength / pChunking
  iNumChunks = CLng(fNumChunks)
  If fNumChunks > iNumChunks Then iNumChunks = iNumChunks + 1
  
  ReDim Preserve pArr(1 To iNumChunks * pChunking) As Variant
End Sub


'Algorithms:
'0 - Quicksort
Public Function Sort(Optional ByVal cbSortBy As stdICallable = Nothing, Optional ByVal cbComparrason As stdICallable = Nothing, Optional ByVal iAlgorithm As Long = 0, Optional ByVal bSortInPlace As Boolean = False) As stdArray
    If Not bSortInPlace Then
        Set Sort = Me.Clone.Sort(cbSortBy, cbComparrason, iAlgorithm, True)
    Else
        Dim arr() As SortStruct
        ReDim arr(1 To Me.Length) As SortStruct
        
        Dim i As Long
        
        'Copy array to sort structures
        For i = 1 To Me.Length
            Call CopyVariant(arr(i).Value, pArr(i))
            If cbSortBy Is Nothing Then
                Call CopyVariant(arr(i).SortValue, pArr(i))
            Else
                Call CopyVariant(arr(i).SortValue, cbSortBy.Run(pArr(i)))
            End If
        Next
        
        'Call sort algorithm
        Select Case iAlgorithm
            Case 0 'QuickSort
                Call Sort_QuickSort(arr, cbComparrason)
            Case Else
                stdError.Raise "Invalid sorting algorithm specified"
        End Select
        
        'Copy sort structures to array
        For i = 1 To Me.Length
            Call CopyVariant(pArr(i), arr(i).Value)
        Next
        
        'Return array
        Set Sort = Me
    End If
End Function

'QuickSort3
' Src: https://www.vbforums.com/showthread.php?473677-VB6-Sorting-algorithms-%28sort-array-sorting-arrays%29
' Omit plngLeft & plngRight; they are used internally during recursion
Private Sub Sort_QuickSort(ByRef pvarArray() As SortStruct, Optional cbComparrison As stdICallable = nothing, Optional ByVal plngLeft As Long, Optional ByVal plngRight As Long)
    Dim lngFirst As Long
    Dim lngLast As Long
    Dim varMid As SortStruct
    Dim varSwap As SortStruct
    
    If plngRight = 0 Then
        plngLeft = 1
        plngRight = Me.Length
    End If
    lngFirst = plngLeft
    lngLast = plngRight
    varMid = pvarArray((plngLeft + plngRight) \ 2)
    Do
        If cbComparrison Is Nothing Then
            Do While pvarArray(lngFirst).SortValue < varMid.SortValue And lngFirst < plngRight
                lngFirst = lngFirst + 1
            Loop
            Do While varMid.SortValue < pvarArray(lngLast).SortValue And lngLast > plngLeft
                lngLast = lngLast - 1
            Loop
        Else
            Do While cbComparrison.Run(pvarArray(lngFirst).SortValue, varMid.SortValue) And lngFirst < plngRight
                lngFirst = lngFirst + 1
            Loop
            Do While cbComparrison.Run(varMid.SortValue, pvarArray(lngLast).SortValue) And lngLast > plngLeft
                lngLast = lngLast - 1
            Loop
        End If
        
        If lngFirst <= lngLast Then
            varSwap = pvarArray(lngFirst)
            pvarArray(lngFirst) = pvarArray(lngLast)
            pvarArray(lngLast) = varSwap
            lngFirst = lngFirst + 1
            lngLast = lngLast - 1
        End If
    Loop Until lngFirst > lngLast
    If plngLeft < lngLast Then Sort_QuickSort pvarArray, cbComparrison, plngLeft, lngLast
    If lngFirst < plngRight Then Sort_QuickSort pvarArray, cbComparrison, lngFirst, plngRight
End Sub





Public Property Get arr() As Variant
    if pLength = 0 then
      arr = Array()
    else
      Dim vRet() As Variant
      ReDim vRet(1 To pLength) As Variant
      For i = 1 To pLength
        Call CopyVariant(vRet(i), pArr(i))
      Next
      arr = vRet
    end if
End Property
Public Property Let arr(v As Variant)
    RaiseEvent BeforeArrLet(me,v)
    Dim lb As Long: lb = LBound(v)
    Dim ub As Long: ub = UBound(v)
    Dim cnt As Long: cnt = ub - lb + 1
    ReDim pArr(1 To (Int(cnt / pChunking) + 1) * pChunking) As Variant
    For i = lb To ub
        Call Push(pArr(i))
    Next
    RaiseEvent AfterArrLet(me,v)
End Property

Public Sub Push(ByVal el As Variant)
  If pInitialised Then
    'Before Add event
    Dim bCancel as Boolean
    RaiseEvent BeforeAdd(me, pLength + 1, el, bCancel)
    if bCancel then exit sub

    If pLength = pProxyLength Then
        pProxyLength = pProxyLength + pChunking
        ReDim Preserve pArr(1 To pProxyLength) As Variant
    End If
    
    pLength = pLength + 1
    CopyVariant pArr(pLength), el

    'After add event
    RaiseEvent AfterAdd(me, pLength, pArr(pLength))
  Else
    'Error
  End If
End Sub

Public Function Pop() As Variant
    If pInitialised Then
        If pLength > 0 Then
            'Raise BeforeRemove event and optionally cancel
            Dim bCancel as Boolean
            RaiseEvent BeforeRemove(me, pLength, pArr(pLength), bCancel)
            If bCancel then exit function

            CopyVariant Pop, pArr(pLength)
            pLength = pLength - 1

            'Raise AfterRemove event
            RaiseEvent AfterRemove(me, pLength)
        Else
            Pop = Empty
        End If
    Else
        'Error
    End If
End Function

Public Function Remove(ByVal index As Long) As Variant
  'Ensure initialised
  If pInitialised Then
    'Ensure length > 0
    If pLength > 0 Then
      'Ensure index < length
      If index <= pLength Then
        'Raise BeforeRemove event and optionally cancel
        Dim bCancel as Boolean
        RaiseEvent BeforeRemove(me, index, pArr(index), bCancel)
        If bCancel then exit function

        'Copy party we are removing to return variable
        CopyVariant Remove, pArr(index)
        
        'Loop through array from removal, set i-1th element to ith element
        Dim i As Long
        For i = index + 1 To pLength
            pArr(i - 1) = pArr(i)
        Next

        'Set last element length and subtract total length by 1
        pArr(pLength) = Empty
        pLength = pLength - 1

        'Raise after remove event
        RaiseEvent AfterRemove(me, index)
      Else
        'Error
      End If
    Else
      'Error
    End If
  Else
      'Error
  End If
End Function

Public Function Shift() As Variant
  'Would be good to use CopyMemory here
  
  CopyVariant Shift, pArr(1)
  Dim i As Long
  For i = 1 To pLength - 1
    pArr(i) = pArr(i + 1)
  Next
  pLength = pLength -1
End Function

Public Function Unshift(val As Variant) As stdArray
  'Would be good to use CopyMemory here
  
  'Before Add event
  Dim bCancel as Boolean
  RaiseEvent BeforeAdd(me, 1, val, bCancel)
  if bCancel then exit Function

  'Ensure array is big enough and increase pLength
  If pLength = pProxyLength Then
    pProxyLength = pProxyLength + pChunking
    ReDim Preserve pArr(1 To pProxyLength) As Variant
  End If
  pLength = pLength + 1
  
  'Unshift
  For i = pLength - 1 To 1 Step -1
    pArr(i + 1) = pArr(i)
  Next
  pArr(1) = val
  
  'After Add event
  RaiseEvent AfterAdd(me, 1, val)

  Set Unshift = Me
End Function

Public Function Slice() As stdArray
  
End Function

Public Function Splice() As stdArray
  
End Function

Public Function Clone() As stdArray
  If pInitialised Then
      If pInitialised Then
        'Similar to CreateFromArray() but passing length through also:
        Set Clone = New stdArray
        
        Call Clone.init(pLength, 10)
        
        Dim i As Long
        For i = 1 To pLength
            Call Clone.Push(pArr(i))
        Next
      Else
        'Error
      End If

      RaiseEvent AfterClone(Clone)
  Else
    'Error
  End If
End Function

Public Function Reverse() As stdArray
    'TODO: Need to find a better more low level approach to creating arrays from existing arrays/preventing redim for methods like this
    Dim ret As stdArray
    Set ret = stdArray.Create()
    For i = pLength To 1 Step -1
      Call ret.Push(pArr(i))
    Next
    Set Reverse = ret
End Function

Public Function Concat(ByVal arr As stdArray) As stdArray
  Dim x As stdArray
  Set x = Clone()
  
  If Not arr Is Nothing Then
    Dim i As Long
    For i = 1 To arr.Length
      Call x.Push(arr.item(i))
    Next
  End If
  
  Set Concat = x
End Function

Public Function Join(Optional ByVal delimeter As String = ",") As String
  If pInitialised Then
      If pLength > 0 Then
        Dim sOutput As String
        sOutput = pArr(1)
        
        Dim i As Long
        For i = 2 To pLength
          sOutput = sOutput & delimeter & pArr(i)
        Next
        Join = sOutput
      Else
        Join = ""
      End If
  Else
    'Error
  End If
End Function


Public Property Get item(ByVal i As Integer) As Variant
Attribute item.VB_UserMemId = 0
    'item(1) = 1st element
    'item(2) = 2nd element
    'etc.
    CopyVariant item, pArr(i)
    
End Property
Public Property Set item(ByVal i As Integer, ByVal item As Object)
  set pArr(i) = item
End Property
Public Property Let item(ByVal i As Integer, ByVal item As Variant)
  pArr(i) = item
End Property
Public Sub PutItem(ByVal i As Integer, ByRef item As Variant)
  CopyVariant pArr(i), item
End Sub


Public Function indexOf(ByVal el As Variant, Optional ByVal start As Integer = 1)
  Dim elIsObj As Boolean, i As Long, item As Variant, itemIsObj As Boolean
  
  'Is element an object?
  elIsObj = IsObject(el)
  
  'Loop over contents starting from start
  For i = start To pLength
    'Get item data
    CopyVariant item, pArr(i)
    
    'Is item an object?
    itemIsObj = IsObject(item)
    
    'If both item and el are objects     (must be the same type in order to be the same data)
    If itemIsObj And elIsObj Then
      If item Is el Then 'check items equal
        indexOf = i 'return item index
        Exit Function
      End If
    'If both item and el are not objects (must be the same type in order to be the same data)
    ElseIf Not itemIsObj And Not elIsObj Then
      If item = el Then 'check items equal
        indexOf = i 'return item index
        Exit Function
      End If
    End If
  Next

  'Return -1 i.e. no match found
  indexOf = -1
End Function

Public Function lastIndexOf(ByVal el As Variant)
  Dim elIsObj As Boolean, i As Long, item As Variant, itemIsObj As Boolean
  
  'Is element an object?
  elIsObj = IsObject(el)
  
  'Loop over contents starting from start
  For i = pLength To 1 Step -1
    'Get item data
    CopyVariant item, pArr(i)
    
    'Is item an object?
    itemIsObj = IsObject(item)
    
    'If both item and el are objects     (must be the same type in order to be the same data)
    If itemIsObj And elIsObj Then
      If item Is el Then 'check items equal
        lastIndexOf = i 'return item index
        Exit Function
      End If
    'If both item and el are not objects (must be the same type in order to be the same data)
    ElseIf Not itemIsObj And Not elIsObj Then
      If item = el Then 'check items equal
        lastIndexOf = i 'return item index
        Exit Function
      End If
    End If
  Next

  'Return -1 i.e. no match found
  lastIndexOf = -1
End Function

Public Function includes(ByVal el As Variant, Optional ByVal startFrom As Integer = 1) As Boolean
  includes = indexOf(el, startFrom) >= startFrom
End Function





'Iterative Functions (All require stdICallable):

'Example: if incidents.IsEvery(cbValid) then ...
Public Function IsEvery(ByVal cb As stdICallable) As Boolean
  If pInitialised Then
    Dim i As Long
    For i = 1 To pLength
      Dim bFlag as Boolean
      bFlag = cb.run(pArr(i))
      
      If Not bFlag Then
        IsEvery = False
        Exit Function
      End If
    Next
    
    IsEvery = True
  Else
    'Error
  End If
End Function

Public Function IsSome(ByVal cb As stdICallable) As Boolean
  If pInitialised Then
    Dim i As Integer
    For i = 1 To pLength
      Dim bFlag as Boolean
      bFlag = cb.Run(pArr(i))
      
      if bFlag then
        IsSome = true
        Exit Function
      end if
    Next
    IsSome = False
  Else
    'Error
  End If
End Function

Public Sub ForEach(ByVal cb As stdICallable)
  If pInitialised Then
    Dim i As Integer
    For i = 1 To pLength
      Call cb.Run(pArr(i))
    Next
  Else
    'Error
  End If
End Sub

Public Function Map(ByVal cb As stdICallable) As stdArray
  If pInitialised Then
    Dim pMap As stdArray
    Set pMap = Me.Clone()
    
    Dim i As Integer
    For i = 1 To pLength
      'BUGFIX: Sometimes required, not sure when
      Dim v As Variant
      CopyVariant v, item(i)
      
      'Call callback
      Call pMap.PutItem(i, cb.Run(v))
    Next
    
    Set Map = pMap
  Else
    'Error
  End If
End Function


'OPTIMISE: Needs optimisation. Currently very sub-optimal
Public Function Unique(Optional ByVal cb As stdICallable = Nothing) As stdArray
  Dim ret As stdArray: Set ret = stdArray.CreateWithOptions(pLength, pChunking)
  Dim retL As stdArray: Set retL = CreateWithOptions(pLength, pChunking)
  
  'Collect keys
  Dim vKeys As stdArray
  If cb Is Nothing Then
    Set vKeys = Me.Clone
  Else
    Set vKeys = Me.Map(cb)
  End If
  
  'Unique by key
  For i = 1 To pLength
    If Not retL.includes(vKeys.item(i)) Then
      Call retL.Push(vKeys.item(i))
      Call ret.Push(pArr(i))
    End If
  Next

  'Return data
  Set Unique = ret
End Function


Public Function Reduce(ByVal cb As stdICallable, Optional ByVal initialValue As Variant=0) As Variant
  If pInitialised Then
    Reduce = initialValue
    
    Dim i As Integer
    For i = 1 To pLength
      'BUGFIX: Sometimes required, not sure when
      Dim el As Variant
      CopyVariant el, pArr(i)

      'Reduce
      Reduce = cb.Run(Reduce, el)
    Next
  Else
    'Error
  End If
End Function

Public Function Filter(ByVal cb As stdICallable) As stdArray
    Dim ret As stdArray
    Set ret = stdArray.CreateWithOptions(pLength, pChunking)
    Set Filter = ret

    'If initialised...
    If pInitialised Then
        Dim i As Long, v As Variant
        'Loop over array
        For i = 1 To pLength
            'If callback succeeds, push retvar
            If cb.Run(pArr(i)) Then
                Call ret.Push(pArr(i))
            End If
        Next i
    Else
        'error
    End If
End Function

Public Function Count(Optional ByVal cb As stdICallable = nothing) As Long
  if cb is nothing then
    Count = Length
  else
    Dim i As Long, lCount As Long
    lCount = 0
    For i = 1 To pLength
      If cb.Run(pArr(i)) Then
        lCount = lCount + 1
      End If
    Next i
    Count = lCount
  end if
End Function

Public Function Group(ByVal cb As stdICallable) As Object
    'Array to store result in
    Dim result As Object
    Set result = CreateObject("Scripting.Dictionary")

    'Loop over items
    Dim i As Long
    For i = 1 To pLength
        'Get grouping key
        Dim key As Variant
        key = cb.Run(pArr(i))

        'If key is not set then set it
        If Not result.exists(key) Then Set result(key) = stdArray.Create()

        'Push item to key
        result(key).Push pArr(i)
    Next

    'Return result
    Set Group = result
End Function

Public Function Max(Optional ByVal cb As stdICallable = nothing, Optional ByVal startingValue As Variant = Empty) as variant
  Dim vRet, vMaxValue, v
  vMaxValue = startingValue: vRet = startingValue
  For i = 1 to pLength
    Call CopyVariant(v,pArr(i))
    
    'Get value to test
    Dim vtValue as variant
    if cb is nothing then
      Call CopyVariant(vtValue,v)
    else
      Call CopyVariant(vtValue,cb.Run(v))
    end if

    'Compare values and return 
    if isEmpty(vRet) then
      Call CopyVariant(vRet,v)
      Call CopyVariant(vMaxValue, vtValue)
    elseif vMaxValue < vtValue then
      Call CopyVariant(vRet,v)
      Call CopyVariant(vMaxValue, vtValue)
    end if
  next

  Call CopyVariant(Max,vRet)
End Function
Public Function Min(Optional ByVal cb As stdICallable = nothing, Optional ByVal startingValue As Variant = Empty) as variant
  Dim vRet, vMinValue, v
  vMinValue = startingValue: vRet = startingValue
  For i = 1 to pLength
    Call CopyVariant(v,pArr(i))
    
    'Get value to test
    Dim vtValue as variant
    if cb is nothing then
      Call CopyVariant(vtValue,v)
    else
      Call CopyVariant(vtValue,cb.Run(v))
    end if

    'Compare values and return 
    if isEmpty(vRet) then
      Call CopyVariant(vRet,v)
      Call CopyVariant(vMinValue, vtValue)
    elseif vMinValue > vtValue then
      Call CopyVariant(vRet,v)
      Call CopyVariant(vMinValue, vtValue)
    end if
  next

  Call CopyVariant(Min,vRet)
End Function

'Copies one variant to a destination
'@param {ByRef Variant} dest Destination to copy variant to
'@param {Variant} value Source to copy variant from.
'@perf This appears to be a faster variant of "oleaut32.dll\VariantCopy" + it's multi-platform
Private Sub CopyVariant(ByRef dest As Variant, ByVal value As Variant)
  If IsObject(value) Then
    Set dest = value
  Else
    dest = value
  End If
End Sub