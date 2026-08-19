/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDSearchTriggerHandlerTest.
* @Why   : ADDSearchTriggerHandlerTest class for the ADDSearchTriggerHandler class.
* @When  : 28-SEP-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                   Modification ID               Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                28-SEP-2018            Work ID / Case ID             Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                13-AUG-2020            Code Audit                    Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* oivan                07-SEP-2020           PMD report fixes          Added System.assert's.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class ADDSearchTriggerHandlerTest {
    /*
    * @Method       : testADDSearchTriggerHandler.
    * @Description  : To test the ADDSearchTriggerHandler class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    public static void testADDSearchTriggerHandler(){
        // Create Application Setup data
        Search__c searchRecord = (Search__c) TestDataFactory.createSObject(new Search__c(Criteria__c  = 'Test',
        										Search_Criteria__c  = 'Ticket: pRE Status not equal to i',
        										Search_Description__c  = 'test'
        										), true);
        Update searchRecord;
        Delete searchRecord;
        //PMD report fix for System assert start. This method should be refactored.
        System.assertEquals(0, [SELECT count() FROM Search__c], 'Record should be deleted');
        //PMD report fix for System assert end.
    }
}