/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : CustomRecordLockingUtilTest.
* @Why   : Test class to handle different scenarios from CustomRecordLockingUtil.
* @When  : 13-JAN-2020.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                  13-JAN-2020            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  09-JUL-2020            Code Audit                      Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class CustomRecordLockingUtilTest {
    /*
    * @Method       : setupData.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @testSetup
    public static void setupData() {
        List <Customer_Response__c> newCRs = new List <Customer_Response__c> ();
        for (Integer i = 0; i < 5; i++) {
            newCRs.add(new Customer_Response__c (
                CMPL123_WF_Status__c = 'Opened'
            ));
        }
        insert newCRs;
    }

    /*
    * @Method       : testBehaviour.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @isTest
    public static void testBehaviour() {
        Map <Id, sObject> newRecords = new Map <Id, sObject> ([SELECT Id, Name, CMPL123_WF_Status__c FROM Customer_Response__c LIMIT 5]);
        Map <Id, sObject> oldRecords = new Map <Id, sObject> ([SELECT Id, Name, CMPL123_WF_Status__c FROM Customer_Response__c LIMIT 5]);

        List <String> lockedStatuses = new List <String> {'Opened'};
        List <String> allowedPermissionSets = new List <String> ();
        List <String> allowedFieldsAPINames = new List <String> ();

        CustomRecordLockingUtil.validateRecordEdit(newRecords, oldRecords, lockedStatuses, allowedPermissionSets, allowedFieldsAPINames);

        System.assertEquals(5, newRecords.keySet().size());
    }
}