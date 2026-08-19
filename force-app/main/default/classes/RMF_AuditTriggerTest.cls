/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : Search_Log_AuditTriggerTest.
* @Why   : Test class to handle different scenarios from RMF_AuditTrigger.
* @When  : 05-SEP-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                  05-SEP-2018            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  09-JUL-2020            Code Audit                      Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* rslob                  08-SEP-2020            PMD                             Added assertion into 
*                                                                               'testADDHazardAssessmentTriggerHandler' method.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class RMF_AuditTriggerTest {
    /*
    * @Method       : testADDHazardAssessmentTriggerHandler.
    * @Description  : To test the RMF_AuditTrigger functionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    public static void testADDHazardAssessmentTriggerHandler(){
        // Create Application Setup data
        ADD_App_Settings__c appConfig = (ADD_App_Settings__c) TestDataFactory.createSObject(new ADD_App_Settings__c(), true);
        Hazard_Assessment__c hazardAssessmentRecord = (Hazard_Assessment__c) TestDataFactory.createSObject(new Hazard_Assessment__c(), true);
        RMF__c rmfRecord = (RMF__c) TestDataFactory.createSObject(new RMF__c(Hazard_Assessment__c = hazardAssessmentRecord.Id), true);
        Update rmfRecord;
        Delete rmfRecord;
        System.assertEquals(0, [SELECT COUNT() FROM RMF__c]);
    }
}