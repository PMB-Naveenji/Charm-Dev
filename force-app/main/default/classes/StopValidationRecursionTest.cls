/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : StopValidationRecursionTest.
* @Why   : StopValidationRecursionTest test class for the StopValidationRecursion class.
* @When  : 10-AUG-2020.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer             Date                Modification ID                   Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                 10-AUG-2020         Work ID / Case ID                 Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                 07-SEP-2020         Code Audit                        Added assertEquals to stopValidationRecursionTest method.
* --------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public class StopValidationRecursionTest {

    /*
    * @Method       : stopValidationRecursionTest.
    * @Description  : To test the StopValidationRecursion functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest static void stopValidationRecursionTest() {
        Test.startTest();
        StopValidationRecursion.runonce();
        Test.stopTest();

        Boolean result = StopValidationRecursion.runonce(); 
        System.assertEquals(false, result, 'Result should be false');
    }
}