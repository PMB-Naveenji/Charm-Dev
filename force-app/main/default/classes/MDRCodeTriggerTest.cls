/*
*  --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020  Sparta Systems, Inc.
* @What  : MDRCodeTrigger.
* @Why   : To Handles all the customization involved on CMPL123CME__MDR_Code__c object.
* @When  : 07-FEB-2019.
* @Where : From CMPL123CME__MDR_Code__c object events.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer               Date                   Modification ID             Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                   07-FEB-2019            Work ID / Case ID           Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                   22-MAY-2020            Defect #123/CHARM-2729      Added testUpdate() method, adjusted existing test() method.
* --------------------------------------------------------------------------------------------------------------------------------------
* rsitc                   19-AUG-2020            Code Audit                  Adjusted class/method headers.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
private class MDRCodeTriggerTest {

    /*
    * @Method       : setupData.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup
    static void setupData(){
        Country__c objCountry = (Country__c) TestDataFactory.createSObject(new Country__c(), true);
        TestDataFactory.createSObject(new Country_Submission_Type__c(
                Name = '30 Days',
                Calendar_Days__c = 30,
                Country__c = objCountry.Id
        ), true);
        Id EMDRInitial = Schema.SObjectType.CMPL123CME__EMDR__c.getRecordTypeInfosByName().get('Initial').getRecordTypeId();
        CMPL123CME__EMDR__c EMDRInitialRecord = (CMPL123CME__EMDR__c) TestDataFactory.createSObject(
                new CMPL123CME__EMDR__c(
                        RecordTypeId = EMDRInitial), true);
        CMPL123CME__MDR_Code__c mdrCode = new CMPL123CME__MDR_Code__c(CMPL123CME__EMDR__c = EMDRInitialRecord.Id);
        insert mdrCode;
    }

    /*
    * @Method       : test.
    * @Description  : Tests deleting of mdrCode.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    // Defect #123/CHARM-2729: removed mdrCode insert as it was moved to testSetup
    @IsTest
    private static void test() {
        CMPL123CME__MDR_Code__c mdrCode = [SELECT Id, LastModifiedDate FROM CMPL123CME__MDR_Code__c LIMIT 1];
        Test.startTest();
        delete mdrCode;
        System.assertEquals(0, [SELECT COUNT() FROM CMPL123CME__MDR_Code__c]);
        Test.stopTest();
    }

    /*
    * @Method       : testUpdate.
    * @Description  : Tests emdr updating upon mdrCode update.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    // Defect #123/CHARM-2729: added testUpdate() to test emdr updating upon mdrCode update
    @IsTest
    private static void testUpdate() {
        CMPL123CME__EMDR__c emdr = [SELECT LastModifiedDate FROM CMPL123CME__EMDR__c LIMIT 1];
        CMPL123CME__MDR_Code__c mdrCode = [SELECT Id, LastmodifiedDate FROM CMPL123CME__MDR_Code__c WHERE CMPL123CME__EMDR__c = :emdr.Id LIMIT 1];
        Test.startTest();
        mdrCode.CMPL123CME__Category__c = 'Evaluation Code';
        EMDRTriggerHandler.isLastModifiedDateUpdatedFromChild = false;
        update mdrCode;
        CMPL123CME__MDR_Code__c mdrCodeUpdated = [SELECT Id, LastModifiedDate FROM CMPL123CME__MDR_Code__c WHERE Id = :mdrCode.Id];
        CMPL123CME__EMDR__c emdrUpdated = [SELECT LastModifiedDate FROM CMPL123CME__EMDR__c WHERE Id = :emdr.Id];
        System.assert(emdrUpdated.LastModifiedDate.minute() - mdrCodeUpdated.LastModifiedDate.minute() <= 10);
        Test.stopTest();
    }
}