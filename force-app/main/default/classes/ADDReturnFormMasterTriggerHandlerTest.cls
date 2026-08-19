/*
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : ADDReturnFormMasterTriggerHandlerTest.
* @Why   : ADDReturnFormMasterTriggerHandlerTest class for the ADDReturnFormMasterTriggerHandler class.
* @When  : 07-SEP-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer            Date                  Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                07-SEP-2018           Work ID / Case ID           Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* vkaih                11-AUG-2020           Code Audit                  Updated class comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class ADDReturnFormMasterTriggerHandlerTest {
    /*
    * @Method       : testADDReturnFormMasterTriggerHandler.
    * @Description  : To test the ADDReturnFormMasterTriggerHandler class functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    public static void testADDReturnFormMasterTriggerHandler(){

        // Create Application Setup data
        Return_Form_Master__c returnFormMasterRecord = (Return_Form_Master__c) TestDataFactory.createSObject(new Return_Form_Master__c(), true);
        Update returnFormMasterRecord;
        Delete returnFormMasterRecord;
    	System.assertEquals(new List<Return_Form_Master__c>(), [SELECT Id FROM Return_Form_Master__c]);
    }
}