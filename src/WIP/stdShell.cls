VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "stdShell"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Public Enum StdShellType
    File
    Dir
    Multifile
End Enum

Private sPaths() As String
Public iType As StdShellType

'@constructor
'@param sPath {String} - The path to wrap a shell object around.
Public Function Create(ByVal sPath As String) As stdShell
    'Get paths array
    Dim tPaths(1) As String: tPaths(1) = sPath
    
    'Get type of shell item
    Dim tType As StdShellType
    Select Case VBA.GetAttr(sPath)
        Case VbFileAttribute.vbDirectory, VbFileAttribute.vbVolume
            tType = Dir
        Case Else
            tType = File
    End Select
    
    'Create shell item
    Set Create = New stdShell
    Call Create.Init(tPaths, tType)
End Function
Public Sub Init(paramPaths() As String, pType As StdShellType)
    sPaths = paramPaths
    iType = pType
End Sub

Public Property Get Children() As stdEnumerator
    Dim vRet As Collection
    If iType = File Then
        Set vRet = New Collection
    ElseIf iType = Dir Then
        'Define return collection
        Set vRet = New Collection
        
        'Get child paths
        Dim sPath As String
        sPath = VBA.Dir(sPath & IIf(Right(sPath, 1) = "\", "*", "\*"))
        While sPath <> ""
            Call vRet.Add(stdShell.Create(sPath))
            sPath = VBA.Dir
        Wend
    End If
    
    Set Children = stdEnumerator.CreateFromIEnumVariant(vRet)
End Property

'Attempts to read data from a file
'@returns {Byte()} - Bytes read from file
Public Function Read() As Byte()
    If iType = File Then
        Dim ff As Long: ff = FreeFile
        Open sPath For Input As #ff
            Read = Input(LOF(ff), #ff)
        Close #ff
    Else
        CriticalFail "Cannot read this item as it is not a file"
    End If
End Function

'Attempts to read data from a file
'@returns {Byte()} - Bytes read from file
Public Function ReadText() As Byte()
    If iType = File Then
        Dim ff As Long: ff = FreeFile
        Open sPath For Input As #ff
            Dim s As String
            s = Input$(LOF(ff), #ff)
        Close #ff
    Else
        CriticalFail "Cannot read this item as it is not a file"
    End If
End Function

'Attempts to append data onto the end of a file
'@param data {ByVal Variant} - Data to append to file
'@returns {Boolean} - Success flag
Public Function Append(ByVal data As Variant) As Boolean
    If iType = File Then
        Dim ff As Long: ff = FreeFile
        Open sPath For Append As #ff
            Print #ff, data
        Close #ff
    Else
        CriticalFail "Cannot append data to this item as it is not a file"
    End If
End Function

'Attempts to overwrite the contents of the file
'@param data {ByVal Variant} - Data to write to file
'@returns {Boolean} - Success flag
Public Function Overwrite(ByVal data As Variant) As Boolean
    If iType = File Then
        Dim ff As Long: ff = FreeFile
        Open sPath For Output As #ff
            Print #ff, data
        Close #ff
    Else
        CriticalFail "Cannot write data to this item as it is not a file"
    End If
End Function

'Attempts to clear the file
'@returns {Boolean} - Success flag
Public Function Clear() As Boolean
    If iType = File Then
        Dim ff As Long: ff = FreeFile
        Open sPath For Output As #ff
        Close #ff
    Else
        CriticalFail "Cannot clear data from this item as it is not a file"
    End If
End Function


'Attempts to clear the file
'
Public Function Find(ByVal callable As stdICallable, Optional ByVal bRecurse As Boolean = True) As stdShell
    If iType = Dir Then
        'Get children as collection
        Dim col As Collection: Set col = Children.Object
        
        Dim shellItem As stdShell
        While Not CollectionShift(col, shellItem) Is Nothing
            Dim child As stdShell
            For Each child In shellItem.Children
                If callable.Run(child) Then
                    Set Find = child
                    Exit Function
                End If
                
                If child.iType = Dir Then col.Add child
            Next
        Wend
    End If
End Function
Public Function FindAll(ByVal callable As stdICallable) As stdEnumerator
    Dim vRet As Collection: Set vRet = New Collection
    If iType = Dir Then
        'Get children as collection
        Dim col As Collection: Set col = Children.Object
        
        Dim shellItem As stdShell
        While Not CollectionShift(col, shellItem) Is Nothing
            Dim child As stdShell
            For Each child In shellItem.Children
                If callable.Run(child) Then
                    vRet.Add child
                End If
                
                If child.iType = Dir Then col.Add child
            Next
        Wend
    End If
    Set FindAll = stdEnumerator.CreateFromIEnumVariant(vRet)
End Function

Private Function CollectionShift(ByRef col As Collection, ByRef shellItem As stdShell) As stdShell
    Set CollectionPop = col.item(1)
    Set shellItem = col.item(1)
    Call col.Remove(1)
End Function
