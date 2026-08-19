/*
* --------------------------------------------------------------------------------------------------------------------------------------
* @Who   : Copyright (c) 2017 - 2020 Sparta Systems, Inc.
* @What  : Test_ComplaintTriggerHandler.
* @Why   : To test functionality of 'ComplaintTriggerHandler' class.
* @When  : 23-MAR-2017.
* @Where : N/A.
* --------------------------------------------------------------------------------------------------------------------------------------
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer              Date                   Modification ID                 Description
* --------------------------------------------------------------------------------------------------------------------------------------
* Admin                  23-MAR-2017            Work ID / Case ID               Created.
* --------------------------------------------------------------------------------------------------------------------------------------
* DSkak                  09-JUL-2020            Code Audit                      Updated header comments.
* --------------------------------------------------------------------------------------------------------------------------------------
* Oober                  07-SEP-2020            Code Audit                      Added assertEquals to testUpdate method.
* --------------------------------------------------------------------------------------------------------------------------------------
*/

@IsTest
public class Test_ComplaintTriggerHandler {
    /*
    * @Method       : setup.
    * @Description  : To insert test data.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @TestSetup
    static void setup() {
        TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            CMPL123Rule_Key_Value__c = 'SERVICE_WORKFLOW',
            CMPL123CME__CMPL123_WF_Status__c = 'Opened',
            Ticket_Type__c = 'Service'
        ), true);

        TestDataFactory.createSObject(new CMPL123CME__Complaint__c(
            CMPL123Rule_Key_Value__c = 'SERVICE_WORKFLOW',
            CMPL123CME__CMPL123_WF_Status__c = 'Opened',
            Ticket_Type__c = 'Service',
            Batch_Lot__c = 'B-T01'
        ), true);
    }

    /*
    * @Method       : testUpdate.
    * @Description  : To test update of Ticket record.
    * @Invoke       : N/A.
    * @Return       : N/A.
    * @Params       : N/A.
    */
    @IsTest
    public static void testUpdate() {
        CMPL123CME__Complaint__c complaint = [SELECT CMPL123Rule_Key_Value__c, CMPL123CME__CMPL123_WF_Status__c
                                                FROM CMPL123CME__Complaint__c
                                                WHERE Batch_Lot__c = 'B-T01'];	

        complaint.Ticket_Type__c = 'Complaint';
        update complaint;

        complaint.CMPL123CME__CMPL123_WF_Status__c = 'Closed-Voided';
        update complaint;

        System.assertEquals('Complaint', complaint.Ticket_Type__c, 'Ticket Type should be updated');
        System.assertEquals('Closed-Voided', complaint.CMPL123CME__CMPL123_WF_Status__c, 'Ticket WF Status should be updated');
    }
}