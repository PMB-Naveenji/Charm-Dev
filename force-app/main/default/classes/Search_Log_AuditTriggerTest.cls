/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : Search_Log_AuditTriggerTest.
* @Why   : Test class to handle different scenarios from 'Search_Log_AuditTrigger' trigger.
* @When  : 30-OCT-2018.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                  30-OCT-2018            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  09-JUL-2020            Code Audit                      Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                  08-SEP-2020            Code Audit                      Added assertEquals to testSearch_Log_AuditTrigger method.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class Search_Log_AuditTriggerTest {
    /*
    * @Method       : setup.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @testSetup
    static void setup(){
        // Create Application Setup data
        ADD_App_Settings__c appConfig = (ADD_App_Settings__c) TestDataFactory.createSObject(new ADD_App_Settings__c(), true);

         //Create Regulatory_Assessment__c
        Search_Log__c  objSearchLog = (Search_Log__c) TestDataFactory.createSObject(new Search_Log__c (),true);
    }

    /*
    * @Method       : testSearch_Log_AuditTrigger.
    * @Description  : To test the Regulatory_Assessment_AuditTriggerfunctionality.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    public static void testSearch_Log_AuditTrigger(){
       Search_Log__c objSearchLog = [SELECT id FROM Search_Log__c];
       Update objSearchLog;
       delete objSearchLog;

       System.assertEquals(0, [SELECT id FROM Search_Log__c].size(), 'Search Log should be deleted');
    }
}