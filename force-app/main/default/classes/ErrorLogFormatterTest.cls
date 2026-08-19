/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ErrorLogFormatterTest.
* @Why   : ErrorLogFormatterTest test class for the ErrorLogFormatter class.
* @When  : 09-AUG-2019.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* rslob                 09-AUG-2019         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                 17-AUG-2020         Code Audit                        Adjusted class/method headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
public with sharing class ErrorLogFormatterTest {

    /*
    * @Method       : TestErrorLogFormatter.
    * @Description  : To test the ErrorLogFormatter class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void TestErrorLogFormatter () {
        List<Error_Log__c> errorLogs = new List<Error_Log__c> ();
        errorLogs.add(ErrorLogFormatter.GetFormattedError(
                'Ticket #1',
                'Lorem ipsum dolor sit amet, ' +
                        'consectetur adipiscing elit. ' +
                        'Donec id justo tortor. Vivamus ' +
                        'ut eros arcu. In auctor vulputate ' +
                        'quam eget sollicitudin. Suspendisse ' +
                        'auctor ex magna, in pulvinar augue mollis ' +
                        'sit amet. Vivamus fringilla feugiat nisi, ' +
                        'vitae posuere.',
                '[{"errorType":"System.JSONException",' +
                        '"errorTxn":"Ticket processing failed",' +
                        '"errorMessage":"Malformed JSON: Expected \'{\' at the beginning of object",' +
                        '"errorCode":"15 : System.JSONException"}]',
                'Payload Data'
        ));
        errorLogs.add(ErrorLogFormatter.GetFormattedError('Ticket #2', '', '', ''));
        insert errorLogs;
        System.assertEquals(2, [SELECT COUNT() FROM Error_Log__c]);
    }

}