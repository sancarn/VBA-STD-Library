Attribute VB_Name = "Main"

Sub MainTestAll()
    Test.refresh

    On Error Resume Next
    Call stdLambdaTests.testAll
    Call stdArrayTests.testAll
    Call stdCallbackTests.testAll
    Call stdEnumeratorTests.testAll
    Call stdClipboardTests.testAll
    Call stdRegexTests.testAll
    Call stdWebSocketTests.testAll
End Sub