Attribute VB_Name = "Main"

Sub MainTestAll()
    Test.refresh

    On Error Resume Next
    Call stdLambdaTests.testAll
    Call stdArrayTests.testAll
    Call stdCallbackTests.testAll
    Call stdEnumeratorTests.testAll
    Call stdClipboardTests.testAll
<<<<<<< HEAD
=======
    Call stdRegexTests.testAll
>>>>>>> master
End Sub