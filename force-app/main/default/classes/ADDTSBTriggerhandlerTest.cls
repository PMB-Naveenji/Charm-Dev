/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDTSBTriggerhandlerTest.
* @Why   : ADDTSBTriggerhandlerTest class for the ADDTSBTriggerhandler class.
* @When  : 03-SEP-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                   Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                03-SEP-2018            Work ID / Case ID             Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                17-AUG-2020            Code Audit                    Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                07-SEP-2020           PMD report fixes          Added System.assert's.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class ADDTSBTriggerhandlerTest {
    /*
    * @Method       : testADDTSB.
    * @Description  : To test the ADDTSBTriggerhandler class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    public static void testADDTSB(){

        // Create Application Setup data
        ADD_App_Settings__c appConfig = (ADD_App_Settings__c) TestDataFactory.createSObject(new ADD_App_Settings__c(), true);
        TSB__c tsbRecord = (TSB__c) TestDataFactory.createSObject(new TSB__c(), true);
        Update tsbRecord;
        Delete tsbRecord;
        //PMD report fix for System assert start. This method should be refactored.
        System.assertEquals(0, [SELECT count() FROM TSB__c], 'Record should be deleted');
        //PMD report fix for System assert end.
    }
}