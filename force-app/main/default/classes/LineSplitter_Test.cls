/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : LineSplitter_Test.
* @Why   : LineSplitter_Test test class for the LineSplitter class.
* @When  : 22-MAY-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                 22-MAY-2019         N/A                               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                 04-JUN-2020         Code Audit                        Removed 'System.debug()'.
* --------------------------------------------------------------------------------------------------------------------------------------
* RSlob                 15-JUN-2020         Code Audit                        Removed commented code. Formatting.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                 17-AUG-2020         Code Audit                        Adjusted class/method headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
private class LineSplitter_Test {

    /*
    * @Method       : nullTest.
    * @Description  : To test null handling.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    private static void nullTest() {
        runTest(null, null, null);
    }

    /*
    * @Method       : noSplitTest.
    * @Description  : To test null length handling.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    private static void noSplitTest() {
        runTest('asdf', null, 'asdf');
    }

    /*
    * @Method       : codeSplit.
    * @Description  : To test code with dashes handling.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    private static void codeSplit() {
        String input = 'BEADI-MTVAD-9SEAA';
        Integer lineLength = 7;
        String output = 'BEADI-' + LineSplitter.NEW_LINE +
            'MTVAD-' + LineSplitter.NEW_LINE +
            '9SEAA';
        runTest(input, lineLength, output);
    }

    /*
    * @Method       : longWord.
    * @Description  : To test long word handling.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    private static void longWord() {
        String input = 'veryverylongword';
        Integer lineLength = 10;
        String output = 'veryveryl-' + LineSplitter.NEW_LINE +
            'ongword';
        runTest(input, lineLength, output);
    }

    /*
    * @Method       : runTest.
    * @Description  : Generic method to run LineSplitter.
    * @Invoke       : From nullTest, noSplitTest, codeSplit and longWord methods.
    * @Return       : N/A.
    * @Params       : String input, Integer lineLength, String expected.
    */
    private static void runTest(String input, Integer lineLength, String expected) {
        LineSplitter splitter = new LineSplitter();
        splitter.myInput = input;
        splitter.myLineLength = lineLength;
        System.assertEquals(expected, splitter.output);
    }
}